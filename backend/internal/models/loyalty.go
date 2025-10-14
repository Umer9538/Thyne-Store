package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LoyaltyProgram represents a user's loyalty program status
type LoyaltyProgram struct {
	ID               primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID           primitive.ObjectID `json:"userId" bson:"userId"`
	TotalCredits     int                `json:"totalCredits" bson:"totalCredits"`         // Lifetime credits earned
	AvailableCredits int                `json:"availableCredits" bson:"availableCredits"` // Current balance
	Tier             LoyaltyTier        `json:"tier" bson:"tier"`
	LoginStreak      int                `json:"loginStreak" bson:"loginStreak"`
	LastLoginDate    *time.Time         `json:"lastLoginDate" bson:"lastLoginDate"`
	TotalSpent       float64            `json:"totalSpent" bson:"totalSpent"`
	TotalOrders      int                `json:"totalOrders" bson:"totalOrders"`
	JoinedAt         time.Time          `json:"joinedAt" bson:"joinedAt"`
	UpdatedAt        time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// LoyaltyTier represents different tiers in the loyalty program
type LoyaltyTier string

const (
	TierBronze   LoyaltyTier = "bronze"
	TierSilver   LoyaltyTier = "silver"
	TierGold     LoyaltyTier = "gold"
	TierPlatinum LoyaltyTier = "platinum"
)

// TierInfo provides tier-specific information
type TierInfo struct {
	Name             string   `json:"name"`
	Icon             string   `json:"icon"`
	SpendingRequired float64  `json:"spendingRequired"` // Total spending needed for tier
	CreditsMultiplier float64 `json:"creditsMultiplier"`
	Benefits         []string `json:"benefits"`
}

// GetTierInfo returns information for a given tier
func (t LoyaltyTier) GetTierInfo() TierInfo {
	switch t {
	case TierBronze:
		return TierInfo{
			Name:              "Bronze",
			Icon:              "🥉",
			SpendingRequired:  0,
			CreditsMultiplier: 1.0,
			Benefits: []string{
				"Earn 1 credit per $1 spent",
				"Login streak bonuses",
				"Early access to sales",
			},
		}
	case TierSilver:
		return TierInfo{
			Name:              "Silver",
			Icon:              "🥈",
			SpendingRequired:  1000,
			CreditsMultiplier: 1.5,
			Benefits: []string{
				"Earn 1.5 credits per $1 spent",
				"Free shipping on orders over $50",
				"Exclusive member discounts",
				"Enhanced login bonuses",
			},
		}
	case TierGold:
		return TierInfo{
			Name:              "Gold",
			Icon:              "🥇",
			SpendingRequired:  5000,
			CreditsMultiplier: 2.0,
			Benefits: []string{
				"Earn 2 credits per $1 spent",
				"Free shipping on all orders",
				"Priority customer service",
				"Exclusive gold member sales",
				"Double login bonuses",
			},
		}
	case TierPlatinum:
		return TierInfo{
			Name:              "Platinum",
			Icon:              "💎",
			SpendingRequired:  10000,
			CreditsMultiplier: 2.5,
			Benefits: []string{
				"Earn 2.5 credits per $1 spent",
				"Free express shipping",
				"VIP customer service",
				"Exclusive platinum previews",
				"Personal shopping assistant",
				"Triple login bonuses",
			},
		}
	default:
		return TierInfo{}
	}
}

// CalculateNextTier returns the next tier and spending needed
func (lp *LoyaltyProgram) CalculateNextTier() (LoyaltyTier, float64) {
	switch lp.Tier {
	case TierBronze:
		return TierSilver, 1000 - lp.TotalSpent
	case TierSilver:
		return TierGold, 5000 - lp.TotalSpent
	case TierGold:
		return TierPlatinum, 10000 - lp.TotalSpent
	default:
		return TierPlatinum, 0 // Already at max tier
	}
}

// CalculateTierProgress returns progress percentage for current tier
func (lp *LoyaltyProgram) CalculateTierProgress() float64 {
	switch lp.Tier {
	case TierBronze:
		return (lp.TotalSpent / 1000.0) * 100
	case TierSilver:
		return ((lp.TotalSpent - 1000) / 4000.0) * 100
	case TierGold:
		return ((lp.TotalSpent - 5000) / 5000.0) * 100
	case TierPlatinum:
		return 100.0
	default:
		return 0.0
	}
}

// UpdateTierBasedOnSpending updates the tier based on total spending
func (lp *LoyaltyProgram) UpdateTierBasedOnSpending() {
	if lp.TotalSpent >= 10000 {
		lp.Tier = TierPlatinum
	} else if lp.TotalSpent >= 5000 {
		lp.Tier = TierGold
	} else if lp.TotalSpent >= 1000 {
		lp.Tier = TierSilver
	} else {
		lp.Tier = TierBronze
	}
}

// CreditTransaction represents a single credit transaction
type CreditTransaction struct {
	ID          primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	UserID      primitive.ObjectID   `json:"userId" bson:"userId"`
	Type        TransactionType      `json:"type" bson:"type"`
	Credits     int                  `json:"credits" bson:"credits"`
	Description string               `json:"description" bson:"description"`
	OrderID     *primitive.ObjectID  `json:"orderId,omitempty" bson:"orderId,omitempty"`
	VoucherID   *primitive.ObjectID  `json:"voucherId,omitempty" bson:"voucherId,omitempty"`
	CreatedAt   time.Time            `json:"createdAt" bson:"createdAt"`
}

// TransactionType represents different types of credit transactions
type TransactionType string

const (
	TransactionEarned       TransactionType = "earned"        // Earned from purchase
	TransactionRedeemed     TransactionType = "redeemed"      // Redeemed for discount/voucher
	TransactionLoginBonus   TransactionType = "login_bonus"   // Daily login bonus
	TransactionStreakBonus  TransactionType = "streak_bonus"  // Login streak milestone bonus
	TransactionWelcomeBonus TransactionType = "welcome_bonus" // Welcome bonus
	TransactionExpired      TransactionType = "expired"       // Credits expired
	TransactionRefund       TransactionType = "refund"        // Refunded from cancelled order
)

// PointTransaction is an alias for backward compatibility
type PointTransaction = CreditTransaction

// VoucherType represents different types of vouchers
type VoucherType string

const (
	VoucherPercentage   VoucherType = "percentage"
	VoucherFixed        VoucherType = "fixed"
	VoucherFreeShipping VoucherType = "freeShipping"
	VoucherGift         VoucherType = "gift"
)

// LoyaltyConfig represents configuration for the loyalty program
type LoyaltyConfig struct {
	ID                   primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	BaseCreditsPerDollar float64            `json:"baseCreditsPerDollar" bson:"baseCreditsPerDollar"`
	DailyLoginBonus      int                `json:"dailyLoginBonus" bson:"dailyLoginBonus"`
	StreakBonusCredits   int                `json:"streakBonusCredits" bson:"streakBonusCredits"`
	StreakBonusDays      int                `json:"streakBonusDays" bson:"streakBonusDays"` // Award bonus every X days
	WelcomeBonus         int                `json:"welcomeBonus" bson:"welcomeBonus"`
	CreditsToMoneyRatio  float64            `json:"creditsToMoneyRatio" bson:"creditsToMoneyRatio"` // e.g., 100 credits = $1
	UpdatedAt            time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// Default loyalty configuration
func DefaultLoyaltyConfig() *LoyaltyConfig {
	return &LoyaltyConfig{
		BaseCreditsPerDollar: 1.0,   // 1 credit per dollar spent
		DailyLoginBonus:      10,    // 10 credits for daily login
		StreakBonusCredits:   50,    // 50 bonus credits for streak milestone
		StreakBonusDays:      7,     // Bonus every 7 days of streak
		WelcomeBonus:         100,   // 100 credits on signup
		CreditsToMoneyRatio:  100.0, // 100 credits = $1 discount
		UpdatedAt:            time.Now(),
	}
}

// RedemptionOption represents options for redeeming credits
type RedemptionOption struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Description string  `json:"description"`
	CreditsRequired int `json:"creditsRequired"`
	DiscountValue   float64 `json:"discountValue"`
	Type        RedemptionType `json:"type"`
}

// RedemptionType represents the type of redemption
type RedemptionType string

const (
	RedemptionDiscount      RedemptionType = "discount"        // Direct discount on order
	RedemptionVoucher       RedemptionType = "voucher"         // Generate voucher code
	RedemptionFreeShipping  RedemptionType = "free_shipping"   // Free shipping voucher
)

// GetRedemptionOptions returns available redemption options
func GetRedemptionOptions() []RedemptionOption {
	return []RedemptionOption{
		{
			ID:              "discount_5",
			Name:            "$5 Discount",
			Description:     "Get $5 off your order",
			CreditsRequired: 500,
			DiscountValue:   5.0,
			Type:            RedemptionDiscount,
		},
		{
			ID:              "discount_10",
			Name:            "$10 Discount",
			Description:     "Get $10 off your order",
			CreditsRequired: 1000,
			DiscountValue:   10.0,
			Type:            RedemptionDiscount,
		},
		{
			ID:              "discount_25",
			Name:            "$25 Discount",
			Description:     "Get $25 off your order",
			CreditsRequired: 2500,
			DiscountValue:   25.0,
			Type:            RedemptionDiscount,
		},
		{
			ID:              "free_shipping",
			Name:            "Free Shipping",
			Description:     "Get free shipping on your next order",
			CreditsRequired: 300,
			DiscountValue:   0,
			Type:            RedemptionFreeShipping,
		},
	}
}

// LoyaltyStatistics represents statistics for the loyalty program
type LoyaltyStatistics struct {
	TotalMembers          int64            `json:"totalMembers"`
	ActiveMembers         int64            `json:"activeMembers"`
	TierDistribution      map[string]int64 `json:"tierDistribution"`
	TotalCreditsIssued    int64            `json:"totalCreditsIssued"`
	TotalCreditsRedeemed  int64            `json:"totalCreditsRedeemed"`
	AverageCreditsPerUser float64          `json:"averageCreditsPerUser"`
}

// TopLoyaltyMember represents a top loyalty program member
type TopLoyaltyMember struct {
	UserID           primitive.ObjectID `json:"userId"`
	TotalCredits     int                `json:"totalCredits"`
	AvailableCredits int                `json:"availableCredits"`
	Tier             LoyaltyTier        `json:"tier"`
	TotalSpent       float64            `json:"totalSpent"`
}