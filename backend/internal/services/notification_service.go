//go:build exclude

package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strconv"
	"time"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"google.golang.org/api/option"
)

// NotificationService handles push notifications
type NotificationService struct {
	notificationRepo repository.NotificationRepository
	userRepo         repository.UserRepository
	fcmClient        *messaging.Client
	emailService     *EmailService
	smsService       *SMSService
}

// NewNotificationService creates a new notification service
func NewNotificationService(
	notificationRepo repository.NotificationRepository,
	userRepo repository.UserRepository,
	firebaseCredentialsPath string,
	emailService *EmailService,
	smsService *SMSService,
) (*NotificationService, error) {
	// Initialize Firebase app
	opt := option.WithCredentialsFile(firebaseCredentialsPath)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize Firebase app: %w", err)
	}

	// Get messaging client
	fcmClient, err := app.Messaging(context.Background())
	if err != nil {
		return nil, fmt.Errorf("failed to initialize FCM client: %w", err)
	}

	return &NotificationService{
		notificationRepo: notificationRepo,
		userRepo:         userRepo,
		fcmClient:        fcmClient,
		emailService:     emailService,
		smsService:       smsService,
	}, nil
}

// RegisterFCMToken registers a user's FCM token
func (s *NotificationService) RegisterFCMToken(ctx context.Context, userID *primitive.ObjectID, token, platform string) error {
	fcmToken := &models.FCMToken{
		UserID:    userID,
		Token:     token,
		Platform:  platform,
		IsActive:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.notificationRepo.CreateFCMToken(ctx, fcmToken)
}

// SendOrderPlacedNotification sends order placed notification
func (s *NotificationService) SendOrderPlacedNotification(ctx context.Context, userID primitive.ObjectID, orderID string) error {
	notification := &models.Notification{
		UserID:    &userID,
		Title:     "Order Confirmed! 🎉",
		Body:      fmt.Sprintf("Your order #%s has been placed successfully. We'll notify you when it ships.", orderID),
		Type:      models.NotificationOrderPlaced,
		Data: map[string]interface{}{
			"type":     "order",
			"targetId": orderID,
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// SendOrderShippedNotification sends order shipped notification
func (s *NotificationService) SendOrderShippedNotification(ctx context.Context, userID primitive.ObjectID, orderID, trackingNumber string) error {
	notification := &models.Notification{
		UserID:    &userID,
		Title:     "Order Shipped! 📦",
		Body:      fmt.Sprintf("Your order #%s is on its way. Track it with: %s", orderID, trackingNumber),
		Type:      models.NotificationOrderShipped,
		Data: map[string]interface{}{
			"type":           "order",
			"targetId":       orderID,
			"trackingNumber": trackingNumber,
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// SendOrderDeliveredNotification sends order delivered notification
func (s *NotificationService) SendOrderDeliveredNotification(ctx context.Context, userID primitive.ObjectID, orderID string) error {
	notification := &models.Notification{
		UserID:    &userID,
		Title:     "Order Delivered! ✅",
		Body:      fmt.Sprintf("Your order #%s has been delivered. Enjoy your purchase!", orderID),
		Type:      models.NotificationOrderDelivered,
		Data: map[string]interface{}{
			"type":     "order",
			"targetId": orderID,
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// SendOrderCancelledNotification sends order cancelled notification
func (s *NotificationService) SendOrderCancelledNotification(ctx context.Context, userID primitive.ObjectID, orderID string) error {
	notification := &models.Notification{
		UserID:    &userID,
		Title:     "Order Cancelled",
		Body:      fmt.Sprintf("Your order #%s has been cancelled. Refund will be processed within 3-5 days.", orderID),
		Type:      models.NotificationOrderCancelled,
		Data: map[string]interface{}{
			"type":     "order",
			"targetId": orderID,
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// SendFlashSaleNotification sends flash sale notification
func (s *NotificationService) SendFlashSaleNotification(ctx context.Context, saleTitle string, discountPercent int) error {
	notification := &models.Notification{
		Title: "⚡ Flash Sale Alert!",
		Body:  fmt.Sprintf("%s - Get %d%% OFF! Limited time only.", saleTitle, discountPercent),
		Type:  models.NotificationFlashSale,
		Data: map[string]interface{}{
			"type":     "promotion",
			"targetId": "flash_sale",
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendBroadcastNotification(ctx, notification)
}

// SendAbandonedCartNotification sends abandoned cart notification
func (s *NotificationService) SendAbandonedCartNotification(ctx context.Context, userID primitive.ObjectID, itemCount int, totalAmount float64) error {
	notification := &models.Notification{
		UserID:    &userID,
		Title:     "Items Still in Your Cart 🛒",
		Body:      fmt.Sprintf("You have %d items worth $%.2f waiting. Complete your purchase now!", itemCount, totalAmount),
		Type:      models.NotificationAbandonedCart,
		Data: map[string]interface{}{
			"type":     "cart",
			"targetId": "cart",
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// SendBackInStockNotification sends back in stock notification
func (s *NotificationService) SendBackInStockNotification(ctx context.Context, userID primitive.ObjectID, productName, productID string) error {
	notification := &models.Notification{
		UserID:    &userID,
		Title:     "Back in Stock! 🎯",
		Body:      fmt.Sprintf("%s is now available. Get it before it sells out again!", productName),
		Type:      models.NotificationBackInStock,
		Data: map[string]interface{}{
			"type":     "product",
			"targetId": productID,
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// SendLoyaltyPointsNotification sends loyalty points notification
func (s *NotificationService) SendLoyaltyPointsNotification(ctx context.Context, userID primitive.ObjectID, points int, tier string) error {
	notification := &models.Notification{
		UserID:    &userID,
		Title:     "You Earned Points! 🌟",
		Body:      fmt.Sprintf("+%d loyalty points added. You're now a %s member!", points, tier),
		Type:      models.NotificationLoyaltyPoints,
		Data: map[string]interface{}{
			"type":     "loyalty",
			"targetId": "rewards",
			"points":   points,
			"tier":     tier,
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// SendStreakBonusNotification sends streak bonus notification
func (s *NotificationService) SendStreakBonusNotification(ctx context.Context, userID primitive.ObjectID, streak, bonusPoints int) error {
	notification := &models.Notification{
		UserID:    &userID,
		Title:     "Login Streak Bonus! 🔥",
		Body:      fmt.Sprintf("%d day streak! You earned %d bonus points.", streak, bonusPoints),
		Type:      models.NotificationStreakBonus,
		Data: map[string]interface{}{
			"type":        "loyalty",
			"targetId":    "rewards",
			"streak":      streak,
			"bonusPoints": bonusPoints,
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// SendTierUpgradeNotification sends tier upgrade notification
func (s *NotificationService) SendTierUpgradeNotification(ctx context.Context, userID primitive.ObjectID, oldTier, newTier models.LoyaltyTier) error {
	newTierInfo := newTier.GetTierInfo()
	notification := &models.Notification{
		UserID:    &userID,
		Title:     fmt.Sprintf("Tier Upgrade! %s", newTierInfo.Icon),
		Body:      fmt.Sprintf("Congratulations! You've been upgraded to %s tier with exclusive benefits!", newTierInfo.Name),
		Type:      models.NotificationTierUpgrade,
		Data: map[string]interface{}{
			"type":     "loyalty",
			"targetId": "rewards",
			"oldTier":  string(oldTier),
			"newTier":  string(newTier),
		},
		IsRead:    false,
		IsSent:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return s.sendNotification(ctx, notification)
}

// sendNotification sends notification to a specific user
func (s *NotificationService) sendNotification(ctx context.Context, notification *models.Notification) error {
	// Save notification to database
	if err := s.notificationRepo.Create(ctx, notification); err != nil {
		return fmt.Errorf("failed to save notification: %w", err)
	}

	// Get user preferences if user is specified
	if notification.UserID != nil {
		prefs, err := s.notificationRepo.GetUserPreferences(ctx, *notification.UserID)
		if err != nil {
			log.Printf("Failed to get user preferences: %v", err)
			// Continue with default preferences
		}

		// Check if user has disabled this type of notification
		if prefs != nil && !s.isNotificationTypeEnabled(prefs, notification.Type) {
			return nil
		}

		// Get user's FCM tokens
		tokens, err := s.notificationRepo.GetActiveFCMTokens(ctx, notification.UserID)
		if err != nil {
			log.Printf("Failed to get FCM tokens for user %s: %v", notification.UserID.Hex(), err)
		} else {
			// Send push notification
			s.sendPushNotification(ctx, tokens, notification)
		}

		// Send email notification if enabled
		if prefs == nil || prefs.EnableEmailNotifications {
			s.sendEmailNotification(ctx, *notification.UserID, notification)
		}

		// Send SMS notification if enabled
		if prefs != nil && prefs.EnableSMSNotifications {
			s.sendSMSNotification(ctx, *notification.UserID, notification)
		}
	}

	return nil
}

// sendBroadcastNotification sends notification to all users
func (s *NotificationService) sendBroadcastNotification(ctx context.Context, notification *models.Notification) error {
	// Save notification to database
	if err := s.notificationRepo.Create(ctx, notification); err != nil {
		return fmt.Errorf("failed to save notification: %w", err)
	}

	// Get all active FCM tokens
	tokens, err := s.notificationRepo.GetAllActiveFCMTokens(ctx)
	if err != nil {
		log.Printf("Failed to get all FCM tokens: %v", err)
		return err
	}

	// Send push notification to all tokens
	return s.sendPushNotification(ctx, tokens, notification)
}

// sendPushNotification sends FCM push notification
func (s *NotificationService) sendPushNotification(ctx context.Context, tokens []models.FCMToken, notification *models.Notification) error {
	if len(tokens) == 0 {
		return nil
	}

	// Prepare FCM message
	message := &messaging.MulticastMessage{
		Notification: &messaging.Notification{
			Title: notification.Title,
			Body:  notification.Body,
		},
		Data: s.convertDataToStringMap(notification.Data),
		Android: &messaging.AndroidConfig{
			Notification: &messaging.AndroidNotification{
				ChannelID: s.getChannelID(notification.Type),
				Priority:  messaging.PriorityHigh,
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Alert: &messaging.ApsAlert{
						Title: notification.Title,
						Body:  notification.Body,
					},
					Sound: "default",
				},
			},
		},
		Tokens: s.extractTokenStrings(tokens),
	}

	// Send multicast message
	response, err := s.fcmClient.SendMulticast(ctx, message)
	if err != nil {
		log.Printf("Failed to send FCM message: %v", err)
		return err
	}

	log.Printf("Successfully sent %d messages, %d failed", response.SuccessCount, response.FailureCount)

	// Handle failed tokens (remove invalid ones)
	if response.FailureCount > 0 {
		s.handleFailedTokens(ctx, tokens, response)
	}

	// Update notification as sent
	notification.IsSent = true
	now := time.Now()
	notification.SentAt = &now
	notification.UpdatedAt = now

	return s.notificationRepo.Update(ctx, notification)
}

// sendEmailNotification sends email notification
func (s *NotificationService) sendEmailNotification(ctx context.Context, userID primitive.ObjectID, notification *models.Notification) {
	if s.emailService == nil {
		return
	}

	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		log.Printf("Failed to get user for email notification: %v", err)
		return
	}

	// Send email asynchronously
	go func() {
		if err := s.emailService.SendNotificationEmail(user.Email, notification.Title, notification.Body); err != nil {
			log.Printf("Failed to send email notification: %v", err)
		}
	}()
}

// sendSMSNotification sends SMS notification
func (s *NotificationService) sendSMSNotification(ctx context.Context, userID primitive.ObjectID, notification *models.Notification) {
	if s.smsService == nil {
		return
	}

	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		log.Printf("Failed to get user for SMS notification: %v", err)
		return
	}

	// Send SMS asynchronously
	go func() {
		if err := s.smsService.SendNotificationSMS(user.Phone, notification.Body); err != nil {
			log.Printf("Failed to send SMS notification: %v", err)
		}
	}()
}

// Helper functions

func (s *NotificationService) isNotificationTypeEnabled(prefs *models.NotificationPreference, notifType models.NotificationType) bool {
	switch notifType {
	case models.NotificationOrderPlaced, models.NotificationOrderConfirmed,
		 models.NotificationOrderShipped, models.NotificationOrderDelivered,
		 models.NotificationOrderCancelled, models.NotificationOrderReturned,
		 models.NotificationOrderRefunded:
		return prefs.EnableOrderUpdates

	case models.NotificationFlashSale, models.NotificationCouponReminder,
		 models.NotificationSeasonalOffer, models.NotificationNewProduct,
		 models.NotificationPriceDiscount:
		return prefs.EnablePromotions

	case models.NotificationAbandonedCart, models.NotificationBackInStock,
		 models.NotificationWishlistDiscount, models.NotificationReviewReminder:
		return prefs.EnableReminders

	case models.NotificationLoyaltyPoints, models.NotificationStreakBonus,
		 models.NotificationTierUpgrade, models.NotificationVoucherExpiring:
		return prefs.EnableLoyaltyUpdates

	default:
		return true
	}
}

func (s *NotificationService) getChannelID(notifType models.NotificationType) string {
	switch notifType {
	case models.NotificationOrderPlaced, models.NotificationOrderConfirmed,
		 models.NotificationOrderShipped, models.NotificationOrderDelivered,
		 models.NotificationOrderCancelled, models.NotificationOrderReturned,
		 models.NotificationOrderRefunded:
		return "order_notifications"

	case models.NotificationFlashSale, models.NotificationCouponReminder,
		 models.NotificationSeasonalOffer, models.NotificationNewProduct,
		 models.NotificationPriceDiscount:
		return "promotional_notifications"

	case models.NotificationAbandonedCart, models.NotificationBackInStock,
		 models.NotificationWishlistDiscount, models.NotificationReviewReminder,
		 models.NotificationLoyaltyPoints, models.NotificationStreakBonus,
		 models.NotificationTierUpgrade, models.NotificationVoucherExpiring:
		return "behavioral_notifications"

	default:
		return "order_notifications"
	}
}

func (s *NotificationService) convertDataToStringMap(data map[string]interface{}) map[string]string {
	stringMap := make(map[string]string)
	for key, value := range data {
		switch v := value.(type) {
		case string:
			stringMap[key] = v
		case int:
			stringMap[key] = strconv.Itoa(v)
		case float64:
			stringMap[key] = strconv.FormatFloat(v, 'f', -1, 64)
		case bool:
			stringMap[key] = strconv.FormatBool(v)
		default:
			// Convert to JSON string for complex types
			if jsonBytes, err := json.Marshal(v); err == nil {
				stringMap[key] = string(jsonBytes)
			}
		}
	}
	return stringMap
}

func (s *NotificationService) extractTokenStrings(tokens []models.FCMToken) []string {
	var tokenStrings []string
	for _, token := range tokens {
		tokenStrings = append(tokenStrings, token.Token)
	}
	return tokenStrings
}

func (s *NotificationService) handleFailedTokens(ctx context.Context, tokens []models.FCMToken, response *messaging.BatchResponse) {
	for i, resp := range response.Responses {
		if !resp.Success && i < len(tokens) {
			// Mark token as inactive if it's invalid
			if resp.Error != nil && (resp.Error.ErrorCode == "registration-token-not-registered" ||
				resp.Error.ErrorCode == "invalid-registration-token") {
				if err := s.notificationRepo.DeactivateFCMToken(ctx, tokens[i].Token); err != nil {
					log.Printf("Failed to deactivate invalid token: %v", err)
				}
			}
		}
	}
}

// API methods for notification management

// GetUserNotifications gets notifications for a user
func (s *NotificationService) GetUserNotifications(ctx context.Context, userID primitive.ObjectID, limit, offset int, unreadOnly bool) ([]models.Notification, error) {
	return s.notificationRepo.GetUserNotifications(ctx, userID, limit, offset, unreadOnly)
}

// MarkNotificationAsRead marks a notification as read
func (s *NotificationService) MarkNotificationAsRead(ctx context.Context, notificationID primitive.ObjectID, userID primitive.ObjectID) error {
	return s.notificationRepo.MarkAsRead(ctx, notificationID, userID)
}

// MarkAllNotificationsAsRead marks all notifications as read for a user
func (s *NotificationService) MarkAllNotificationsAsRead(ctx context.Context, userID primitive.ObjectID) error {
	return s.notificationRepo.MarkAllAsRead(ctx, userID)
}

// GetNotificationPreferences gets user's notification preferences
func (s *NotificationService) GetNotificationPreferences(ctx context.Context, userID primitive.ObjectID) (*models.NotificationPreference, error) {
	prefs, err := s.notificationRepo.GetUserPreferences(ctx, userID)
	if err != nil {
		// Create default preferences if not found
		prefs = models.DefaultNotificationPreferences(userID)
		if createErr := s.notificationRepo.CreateUserPreferences(ctx, prefs); createErr != nil {
			return nil, fmt.Errorf("failed to create default preferences: %w", createErr)
		}
	}
	return prefs, nil
}

// UpdateNotificationPreferences updates user's notification preferences
func (s *NotificationService) UpdateNotificationPreferences(ctx context.Context, prefs *models.NotificationPreference) error {
	prefs.UpdatedAt = time.Now()
	return s.notificationRepo.UpdateUserPreferences(ctx, prefs)
}

// SendCampaign sends a notification campaign
func (s *NotificationService) SendCampaign(ctx context.Context, campaign *models.NotificationCampaign) error {
	// Update campaign status
	campaign.Status = models.CampaignStatusSending
	campaign.UpdatedAt = time.Now()

	if err := s.notificationRepo.UpdateCampaign(ctx, campaign); err != nil {
		return fmt.Errorf("failed to update campaign status: %w", err)
	}

	// Get target users based on audience criteria
	userIDs, err := s.getTargetUsers(ctx, campaign.TargetAudience)
	if err != nil {
		campaign.Status = models.CampaignStatusFailed
		s.notificationRepo.UpdateCampaign(ctx, campaign)
		return fmt.Errorf("failed to get target users: %w", err)
	}

	campaign.Recipients = len(userIDs)

	// Send notifications to all target users
	sentCount := 0
	for _, userID := range userIDs {
		notification := &models.Notification{
			UserID:    &userID,
			Title:     campaign.Title,
			Body:      campaign.Body,
			Type:      campaign.Type,
			Data:      campaign.Data,
			IsRead:    false,
			IsSent:    false,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}

		if err := s.sendNotification(ctx, notification); err != nil {
			log.Printf("Failed to send campaign notification to user %s: %v", userID.Hex(), err)
		} else {
			sentCount++
		}
	}

	// Update campaign with results
	campaign.Status = models.CampaignStatusSent
	campaign.DeliveredCount = sentCount
	now := time.Now()
	campaign.SentAt = &now
	campaign.UpdatedAt = now

	return s.notificationRepo.UpdateCampaign(ctx, campaign)
}

// getTargetUsers gets user IDs based on campaign audience criteria
func (s *NotificationService) getTargetUsers(ctx context.Context, audience models.CampaignAudience) ([]primitive.ObjectID, error) {
	if audience.AllUsers {
		return s.userRepo.GetAllUserIDs(ctx)
	}

	// Implement specific audience targeting logic here
	// This would involve querying users based on various criteria
	// For now, return specific user IDs if provided
	if len(audience.SpecificUserIDs) > 0 {
		return audience.SpecificUserIDs, nil
	}

	// Default to empty list
	return []primitive.ObjectID{}, nil
}