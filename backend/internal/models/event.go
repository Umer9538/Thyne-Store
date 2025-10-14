package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Event represents a festival or special event
type Event struct {
	ID                  primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name                string             `json:"name" bson:"name" validate:"required,min=2,max=200"`
	Type                string             `json:"type" bson:"type" validate:"required"` // 'festival', 'sale', 'promotion', 'holiday'
	Date                time.Time          `json:"date" bson:"date" validate:"required"`
	Description         *string            `json:"description,omitempty" bson:"description,omitempty"`
	ThemeColor          *string            `json:"themeColor,omitempty" bson:"themeColor,omitempty"`
	IconURL             *string            `json:"iconUrl,omitempty" bson:"iconUrl,omitempty"`
	IsRecurring         bool               `json:"isRecurring" bson:"isRecurring"`
	SuggestedCategories []string           `json:"suggestedCategories" bson:"suggestedCategories"`
	BannerTemplate      *string            `json:"bannerTemplate,omitempty" bson:"bannerTemplate,omitempty"`
	IsActive            bool               `json:"isActive" bson:"isActive"`
	CreatedAt           time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt           time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// Banner represents a promotional banner
type Banner struct {
	ID              primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Title           string             `json:"title" bson:"title" validate:"required,min=2,max=200"`
	ImageURL        string             `json:"imageUrl" bson:"imageUrl" validate:"required"`
	Description     *string            `json:"description,omitempty" bson:"description,omitempty"`
	Type            string             `json:"type" bson:"type" validate:"required"` // 'main', 'promotional', 'festival', 'flash_sale'
	TargetURL       *string            `json:"targetUrl,omitempty" bson:"targetUrl,omitempty"`
	TargetProductID *string            `json:"targetProductId,omitempty" bson:"targetProductId,omitempty"`
	TargetCategory  *string            `json:"targetCategory,omitempty" bson:"targetCategory,omitempty"`
	StartDate       time.Time          `json:"startDate" bson:"startDate" validate:"required"`
	EndDate         *time.Time         `json:"endDate,omitempty" bson:"endDate,omitempty"`
	IsActive        bool               `json:"isActive" bson:"isActive"`
	Priority        int                `json:"priority" bson:"priority"` // Higher number = higher priority
	FestivalTag     *string            `json:"festivalTag,omitempty" bson:"festivalTag,omitempty"`
	CreatedAt       time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// IsLive checks if banner is currently live
func (b *Banner) IsLive() bool {
	now := time.Now()
	if !b.IsActive {
		return false
	}
	if now.Before(b.StartDate) {
		return false
	}
	if b.EndDate != nil && now.After(*b.EndDate) {
		return false
	}
	return true
}

// IsScheduled checks if banner is scheduled for future
func (b *Banner) IsScheduled() bool {
	return b.IsActive && time.Now().Before(b.StartDate)
}

// IsExpired checks if banner has expired
func (b *Banner) IsExpired() bool {
	if b.EndDate == nil {
		return false
	}
	return time.Now().After(*b.EndDate)
}

// ThemeConfiguration represents app theme customization
type ThemeConfiguration struct {
	ID              primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name            string             `json:"name" bson:"name" validate:"required,min=2,max=100"`
	Type            string             `json:"type" bson:"type" validate:"required"` // 'festival', 'seasonal', 'custom'
	PrimaryColor    string             `json:"primaryColor" bson:"primaryColor" validate:"required"`
	SecondaryColor  string             `json:"secondaryColor" bson:"secondaryColor" validate:"required"`
	AccentColor     string             `json:"accentColor" bson:"accentColor" validate:"required"`
	LogoURL         *string            `json:"logoUrl,omitempty" bson:"logoUrl,omitempty"`
	BackgroundImage *string            `json:"backgroundImage,omitempty" bson:"backgroundImage,omitempty"`
	StartDate       *time.Time         `json:"startDate,omitempty" bson:"startDate,omitempty"`
	EndDate         *time.Time         `json:"endDate,omitempty" bson:"endDate,omitempty"`
	IsActive        bool               `json:"isActive" bson:"isActive"`
	CreatedAt       time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// EventPromotion represents a promotion tied to an event
type EventPromotion struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	EventID        primitive.ObjectID `json:"eventId" bson:"eventId" validate:"required"`
	EventName      string             `json:"eventName" bson:"eventName"`
	Title          string             `json:"title" bson:"title" validate:"required,min=2,max=200"`
	Description    string             `json:"description" bson:"description" validate:"required,min=10,max=1000"`
	DiscountType   string             `json:"discountType" bson:"discountType" validate:"required"` // 'percentage', 'fixed', 'bogo'
	DiscountValue  float64            `json:"discountValue" bson:"discountValue" validate:"required,min=0"`
	MinPurchase    *float64           `json:"minPurchase,omitempty" bson:"minPurchase,omitempty"`
	MaxDiscount    *float64           `json:"maxDiscount,omitempty" bson:"maxDiscount,omitempty"`
	ApplicableTo   string             `json:"applicableTo" bson:"applicableTo"` // 'all', 'category', 'product'
	Categories     []string           `json:"categories,omitempty" bson:"categories,omitempty"`
	ProductIDs     []string           `json:"productIds,omitempty" bson:"productIds,omitempty"`
	StartDate      time.Time          `json:"startDate" bson:"startDate" validate:"required"`
	EndDate        time.Time          `json:"endDate" bson:"endDate" validate:"required"`
	IsActive       bool               `json:"isActive" bson:"isActive"`
	ShowAsPopup    bool               `json:"showAsPopup" bson:"showAsPopup"`
	PopupImageURL  *string            `json:"popupImageUrl,omitempty" bson:"popupImageUrl,omitempty"`
	PopupFrequency string             `json:"popupFrequency" bson:"popupFrequency"` // 'once', 'daily', 'session'
	CreatedAt      time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt      time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// IsLive checks if promotion is currently live
func (p *EventPromotion) IsLive() bool {
	now := time.Now()
	return p.IsActive && 
		now.After(p.StartDate) && 
		now.Before(p.EndDate)
}

// CalculateDiscount calculates the discount amount for a given price
func (p *EventPromotion) CalculateDiscount(price float64) float64 {
	if !p.IsLive() {
		return 0
	}

	var discount float64
	switch p.DiscountType {
	case "percentage":
		discount = price * (p.DiscountValue / 100)
	case "fixed":
		discount = p.DiscountValue
	case "bogo":
		// Buy one get one - 50% discount effectively
		discount = price * 0.5
	default:
		return 0
	}

	// Apply max discount cap if set
	if p.MaxDiscount != nil && discount > *p.MaxDiscount {
		discount = *p.MaxDiscount
	}

	return discount
}

