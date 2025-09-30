//go:build exclude

package services

import (
	"context"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// StorefrontService handles dynamic storefront configuration
type StorefrontService struct {
	storefrontRepo repository.StorefrontRepository
	productRepo    repository.ProductRepository
	cacheService   *CacheService
}

// NewStorefrontService creates a new storefront service
func NewStorefrontService(
	storefrontRepo repository.StorefrontRepository,
	productRepo repository.ProductRepository,
	cacheService *CacheService,
) *StorefrontService {
	return &StorefrontService{
		storefrontRepo: storefrontRepo,
		productRepo:    productRepo,
		cacheService:   cacheService,
	}
}

// GetStorefrontConfig gets the current storefront configuration
func (s *StorefrontService) GetStorefrontConfig(ctx context.Context) (*models.StorefrontConfig, error) {
	// Try to get from cache first
	if s.cacheService != nil {
		if cached, err := s.cacheService.GetStorefrontConfig(ctx); err == nil && cached != nil {
			return cached, nil
		}
	}

	config, err := s.storefrontRepo.GetConfig(ctx)
	if err != nil {
		// Return default config if not found
		config = models.DefaultStorefrontConfig()
		if createErr := s.storefrontRepo.CreateConfig(ctx, config); createErr != nil {
			return nil, fmt.Errorf("failed to create default config: %w", createErr)
		}
	}

	// Cache the config
	if s.cacheService != nil {
		s.cacheService.SetStorefrontConfig(ctx, config)
	}

	return config, nil
}

// UpdateStorefrontConfig updates the storefront configuration
func (s *StorefrontService) UpdateStorefrontConfig(ctx context.Context, config *models.StorefrontConfig, adminID primitive.ObjectID) error {
	config.LastUpdated = time.Now()
	config.UpdatedBy = adminID
	config.Version++

	if err := s.storefrontRepo.UpdateConfig(ctx, config); err != nil {
		return fmt.Errorf("failed to update storefront config: %w", err)
	}

	// Clear cache
	if s.cacheService != nil {
		s.cacheService.ClearStorefrontConfig(ctx)
	}

	return nil
}

// GetHomePageConfig gets homepage configuration with resolved data
func (s *StorefrontService) GetHomePageConfig(ctx context.Context) (*models.HomePageConfig, error) {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return nil, err
	}

	// Get active hero banners
	activeHeroBanners := make([]models.HeroBanner, 0)
	for _, banner := range config.HomePage.HeroBanners {
		if banner.IsCurrentlyActive() {
			activeHeroBanners = append(activeHeroBanners, banner)
		}
	}
	config.HomePage.HeroBanners = activeHeroBanners

	return &config.HomePage, nil
}

// GetFeaturedProducts gets featured products based on configuration
func (s *StorefrontService) GetFeaturedProducts(ctx context.Context, limit int) ([]models.Product, error) {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return nil, err
	}

	// Get specifically configured featured products
	if len(config.HomePage.FeaturedProductIDs) > 0 {
		products, err := s.productRepo.GetByIDs(ctx, config.HomePage.FeaturedProductIDs)
		if err != nil {
			return nil, fmt.Errorf("failed to get featured products: %w", err)
		}
		if len(products) >= limit {
			return products[:limit], nil
		}
		return products, nil
	}

	// Fallback to default featured products (high rated, in stock)
	return s.productRepo.GetFeaturedProducts(ctx, limit)
}

// GetNewArrivals gets new arrival products if enabled
func (s *StorefrontService) GetNewArrivals(ctx context.Context, limit int) ([]models.Product, error) {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return nil, err
	}

	if !config.HomePage.ShowNewArrivals {
		return []models.Product{}, nil
	}

	return s.productRepo.GetNewArrivals(ctx, limit)
}

// GetBestSellers gets best selling products if enabled
func (s *StorefrontService) GetBestSellers(ctx context.Context, limit int) ([]models.Product, error) {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return nil, err
	}

	if !config.HomePage.ShowBestSellers {
		return []models.Product{}, nil
	}

	return s.productRepo.GetBestSellers(ctx, limit)
}

// GetVisibleCategories gets categories that are configured to be visible
func (s *StorefrontService) GetVisibleCategories(ctx context.Context) ([]models.CategoryVisibility, error) {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return nil, err
	}

	visibleCategories := make([]models.CategoryVisibility, 0)
	for _, category := range config.CategoryVisibility {
		if category.IsVisible {
			visibleCategories = append(visibleCategories, category)
		}
	}

	return visibleCategories, nil
}

// CreateHeroBanner creates a new hero banner
func (s *StorefrontService) CreateHeroBanner(ctx context.Context, banner *models.HeroBanner, adminID primitive.ObjectID) error {
	banner.ID = primitive.NewObjectID()
	banner.CreatedAt = time.Now()
	banner.UpdatedAt = time.Now()

	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	config.HomePage.HeroBanners = append(config.HomePage.HeroBanners, *banner)
	return s.UpdateStorefrontConfig(ctx, config, adminID)
}

// UpdateHeroBanner updates an existing hero banner
func (s *StorefrontService) UpdateHeroBanner(ctx context.Context, bannerID primitive.ObjectID, updatedBanner *models.HeroBanner, adminID primitive.ObjectID) error {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	for i, banner := range config.HomePage.HeroBanners {
		if banner.ID == bannerID {
			updatedBanner.ID = bannerID
			updatedBanner.CreatedAt = banner.CreatedAt
			updatedBanner.UpdatedAt = time.Now()
			config.HomePage.HeroBanners[i] = *updatedBanner
			return s.UpdateStorefrontConfig(ctx, config, adminID)
		}
	}

	return fmt.Errorf("hero banner not found")
}

// DeleteHeroBanner deletes a hero banner
func (s *StorefrontService) DeleteHeroBanner(ctx context.Context, bannerID primitive.ObjectID, adminID primitive.ObjectID) error {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	for i, banner := range config.HomePage.HeroBanners {
		if banner.ID == bannerID {
			config.HomePage.HeroBanners = append(config.HomePage.HeroBanners[:i], config.HomePage.HeroBanners[i+1:]...)
			return s.UpdateStorefrontConfig(ctx, config, adminID)
		}
	}

	return fmt.Errorf("hero banner not found")
}

// UpdateCategoryVisibility updates category visibility settings
func (s *StorefrontService) UpdateCategoryVisibility(ctx context.Context, categoryVisibility []models.CategoryVisibility, adminID primitive.ObjectID) error {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	config.CategoryVisibility = categoryVisibility
	return s.UpdateStorefrontConfig(ctx, config, adminID)
}

// UpdatePromotionalBanners updates promotional banner settings
func (s *StorefrontService) UpdatePromotionalBanners(ctx context.Context, banners *models.PromotionalBanners, adminID primitive.ObjectID) error {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	config.PromotionalBanners = *banners
	return s.UpdateStorefrontConfig(ctx, config, adminID)
}

// UpdateThemeConfig updates theme configuration
func (s *StorefrontService) UpdateThemeConfig(ctx context.Context, theme *models.ThemeConfig, adminID primitive.ObjectID) error {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	config.ThemeConfig = *theme
	return s.UpdateStorefrontConfig(ctx, config, adminID)
}

// UpdateFeatureFlags updates feature flags
func (s *StorefrontService) UpdateFeatureFlags(ctx context.Context, flags *models.FeatureFlags, adminID primitive.ObjectID) error {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	config.FeatureFlags = *flags
	return s.UpdateStorefrontConfig(ctx, config, adminID)
}

// IsFeatureEnabled checks if a specific feature is enabled
func (s *StorefrontService) IsFeatureEnabled(ctx context.Context, feature string) (bool, error) {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return false, err
	}

	switch feature {
	case "loyalty":
		return config.FeatureFlags.EnableLoyaltyProgram, nil
	case "wishlist":
		return config.FeatureFlags.EnableWishlist, nil
	case "reviews":
		return config.FeatureFlags.EnableReviews, nil
	case "chat":
		return config.FeatureFlags.EnableChat, nil
	case "ar":
		return config.FeatureFlags.EnableAR, nil
	case "socialLogin":
		return config.FeatureFlags.EnableSocialLogin, nil
	case "guestCheckout":
		return config.FeatureFlags.EnableGuestCheckout, nil
	case "referrals":
		return config.FeatureFlags.EnableReferrals, nil
	default:
		return false, fmt.Errorf("unknown feature: %s", feature)
	}
}

// CreatePopupBanner creates a new popup banner
func (s *StorefrontService) CreatePopupBanner(ctx context.Context, banner *models.PopupBanner, adminID primitive.ObjectID) error {
	banner.ID = primitive.NewObjectID()
	banner.CreatedAt = time.Now()
	banner.UpdatedAt = time.Now()

	return s.storefrontRepo.CreatePopupBanner(ctx, banner)
}

// GetActivePopupBanners gets currently active popup banners
func (s *StorefrontService) GetActivePopupBanners(ctx context.Context) ([]models.PopupBanner, error) {
	banners, err := s.storefrontRepo.GetActivePopupBanners(ctx)
	if err != nil {
		return nil, err
	}

	// Filter by date and active status
	activeBanners := make([]models.PopupBanner, 0)
	now := time.Now()

	for _, banner := range banners {
		if !banner.IsActive {
			continue
		}

		if banner.StartDate != nil && now.Before(*banner.StartDate) {
			continue
		}

		if banner.EndDate != nil && now.After(*banner.EndDate) {
			continue
		}

		activeBanners = append(activeBanners, banner)
	}

	return activeBanners, nil
}

// UpdateMenuConfig updates menu configuration
func (s *StorefrontService) UpdateMenuConfig(ctx context.Context, menuConfig *models.MenuConfig, adminID primitive.ObjectID) error {
	menuConfig.UpdatedAt = time.Now()
	return s.storefrontRepo.UpdateMenuConfig(ctx, menuConfig)
}

// GetMenuConfig gets menu configuration
func (s *StorefrontService) GetMenuConfig(ctx context.Context) (*models.MenuConfig, error) {
	return s.storefrontRepo.GetMenuConfig(ctx)
}

// UpdateSEOConfig updates SEO configuration
func (s *StorefrontService) UpdateSEOConfig(ctx context.Context, seoConfig *models.SEOConfig, adminID primitive.ObjectID) error {
	seoConfig.UpdatedAt = time.Now()
	return s.storefrontRepo.UpdateSEOConfig(ctx, seoConfig)
}

// GetSEOConfig gets SEO configuration
func (s *StorefrontService) GetSEOConfig(ctx context.Context) (*models.SEOConfig, error) {
	return s.storefrontRepo.GetSEOConfig(ctx)
}

// RecordBannerClick records a banner click for analytics
func (s *StorefrontService) RecordBannerClick(ctx context.Context, bannerID string) error {
	return s.storefrontRepo.RecordBannerClick(ctx, bannerID)
}

// RecordSectionView records a section view for analytics
func (s *StorefrontService) RecordSectionView(ctx context.Context, sectionName string) error {
	return s.storefrontRepo.RecordSectionView(ctx, sectionName)
}

// RecordFeatureUsage records feature usage for analytics
func (s *StorefrontService) RecordFeatureUsage(ctx context.Context, feature string) error {
	return s.storefrontRepo.RecordFeatureUsage(ctx, feature)
}

// GetStorefrontAnalytics gets storefront analytics data
func (s *StorefrontService) GetStorefrontAnalytics(ctx context.Context, startDate, endDate time.Time) ([]models.StorefrontAnalytics, error) {
	return s.storefrontRepo.GetAnalytics(ctx, startDate, endDate)
}

// ValidateStorefrontConfig validates storefront configuration
func (s *StorefrontService) ValidateStorefrontConfig(config *models.StorefrontConfig) error {
	// Validate hero banners
	for _, banner := range config.HomePage.HeroBanners {
		if banner.ImageURL == "" {
			return fmt.Errorf("hero banner image URL is required")
		}
		if banner.Order < 0 {
			return fmt.Errorf("hero banner order must be non-negative")
		}
	}

	// Validate category visibility
	orderMap := make(map[int]bool)
	for _, category := range config.CategoryVisibility {
		if category.CategoryID == "" {
			return fmt.Errorf("category ID is required")
		}
		if category.Order <= 0 {
			return fmt.Errorf("category order must be positive")
		}
		if orderMap[category.Order] {
			return fmt.Errorf("duplicate category order: %d", category.Order)
		}
		orderMap[category.Order] = true
	}

	// Validate theme colors
	if config.ThemeConfig.PrimaryColor == "" {
		return fmt.Errorf("primary color is required")
	}
	if config.ThemeConfig.SecondaryColor == "" {
		return fmt.Errorf("secondary color is required")
	}

	return nil
}

// GetConfigurationHistory gets configuration change history
func (s *StorefrontService) GetConfigurationHistory(ctx context.Context, limit int) ([]models.StorefrontConfig, error) {
	return s.storefrontRepo.GetConfigHistory(ctx, limit)
}

// RevertToConfigVersion reverts to a specific configuration version
func (s *StorefrontService) RevertToConfigVersion(ctx context.Context, version int, adminID primitive.ObjectID) error {
	// Get the specific version
	config, err := s.storefrontRepo.GetConfigByVersion(ctx, version)
	if err != nil {
		return fmt.Errorf("failed to get config version %d: %w", version, err)
	}

	// Update to current version
	config.LastUpdated = time.Now()
	config.UpdatedBy = adminID
	config.Version++ // Increment version for the revert

	return s.UpdateStorefrontConfig(ctx, config, adminID)
}

// CreateCarouselSection creates a new carousel section
func (s *StorefrontService) CreateCarouselSection(ctx context.Context, carousel *models.CarouselSection, adminID primitive.ObjectID) error {
	carousel.ID = primitive.NewObjectID()

	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	config.HomePage.Carousels = append(config.HomePage.Carousels, *carousel)
	return s.UpdateStorefrontConfig(ctx, config, adminID)
}

// UpdateCarouselSection updates an existing carousel section
func (s *StorefrontService) UpdateCarouselSection(ctx context.Context, carouselID primitive.ObjectID, updatedCarousel *models.CarouselSection, adminID primitive.ObjectID) error {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	for i, carousel := range config.HomePage.Carousels {
		if carousel.ID == carouselID {
			updatedCarousel.ID = carouselID
			config.HomePage.Carousels[i] = *updatedCarousel
			return s.UpdateStorefrontConfig(ctx, config, adminID)
		}
	}

	return fmt.Errorf("carousel section not found")
}

// DeleteCarouselSection deletes a carousel section
func (s *StorefrontService) DeleteCarouselSection(ctx context.Context, carouselID primitive.ObjectID, adminID primitive.ObjectID) error {
	config, err := s.GetStorefrontConfig(ctx)
	if err != nil {
		return err
	}

	for i, carousel := range config.HomePage.Carousels {
		if carousel.ID == carouselID {
			config.HomePage.Carousels = append(config.HomePage.Carousels[:i], config.HomePage.Carousels[i+1:]...)
			return s.UpdateStorefrontConfig(ctx, config, adminID)
		}
	}

	return fmt.Errorf("carousel section not found")
}


