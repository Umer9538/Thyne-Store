//go:build exclude

package mongo

import (
	"context"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type notificationRepository struct {
	notificationCollection *mongo.Collection
	fcmTokenCollection     *mongo.Collection
	campaignCollection     *mongo.Collection
	preferencesCollection  *mongo.Collection
	templateCollection     *mongo.Collection
}

// NewNotificationRepository creates a new notification repository
func NewNotificationRepository(db *mongo.Database) repository.NotificationRepository {
	return &notificationRepository{
		notificationCollection: db.Collection("notifications"),
		fcmTokenCollection:     db.Collection("fcm_tokens"),
		campaignCollection:     db.Collection("notification_campaigns"),
		preferencesCollection:  db.Collection("notification_preferences"),
		templateCollection:     db.Collection("notification_templates"),
	}
}

func (r *notificationRepository) Create(ctx context.Context, notification *models.Notification) error {
	notification.ID = primitive.NewObjectID()
	notification.CreatedAt = time.Now()

	_, err := r.notificationCollection.InsertOne(ctx, notification)
	if err != nil {
		return fmt.Errorf("failed to create notification: %w", err)
	}

	return nil
}

func (r *notificationRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Notification, error) {
	var notification models.Notification
	err := r.notificationCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&notification)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("notification not found")
		}
		return nil, fmt.Errorf("failed to get notification: %w", err)
	}
	return &notification, nil
}

func (r *notificationRepository) Update(ctx context.Context, notification *models.Notification) error {
	_, err := r.notificationCollection.UpdateOne(
		ctx,
		bson.M{"_id": notification.ID},
		bson.M{"$set": notification},
	)
	if err != nil {
		return fmt.Errorf("failed to update notification: %w", err)
	}

	return nil
}

func (r *notificationRepository) GetUserNotifications(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Notification, int64, error) {
	filter := bson.M{"userId": userID}

	// Get total count
	total, err := r.notificationCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count notifications: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find notifications
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.notificationCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find notifications: %w", err)
	}
	defer cursor.Close(ctx)

	var notifications []models.Notification
	if err = cursor.All(ctx, &notifications); err != nil {
		return nil, 0, fmt.Errorf("failed to decode notifications: %w", err)
	}

	return notifications, total, nil
}

func (r *notificationRepository) MarkAsRead(ctx context.Context, id primitive.ObjectID) error {
	now := time.Now()
	_, err := r.notificationCollection.UpdateOne(
		ctx,
		bson.M{"_id": id},
		bson.M{
			"$set": bson.M{
				"isRead":  true,
				"readAt":  &now,
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to mark notification as read: %w", err)
	}

	return nil
}

func (r *notificationRepository) MarkAllAsRead(ctx context.Context, userID primitive.ObjectID) error {
	now := time.Now()
	_, err := r.notificationCollection.UpdateMany(
		ctx,
		bson.M{"userId": userID, "isRead": false},
		bson.M{
			"$set": bson.M{
				"isRead":  true,
				"readAt":  &now,
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to mark all notifications as read: %w", err)
	}

	return nil
}

func (r *notificationRepository) GetUnreadCount(ctx context.Context, userID primitive.ObjectID) (int64, error) {
	count, err := r.notificationCollection.CountDocuments(ctx, bson.M{
		"userId": userID,
		"isRead": false,
	})
	if err != nil {
		return 0, fmt.Errorf("failed to get unread count: %w", err)
	}

	return count, nil
}

func (r *notificationRepository) CreateFCMToken(ctx context.Context, token *models.FCMToken) error {
	token.ID = primitive.NewObjectID()
	token.CreatedAt = time.Now()
	token.UpdatedAt = time.Now()

	// Use upsert to avoid duplicates
	opts := options.Replace().SetUpsert(true)
	_, err := r.fcmTokenCollection.ReplaceOne(
		ctx,
		bson.M{"token": token.Token, "userId": token.UserID},
		token,
		opts,
	)
	if err != nil {
		return fmt.Errorf("failed to create FCM token: %w", err)
	}

	return nil
}

func (r *notificationRepository) GetFCMTokensByUserID(ctx context.Context, userID primitive.ObjectID) ([]models.FCMToken, error) {
	filter := bson.M{"userId": userID, "isActive": true}

	cursor, err := r.fcmTokenCollection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("failed to find FCM tokens: %w", err)
	}
	defer cursor.Close(ctx)

	var tokens []models.FCMToken
	if err = cursor.All(ctx, &tokens); err != nil {
		return nil, fmt.Errorf("failed to decode FCM tokens: %w", err)
	}

	return tokens, nil
}

func (r *notificationRepository) UpdateFCMToken(ctx context.Context, token *models.FCMToken) error {
	token.UpdatedAt = time.Now()

	_, err := r.fcmTokenCollection.UpdateOne(
		ctx,
		bson.M{"_id": token.ID},
		bson.M{"$set": token},
	)
	if err != nil {
		return fmt.Errorf("failed to update FCM token: %w", err)
	}

	return nil
}

func (r *notificationRepository) DeleteFCMToken(ctx context.Context, tokenValue string) error {
	_, err := r.fcmTokenCollection.DeleteOne(ctx, bson.M{"token": tokenValue})
	if err != nil {
		return fmt.Errorf("failed to delete FCM token: %w", err)
	}

	return nil
}

func (r *notificationRepository) CreateCampaign(ctx context.Context, campaign *models.NotificationCampaign) error {
	campaign.ID = primitive.NewObjectID()
	campaign.CreatedAt = time.Now()
	campaign.UpdatedAt = time.Now()

	_, err := r.campaignCollection.InsertOne(ctx, campaign)
	if err != nil {
		return fmt.Errorf("failed to create campaign: %w", err)
	}

	return nil
}

func (r *notificationRepository) GetCampaignByID(ctx context.Context, id primitive.ObjectID) (*models.NotificationCampaign, error) {
	var campaign models.NotificationCampaign
	err := r.campaignCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&campaign)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("campaign not found")
		}
		return nil, fmt.Errorf("failed to get campaign: %w", err)
	}
	return &campaign, nil
}

func (r *notificationRepository) UpdateCampaign(ctx context.Context, campaign *models.NotificationCampaign) error {
	campaign.UpdatedAt = time.Now()

	_, err := r.campaignCollection.UpdateOne(
		ctx,
		bson.M{"_id": campaign.ID},
		bson.M{"$set": campaign},
	)
	if err != nil {
		return fmt.Errorf("failed to update campaign: %w", err)
	}

	return nil
}

func (r *notificationRepository) GetCampaigns(ctx context.Context, page, limit int) ([]models.NotificationCampaign, int64, error) {
	// Get total count
	total, err := r.campaignCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count campaigns: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find campaigns
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.campaignCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find campaigns: %w", err)
	}
	defer cursor.Close(ctx)

	var campaigns []models.NotificationCampaign
	if err = cursor.All(ctx, &campaigns); err != nil {
		return nil, 0, fmt.Errorf("failed to decode campaigns: %w", err)
	}

	return campaigns, total, nil
}

func (r *notificationRepository) GetUserPreferences(ctx context.Context, userID primitive.ObjectID) (*models.NotificationPreferences, error) {
	var preferences models.NotificationPreferences
	err := r.preferencesCollection.FindOne(ctx, bson.M{"userId": userID}).Decode(&preferences)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Return default preferences
			return &models.NotificationPreferences{
				UserID: userID,
				Push:   true,
				Email:  true,
				SMS:    false,
				Types: map[string]bool{
					"order_updates":      true,
					"promotions":         true,
					"loyalty_updates":    true,
					"product_updates":    false,
					"marketing":          false,
				},
			}, nil
		}
		return nil, fmt.Errorf("failed to get preferences: %w", err)
	}
	return &preferences, nil
}

func (r *notificationRepository) UpdateUserPreferences(ctx context.Context, preferences *models.NotificationPreferences) error {
	preferences.UpdatedAt = time.Now()

	opts := options.Replace().SetUpsert(true)
	_, err := r.preferencesCollection.ReplaceOne(
		ctx,
		bson.M{"userId": preferences.UserID},
		preferences,
		opts,
	)
	if err != nil {
		return fmt.Errorf("failed to update preferences: %w", err)
	}

	return nil
}

func (r *notificationRepository) GetNotificationStatistics(ctx context.Context) (*models.NotificationStatistics, error) {
	// Get basic counts
	totalSent, _ := r.notificationCollection.CountDocuments(ctx, bson.M{})
	totalDelivered, _ := r.notificationCollection.CountDocuments(ctx, bson.M{"deliveredAt": bson.M{"$ne": nil}})
	totalOpened, _ := r.notificationCollection.CountDocuments(ctx, bson.M{"isRead": true})
	totalClicked, _ := r.notificationCollection.CountDocuments(ctx, bson.M{"clickedAt": bson.M{"$ne": nil}})

	// Calculate rates
	var deliveryRate, openRate, clickRate float64
	if totalSent > 0 {
		deliveryRate = (float64(totalDelivered) / float64(totalSent)) * 100
		openRate = (float64(totalOpened) / float64(totalSent)) * 100
		clickRate = (float64(totalClicked) / float64(totalSent)) * 100
	}

	// Get notifications by type
	notificationsByType, err := r.getNotificationsByType(ctx)
	if err != nil {
		notificationsByType = make(map[string]int64)
	}

	// Get campaign performance
	campaignPerformance, err := r.getCampaignPerformance(ctx)
	if err != nil {
		campaignPerformance = []models.CampaignStats{}
	}

	return &models.NotificationStatistics{
		TotalSent:           totalSent,
		TotalDelivered:      totalDelivered,
		TotalOpened:         totalOpened,
		TotalClicked:        totalClicked,
		DeliveryRate:        deliveryRate,
		OpenRate:            openRate,
		ClickRate:           clickRate,
		NotificationsByType: notificationsByType,
		CampaignPerformance: campaignPerformance,
	}, nil
}

func (r *notificationRepository) CreateTemplate(ctx context.Context, template *models.NotificationTemplate) error {
	template.ID = primitive.NewObjectID()
	template.CreatedAt = time.Now()
	template.UpdatedAt = time.Now()

	_, err := r.templateCollection.InsertOne(ctx, template)
	if err != nil {
		return fmt.Errorf("failed to create template: %w", err)
	}

	return nil
}

func (r *notificationRepository) GetTemplateByType(ctx context.Context, templateType string) (*models.NotificationTemplate, error) {
	var template models.NotificationTemplate
	err := r.templateCollection.FindOne(ctx, bson.M{
		"type":     templateType,
		"isActive": true,
	}).Decode(&template)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("template not found")
		}
		return nil, fmt.Errorf("failed to get template: %w", err)
	}
	return &template, nil
}

// Helper methods

func (r *notificationRepository) getNotificationsByType(ctx context.Context) (map[string]int64, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":   "$type",
				"count": bson.M{"$sum": 1},
			},
		},
	}

	cursor, err := r.notificationCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	notificationsByType := make(map[string]int64)
	for cursor.Next(ctx) {
		var result struct {
			Type  string `bson:"_id"`
			Count int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		notificationsByType[result.Type] = result.Count
	}

	return notificationsByType, nil
}

func (r *notificationRepository) getCampaignPerformance(ctx context.Context) ([]models.CampaignStats, error) {
	cursor, err := r.campaignCollection.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var campaigns []models.CampaignStats
	for cursor.Next(ctx) {
		var campaign models.NotificationCampaign
		if err := cursor.Decode(&campaign); err != nil {
			continue
		}

		// Calculate rates
		var deliveryRate, openRate, clickRate float64
		if campaign.TotalSent > 0 {
			deliveryRate = (float64(campaign.TotalDelivered) / float64(campaign.TotalSent)) * 100
			openRate = (float64(campaign.TotalOpened) / float64(campaign.TotalSent)) * 100
			clickRate = (float64(campaign.TotalClicked) / float64(campaign.TotalSent)) * 100
		}

		campaigns = append(campaigns, models.CampaignStats{
			CampaignID:   campaign.ID,
			Name:         campaign.Name,
			Type:         campaign.Type,
			Sent:         campaign.TotalSent,
			Delivered:    campaign.TotalDelivered,
			Opened:       campaign.TotalOpened,
			Clicked:      campaign.TotalClicked,
			DeliveryRate: deliveryRate,
			OpenRate:     openRate,
			ClickRate:    clickRate,
			CreatedAt:    campaign.CreatedAt,
		})
	}

	return campaigns, nil
}