package services

import (
	"context"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// VoucherService handles voucher and reward operations
type VoucherService struct {
	voucherRepo repository.VoucherRepository
	loyaltyRepo repository.LoyaltyRepository
}

// NewVoucherService creates a new voucher service
func NewVoucherService(voucherRepo repository.VoucherRepository, loyaltyRepo repository.LoyaltyRepository) *VoucherService {
	return &VoucherService{
		voucherRepo: voucherRepo,
		loyaltyRepo: loyaltyRepo,
	}
}

// CreateVoucher creates a new voucher template
func (s *VoucherService) CreateVoucher(ctx context.Context, voucher *models.Voucher) error {
	voucher.ID = primitive.NewObjectID()
	voucher.CreatedAt = time.Now()
	voucher.UpdatedAt = time.Now()
	voucher.IsActive = true

	// Generate unique code if not provided
	if voucher.Code == "" {
		voucher.Code = fmt.Sprintf("VOUCHER_%s", voucher.ID.Hex()[:8])
	}

	return s.voucherRepo.Create(ctx, voucher)
}

// GetAvailableVouchers returns all available vouchers for redemption
func (s *VoucherService) GetAvailableVouchers(ctx context.Context) ([]models.Voucher, error) {
	return s.voucherRepo.GetAvailable(ctx)
}

// RedeemVoucher redeems a voucher for loyalty points
func (s *VoucherService) RedeemVoucher(ctx context.Context, userID, voucherID primitive.ObjectID) (*models.UserVoucher, error) {
	// Get voucher details
	voucher, err := s.voucherRepo.GetByID(ctx, voucherID)
	if err != nil {
		return nil, fmt.Errorf("voucher not found: %w", err)
	}

	// Check if voucher is valid
	if !voucher.IsValid() {
		return nil, fmt.Errorf("voucher is not valid or has expired")
	}

	// Check redemption limits
	if voucher.MaxRedemptions > 0 {
		count, err := s.voucherRepo.GetRedemptionCount(ctx, voucherID)
		if err != nil {
			return nil, fmt.Errorf("failed to check redemption count: %w", err)
		}
		if count >= voucher.MaxRedemptions {
			return nil, fmt.Errorf("voucher redemption limit reached")
		}
	}

	// Check per-user limits
	if voucher.MaxPerUser > 0 {
		userCount, err := s.voucherRepo.GetUserRedemptionCount(ctx, userID, voucherID)
		if err != nil {
			return nil, fmt.Errorf("failed to check user redemption count: %w", err)
		}
		if userCount >= voucher.MaxPerUser {
			return nil, fmt.Errorf("user redemption limit reached for this voucher")
		}
	}

	// Get user loyalty program to check points
	loyaltyProgram, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Check if user has enough points
	if loyaltyProgram.CurrentPoints < voucher.PointsCost {
		return nil, fmt.Errorf("insufficient points: need %d, have %d", voucher.PointsCost, loyaltyProgram.CurrentPoints)
	}

	// Deduct points from user's account
	loyaltyProgram.CurrentPoints -= voucher.PointsCost
	// Note: RedeemedPoints field doesn't exist in current model
	loyaltyProgram.UpdatedAt = time.Now()

	err = s.loyaltyRepo.UpdateProgram(ctx, loyaltyProgram)
	if err != nil {
		return nil, fmt.Errorf("failed to update loyalty program: %w", err)
	}

	// Create user voucher
	userVoucher := &models.UserVoucher{
		ID:              primitive.NewObjectID(),
		UserID:          userID,
		VoucherID:       voucherID,
		Code:            fmt.Sprintf("%s_%s", voucher.Code, primitive.NewObjectID().Hex()[:6]),
		DiscountType:    voucher.DiscountType,
		Value:           voucher.Value,
		MinOrderValue:   voucher.MinOrderValue,
		MaxDiscount:     voucher.MaxDiscount,
		IssuedAt:        time.Now(),
		IsUsed:          false,
		UsageConditions: voucher.UsageConditions,
	}

	// Set expiration date
	if voucher.ValidUntil != nil {
		userVoucher.ExpiresAt = voucher.ValidUntil
	}

	err = s.voucherRepo.CreateUserVoucher(ctx, userVoucher)
	if err != nil {
		return nil, fmt.Errorf("failed to create user voucher: %w", err)
	}

	// TODO: Add points transaction record when PointTransaction model is available

	return userVoucher, nil
}

// GetUserVouchers returns vouchers owned by a user
func (s *VoucherService) GetUserVouchers(ctx context.Context, userID primitive.ObjectID, onlyUnused bool) ([]models.UserVoucher, error) {
	return s.voucherRepo.GetUserVouchers(ctx, userID, onlyUnused)
}

// ValidateVoucherCode validates a voucher code for order usage
func (s *VoucherService) ValidateVoucherCode(ctx context.Context, userID primitive.ObjectID, code string, orderValue float64) (*models.VoucherValidation, error) {
	userVoucher, err := s.voucherRepo.GetUserVoucherByCode(ctx, userID, code)
	if err != nil {
		return &models.VoucherValidation{
			IsValid: false,
			Error:   "Voucher not found",
		}, nil
	}

	if userVoucher.IsUsed {
		return &models.VoucherValidation{
			IsValid: false,
			Error:   "Voucher has already been used",
		}, nil
	}

	if userVoucher.ExpiresAt != nil && time.Now().After(*userVoucher.ExpiresAt) {
		return &models.VoucherValidation{
			IsValid: false,
			Error:   "Voucher has expired",
		}, nil
	}

	if orderValue < userVoucher.MinOrderValue {
		return &models.VoucherValidation{
			IsValid: false,
			Error:   fmt.Sprintf("Minimum order value of %.2f required", userVoucher.MinOrderValue),
		}, nil
	}

	// Calculate discount
	var discountAmount float64
	if userVoucher.DiscountType == "percentage" {
		discountAmount = orderValue * (userVoucher.Value / 100)
		if userVoucher.MaxDiscount > 0 && discountAmount > userVoucher.MaxDiscount {
			discountAmount = userVoucher.MaxDiscount
		}
	} else {
		discountAmount = userVoucher.Value
	}

	finalAmount := orderValue - discountAmount
	if finalAmount < 0 {
		finalAmount = 0
	}

	return &models.VoucherValidation{
		IsValid:        true,
		UserVoucher:    userVoucher,
		DiscountAmount: discountAmount,
		FinalAmount:    finalAmount,
	}, nil
}

// UseVoucher marks a voucher as used
func (s *VoucherService) UseVoucher(ctx context.Context, userID primitive.ObjectID, code string) error {
	userVoucher, err := s.voucherRepo.GetUserVoucherByCode(ctx, userID, code)
	if err != nil {
		return fmt.Errorf("voucher not found: %w", err)
	}

	if userVoucher.IsUsed {
		return fmt.Errorf("voucher has already been used")
	}

	if userVoucher.ExpiresAt != nil && time.Now().After(*userVoucher.ExpiresAt) {
		return fmt.Errorf("voucher has expired")
	}

	// Mark as used
	now := time.Now()
	userVoucher.IsUsed = true
	userVoucher.UsedAt = &now

	return s.voucherRepo.UpdateUserVoucher(ctx, userVoucher)
}

// UpdateVoucher updates an existing voucher
func (s *VoucherService) UpdateVoucher(ctx context.Context, voucher *models.Voucher) error {
	voucher.UpdatedAt = time.Now()
	return s.voucherRepo.Update(ctx, voucher)
}

// DeactivateVoucher deactivates a voucher
func (s *VoucherService) DeactivateVoucher(ctx context.Context, voucherID primitive.ObjectID) error {
	voucher, err := s.voucherRepo.GetByID(ctx, voucherID)
	if err != nil {
		return fmt.Errorf("voucher not found: %w", err)
	}

	voucher.IsActive = false
	voucher.UpdatedAt = time.Now()

	return s.voucherRepo.Update(ctx, voucher)
}

// GetVoucherAnalytics returns voucher usage analytics
func (s *VoucherService) GetVoucherAnalytics(ctx context.Context, startDate, endDate time.Time) (*models.VoucherAnalytics, error) {
	return s.voucherRepo.GetAnalytics(ctx, startDate, endDate)
}

// CreateReward creates a reward for user actions
func (s *VoucherService) CreateReward(ctx context.Context, userID primitive.ObjectID, rewardType string, metadata map[string]interface{}) error {
	reward := &models.Reward{
		ID:          primitive.NewObjectID(),
		UserID:      userID,
		Type:        rewardType,
		Status:      models.RewardStatusEarned,
		Metadata:    metadata,
		EarnedAt:    time.Now(),
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	// Set reward details based on type
	switch rewardType {
	case models.RewardTypeFirstOrder:
		reward.Description = "First order reward"
		reward.Value = 100
	case models.RewardTypeReviewSubmitted:
		reward.Description = "Review submission reward"
		reward.Value = 50
	case models.RewardTypeReferralSuccessful:
		reward.Description = "Successful referral reward"
		reward.Value = 200
	default:
		reward.Description = fmt.Sprintf("%s reward", rewardType)
		reward.Value = 10
	}

	return s.voucherRepo.CreateReward(ctx, reward)
}

// GetUserRewards returns rewards for a user
func (s *VoucherService) GetUserRewards(ctx context.Context, userID primitive.ObjectID, status string) ([]models.Reward, error) {
	return s.voucherRepo.GetUserRewards(ctx, userID, status)
}

// ClaimReward claims a pending reward
func (s *VoucherService) ClaimReward(ctx context.Context, userID, rewardID primitive.ObjectID) error {
	reward, err := s.voucherRepo.GetRewardByID(ctx, rewardID)
	if err != nil {
		return fmt.Errorf("reward not found: %w", err)
	}

	if reward.UserID != userID {
		return fmt.Errorf("reward does not belong to user")
	}

	if reward.Status != models.RewardStatusEarned {
		return fmt.Errorf("reward is not available for claiming")
	}

	// Update reward status
	now := time.Now()
	reward.Status = models.RewardStatusClaimed
	reward.ClaimedAt = &now
	reward.UpdatedAt = now

	err = s.voucherRepo.UpdateReward(ctx, reward)
	if err != nil {
		return fmt.Errorf("failed to update reward: %w", err)
	}

	// Add points to user's loyalty account
	loyaltyProgram, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	loyaltyProgram.CurrentPoints += reward.Value
	loyaltyProgram.UpdatedAt = time.Now()

	err = s.loyaltyRepo.UpdateProgram(ctx, loyaltyProgram)
	if err != nil {
		return fmt.Errorf("failed to update loyalty program: %w", err)
	}

	// TODO: Add transaction record when PointTransaction model is available
	return nil
}

// ProcessOrderRewards processes rewards for order completion
func (s *VoucherService) ProcessOrderRewards(ctx context.Context, userID, orderID primitive.ObjectID) error {
	// This would typically check order details and award appropriate rewards
	// For now, just create a simple order completion reward
	return s.CreateReward(ctx, userID, models.RewardTypeFirstOrder, map[string]interface{}{
		"orderId": orderID,
	})
}
