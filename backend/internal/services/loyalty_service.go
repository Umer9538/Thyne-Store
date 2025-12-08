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
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		// Create new loyalty program if doesn't exist
		return s.CreateLoyaltyProgram(ctx, userID)
	}

	// Check and update daily login (non-blocking - don't fail if this fails)
	if err := s.CheckDailyLogin(ctx, userID); err != nil {
		// Log the error but continue - daily login is not critical
		fmt.Printf("Warning: failed to check daily login for user %s: %v\n", userID.Hex(), err)
		// Return the existing program anyway
		return program, nil
	}

	// Refresh data after potential daily login update
	return s.loyaltyRepo.GetProgramByUserID(ctx, userID)
}

// CreateLoyaltyProgram creates a new loyalty program for user
func (s *LoyaltyService) CreateLoyaltyProgram(ctx context.Context, userID primitive.ObjectID) (*models.LoyaltyProgram, error) {
	program := &models.LoyaltyProgram{
		UserID:           userID,
		TotalCredits:     s.config.WelcomeBonus,
		AvailableCredits: s.config.WelcomeBonus,
		Tier:             models.TierBronze,
		LoginStreak:      0,
		LastLoginDate:    nil,
		TotalSpent:       0,
		TotalOrders:      0,
		JoinedAt:         time.Now(),
		UpdatedAt:        time.Now(),
	}

	if err := s.loyaltyRepo.CreateProgram(ctx, program); err != nil {
		return nil, fmt.Errorf("failed to create loyalty program: %w", err)
	}

	// Add welcome bonus transaction
	transaction := &models.PointTransaction{
		UserID:      userID,
		Type:        models.TransactionWelcomeBonus,
		Credits:     s.config.WelcomeBonus,
		Description: "Welcome to the loyalty program!",
	}
	if err := s.loyaltyRepo.AddTransaction(ctx, transaction); err != nil {
		return nil, fmt.Errorf("failed to add welcome bonus transaction: %w", err)
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

	// Get tier info for multiplier
	tierInfo := program.Tier.GetTierInfo()
	bonusCredits := int(float64(s.config.DailyLoginBonus) * tierInfo.CreditsMultiplier)
	newStreak := 1
	description := "Daily login bonus"

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
			description = fmt.Sprintf("Daily login bonus (%d day streak)", newStreak)

			// Check for streak bonus
			if newStreak%s.config.StreakBonusDays == 0 {
				streakBonus := int(float64(s.config.StreakBonusCredits) * tierInfo.CreditsMultiplier)

				// Add streak bonus as separate transaction
				if err := s.AddCredits(ctx, userID, streakBonus, fmt.Sprintf("Streak milestone bonus! (%d days)", newStreak), models.TransactionStreakBonus, nil); err != nil {
					return fmt.Errorf("failed to add streak bonus: %w", err)
				}

				// TODO: Send streak bonus notification when notification service is available
			}
		}
	}

	// Add daily login bonus
	if err := s.AddCredits(ctx, userID, bonusCredits, description, models.TransactionLoginBonus, nil); err != nil {
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

// AddCredits adds credits to user's loyalty program
func (s *LoyaltyService) AddCredits(ctx context.Context, userID primitive.ObjectID, credits int, description string, transactionType models.TransactionType, orderID *primitive.ObjectID) error {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Create transaction
	transaction := &models.PointTransaction{
		UserID:      userID,
		Type:        transactionType,
		Credits:     credits,
		Description: description,
		OrderID:     orderID,
	}

	if err := s.loyaltyRepo.AddTransaction(ctx, transaction); err != nil {
		return fmt.Errorf("failed to add transaction: %w", err)
	}

	// Update credits
	program.TotalCredits += credits
	program.AvailableCredits += credits
	program.UpdatedAt = time.Now()

	if err := s.loyaltyRepo.UpdateProgram(ctx, program); err != nil {
		return fmt.Errorf("failed to update loyalty program: %w", err)
	}

	return nil
}

// AddCreditsFromPurchase adds credits based on purchase amount
func (s *LoyaltyService) AddCreditsFromPurchase(ctx context.Context, userID primitive.ObjectID, amount float64, orderID primitive.ObjectID) error {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Update total spent and orders first
	program.TotalSpent += amount
	program.TotalOrders++

	// Check for tier upgrade based on spending
	oldTier := program.Tier
	program.UpdateTierBasedOnSpending()

	// Calculate credits with tier multiplier
	tierInfo := program.Tier.GetTierInfo()
	credits := int(amount * s.config.BaseCreditsPerDollar * tierInfo.CreditsMultiplier)

	// Add purchase credits
	if err := s.AddCredits(ctx, userID, credits, fmt.Sprintf("Purchase reward for order #%s", orderID.Hex()[:8]), models.TransactionEarned, &orderID); err != nil {
		return fmt.Errorf("failed to add purchase credits: %w", err)
	}

	// Update program (spending and tier changes)
	program.UpdatedAt = time.Now()
	if err := s.loyaltyRepo.UpdateProgram(ctx, program); err != nil {
		return fmt.Errorf("failed to update purchase stats: %w", err)
	}

	// Send tier upgrade notification if tier changed
	if program.Tier != oldTier {
		// TODO: Send tier upgrade notification when notification service is available
	}

	// TODO: Send credits earned notification when notification service is available

	return nil
}

// RedeemCredits redeems credits for a discount or voucher
func (s *LoyaltyService) RedeemCredits(ctx context.Context, userID primitive.ObjectID, redemptionID string) (string, error) {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return "", fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Find the redemption option
	options := models.GetRedemptionOptions()
	var selectedOption *models.RedemptionOption
	for _, opt := range options {
		if opt.ID == redemptionID {
			selectedOption = &opt
			break
		}
	}

	if selectedOption == nil {
		return "", fmt.Errorf("invalid redemption option")
	}

	// Check if user has enough credits
	if program.AvailableCredits < selectedOption.CreditsRequired {
		return "", fmt.Errorf("insufficient credits: you have %d credits, need %d", program.AvailableCredits, selectedOption.CreditsRequired)
	}

	// Deduct credits
	program.AvailableCredits -= selectedOption.CreditsRequired
	program.UpdatedAt = time.Now()

	// Create redemption transaction (negative credits)
	transaction := &models.PointTransaction{
		UserID:      userID,
		Type:        models.TransactionRedeemed,
		Credits:     -selectedOption.CreditsRequired,
		Description: fmt.Sprintf("Redeemed: %s", selectedOption.Name),
	}

	if err := s.loyaltyRepo.AddTransaction(ctx, transaction); err != nil {
		return "", fmt.Errorf("failed to add redemption transaction: %w", err)
	}

	// Update program
	if err := s.loyaltyRepo.UpdateProgram(ctx, program); err != nil {
		return "", fmt.Errorf("failed to update loyalty program: %w", err)
	}

	// Generate voucher code (simple implementation)
	voucherCode := fmt.Sprintf("%s-%s-%d", selectedOption.Type, userID.Hex()[:8], time.Now().Unix())

	// TODO: Create actual voucher in voucher service when available
	// TODO: Send redemption notification when notification service is available

	return voucherCode, nil
}

// GetRedemptionOptions gets all available redemption options
func (s *LoyaltyService) GetRedemptionOptions(ctx context.Context) []models.RedemptionOption {
	return models.GetRedemptionOptions()
}

// GetCreditHistory gets user's credit transaction history
func (s *LoyaltyService) GetCreditHistory(ctx context.Context, userID primitive.ObjectID, limit int, offset int) ([]models.PointTransaction, error) {
	transactions, err := s.loyaltyRepo.GetTransactionHistory(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get transaction history: %w", err)
	}

	return transactions, nil
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

// GetLoyaltyStatistics gets loyalty program statistics (admin)
func (s *LoyaltyService) GetLoyaltyStatistics(ctx context.Context) (*models.LoyaltyStatistics, error) {
	stats, err := s.loyaltyRepo.GetLoyaltyStatistics(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get loyalty statistics: %w", err)
	}

	return stats, nil
}

// GetTopLoyaltyMembers gets top loyalty members by total credits (admin)
func (s *LoyaltyService) GetTopLoyaltyMembers(ctx context.Context, limit int) ([]models.TopLoyaltyMember, error) {
	members, err := s.loyaltyRepo.GetTopLoyaltyMembers(ctx, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get top loyalty members: %w", err)
	}

	return members, nil
}

// ExportLoyaltyData exports loyalty data in specified format (admin)
func (s *LoyaltyService) ExportLoyaltyData(ctx context.Context, format string, startDate, endDate time.Time) (string, error) {
	filename, err := s.loyaltyRepo.ExportLoyaltyData(ctx, format, startDate, endDate)
	if err != nil {
		return "", fmt.Errorf("failed to export loyalty data: %w", err)
	}

	return filename, nil
}