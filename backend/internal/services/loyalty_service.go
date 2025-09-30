package services

import (
	"context"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LoyaltyService handles loyalty program operations
type LoyaltyService struct {
	loyaltyRepo      repository.LoyaltyRepository
	userRepo         repository.UserRepository
	config           *models.LoyaltyConfig
}

// NewLoyaltyService creates a new loyalty service
func NewLoyaltyService(
	loyaltyRepo repository.LoyaltyRepository,
	userRepo repository.UserRepository,
	_ interface{}, // placeholder for notification service
) *LoyaltyService {
	return &LoyaltyService{
		loyaltyRepo: loyaltyRepo,
		userRepo:    userRepo,
		config:      models.DefaultLoyaltyConfig(),
	}
}

// GetLoyaltyProgram gets user's loyalty program
func (s *LoyaltyService) GetLoyaltyProgram(ctx context.Context, userID primitive.ObjectID) (*models.LoyaltyProgram, error) {
	_, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		// Create new loyalty program if doesn't exist
		return s.CreateLoyaltyProgram(ctx, userID)
	}

	// Check and update daily login
	if err := s.CheckDailyLogin(ctx, userID); err != nil {
		return nil, fmt.Errorf("failed to check daily login: %w", err)
	}

	// Refresh data after potential daily login update
	return s.loyaltyRepo.GetProgramByUserID(ctx, userID)
}

// CreateLoyaltyProgram creates a new loyalty program for user
func (s *LoyaltyService) CreateLoyaltyProgram(ctx context.Context, userID primitive.ObjectID) (*models.LoyaltyProgram, error) {
	program := &models.LoyaltyProgram{
		UserID:        userID,
		TotalPoints:   s.config.WelcomeBonus,
		CurrentPoints: s.config.WelcomeBonus,
		Tier:          models.TierBronze,
		LoginStreak:   1,
		LastLoginDate: &time.Time{},
		TotalSpent:    0,
		TotalOrders:   0,
		Transactions: []models.PointTransaction{
			{
				ID:          primitive.NewObjectID(),
				Type:        models.TransactionBonus,
				Points:      s.config.WelcomeBonus,
				Description: "Welcome bonus!",
				CreatedAt:   time.Now(),
			},
		},
		Vouchers:  []models.UserVoucher{},
		JoinedAt:  time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := s.loyaltyRepo.CreateProgram(ctx, program); err != nil {
		return nil, fmt.Errorf("failed to create loyalty program: %w", err)
	}

	// TODO: Send welcome notification when notification service is available

	return program, nil
}

// CheckDailyLogin checks and awards daily login bonus
func (s *LoyaltyService) CheckDailyLogin(ctx context.Context, userID primitive.ObjectID) error {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	// Check if already logged in today
	if program.LastLoginDate != nil {
		lastLoginDay := time.Date(
			program.LastLoginDate.Year(),
			program.LastLoginDate.Month(),
			program.LastLoginDate.Day(),
			0, 0, 0, 0, program.LastLoginDate.Location(),
		)

		if today.Equal(lastLoginDay) {
			return nil // Already logged in today
		}
	}

	bonusPoints := s.config.DailyLoginBonus
	newStreak := 1

	if program.LastLoginDate != nil {
		yesterday := today.AddDate(0, 0, -1)
		lastLoginDay := time.Date(
			program.LastLoginDate.Year(),
			program.LastLoginDate.Month(),
			program.LastLoginDate.Day(),
			0, 0, 0, 0, program.LastLoginDate.Location(),
		)

		if yesterday.Equal(lastLoginDay) {
			// Consecutive day
			newStreak = program.LoginStreak + 1

			// Check for streak bonus
			if newStreak%s.config.StreakBonusDays == 0 {
				bonusPoints += s.config.StreakBonusPoints

				// TODO: Send streak bonus notification when notification service is available
			}
		}
	}

	// Add daily login bonus
	if err := s.AddPoints(ctx, userID, bonusPoints, fmt.Sprintf("Daily login bonus (%d day streak)", newStreak), models.TransactionBonus, nil); err != nil {
		return fmt.Errorf("failed to add daily login bonus: %w", err)
	}

	// Update login streak and last login date
	program.LoginStreak = newStreak
	program.LastLoginDate = &now

	if err := s.loyaltyRepo.UpdateProgram(ctx, program); err != nil {
		return fmt.Errorf("failed to update login streak: %w", err)
	}

	return nil
}

// AddPoints adds points to user's loyalty program
func (s *LoyaltyService) AddPoints(ctx context.Context, userID primitive.ObjectID, points int, description string, transactionType models.TransactionType, orderID *primitive.ObjectID) error {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Create transaction
	transaction := models.PointTransaction{
		ID:          primitive.NewObjectID(),
		Type:        transactionType,
		Points:      points,
		Description: description,
		OrderID:     orderID,
		CreatedAt:   time.Now(),
	}

	// Update points
	program.TotalPoints += points
	program.CurrentPoints += points
	program.Transactions = append(program.Transactions, transaction)
	program.UpdatedAt = time.Now()

	// Check for tier upgrade
	newTier := s.CalculateTier(program.TotalPoints)
	if newTier != program.Tier {
		program.Tier = newTier

		// TODO: Send tier upgrade notification when notification service is available
	}

	if err := s.loyaltyRepo.UpdateProgram(ctx, program); err != nil {
		return fmt.Errorf("failed to update loyalty program: %w", err)
	}

	return nil
}

// AddPointsFromPurchase adds points based on purchase amount
func (s *LoyaltyService) AddPointsFromPurchase(ctx context.Context, userID primitive.ObjectID, amount float64, orderID primitive.ObjectID) error {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Calculate points with tier multiplier
	tierInfo := program.Tier.GetTierInfo()
	points := int(amount * s.config.BasePointsPerDollar * tierInfo.Multiplier)

	// Add purchase points
	if err := s.AddPoints(ctx, userID, points, fmt.Sprintf("Purchase reward for order #%s", orderID.Hex()[:8]), models.TransactionEarned, &orderID); err != nil {
		return fmt.Errorf("failed to add purchase points: %w", err)
	}

	// Update total spent and orders
	program.TotalSpent += amount
	program.TotalOrders++
	program.UpdatedAt = time.Now()

	if err := s.loyaltyRepo.UpdateProgram(ctx, program); err != nil {
		return fmt.Errorf("failed to update purchase stats: %w", err)
	}

	// TODO: Send points earned notification when notification service is available

	return nil
}

// RedeemVoucher redeems a voucher for points
func (s *LoyaltyService) RedeemVoucher(ctx context.Context, userID primitive.ObjectID, voucherID primitive.ObjectID) (*models.UserVoucher, error) {
	// Note: Voucher operations should be handled by VoucherService
	return nil, fmt.Errorf("voucher operations should be handled by VoucherService")
}

// GetAvailableVouchers gets all available vouchers for redemption
func (s *LoyaltyService) GetAvailableVouchers(ctx context.Context) ([]models.Voucher, error) {
	// Note: This should be handled by VoucherService
	return []models.Voucher{}, nil
}

// UseVoucher marks a user voucher as used
func (s *LoyaltyService) UseVoucher(ctx context.Context, userID primitive.ObjectID, voucherCode string) error {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Find the voucher
	for i, voucher := range program.Vouchers {
		if voucher.Code == voucherCode && !voucher.IsUsed {
			// Check if voucher is still valid
			if voucher.ExpiresAt != nil && time.Now().After(*voucher.ExpiresAt) {
				return fmt.Errorf("voucher has expired")
			}

			// Mark as used
			now := time.Now()
			program.Vouchers[i].IsUsed = true
			program.Vouchers[i].UsedAt = &now
			program.UpdatedAt = time.Now()

			return s.loyaltyRepo.UpdateProgram(ctx, program)
		}
	}

	return fmt.Errorf("voucher not found or already used")
}

// CalculateTier calculates loyalty tier based on total points
func (s *LoyaltyService) CalculateTier(totalPoints int) models.LoyaltyTier {
	if totalPoints >= 5000 {
		return models.TierPlatinum
	} else if totalPoints >= 2000 {
		return models.TierGold
	} else if totalPoints >= 500 {
		return models.TierSilver
	}
	return models.TierBronze
}

// GetPointsHistory gets user's points transaction history
func (s *LoyaltyService) GetPointsHistory(ctx context.Context, userID primitive.ObjectID, limit int, offset int) ([]models.PointTransaction, error) {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get loyalty program: %w", err)
	}

	transactions := program.Transactions

	// Sort by creation date (newest first)
	start := offset
	end := offset + limit

	if start >= len(transactions) {
		return []models.PointTransaction{}, nil
	}

	if end > len(transactions) {
		end = len(transactions)
	}

	// Reverse slice to get newest first
	reversed := make([]models.PointTransaction, len(transactions))
	for i, j := 0, len(transactions)-1; i < len(transactions); i, j = i+1, j-1 {
		reversed[i] = transactions[j]
	}

	return reversed[start:end], nil
}

// GetUserVouchers gets all vouchers owned by user
func (s *LoyaltyService) GetUserVouchers(ctx context.Context, userID primitive.ObjectID, onlyUnused bool) ([]models.UserVoucher, error) {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get loyalty program: %w", err)
	}

	if !onlyUnused {
		return program.Vouchers, nil
	}

	// Filter only unused vouchers
	var unusedVouchers []models.UserVoucher
	for _, voucher := range program.Vouchers {
		if !voucher.IsUsed {
			// Check if still valid
			if voucher.ExpiresAt == nil || time.Now().Before(*voucher.ExpiresAt) {
				unusedVouchers = append(unusedVouchers, voucher)
			}
		}
	}

	return unusedVouchers, nil
}

// UpdateLoyaltyConfig updates loyalty program configuration
func (s *LoyaltyService) UpdateLoyaltyConfig(ctx context.Context, config *models.LoyaltyConfig) error {
	config.UpdatedAt = time.Now()
	s.config = config
	return s.loyaltyRepo.UpdateConfig(ctx, config)
}

// GetLoyaltyConfig gets current loyalty program configuration
func (s *LoyaltyService) GetLoyaltyConfig(ctx context.Context) (*models.LoyaltyConfig, error) {
	if s.config != nil {
		return s.config, nil
	}

	config, err := s.loyaltyRepo.GetConfig(ctx)
	if err != nil {
		// Return default config if not found
		s.config = models.DefaultLoyaltyConfig()
		return s.config, nil
	}

	s.config = config
	return config, nil
}