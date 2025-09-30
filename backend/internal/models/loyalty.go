package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LoyaltyProgram represents a user's loyalty program status
type LoyaltyProgram struct {
	ID           primitive.ObjectID    `json:"id" bson:"_id,omitempty"`
	UserID       primitive.ObjectID    `json:"userId" bson:"userId"`
	TotalPoints  int                   `json:"totalPoints" bson:"totalPoints"`
	CurrentPoints int                  `json:"currentPoints" bson:"currentPoints"`
	Tier         LoyaltyTier          `json:"tier" bson:"tier"`
	LoginStreak  int                  `json:"loginStreak" bson:"loginStreak"`
	LastLoginDate *time.Time          `json:"lastLoginDate" bson:"lastLoginDate"`
	TotalSpent   float64              `json:"totalSpent" bson:"totalSpent"`
	TotalOrders  int                  `json:"totalOrders" bson:"totalOrders"`
	Transactions []PointTransaction   `json:"transactions" bson:"transactions"`
	Vouchers     []UserVoucher        `json:"vouchers" bson:"vouchers"`
	JoinedAt     time.Time            `json:"joinedAt" bson:"joinedAt"`
	UpdatedAt    time.Time            `json:"updatedAt" bson:"updatedAt"`
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
	Name           string   `json:"name"`
	Icon           string   `json:"icon"`
	PointsRequired int      `json:"pointsRequired"`
	Multiplier     float64  `json:"multiplier"`
	Benefits       []string `json:"benefits"`
}

// GetTierInfo returns information for a given tier
func (t LoyaltyTier) GetTierInfo() TierInfo {
	switch t {
	case TierBronze:
		return TierInfo{
			Name:           "Bronze",
			Icon:           "🥉",
			PointsRequired: 0,
			Multiplier:     1.0,
			Benefits: []string{
				"Earn 1 point per $1 spent",
				"Birthday bonus points",
				"Early access to sales",
			},
		}
	case TierSilver:
		return TierInfo{
			Name:           "Silver",
			Icon:           "🥈",
			PointsRequired: 500,
			Multiplier:     1.2,
			Benefits: []string{
				"Earn 1.2 points per $1 spent",
				"Free shipping on orders over $50",
				"Exclusive member discounts",
				"Birthday bonus points",
			},
		}
	case TierGold:
		return TierInfo{
			Name:           "Gold",
			Icon:           "🥇",
			PointsRequired: 2000,
			Multiplier:     1.5,
			Benefits: []string{
				"Earn 1.5 points per $1 spent",
				"Free shipping on all orders",
				"Priority customer service",
				"Exclusive gold member sales",
				"Birthday bonus points",
			},
		}
	case TierPlatinum:
		return TierInfo{
			Name:           "Platinum",
			Icon:           "💎",
			PointsRequired: 5000,
			Multiplier:     2.0,
			Benefits: []string{
				"Earn 2 points per $1 spent",
				"Free express shipping",
				"VIP customer service",
				"Exclusive platinum previews",
				"Personal shopping assistant",
				"Birthday bonus points",
			},
		}
	default:
		return TierInfo{}
	}
}

// CalculateNextTier returns the next tier and points needed
func (lp *LoyaltyProgram) CalculateNextTier() (LoyaltyTier, int) {
	switch lp.Tier {
	case TierBronze:
		return TierSilver, 500 - lp.TotalPoints
	case TierSilver:
		return TierGold, 2000 - lp.TotalPoints
	case TierGold:
		return TierPlatinum, 5000 - lp.TotalPoints
	default:
		return TierPlatinum, 0 // Already at max tier
	}
}

// CalculateTierProgress returns progress percentage for current tier
func (lp *LoyaltyProgram) CalculateTierProgress() float64 {
	switch lp.Tier {
	case TierBronze:
		return float64(lp.TotalPoints) / 500.0
	case TierSilver:
		return float64(lp.TotalPoints-500) / 1500.0
	case TierGold:
		return float64(lp.TotalPoints-2000) / 3000.0
	case TierPlatinum:
		return 1.0
	default:
		return 0.0
	}
}

// PointTransaction represents a single point transaction
type PointTransaction struct {
	ID          primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	Type        TransactionType      `json:"type" bson:"type"`
	Points      int                  `json:"points" bson:"points"`
	Description string               `json:"description" bson:"description"`
	OrderID     *primitive.ObjectID  `json:"orderId,omitempty" bson:"orderId,omitempty"`
	CreatedAt   time.Time            `json:"createdAt" bson:"createdAt"`
}

// TransactionType represents different types of point transactions
type TransactionType string

const (
	TransactionEarned   TransactionType = "earned"
	TransactionRedeemed TransactionType = "redeemed"
	TransactionBonus    TransactionType = "bonus"
	TransactionExpired  TransactionType = "expired"
)

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
	ID                 primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	BasePointsPerDollar float64           `json:"basePointsPerDollar" bson:"basePointsPerDollar"`
	DailyLoginBonus    int               `json:"dailyLoginBonus" bson:"dailyLoginBonus"`
	StreakBonusPoints  int               `json:"streakBonusPoints" bson:"streakBonusPoints"`
	StreakBonusDays    int               `json:"streakBonusDays" bson:"streakBonusDays"`
	ReferralBonus      int               `json:"referralBonus" bson:"referralBonus"`
	ReviewBonus        int               `json:"reviewBonus" bson:"reviewBonus"`
	WelcomeBonus       int               `json:"welcomeBonus" bson:"welcomeBonus"`
	UpdatedAt          time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// Default loyalty configuration
func DefaultLoyaltyConfig() *LoyaltyConfig {
	return &LoyaltyConfig{
		BasePointsPerDollar: 1.0,
		DailyLoginBonus:     10,
		StreakBonusPoints:   50,
		StreakBonusDays:     7,
		ReferralBonus:       100,
		ReviewBonus:         25,
		WelcomeBonus:        100,
		UpdatedAt:           time.Now(),
	}
}