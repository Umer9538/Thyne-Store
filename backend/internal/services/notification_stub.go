package services

import (
    "context"
    "thyne-jewels-backend/internal/models"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

// NotificationService is a no-op stub used for builds without notification implementation
type NotificationService struct{}

func (s *NotificationService) SendOrderPlacedNotification(ctx context.Context, userID primitive.ObjectID, orderID string) error { return nil }
func (s *NotificationService) SendOrderShippedNotification(ctx context.Context, userID primitive.ObjectID, orderID, trackingNumber string) error {
    return nil
}
func (s *NotificationService) SendOrderDeliveredNotification(ctx context.Context, userID primitive.ObjectID, orderID string) error { return nil }
func (s *NotificationService) SendOrderCancelledNotification(ctx context.Context, userID primitive.ObjectID, orderID string) error { return nil }
func (s *NotificationService) SendAbandonedCartNotification(ctx context.Context, userID primitive.ObjectID, itemCount int, totalAmount float64) error {
    return nil
}
func (s *NotificationService) SendBackInStockNotification(ctx context.Context, userID primitive.ObjectID, productName, productID string) error {
    return nil
}

// Preferences-related no-ops
func (s *NotificationService) GetNotificationPreferences(ctx context.Context, userID primitive.ObjectID) (*models.NotificationPreference, error) {
    return nil, nil
}
func (s *NotificationService) UpdateNotificationPreferences(ctx context.Context, prefs *models.NotificationPreference) error { return nil }

