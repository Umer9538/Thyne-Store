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

type storefrontRepository struct {
	configCollection     *mongo.Collection
	popupCollection      *mongo.Collection
	menuCollection       *mongo.Collection
	seoCollection        *mongo.Collection
	analyticsCollection  *mongo.Collection
	businessCollection   *mongo.Collection
}

// NewStorefrontRepository creates a new storefront repository
func NewStorefrontRepository(db *mongo.Database) repository.StorefrontRepository {
	return &storefrontRepository{
		configCollection:    db.Collection("storefront_config"),
		popupCollection:     db.Collection("popup_banners"),
		menuCollection:      db.Collection("menu_config"),
		seoCollection:       db.Collection("seo_config"),
		analyticsCollection: db.Collection("storefront_analytics"),
		businessCollection:  db.Collection("business_config"),
	}
}

func (r *storefrontRepository) GetConfig(ctx context.Context) (*models.StorefrontConfig, error) {
	var config models.StorefrontConfig
	opts := options.FindOne().SetSort(bson.M{"version": -1})
	err := r.configCollection.FindOne(ctx, bson.M{}, opts).Decode(&config)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("storefront config not found")
		}
		return nil, fmt.Errorf("failed to get storefront config: %w", err)
	}
	return &config, nil
}

func (r *storefrontRepository) CreateConfig(ctx context.Context, config *models.StorefrontConfig) error {
	config.ID = primitive.NewObjectID()
	config.CreatedAt = time.Now()
	config.LastUpdated = time.Now()
	config.Version = 1

	_, err := r.configCollection.InsertOne(ctx, config)
	if err != nil {
		return fmt.Errorf("failed to create storefront config: %w", err)
	}

	return nil
}

func (r *storefrontRepository) UpdateConfig(ctx context.Context, config *models.StorefrontConfig) error {
	config.LastUpdated = time.Now()

	// Replace the current config (keeping version history)
	_, err := r.configCollection.InsertOne(ctx, config)
	if err != nil {
		return fmt.Errorf("failed to update storefront config: %w", err)
	}

	return nil
}

func (r *storefrontRepository) GetConfigHistory(ctx context.Context, limit int) ([]models.StorefrontConfig, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"version": -1})

	cursor, err := r.configCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find config history: %w", err)
	}
	defer cursor.Close(ctx)

	var configs []models.StorefrontConfig
	if err = cursor.All(ctx, &configs); err != nil {
		return nil, fmt.Errorf("failed to decode config history: %w", err)
	}

	return configs, nil
}

func (r *storefrontRepository) GetConfigByVersion(ctx context.Context, version int) (*models.StorefrontConfig, error) {
	var config models.StorefrontConfig
	err := r.configCollection.FindOne(ctx, bson.M{"version": version}).Decode(&config)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("config version not found")
		}
		return nil, fmt.Errorf("failed to get config by version: %w", err)
	}
	return &config, nil
}

func (r *storefrontRepository) CreatePopupBanner(ctx context.Context, banner *models.PopupBanner) error {
	banner.ID = primitive.NewObjectID()
	banner.CreatedAt = time.Now()
	banner.UpdatedAt = time.Now()

	_, err := r.popupCollection.InsertOne(ctx, banner)
	if err != nil {
		return fmt.Errorf("failed to create popup banner: %w", err)
	}

	return nil
}

func (r *storefrontRepository) GetActivePopupBanners(ctx context.Context) ([]models.PopupBanner, error) {
	filter := bson.M{"isActive": true}

	cursor, err := r.popupCollection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("failed to find active popup banners: %w", err)
	}
	defer cursor.Close(ctx)

	var banners []models.PopupBanner
	if err = cursor.All(ctx, &banners); err != nil {
		return nil, fmt.Errorf("failed to decode popup banners: %w", err)
	}

	return banners, nil
}

func (r *storefrontRepository) UpdateMenuConfig(ctx context.Context, menuConfig *models.MenuConfig) error {
	menuConfig.UpdatedAt = time.Now()

	opts := options.Replace().SetUpsert(true)
	_, err := r.menuCollection.ReplaceOne(ctx, bson.M{}, menuConfig, opts)
	if err != nil {
		return fmt.Errorf("failed to update menu config: %w", err)
	}

	return nil
}

func (r *storefrontRepository) GetMenuConfig(ctx context.Context) (*models.MenuConfig, error) {
	var menuConfig models.MenuConfig
	err := r.menuCollection.FindOne(ctx, bson.M{}).Decode(&menuConfig)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Return default menu config
			return &models.MenuConfig{
				ID:        primitive.NewObjectID(),
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			}, nil
		}
		return nil, fmt.Errorf("failed to get menu config: %w", err)
	}
	return &menuConfig, nil
}

func (r *storefrontRepository) UpdateSEOConfig(ctx context.Context, seoConfig *models.SEOConfig) error {
	seoConfig.UpdatedAt = time.Now()

	opts := options.Replace().SetUpsert(true)
	_, err := r.seoCollection.ReplaceOne(ctx, bson.M{}, seoConfig, opts)
	if err != nil {
		return fmt.Errorf("failed to update SEO config: %w", err)
	}

	return nil
}

func (r *storefrontRepository) GetSEOConfig(ctx context.Context) (*models.SEOConfig, error) {
	var seoConfig models.SEOConfig
	err := r.seoCollection.FindOne(ctx, bson.M{}).Decode(&seoConfig)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Return default SEO config
			return &models.SEOConfig{
				ID:        primitive.NewObjectID(),
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			}, nil
		}
		return nil, fmt.Errorf("failed to get SEO config: %w", err)
	}
	return &seoConfig, nil
}

func (r *storefrontRepository) RecordBannerClick(ctx context.Context, bannerID string) error {
	analytics := &models.StorefrontAnalytics{
		ID:        primitive.NewObjectID(),
		Event:     "banner_click",
		Data:      map[string]interface{}{"bannerId": bannerID},
		Timestamp: time.Now(),
	}

	_, err := r.analyticsCollection.InsertOne(ctx, analytics)
	if err != nil {
		return fmt.Errorf("failed to record banner click: %w", err)
	}

	return nil
}

func (r *storefrontRepository) RecordSectionView(ctx context.Context, sectionName string) error {
	analytics := &models.StorefrontAnalytics{
		ID:        primitive.NewObjectID(),
		Event:     "section_view",
		Data:      map[string]interface{}{"sectionName": sectionName},
		Timestamp: time.Now(),
	}

	_, err := r.analyticsCollection.InsertOne(ctx, analytics)
	if err != nil {
		return fmt.Errorf("failed to record section view: %w", err)
	}

	return nil
}

func (r *storefrontRepository) RecordFeatureUsage(ctx context.Context, feature string) error {
	analytics := &models.StorefrontAnalytics{
		ID:        primitive.NewObjectID(),
		Event:     "feature_usage",
		Data:      map[string]interface{}{"feature": feature},
		Timestamp: time.Now(),
	}

	_, err := r.analyticsCollection.InsertOne(ctx, analytics)
	if err != nil {
		return fmt.Errorf("failed to record feature usage: %w", err)
	}

	return nil
}

func (r *storefrontRepository) GetAnalytics(ctx context.Context, startDate, endDate time.Time) ([]models.StorefrontAnalytics, error) {
	filter := bson.M{
		"timestamp": bson.M{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	opts := options.Find().SetSort(bson.M{"timestamp": -1})

	cursor, err := r.analyticsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find analytics: %w", err)
	}
	defer cursor.Close(ctx)

	var analytics []models.StorefrontAnalytics
	if err = cursor.All(ctx, &analytics); err != nil {
		return nil, fmt.Errorf("failed to decode analytics: %w", err)
	}

	return analytics, nil
}

func (r *storefrontRepository) GetBusinessConfig(ctx context.Context) (*models.BusinessConfig, error) {
	var config models.BusinessConfig
	err := r.businessCollection.FindOne(ctx, bson.M{}).Decode(&config)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Return default business config
			defaultConfig := models.GetDefaultBusinessConfig()
			// Save default config
			if createErr := r.UpdateBusinessConfig(ctx, defaultConfig); createErr != nil {
				return nil, fmt.Errorf("failed to create default business config: %w", createErr)
			}
			return defaultConfig, nil
		}
		return nil, fmt.Errorf("failed to get business config: %w", err)
	}
	return &config, nil
}

func (r *storefrontRepository) UpdateBusinessConfig(ctx context.Context, config *models.BusinessConfig) error {
	if config.ID.IsZero() {
		config.ID = primitive.NewObjectID()
		config.CreatedAt = time.Now()
	}
	config.UpdatedAt = time.Now()

	opts := options.Replace().SetUpsert(true)
	_, err := r.businessCollection.ReplaceOne(ctx, bson.M{}, config, opts)
	if err != nil {
		return fmt.Errorf("failed to update business config: %w", err)
	}

	return nil
}