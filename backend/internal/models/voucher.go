package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Voucher represents a voucher template that can be redeemed
type Voucher struct {
	ID               primitive.ObjectID     `json:"id" bson:"_id,omitempty"`
	Code             string                 `json:"code" bson:"code"`
	Title            string                 `json:"title" bson:"title"`
	Description      string                 `json:"description" bson:"description"`
	Type             string                 `json:"type" bson:"type"` // "welcome", "loyalty", "seasonal", "special"
	DiscountType     string                 `json:"discountType" bson:"discountType"` // "percentage", "fixed"
	Value            float64                `json:"value" bson:"value"` // Percentage or fixed amount
	MinOrderValue    float64                `json:"minOrderValue" bson:"minOrderValue"`
	MaxDiscount      float64                `json:"maxDiscount" bson:"maxDiscount"`
	PointsCost       int                    `json:"pointsCost" bson:"pointsCost"`
	MaxRedemptions   int                    `json:"maxRedemptions" bson:"maxRedemptions"` // 0 = unlimited
	MaxPerUser       int                    `json:"maxPerUser" bson:"maxPerUser"` // 0 = unlimited
	ValidFrom        *time.Time             `json:"validFrom,omitempty" bson:"validFrom,omitempty"`
	ValidUntil       *time.Time             `json:"validUntil,omitempty" bson:"validUntil,omitempty"`
	UsageConditions  map[string]interface{} `json:"usageConditions" bson:"usageConditions"`
	IsActive         bool                   `json:"isActive" bson:"isActive"`
	ImageURL         string                 `json:"imageUrl" bson:"imageUrl"`
	Terms            []string               `json:"terms" bson:"terms"`
	CreatedAt        time.Time              `json:"createdAt" bson:"createdAt"`
	UpdatedAt        time.Time              `json:"updatedAt" bson:"updatedAt"`
}

// IsValid checks if the voucher is valid for use
func (v *Voucher) IsValid() bool {
	now := time.Now()
	return v.IsActive &&
		(v.ValidFrom == nil || now.After(*v.ValidFrom)) &&
		(v.ValidUntil == nil || now.Before(*v.ValidUntil)) &&
		(v.MaxRedemptions == 0 || v.MaxRedemptions > 0) // simplified check
}

// UserVoucher represents a voucher owned by a user
type UserVoucher struct {
	ID               primitive.ObjectID     `json:"id" bson:"_id,omitempty"`
	UserID           primitive.ObjectID     `json:"userId" bson:"userId"`
	VoucherID        primitive.ObjectID     `json:"voucherId" bson:"voucherId"`
	Code             string                 `json:"code" bson:"code"`
	DiscountType     string                 `json:"discountType" bson:"discountType"`
	Value            float64                `json:"value" bson:"value"`
	MinOrderValue    float64                `json:"minOrderValue" bson:"minOrderValue"`
	MaxDiscount      float64                `json:"maxDiscount" bson:"maxDiscount"`
	IssuedAt         time.Time              `json:"issuedAt" bson:"issuedAt"`
	ExpiresAt        *time.Time             `json:"expiresAt,omitempty" bson:"expiresAt,omitempty"`
	IsUsed           bool                   `json:"isUsed" bson:"isUsed"`
	UsedAt           *time.Time             `json:"usedAt,omitempty" bson:"usedAt,omitempty"`
	OrderID          *primitive.ObjectID    `json:"orderId,omitempty" bson:"orderId,omitempty"`
	UsageConditions  map[string]interface{} `json:"usageConditions" bson:"usageConditions"`
}

// VoucherValidation represents voucher validation result
type VoucherValidation struct {
	IsValid        bool         `json:"isValid"`
	UserVoucher    *UserVoucher `json:"userVoucher,omitempty"`
	DiscountAmount float64      `json:"discountAmount"`
	FinalAmount    float64      `json:"finalAmount"`
	Error          string       `json:"error,omitempty"`
}

// Reward represents a reward earned by user actions
type Reward struct {
	ID          primitive.ObjectID     `json:"id" bson:"_id,omitempty"`
	UserID      primitive.ObjectID     `json:"userId" bson:"userId"`
	Type        string                 `json:"type" bson:"type"` // "first_order", "review_submitted", "referral_successful", etc.
	Description string                 `json:"description" bson:"description"`
	Value       int                    `json:"value" bson:"value"` // Points or monetary value
	Status      string                 `json:"status" bson:"status"` // "earned", "claimed", "expired"
	Metadata    map[string]interface{} `json:"metadata" bson:"metadata"`
	EarnedAt    time.Time              `json:"earnedAt" bson:"earnedAt"`
	ClaimedAt   *time.Time             `json:"claimedAt,omitempty" bson:"claimedAt,omitempty"`
	ExpiresAt   *time.Time             `json:"expiresAt,omitempty" bson:"expiresAt,omitempty"`
	CreatedAt   time.Time              `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time              `json:"updatedAt" bson:"updatedAt"`
}

// RewardRule represents rules for earning rewards
type RewardRule struct {
	ID          primitive.ObjectID     `json:"id" bson:"_id,omitempty"`
	Name        string                 `json:"name" bson:"name"`
	Type        string                 `json:"type" bson:"type"` // "order_completion", "review_submission", "referral", etc.
	Description string                 `json:"description" bson:"description"`
	Conditions  map[string]interface{} `json:"conditions" bson:"conditions"`
	Rewards     []RewardDefinition     `json:"rewards" bson:"rewards"`
	IsActive    bool                   `json:"isActive" bson:"isActive"`
	StartDate   *time.Time             `json:"startDate,omitempty" bson:"startDate,omitempty"`
	EndDate     *time.Time             `json:"endDate,omitempty" bson:"endDate,omitempty"`
	MaxClaims   int                    `json:"maxClaims" bson:"maxClaims"` // 0 = unlimited
	CreatedAt   time.Time              `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time              `json:"updatedAt" bson:"updatedAt"`
}

// RewardDefinition defines what reward is given
type RewardDefinition struct {
	Type        string                 `json:"type" bson:"type"` // "points", "voucher", "badge"
	Value       int                    `json:"value" bson:"value"`
	Description string                 `json:"description" bson:"description"`
	Metadata    map[string]interface{} `json:"metadata" bson:"metadata"`
}

// VoucherAnalytics represents voucher usage analytics
type VoucherAnalytics struct {
	TotalVouchers       int64                          `json:"totalVouchers"`
	ActiveVouchers      int64                          `json:"activeVouchers"`
	TotalRedemptions    int64                          `json:"totalRedemptions"`
	TotalUsage          int64                          `json:"totalUsage"`
	TotalDiscountValue  float64                        `json:"totalDiscountValue"`
	PopularVouchers     []VoucherPopularity            `json:"popularVouchers"`
	RedemptionsByType   map[string]int64               `json:"redemptionsByType"`
	UsageByMonth        []MonthlyVoucherUsage          `json:"usageByMonth"`
	AverageDiscount     float64                        `json:"averageDiscount"`
	ConversionRate      float64                        `json:"conversionRate"` // redemptions to usage ratio
}

// VoucherPopularity represents voucher popularity metrics
type VoucherPopularity struct {
	VoucherID     primitive.ObjectID `json:"voucherId"`
	VoucherTitle  string             `json:"voucherTitle"`
	Redemptions   int64              `json:"redemptions"`
	Usage         int64              `json:"usage"`
	TotalDiscount float64            `json:"totalDiscount"`
}

// MonthlyVoucherUsage represents monthly voucher usage
type MonthlyVoucherUsage struct {
	Month       string  `json:"month"`
	Redemptions int64   `json:"redemptions"`
	Usage       int64   `json:"usage"`
	Discount    float64 `json:"discount"`
}

// ReferralProgram represents referral program configuration
type ReferralProgram struct {
	ID                 primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	IsActive           bool               `json:"isActive" bson:"isActive"`
	ReferrerReward     int                `json:"referrerReward" bson:"referrerReward"` // Points for referrer
	RefereeReward      int                `json:"refereeReward" bson:"refereeReward"`   // Points for referee
	MinOrderValue      float64            `json:"minOrderValue" bson:"minOrderValue"`   // Minimum order for reward
	MaxReferrals       int                `json:"maxReferrals" bson:"maxReferrals"`     // Max referrals per user
	ValidityDays       int                `json:"validityDays" bson:"validityDays"`     // Days referral link is valid
	Description        string             `json:"description" bson:"description"`
	Terms              []string           `json:"terms" bson:"terms"`
	CreatedAt          time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt          time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// UserReferral represents a user referral
type UserReferral struct {
	ID              primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	ReferrerID      primitive.ObjectID  `json:"referrerId" bson:"referrerId"`
	RefereeID       *primitive.ObjectID `json:"refereeId,omitempty" bson:"refereeId,omitempty"`
	ReferralCode    string              `json:"referralCode" bson:"referralCode"`
	RefereeEmail    string              `json:"refereeEmail" bson:"refereeEmail"`
	Status          string              `json:"status" bson:"status"` // "pending", "completed", "expired"
	FirstOrderID    *primitive.ObjectID `json:"firstOrderId,omitempty" bson:"firstOrderId,omitempty"`
	ReferrerReward  int                 `json:"referrerReward" bson:"referrerReward"`
	RefereeReward   int                 `json:"refereeReward" bson:"refereeReward"`
	CreatedAt       time.Time           `json:"createdAt" bson:"createdAt"`
	CompletedAt     *time.Time          `json:"completedAt,omitempty" bson:"completedAt,omitempty"`
	ExpiresAt       time.Time           `json:"expiresAt" bson:"expiresAt"`
}

// Badge represents achievement badges
type Badge struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name        string             `json:"name" bson:"name"`
	Description string             `json:"description" bson:"description"`
	IconURL     string             `json:"iconUrl" bson:"iconUrl"`
	Criteria    string             `json:"criteria" bson:"criteria"`
	Rarity      string             `json:"rarity" bson:"rarity"` // "common", "rare", "epic", "legendary"
	Points      int                `json:"points" bson:"points"`
	IsActive    bool               `json:"isActive" bson:"isActive"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// UserBadge represents a badge earned by a user
type UserBadge struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId"`
	BadgeID   primitive.ObjectID `json:"badgeId" bson:"badgeId"`
	EarnedAt  time.Time          `json:"earnedAt" bson:"earnedAt"`
	Metadata  map[string]interface{} `json:"metadata" bson:"metadata"`
}

// SeasonalCampaign represents seasonal marketing campaigns
type SeasonalCampaign struct {
	ID              primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name            string             `json:"name" bson:"name"`
	Description     string             `json:"description" bson:"description"`
	Theme           string             `json:"theme" bson:"theme"` // "christmas", "diwali", "valentine", etc.
	StartDate       time.Time          `json:"startDate" bson:"startDate"`
	EndDate         time.Time          `json:"endDate" bson:"endDate"`
	PointsMultiplier float64           `json:"pointsMultiplier" bson:"pointsMultiplier"`
	SpecialVouchers []primitive.ObjectID `json:"specialVouchers" bson:"specialVouchers"`
	SpecialRewards  []RewardDefinition `json:"specialRewards" bson:"specialRewards"`
	IsActive        bool               `json:"isActive" bson:"isActive"`
	BannerURL       string             `json:"bannerUrl" bson:"bannerUrl"`
	CreatedAt       time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// GamificationConfig represents gamification settings
type GamificationConfig struct {
	ID                    primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	EnableBadges          bool               `json:"enableBadges" bson:"enableBadges"`
	EnableLeaderboard     bool               `json:"enableLeaderboard" bson:"enableLeaderboard"`
	EnableChallenges      bool               `json:"enableChallenges" bson:"enableChallenges"`
	EnableStreaks         bool               `json:"enableStreaks" bson:"enableStreaks"`
	PointsPerDollarSpent  float64            `json:"pointsPerDollarSpent" bson:"pointsPerDollarSpent"`
	ReviewPoints          int                `json:"reviewPoints" bson:"reviewPoints"`
	ReferralPoints        int                `json:"referralPoints" bson:"referralPoints"`
	DailyLoginPoints      int                `json:"dailyLoginPoints" bson:"dailyLoginPoints"`
	WeeklyStreakBonus     int                `json:"weeklyStreakBonus" bson:"weeklyStreakBonus"`
	MonthlyStreakBonus    int                `json:"monthlyStreakBonus" bson:"monthlyStreakBonus"`
	CreatedAt             time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt             time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// Challenge represents gamification challenges
type Challenge struct {
	ID              primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	Title           string              `json:"title" bson:"title"`
	Description     string              `json:"description" bson:"description"`
	Type            string              `json:"type" bson:"type"` // "spend_amount", "place_orders", "refer_friends"
	Target          int                 `json:"target" bson:"target"`
	Reward          RewardDefinition    `json:"reward" bson:"reward"`
	StartDate       time.Time           `json:"startDate" bson:"startDate"`
	EndDate         time.Time           `json:"endDate" bson:"endDate"`
	IsActive        bool                `json:"isActive" bson:"isActive"`
	Participants    []primitive.ObjectID `json:"participants" bson:"participants"`
	CreatedAt       time.Time           `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time           `json:"updatedAt" bson:"updatedAt"`
}

// UserChallenge represents user participation in challenges
type UserChallenge struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID      primitive.ObjectID `json:"userId" bson:"userId"`
	ChallengeID primitive.ObjectID `json:"challengeId" bson:"challengeId"`
	Progress    int                `json:"progress" bson:"progress"`
	IsCompleted bool               `json:"isCompleted" bson:"isCompleted"`
	CompletedAt *time.Time         `json:"completedAt,omitempty" bson:"completedAt,omitempty"`
	JoinedAt    time.Time          `json:"joinedAt" bson:"joinedAt"`
}

// Leaderboard represents leaderboard entries
type Leaderboard struct {
	UserID      primitive.ObjectID `json:"userId" bson:"userId"`
	UserName    string             `json:"userName" bson:"userName"`
	Avatar      string             `json:"avatar" bson:"avatar"`
	Points      int                `json:"points" bson:"points"`
	Tier        string             `json:"tier" bson:"tier"`
	Rank        int                `json:"rank" bson:"rank"`
	BadgeCount  int                `json:"badgeCount" bson:"badgeCount"`
}

// Constants for voucher and reward types
const (
	VoucherTypeWelcome   = "welcome"
	VoucherTypeLoyalty   = "loyalty"
	VoucherTypeSeasonal  = "seasonal"
	VoucherTypeSpecial   = "special"
	VoucherTypeBirthday  = "birthday"
	VoucherTypeReferral  = "referral"

	DiscountTypePercentage = "percentage"
	DiscountTypeFixed      = "fixed"

	RewardTypeFirstOrder         = "first_order"
	RewardTypeReviewSubmitted    = "review_submitted"
	RewardTypeReferralSuccessful = "referral_successful"
	RewardTypeBirthdayBonus     = "birthday_bonus"
	RewardTypeMilestoneReached  = "milestone_reached"
	RewardTypeSeasonalBonus     = "seasonal_bonus"
	RewardTypeChallengeComplete = "challenge_complete"

	RewardStatusEarned   = "earned"
	RewardStatusClaimed  = "claimed"
	RewardStatusExpired  = "expired"

	ReferralStatusPending   = "pending"
	ReferralStatusCompleted = "completed"
	ReferralStatusExpired   = "expired"

	BadgeRarityCommon    = "common"
	BadgeRarityRare      = "rare"
	BadgeRarityEpic      = "epic"
	BadgeRarityLegendary = "legendary"

	ChallengeTypeSpendAmount  = "spend_amount"
	ChallengeTypePlaceOrders  = "place_orders"
	ChallengeTypeReferFriends = "refer_friends"
	ChallengeTypeEarnPoints   = "earn_points"
)

// GetDefaultGamificationConfig returns default gamification configuration
func GetDefaultGamificationConfig() *GamificationConfig {
	return &GamificationConfig{
		EnableBadges:          true,
		EnableLeaderboard:     true,
		EnableChallenges:      true,
		EnableStreaks:         true,
		PointsPerDollarSpent:  0.1, // 1 point per ₹10 spent
		ReviewPoints:          50,
		ReferralPoints:        200,
		DailyLoginPoints:      10,
		WeeklyStreakBonus:     50,
		MonthlyStreakBonus:    200,
		CreatedAt:             time.Now(),
		UpdatedAt:             time.Now(),
	}
}

// GetDefaultReferralProgram returns default referral program configuration
func GetDefaultReferralProgram() *ReferralProgram {
	return &ReferralProgram{
		IsActive:      true,
		ReferrerReward: 200,
		RefereeReward:  100,
		MinOrderValue: 1000,
		MaxReferrals:  10,
		ValidityDays:  30,
		Description:   "Refer friends and earn rewards when they make their first purchase!",
		Terms: []string{
			"Referee must be a new customer",
			"Minimum order value of ₹1000 required",
			"Rewards credited after successful order completion",
			"Referral link valid for 30 days",
			"Maximum 10 referrals per user",
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}