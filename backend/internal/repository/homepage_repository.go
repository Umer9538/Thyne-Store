package repository

import (
	"context"

	"thyne-jewels-backend/internal/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// HomepageRepository defines the interface for homepage data operations
type HomepageRepository interface {
	// Homepage Configuration
	GetHomepageConfig(ctx context.Context) (*models.HomepageConfig, error)
	UpdateHomepageConfig(ctx context.Context, config *models.HomepageConfig) error
	GetActiveSections(ctx context.Context) ([]models.HomepageSection, error)

	// Homepage Layout
	GetHomepageLayout(ctx context.Context) (*models.HomepageLayout, error)
	UpdateHomepageLayout(ctx context.Context, layout *models.HomepageLayout) error
	CreateDefaultLayout(ctx context.Context) error

	// Deal of Day
	CreateDealOfDay(ctx context.Context, deal *models.DealOfDay) error
	GetActiveDealOfDay(ctx context.Context) (*models.DealOfDay, error)
	GetDealByID(ctx context.Context, dealID primitive.ObjectID) (*models.DealOfDay, error)
	UpdateDealOfDay(ctx context.Context, deal *models.DealOfDay) error
	IncrementDealSold(ctx context.Context, dealID primitive.ObjectID) error

	// Flash Sales
	CreateFlashSale(ctx context.Context, sale *models.FlashSale) error
	GetActiveFlashSales(ctx context.Context) ([]models.FlashSale, error)
	GetFlashSaleByID(ctx context.Context, saleID primitive.ObjectID) (*models.FlashSale, error)
	UpdateFlashSale(ctx context.Context, sale *models.FlashSale) error
	GetAllFlashSales(ctx context.Context) ([]models.FlashSale, error)

	// Brands
	CreateBrand(ctx context.Context, brand *models.Brand) error
	GetActiveBrands(ctx context.Context) ([]models.Brand, error)
	GetBrandByID(ctx context.Context, brandID primitive.ObjectID) (*models.Brand, error)
	UpdateBrand(ctx context.Context, brand *models.Brand) error
	DeleteBrand(ctx context.Context, brandID primitive.ObjectID) error
	GetAllBrands(ctx context.Context) ([]models.Brand, error)

	// Recently Viewed
	TrackProductView(ctx context.Context, userID *primitive.ObjectID, sessionID *string, productID primitive.ObjectID) error
	GetRecentlyViewed(ctx context.Context, userID *primitive.ObjectID, sessionID *string, limit int) ([]primitive.ObjectID, error)

	// 360° Showcase
	CreateShowcase360(ctx context.Context, showcase *models.Showcase360) error
	GetActiveShowcases360(ctx context.Context) ([]models.Showcase360, error)
	GetShowcase360ByID(ctx context.Context, showcaseID primitive.ObjectID) (*models.Showcase360, error)
	UpdateShowcase360(ctx context.Context, showcase *models.Showcase360) error
	DeleteShowcase360(ctx context.Context, showcaseID primitive.ObjectID) error

	// Bundle Deals
	CreateBundleDeal(ctx context.Context, bundle *models.BundleDeal) error
	GetActiveBundleDeals(ctx context.Context) ([]models.BundleDeal, error)
	GetBundleDealByID(ctx context.Context, bundleID primitive.ObjectID) (*models.BundleDeal, error)
	UpdateBundleDeal(ctx context.Context, bundle *models.BundleDeal) error
	DeleteBundleDeal(ctx context.Context, bundleID primitive.ObjectID) error
	IncrementBundleSold(ctx context.Context, bundleID primitive.ObjectID) error
}
