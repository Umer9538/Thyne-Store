package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Notification represents a push notification
type Notification struct {
	ID        primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	UserID    *primitive.ObjectID `json:"userId,omitempty" bson:"userId,omitempty"`
	Title     string              `json:"title" bson:"title"`
	Body      string              `json:"body" bson:"body"`
	Type      NotificationType    `json:"type" bson:"type"`
	Data      map[string]interface{} `json:"data,omitempty" bson:"data,omitempty"`
	IsRead    bool                `json:"isRead" bson:"isRead"`
	IsSent    bool                `json:"isSent" bson:"isSent"`
	SentAt    *time.Time          `json:"sentAt,omitempty" bson:"sentAt,omitempty"`
	CreatedAt time.Time           `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time           `json:"updatedAt" bson:"updatedAt"`
}

// NotificationType represents different types of notifications
type NotificationType string

const (
	// Transactional notifications
	NotificationOrderPlaced    NotificationType = "order_placed"
	NotificationOrderConfirmed NotificationType = "order_confirmed"
	NotificationOrderShipped   NotificationType = "order_shipped"
	NotificationOrderDelivered NotificationType = "order_delivered"
	NotificationOrderCancelled NotificationType = "order_cancelled"
	NotificationOrderReturned  NotificationType = "order_returned"
	NotificationOrderRefunded  NotificationType = "order_refunded"

	// Promotional notifications
	NotificationFlashSale        NotificationType = "flash_sale"
	NotificationCouponReminder   NotificationType = "coupon_reminder"
	NotificationSeasonalOffer    NotificationType = "seasonal_offer"
	NotificationNewProduct       NotificationType = "new_product"
	NotificationPriceDiscount    NotificationType = "price_discount"

	// Behavioral notifications
	NotificationAbandonedCart    NotificationType = "abandoned_cart"
	NotificationBackInStock      NotificationType = "back_in_stock"
	NotificationWishlistDiscount NotificationType = "wishlist_discount"
	NotificationReviewReminder   NotificationType = "review_reminder"

	// Loyalty notifications
	NotificationLoyaltyPoints   NotificationType = "loyalty_points"
	NotificationStreakBonus     NotificationType = "streak_bonus"
	NotificationTierUpgrade     NotificationType = "tier_upgrade"
	NotificationVoucherExpiring NotificationType = "voucher_expiring"
)

// FCMToken represents a user's Firebase Cloud Messaging token
type FCMToken struct {
	ID        primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	UserID    *primitive.ObjectID `json:"userId,omitempty" bson:"userId,omitempty"`
	Token     string              `json:"token" bson:"token"`
	Platform  string              `json:"platform" bson:"platform"` // "android", "ios", "web"
	IsActive  bool                `json:"isActive" bson:"isActive"`
	CreatedAt time.Time           `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time           `json:"updatedAt" bson:"updatedAt"`
}

// NotificationPreference represents user's notification preferences
type NotificationPreference struct {
	ID                     primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID                 primitive.ObjectID `json:"userId" bson:"userId"`
	EnableOrderUpdates     bool               `json:"enableOrderUpdates" bson:"enableOrderUpdates"`
	EnablePromotions       bool               `json:"enablePromotions" bson:"enablePromotions"`
	EnableReminders        bool               `json:"enableReminders" bson:"enableReminders"`
	EnableLoyaltyUpdates   bool               `json:"enableLoyaltyUpdates" bson:"enableLoyaltyUpdates"`
	EnablePushNotifications bool              `json:"enablePushNotifications" bson:"enablePushNotifications"`
	EnableEmailNotifications bool             `json:"enableEmailNotifications" bson:"enableEmailNotifications"`
	EnableSMSNotifications bool               `json:"enableSMSNotifications" bson:"enableSMSNotifications"`
	CreatedAt              time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt              time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// NotificationPreferences is an alias for compatibility
type NotificationPreferences = NotificationPreference

// Default notification preferences for new users
func DefaultNotificationPreferences(userID primitive.ObjectID) *NotificationPreference {
	return &NotificationPreference{
		UserID:                   userID,
		EnableOrderUpdates:       true,
		EnablePromotions:         true,
		EnableReminders:          true,
		EnableLoyaltyUpdates:     true,
		EnablePushNotifications:  true,
		EnableEmailNotifications: true,
		EnableSMSNotifications:   false,
		CreatedAt:                time.Now(),
		UpdatedAt:                time.Now(),
	}
}

// NotificationTemplate represents a template for notifications
type NotificationTemplate struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Type        NotificationType   `json:"type" bson:"type"`
	Title       string             `json:"title" bson:"title"`
	Body        string             `json:"body" bson:"body"`
	Variables   []string           `json:"variables" bson:"variables"`
	IsActive    bool               `json:"isActive" bson:"isActive"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// NotificationCampaign represents a marketing campaign
type NotificationCampaign struct {
	ID              primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	Name            string               `json:"name" bson:"name"`
	Title           string               `json:"title" bson:"title"`
	Body            string               `json:"body" bson:"body"`
	Type            NotificationType     `json:"type" bson:"type"`
	TargetAudience  CampaignAudience     `json:"targetAudience" bson:"targetAudience"`
	ScheduledAt     *time.Time           `json:"scheduledAt,omitempty" bson:"scheduledAt,omitempty"`
	SentAt          *time.Time           `json:"sentAt,omitempty" bson:"sentAt,omitempty"`
	Status          CampaignStatus       `json:"status" bson:"status"`
	Recipients      int                  `json:"recipients" bson:"recipients"`
	DeliveredCount  int                  `json:"deliveredCount" bson:"deliveredCount"`
	OpenedCount     int                  `json:"openedCount" bson:"openedCount"`
	ClickedCount    int                  `json:"clickedCount" bson:"clickedCount"`
	Data            map[string]interface{} `json:"data,omitempty" bson:"data,omitempty"`
	CreatedBy       primitive.ObjectID   `json:"createdBy" bson:"createdBy"`
	CreatedAt       time.Time            `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time            `json:"updatedAt" bson:"updatedAt"`
}

// CampaignAudience represents targeting criteria
type CampaignAudience struct {
	AllUsers          bool          `json:"allUsers" bson:"allUsers"`
	LoyaltyTiers      []LoyaltyTier `json:"loyaltyTiers,omitempty" bson:"loyaltyTiers,omitempty"`
	MinOrderCount     *int          `json:"minOrderCount,omitempty" bson:"minOrderCount,omitempty"`
	MinTotalSpent     *float64      `json:"minTotalSpent,omitempty" bson:"minTotalSpent,omitempty"`
	HasAbandonedCart  *bool         `json:"hasAbandonedCart,omitempty" bson:"hasAbandonedCart,omitempty"`
	LastOrderDaysAgo  *int          `json:"lastOrderDaysAgo,omitempty" bson:"lastOrderDaysAgo,omitempty"`
	SpecificUserIDs   []primitive.ObjectID `json:"specificUserIds,omitempty" bson:"specificUserIds,omitempty"`
}

// CampaignStatus represents the status of a campaign
type CampaignStatus string

const (
	CampaignStatusDraft     CampaignStatus = "draft"
	CampaignStatusScheduled CampaignStatus = "scheduled"
	CampaignStatusSending   CampaignStatus = "sending"
	CampaignStatusSent      CampaignStatus = "sent"
	CampaignStatusFailed    CampaignStatus = "failed"
)

// NotificationAnalytics represents analytics for notifications
type NotificationAnalytics struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Date           time.Time          `json:"date" bson:"date"`
	TotalSent      int                `json:"totalSent" bson:"totalSent"`
	TotalDelivered int                `json:"totalDelivered" bson:"totalDelivered"`
	TotalOpened    int                `json:"totalOpened" bson:"totalOpened"`
	TotalClicked   int                `json:"totalClicked" bson:"totalClicked"`
	ByType         map[NotificationType]int `json:"byType" bson:"byType"`
	CreatedAt      time.Time          `json:"createdAt" bson:"createdAt"`
}