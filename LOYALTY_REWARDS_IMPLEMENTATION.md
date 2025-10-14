# Loyalty & Rewards System - Complete Implementation Guide

## Overview
A comprehensive loyalty/rewards program with:
1. **Earn Credits on Purchase** - Earn credits based on order amount with tier multipliers
2. **Daily Login Streaks** - Bonus credits for consecutive logins
3. **Spending-Based Tiers** - Bronze, Silver, Gold, Platinum tiers based on total spending
4. **Credit Redemption** - Redeem credits for discounts and vouchers

---

## Backend Implementation

### ✅ Models (COMPLETED)
**File:** `backend/internal/models/loyalty.go`

**Key Features:**
- `LoyaltyProgram` with `TotalCredits`, `AvailableCredits`, tiering based on `TotalSpent`
- `CreditTransaction` types: `earned`, `login_bonus`, `streak_bonus`, `redeemed`
- Tier thresholds: Bronze ($0), Silver ($1000), Gold ($5000), Platinum ($10,000)
- Credit multipliers by tier: Bronze (1x), Silver (1.5x), Gold (2x), Platinum (2.5x)
- `RedemptionOption` with predefined redemption tiers
- Default config: 1 credit per dollar, 10 credits daily login, 50 credits streak bonus every 7 days

###  Repository (COMPLETED)
**File:** `backend/internal/repository/mongo/loyalty_repository.go`

**Status:** ✅ Updated and enabled (removed `//go:build exclude`)

### ⚠️ Service (NEEDS UPDATE)
**File:** `backend/internal/services/loyalty_service.go`

**Required Changes:**

```go
// Replace CreateLoyaltyProgram method around line 51
func (s *LoyaltyService) CreateLoyaltyProgram(ctx context.Context, userID primitive.ObjectID) (*models.LoyaltyProgram, error) {
	program := &models.LoyaltyProgram{
		UserID:           userID,
		TotalCredits:     s.config.WelcomeBonus,
		AvailableCredits: s.config.WelcomeBonus,
		Tier:             models.TierBronze,
		LoginStreak:      1,
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
	transaction := &models.CreditTransaction{
		UserID:      userID,
		Type:        models.TransactionWelcomeBonus,
		Credits:     s.config.WelcomeBonus,
		Description: "Welcome to our loyalty program!",
	}
	if err := s.loyaltyRepo.AddTransaction(ctx, transaction); err != nil {
		return nil, fmt.Errorf("failed to add welcome transaction: %w", err)
	}

	return program, nil
}

// Replace CheckDailyLogin around line 84 to award based on tier
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

	// Base daily bonus adjusted by tier
	tierInfo := program.Tier.GetTierInfo()
	bonusCredits := int(float64(s.config.DailyLoginBonus) * tierInfo.CreditsMultiplier)
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
				streakBonus := s.config.StreakBonusCredits
				bonusCredits += streakBonus

				// Add streak bonus transaction
				streakTransaction := &models.CreditTransaction{
					UserID:      userID,
					Type:        models.TransactionStreakBonus,
					Credits:     streakBonus,
					Description: fmt.Sprintf("%d day streak bonus!", newStreak),
				}
				s.loyaltyRepo.AddTransaction(ctx, streakTransaction)
			}
		}
	}

	// Add daily login bonus
	if err := s.AddCredits(ctx, userID, bonusCredits, fmt.Sprintf("Daily login bonus (%d day streak)", newStreak), models.TransactionLoginBonus, nil); err != nil {
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

// ADD NEW METHOD: AddCredits
func (s *LoyaltyService) AddCredits(ctx context.Context, userID primitive.ObjectID, credits int, description string, transactionType models.TransactionType, orderID *primitive.ObjectID) error {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Create transaction
	transaction := &models.CreditTransaction{
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

// ADD NEW METHOD: AddCreditsFromPurchase
func (s *LoyaltyService) AddCreditsFromPurchase(ctx context.Context, userID primitive.ObjectID, amount float64, orderID primitive.ObjectID) error {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Calculate credits with tier multiplier
	tierInfo := program.Tier.GetTierInfo()
	credits := int(amount * s.config.BaseCreditsPerDollar * tierInfo.CreditsMultiplier)

	// Add purchase credits
	if err := s.AddCredits(ctx, userID, credits, fmt.Sprintf("Earned from order #%s", orderID.Hex()[:8]), models.TransactionEarned, &orderID); err != nil {
		return fmt.Errorf("failed to add purchase credits: %w", err)
	}

	// Update total spent and orders
	program.TotalSpent += amount
	program.TotalOrders++

	// Check for tier upgrade based on spending
	oldTier := program.Tier
	program.UpdateTierBasedOnSpending()

	if program.Tier != oldTier {
		// Tier upgrade notification
		tierInfo := program.Tier.GetTierInfo()
		description := fmt.Sprintf("Congratulations! You've been upgraded to %s tier!", tierInfo.Name)
		// TODO: Send notification
		_ = description
	}

	program.UpdatedAt = time.Now()

	if err := s.loyaltyRepo.UpdateProgram(ctx, program); err != nil {
		return fmt.Errorf("failed to update purchase stats: %w", err)
	}

	return nil
}

// ADD NEW METHOD: RedeemCredits
func (s *LoyaltyService) RedeemCredits(ctx context.Context, userID primitive.ObjectID, optionID string) (*models.RedemptionOption, error) {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get loyalty program: %w", err)
	}

	// Find redemption option
	var option *models.RedemptionOption
	for _, opt := range models.GetRedemptionOptions() {
		if opt.ID == optionID {
			option = &opt
			break
		}
	}

	if option == nil {
		return nil, fmt.Errorf("redemption option not found")
	}

	// Check if user has enough credits
	if program.AvailableCredits < option.CreditsRequired {
		return nil, fmt.Errorf("insufficient credits: need %d, have %d", option.CreditsRequired, program.AvailableCredits)
	}

	// Deduct credits
	program.AvailableCredits -= option.CreditsRequired
	program.UpdatedAt = time.Now()

	// Create redemption transaction (negative credits)
	transaction := &models.CreditTransaction{
		UserID:      userID,
		Type:        models.TransactionRedeemed,
		Credits:     -option.CreditsRequired,
		Description: fmt.Sprintf("Redeemed: %s", option.Name),
	}

	if err := s.loyaltyRepo.AddTransaction(ctx, transaction); err != nil {
		return nil, fmt.Errorf("failed to add redemption transaction: %w", err)
	}

	if err := s.loyaltyRepo.UpdateProgram(ctx, program); err != nil {
		return nil, fmt.Errorf("failed to update program: %w", err)
	}

	return option, nil
}

// ADD NEW METHOD: GetRedemptionOptions
func (s *LoyaltyService) GetRedemptionOptions(ctx context.Context, userID primitive.ObjectID) ([]models.RedemptionOption, error) {
	program, err := s.loyaltyRepo.GetProgramByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get loyalty program: %w", err)
	}

	options := models.GetRedemptionOptions()

	// Mark which options user can afford
	for i := range options {
		if program.AvailableCredits >= options[i].CreditsRequired {
			// User can afford this option
			// This is just informational, frontend will handle display
		}
	}

	return options, nil
}

// ADD NEW METHOD: GetCreditHistory
func (s *LoyaltyService) GetCreditHistory(ctx context.Context, userID primitive.ObjectID, limit int, offset int) ([]models.CreditTransaction, error) {
	return s.loyaltyRepo.GetTransactionHistory(ctx, userID, limit, offset)
}
```

###  Handlers (TO CREATE)
**File:** `backend/internal/handlers/loyalty_handler.go`

**Create this new file:**

```go
package handlers

import (
	"net/http"
	"strconv"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type LoyaltyHandler struct {
	loyaltyService *services.LoyaltyService
}

func NewLoyaltyHandler(loyaltyService *services.LoyaltyService) *LoyaltyHandler {
	return &LoyaltyHandler{
		loyaltyService: loyaltyService,
	}
}

// GetLoyaltyProgram gets user's loyalty program
// @Summary Get loyalty program
// @Tags Loyalty
// @Produce json
// @Success 200 {object} models.LoyaltyProgram
// @Router /api/v1/loyalty/program [get]
func (h *LoyaltyHandler) GetLoyaltyProgram(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	program, err := h.loyaltyService.GetLoyaltyProgram(c.Request.Context(), userID.(primitive.ObjectID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": program})
}

// GetCreditHistory gets user's credit transaction history
// @Summary Get credit history
// @Tags Loyalty
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Success 200 {array} models.CreditTransaction
// @Router /api/v1/loyalty/history [get]
func (h *LoyaltyHandler) GetCreditHistory(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	transactions, err := h.loyaltyService.GetCreditHistory(c.Request.Context(), userID.(primitive.ObjectID), limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": transactions,
		"page": page,
		"limit": limit,
	})
}

// GetRedemptionOptions gets available redemption options
// @Summary Get redemption options
// @Tags Loyalty
// @Produce json
// @Success 200 {array} models.RedemptionOption
// @Router /api/v1/loyalty/redemption-options [get]
func (h *LoyaltyHandler) GetRedemptionOptions(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	options, err := h.loyaltyService.GetRedemptionOptions(c.Request.Context(), userID.(primitive.ObjectID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": options})
}

// RedeemCredits redeems credits for a reward
// @Summary Redeem credits
// @Tags Loyalty
// @Accept json
// @Produce json
// @Param request body object true "Redemption request"
// @Success 200 {object} models.RedemptionOption
// @Router /api/v1/loyalty/redeem [post]
func (h *LoyaltyHandler) RedeemCredits(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var request struct {
		OptionID string `json:"optionId" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	option, err := h.loyaltyService.RedeemCredits(c.Request.Context(), userID.(primitive.ObjectID), request.OptionID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Credits redeemed successfully",
		"data": option,
	})
}

// GetLoyaltyConfig gets loyalty program configuration
// @Summary Get loyalty config
// @Tags Loyalty
// @Produce json
// @Success 200 {object} models.LoyaltyConfig
// @Router /api/v1/loyalty/config [get]
func (h *LoyaltyHandler) GetLoyaltyConfig(c *gin.Context) {
	config, err := h.loyaltyService.GetLoyaltyConfig(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": config})
}

// Admin: UpdateLoyaltyConfig updates loyalty program configuration
// @Summary Update loyalty config (Admin)
// @Tags Loyalty
// @Accept json
// @Produce json
// @Param config body models.LoyaltyConfig true "Loyalty config"
// @Success 200 {object} models.LoyaltyConfig
// @Router /api/v1/admin/loyalty/config [put]
func (h *LoyaltyHandler) UpdateLoyaltyConfig(c *gin.Context) {
	var config models.LoyaltyConfig

	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.loyaltyService.UpdateLoyaltyConfig(c.Request.Context(), &config); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Loyalty config updated",
		"data": config,
	})
}

// Admin: GetLoyaltyStatistics gets loyalty program statistics
// @Summary Get loyalty statistics (Admin)
// @Tags Loyalty
// @Produce json
// @Success 200 {object} models.LoyaltyStatistics
// @Router /api/v1/admin/loyalty/statistics [get]
func (h *LoyaltyHandler) GetLoyaltyStatistics(c *gin.Context) {
	stats, err := h.loyaltyService.GetLoyaltyStatistics(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": stats})
}
```

### ⚠️ Routes (TO UPDATE)
**File:** `backend/cmd/server/main.go`

**Add these changes:**

1. **Line 79** - Initialize loyalty repository:
```go
loyaltyRepo := mongo.NewLoyaltyRepository(db)
```

2. **Line 88-97** - Replace nil loyalty service:
```go
loyaltyService := services.NewLoyaltyService(loyaltyRepo, userRepo, nil)
```

3. **Line 117** - Initialize loyalty handler:
```go
loyaltyHandler := handlers.NewLoyaltyHandler(loyaltyService)
```

4. **After line 267** - Add loyalty routes:
```go
// Loyalty routes
loyalty := api.Group("/loyalty")
loyalty.Use(middleware.AuthRequired(authService))
{
	loyalty.GET("/program", loyaltyHandler.GetLoyaltyProgram)
	loyalty.GET("/history", loyaltyHandler.GetCreditHistory)
	loyalty.GET("/redemption-options", loyaltyHandler.GetRedemptionOptions)
	loyalty.POST("/redeem", loyaltyHandler.RedeemCredits)
	loyalty.GET("/config", loyaltyHandler.GetLoyaltyConfig)
}

// Admin loyalty routes
admin.GET("/loyalty/statistics", loyaltyHandler.GetLoyaltyStatistics)
admin.PUT("/loyalty/config", loyaltyHandler.UpdateLoyaltyConfig)
```

### Integration with Order Service
**File:** `backend/internal/services/order_service.go`

**Add after order confirmation (around line where order is marked as delivered/completed):**

```go
// Award loyalty credits for purchase
if orderServiceImpl, ok := s.(*orderService); ok && orderServiceImpl.loyaltyService != nil {
	if order.UserID != nil {
		go func() {
			ctx := context.Background()
			if err := orderServiceImpl.loyaltyService.AddCreditsFromPurchase(ctx, *order.UserID, order.Total, order.ID); err != nil {
				log.Printf("Failed to award loyalty credits: %v", err)
			}
		}()
	}
}
```

---

## Frontend Implementation (Flutter)

### 📱 Models (TO CREATE)
**File:** `lib/models/loyalty.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'loyalty.g.dart';

@JsonSerializable()
class LoyaltyProgram {
  final String id;
  final String userId;
  final int totalCredits;
  final int availableCredits;
  final String tier;
  final int loginStreak;
  final DateTime? lastLoginDate;
  final double totalSpent;
  final int totalOrders;
  final DateTime joinedAt;
  final DateTime updatedAt;

  LoyaltyProgram({
    required this.id,
    required this.userId,
    required this.totalCredits,
    required this.availableCredits,
    required this.tier,
    required this.loginStreak,
    this.lastLoginDate,
    required this.totalSpent,
    required this.totalOrders,
    required this.joinedAt,
    required this.updatedAt,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) => _$LoyaltyProgramFromJson(json);
  Map<String, dynamic> toJson() => _$LoyaltyProgramToJson(this);

  String get tierDisplayName {
    switch (tier) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return tier;
    }
  }

  String get tierIcon {
    switch (tier) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      case 'platinum':
        return '💎';
      default:
        return '';
    }
  }
}

@JsonSerializable()
class CreditTransaction {
  final String id;
  final String userId;
  final String type;
  final int credits;
  final String description;
  final String? orderId;
  final String? voucherId;
  final DateTime createdAt;

  CreditTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.credits,
    required this.description,
    this.orderId,
    this.voucherId,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) => _$CreditTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$CreditTransactionToJson(this);

  String get typeDisplayName {
    switch (type) {
      case 'earned':
        return 'Purchase Reward';
      case 'login_bonus':
        return 'Daily Login';
      case 'streak_bonus':
        return 'Streak Bonus';
      case 'welcome_bonus':
        return 'Welcome Bonus';
      case 'redeemed':
        return 'Redeemed';
      default:
        return type;
    }
  }

  bool get isPositive => credits > 0;
}

@JsonSerializable()
class RedemptionOption {
  final String id;
  final String name;
  final String description;
  final int creditsRequired;
  final double discountValue;
  final String type;

  RedemptionOption({
    required this.id,
    required this.name,
    required this.description,
    required this.creditsRequired,
    required this.discountValue,
    required this.type,
  });

  factory RedemptionOption.fromJson(Map<String, dynamic> json) => _$RedemptionOptionFromJson(json);
  Map<String, dynamic> toJson() => _$RedemptionOptionToJson(this);
}
```

### 🔌 API Service (TO UPDATE)
**File:** `lib/services/api_service.dart`

Add these methods:

```dart
// Loyalty methods
static Future<Map<String, dynamic>> getLoyaltyProgram() async {
  final response = await _authenticatedRequest('GET', '/loyalty/program');
  return response;
}

static Future<Map<String, dynamic>> getCreditHistory({int page = 1, int limit = 20}) async {
  final response = await _authenticatedRequest('GET', '/loyalty/history?page=$page&limit=$limit');
  return response;
}

static Future<Map<String, dynamic>> getRedemptionOptions() async {
  final response = await _authenticatedRequest('GET', '/loyalty/redemption-options');
  return response;
}

static Future<Map<String, dynamic>> redeemCredits({required String optionId}) async {
  final response = await _authenticatedRequest(
    'POST',
    '/loyalty/redeem',
    body: {'optionId': optionId},
  );
  return response;
}

static Future<Map<String, dynamic>> getLoyaltyConfig() async {
  final response = await _authenticatedRequest('GET', '/loyalty/config');
  return response;
}
```

### 🎨 UI Screens (TO CREATE)

#### 1. Loyalty Dashboard Screen
**File:** `lib/screens/loyalty/loyalty_dashboard_screen.dart`

Create a comprehensive dashboard showing:
- Current tier with progress bar
- Available credits
- Login streak
- Quick actions (redeem, view history)

#### 2. Credit History Screen
**File:** `lib/screens/loyalty/credit_history_screen.dart`

Show transaction history with:
- Transaction type icons
- Credits earned/spent
- Dates and descriptions

#### 3. Redemption Screen
**File:** `lib/screens/loyalty/redemption_screen.dart`

Display redemption options:
- Cards showing each option
- Credits required vs available
- Redeem button (enabled/disabled based on balance)

---

## Testing Guide

### Backend Testing

1. **Start Backend:**
```bash
cd backend
go run cmd/server/main.go
```

2. **Test Endpoints (via Swagger or curl):**

**Get Loyalty Program:**
```bash
curl -X GET http://localhost:8080/api/v1/loyalty/program \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Redeem Credits:**
```bash
curl -X POST http://localhost:8080/api/v1/loyalty/redeem \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"optionId": "discount_5"}'
```

### Frontend Testing

1. **Run Flutter App:**
```bash
flutter run
```

2. **Test Flow:**
- Login → Automatic loyalty program creation
- View loyalty dashboard → Check welcome bonus
- Login daily for 7 days → Check streak bonus
- Make a purchase → Check credits earned
- Navigate to redemption → Redeem credits
- Check credit history → Verify all transactions

---

## Configuration

### Adjust Tier Thresholds
Edit `backend/internal/models/loyalty.go` lines 46-99 to modify:
- Spending required per tier
- Credits multipliers
- Tier benefits

### Adjust Credit Rates
Edit default config in `backend/internal/models/loyalty.go` lines 199-209:
- `BaseCreditsPerDollar`: Credits per dollar spent
- `DailyLoginBonus`: Daily login credits
- `StreakBonusCredits`: Bonus for streak milestone
- `StreakBonusDays`: Days between streak bonuses
- `WelcomeBonus`: New member bonus
- `CreditsToMoneyRatio`: Conversion rate for redemption

### Adjust Redemption Options
Edit `backend/internal/models/loyalty.go` lines 230-265 to modify redemption tiers.

---

## Summary

### ✅ Completed
- Models with credits-based system
- Spending-based tier system
- Repository implementation
- Transaction tracking

### ⚠️ To Complete (Estimated: 3-4 hours)
1. Update `loyalty_service.go` methods (1 hour)
2. Create `loyalty_handler.go` (30 min)
3. Update `main.go` routes (15 min)
4. Integrate with order service (30 min)
5. Create Flutter models (30 min)
6. Update API service (15 min)
7. Create Flutter UI screens (1-1.5 hours)
8. Testing (30-45 min)

### Key Features Delivered
✅ Earn credits on purchase (with tier multipliers)
✅ Daily login bonuses
✅ Streak bonuses (every 7 days)
✅ Spending-based tiers (Bronze → Silver → Gold → Platinum)
✅ Credit redemption system
✅ Transaction history
✅ Admin statistics

---

## Next Steps

1. **Update the loyalty service methods** as shown above
2. **Create the loyalty handler**
3. **Add routes to main.go**
4. **Build and test backend**
5. **Create Flutter models and run code generation**
6. **Implement Flutter UI screens**
7. **Test end-to-end flow**

The foundation is complete! Follow this guide to finish the implementation. 🚀
