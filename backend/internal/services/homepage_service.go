package services

import (
	"context"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// HomepageService handles homepage business logic
type HomepageService struct {
	homepageRepo repository.HomepageRepository
	productRepo  repository.ProductRepository
}

// NewHomepageService creates a new homepage service
func NewHomepageService(
	homepageRepo repository.HomepageRepository,
	productRepo repository.ProductRepository,
) *HomepageService {
	return &HomepageService{
		homepageRepo: homepageRepo,
		productRepo:  productRepo,
	}
}

// GetHomepageData returns all data needed for the homepage
func (s *HomepageService) GetHomepageData(ctx context.Context, userID *primitive.ObjectID, sessionID *string) (*models.HomepageResponse, error) {
	response := &models.HomepageResponse{}

	// Get homepage layout configuration
	layout, err := s.homepageRepo.GetHomepageLayout(ctx)
	if err == nil && layout != nil {
		response.Layout = layout.Layout
	}

	// Get active sections
	sections, err := s.homepageRepo.GetActiveSections(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get sections: %w", err)
	}
	response.Sections = sections

	// Get active deal of the day
	deal, err := s.homepageRepo.GetActiveDealOfDay(ctx)
	if err == nil && deal != nil {
		response.DealOfDay = deal
	}

	// Get active flash sales
	flashSales, err := s.homepageRepo.GetActiveFlashSales(ctx)
	if err == nil {
		response.ActiveFlashSales = flashSales
	}

	// Get active brands
	brands, err := s.homepageRepo.GetActiveBrands(ctx)
	if err == nil {
		response.Brands = brands
	}

	// Get recently viewed products
	if userID != nil || sessionID != nil {
		productIDs, err := s.homepageRepo.GetRecentlyViewed(ctx, userID, sessionID, 10)
		if err == nil && len(productIDs) > 0 {
			products := []models.Product{}
			for _, id := range productIDs {
				product, err := s.productRepo.GetByID(ctx, id)
				if err == nil {
					products = append(products, *product)
				}
			}
			response.RecentlyViewed = products
		}
	}

	// Get active 360° showcases
	showcases360, err := s.homepageRepo.GetActiveShowcases(ctx)
	if err == nil {
		response.Showcases360 = showcases360
	}

	// Get active bundle deals
	bundleDeals, err := s.homepageRepo.GetActiveBundleDeals(ctx)
	if err == nil {
		response.BundleDeals = bundleDeals
	}

	return response, nil
}

// Homepage Configuration

func (s *HomepageService) GetHomepageConfig(ctx context.Context) (*models.HomepageConfig, error) {
	return s.homepageRepo.GetHomepageConfig(ctx)
}

func (s *HomepageService) UpdateHomepageConfig(ctx context.Context, config *models.HomepageConfig, adminID primitive.ObjectID) error {
	config.UpdatedBy = adminID
	return s.homepageRepo.UpdateHomepageConfig(ctx, config)
}

// Homepage Layout

func (s *HomepageService) GetHomepageLayout(ctx context.Context) (*models.HomepageLayout, error) {
	return s.homepageRepo.GetHomepageLayout(ctx)
}

func (s *HomepageService) UpdateHomepageLayout(ctx context.Context, layout *models.HomepageLayout, adminID primitive.ObjectID) error {
	// Validate that orders are unique and sequential
	orderMap := make(map[int]bool)
	for _, item := range layout.Layout {
		if orderMap[item.Order] {
			return fmt.Errorf("duplicate order value: %d", item.Order)
		}
		orderMap[item.Order] = true
	}

	// If no ID provided, get the existing layout's ID
	if layout.ID.IsZero() {
		existingLayout, err := s.homepageRepo.GetHomepageLayout(ctx)
		if err == nil && existingLayout != nil {
			layout.ID = existingLayout.ID
		} else {
			// If no existing layout, create a new ID
			layout.ID = primitive.NewObjectID()
			layout.CreatedAt = time.Now()
		}
	}

	layout.UpdatedBy = adminID
	layout.UpdatedAt = time.Now()
	return s.homepageRepo.UpdateHomepageLayout(ctx, layout)
}

func (s *HomepageService) CreateDefaultLayout(ctx context.Context) error {
	return s.homepageRepo.CreateDefaultLayout(ctx)
}

// Deal of Day

func (s *HomepageService) CreateDealOfDay(ctx context.Context, deal *models.DealOfDay) error {
	// Validate dates
	if deal.StartTime.After(deal.EndTime) {
		return fmt.Errorf("start time must be before end time")
	}

	// Verify product exists
	product, err := s.productRepo.GetByID(ctx, deal.ProductID)
	if err != nil {
		return fmt.Errorf("product not found: %w", err)
	}

	// Set prices
	deal.OriginalPrice = product.Price
	if deal.DiscountPercent > 0 {
		deal.DealPrice = product.Price * (1 - float64(deal.DiscountPercent)/100)
	}

	deal.SoldCount = 0
	deal.IsActive = true

	return s.homepageRepo.CreateDealOfDay(ctx, deal)
}

func (s *HomepageService) GetActiveDealOfDay(ctx context.Context) (*models.DealOfDay, error) {
	return s.homepageRepo.GetActiveDealOfDay(ctx)
}

// GetActiveDealOfDayWithProduct returns the active deal with full product details
func (s *HomepageService) GetActiveDealOfDayWithProduct(ctx context.Context) (*models.DealOfDayWithProduct, error) {
	deal, err := s.homepageRepo.GetActiveDealOfDay(ctx)
	if err != nil {
		return nil, err
	}
	if deal == nil {
		return nil, nil
	}

	// Fetch the product
	product, err := s.productRepo.GetByID(ctx, deal.ProductID)
	if err != nil {
		return nil, fmt.Errorf("failed to get product: %w", err)
	}

	return &models.DealOfDayWithProduct{
		ID:              deal.ID,
		Product:         *product,
		OriginalPrice:   deal.OriginalPrice,
		DealPrice:       deal.DealPrice,
		DiscountPercent: deal.DiscountPercent,
		StartTime:       deal.StartTime,
		EndTime:         deal.EndTime,
		Stock:           deal.Stock,
		SoldCount:       deal.SoldCount,
		IsActive:        deal.IsActive,
	}, nil
}

func (s *HomepageService) UpdateDealOfDay(ctx context.Context, deal *models.DealOfDay) error {
	existing, err := s.homepageRepo.GetDealByID(ctx, deal.ID)
	if err != nil {
		return err
	}

	// Update only allowed fields
	existing.Stock = deal.Stock
	existing.IsActive = deal.IsActive
	existing.EndTime = deal.EndTime

	return s.homepageRepo.UpdateDealOfDay(ctx, existing)
}

// Flash Sales

func (s *HomepageService) CreateFlashSale(ctx context.Context, sale *models.FlashSale) error {
	// Validate dates
	if sale.StartTime.After(sale.EndTime) {
		return fmt.Errorf("start time must be before end time")
	}

	// Verify all products exist
	for _, productID := range sale.ProductIDs {
		_, err := s.productRepo.GetByID(ctx, productID)
		if err != nil {
			return fmt.Errorf("product %s not found: %w", productID.Hex(), err)
		}
	}

	sale.IsActive = true
	return s.homepageRepo.CreateFlashSale(ctx, sale)
}

func (s *HomepageService) GetActiveFlashSales(ctx context.Context) ([]models.FlashSale, error) {
	return s.homepageRepo.GetActiveFlashSales(ctx)
}

// GetActiveFlashSalesWithProducts returns active flash sales with full product details and discounted prices
func (s *HomepageService) GetActiveFlashSalesWithProducts(ctx context.Context) ([]models.FlashSaleWithProducts, error) {
	sales, err := s.homepageRepo.GetActiveFlashSales(ctx)
	if err != nil {
		return nil, err
	}

	var result []models.FlashSaleWithProducts
	for _, sale := range sales {
		saleWithProducts := models.FlashSaleWithProducts{
			ID:          sale.ID,
			Title:       sale.Title,
			Description: sale.Description,
			BannerImage: sale.BannerImage,
			StartTime:   sale.StartTime,
			EndTime:     sale.EndTime,
			Discount:    sale.Discount,
			IsActive:    sale.IsActive,
			Products:    []models.FlashSaleProduct{},
		}

		// Fetch each product and calculate discounted price
		for _, productID := range sale.ProductIDs {
			product, err := s.productRepo.GetByID(ctx, productID)
			if err != nil {
				continue // Skip products that can't be found
			}

			originalPrice := product.Price
			salePrice := originalPrice * (1 - float64(sale.Discount)/100)

			saleWithProducts.Products = append(saleWithProducts.Products, models.FlashSaleProduct{
				Product:       *product,
				OriginalPrice: originalPrice,
				SalePrice:     salePrice,
				Discount:      sale.Discount,
			})
		}

		result = append(result, saleWithProducts)
	}

	return result, nil
}

func (s *HomepageService) GetAllFlashSales(ctx context.Context) ([]models.FlashSale, error) {
	return s.homepageRepo.GetAllFlashSales(ctx)
}

func (s *HomepageService) UpdateFlashSale(ctx context.Context, sale *models.FlashSale) error {
	existing, err := s.homepageRepo.GetFlashSaleByID(ctx, sale.ID)
	if err != nil {
		return err
	}

	// Update allowed fields
	existing.Title = sale.Title
	existing.Description = sale.Description
	existing.BannerImage = sale.BannerImage
	existing.ProductIDs = sale.ProductIDs
	existing.EndTime = sale.EndTime
	existing.Discount = sale.Discount
	existing.IsActive = sale.IsActive

	return s.homepageRepo.UpdateFlashSale(ctx, existing)
}

func (s *HomepageService) DeleteFlashSale(ctx context.Context, saleID string) error {
	return s.homepageRepo.DeleteFlashSale(ctx, saleID)
}

// Brands

func (s *HomepageService) CreateBrand(ctx context.Context, brand *models.Brand) error {
	if brand.Name == "" {
		return fmt.Errorf("brand name is required")
	}

	brand.IsActive = true
	return s.homepageRepo.CreateBrand(ctx, brand)
}

func (s *HomepageService) GetActiveBrands(ctx context.Context) ([]models.Brand, error) {
	return s.homepageRepo.GetActiveBrands(ctx)
}

func (s *HomepageService) GetAllBrands(ctx context.Context) ([]models.Brand, error) {
	return s.homepageRepo.GetAllBrands(ctx)
}

func (s *HomepageService) UpdateBrand(ctx context.Context, brand *models.Brand) error {
	existing, err := s.homepageRepo.GetBrandByID(ctx, brand.ID)
	if err != nil {
		return err
	}

	existing.Name = brand.Name
	existing.Logo = brand.Logo
	existing.Description = brand.Description
	existing.IsActive = brand.IsActive
	existing.Priority = brand.Priority

	return s.homepageRepo.UpdateBrand(ctx, existing)
}

func (s *HomepageService) DeleteBrand(ctx context.Context, brandID primitive.ObjectID) error {
	return s.homepageRepo.DeleteBrand(ctx, brandID)
}

// Recently Viewed Tracking

func (s *HomepageService) TrackProductView(ctx context.Context, userID *primitive.ObjectID, sessionID *string, productID primitive.ObjectID) error {
	// Verify product exists
	_, err := s.productRepo.GetByID(ctx, productID)
	if err != nil {
		return fmt.Errorf("product not found: %w", err)
	}

	return s.homepageRepo.TrackProductView(ctx, userID, sessionID, productID)
}

func (s *HomepageService) GetRecentlyViewed(ctx context.Context, userID *primitive.ObjectID, sessionID *string, limit int) ([]models.Product, error) {
	productIDs, err := s.homepageRepo.GetRecentlyViewed(ctx, userID, sessionID, limit)
	if err != nil {
		return nil, err
	}

	var products []models.Product
	for _, id := range productIDs {
		product, err := s.productRepo.GetByID(ctx, id)
		if err == nil {
			products = append(products, *product)
		}
	}

	return products, nil
}

// Helper methods

func (s *HomepageService) GetBestSellers(ctx context.Context, limit int) ([]models.Product, error) {
	// Get all products and sort by some popularity metric
	// For now, we'll use featured products as a proxy
	products, err := s.productRepo.GetFeatured(ctx)
	if err != nil {
		return nil, err
	}

	// Limit results
	if limit > 0 && limit < len(products) {
		products = products[:limit]
	}

	return products, nil
}

func (s *HomepageService) GetNewArrivals(ctx context.Context, limit int) ([]models.Product, error) {
	// Get products from the last 30 days
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30)

	// This would need to be implemented in the product repository
	// For now, return featured products
	products, err := s.productRepo.GetFeatured(ctx)
	if err != nil {
		return nil, err
	}

	// Filter by created date and limit
	var newProducts []models.Product
	for _, product := range products {
		if product.CreatedAt.After(thirtyDaysAgo) {
			newProducts = append(newProducts, product)
			if limit > 0 && len(newProducts) >= limit {
				break
			}
		}
	}

	return newProducts, nil
}

// 360° Showcase

func (s *HomepageService) CreateShowcase(ctx context.Context, showcase *models.Showcase360) error {
	// Verify product exists
	_, err := s.productRepo.GetByID(ctx, showcase.ProductID)
	if err != nil {
		return fmt.Errorf("product not found: %w", err)
	}

	showcase.IsActive = true
	return s.homepageRepo.CreateShowcase(ctx, showcase)
}

func (s *HomepageService) GetActiveShowcases(ctx context.Context) ([]models.Showcase360, error) {
	return s.homepageRepo.GetActiveShowcases(ctx)
}

func (s *HomepageService) GetAllShowcases(ctx context.Context) ([]models.Showcase360, error) {
	return s.homepageRepo.GetAllShowcases(ctx)
}

func (s *HomepageService) GetShowcaseByID(ctx context.Context, showcaseID primitive.ObjectID) (*models.Showcase360, error) {
	return s.homepageRepo.GetShowcaseByID(ctx, showcaseID)
}

func (s *HomepageService) UpdateShowcase(ctx context.Context, showcase *models.Showcase360) error {
	existing, err := s.homepageRepo.GetShowcaseByID(ctx, showcase.ID)
	if err != nil {
		return err
	}

	// Update fields
	existing.Title = showcase.Title
	existing.Description = showcase.Description
	existing.Images360 = showcase.Images360
	existing.VideoURL = showcase.VideoURL
	existing.ThumbnailURL = showcase.ThumbnailURL
	existing.Priority = showcase.Priority
	existing.IsActive = showcase.IsActive
	existing.StartTime = showcase.StartTime
	existing.EndTime = showcase.EndTime

	return s.homepageRepo.UpdateShowcase(ctx, existing)
}

func (s *HomepageService) DeleteShowcase(ctx context.Context, showcaseID primitive.ObjectID) error {
	return s.homepageRepo.DeleteShowcase(ctx, showcaseID)
}

// Bundle Deals

func (s *HomepageService) CreateBundleDeal(ctx context.Context, bundle *models.BundleDeal) error {
	// Verify all products exist and calculate original price
	var totalOriginalPrice float64
	for _, item := range bundle.Items {
		product, err := s.productRepo.GetByID(ctx, item.ProductID)
		if err != nil {
			return fmt.Errorf("product %s not found: %w", item.ProductID.Hex(), err)
		}
		totalOriginalPrice += product.Price * float64(item.Quantity)
	}

	// Set original price if not provided
	if bundle.OriginalPrice == 0 {
		bundle.OriginalPrice = totalOriginalPrice
	}

	// Calculate bundle price if discount is provided
	if bundle.DiscountPercent > 0 && bundle.BundlePrice == 0 {
		bundle.BundlePrice = bundle.OriginalPrice * (1 - float64(bundle.DiscountPercent)/100)
	}

	// Calculate discount percent if bundle price is provided
	if bundle.BundlePrice > 0 && bundle.DiscountPercent == 0 {
		bundle.DiscountPercent = int((bundle.OriginalPrice - bundle.BundlePrice) / bundle.OriginalPrice * 100)
	}

	bundle.SoldCount = 0
	bundle.IsActive = true

	return s.homepageRepo.CreateBundleDeal(ctx, bundle)
}

func (s *HomepageService) GetActiveBundleDeals(ctx context.Context) ([]models.BundleDeal, error) {
	return s.homepageRepo.GetActiveBundleDeals(ctx)
}

func (s *HomepageService) GetBundleDealByID(ctx context.Context, bundleID primitive.ObjectID) (*models.BundleDeal, error) {
	return s.homepageRepo.GetBundleDealByID(ctx, bundleID)
}

func (s *HomepageService) UpdateBundleDeal(ctx context.Context, bundle *models.BundleDeal) error {
	existing, err := s.homepageRepo.GetBundleDealByID(ctx, bundle.ID)
	if err != nil {
		return err
	}

	// Update fields
	existing.Title = bundle.Title
	existing.Description = bundle.Description
	existing.BannerImage = bundle.BannerImage
	existing.Items = bundle.Items
	existing.BundlePrice = bundle.BundlePrice
	existing.DiscountPercent = bundle.DiscountPercent
	existing.Category = bundle.Category
	existing.Priority = bundle.Priority
	existing.Stock = bundle.Stock
	existing.IsActive = bundle.IsActive
	existing.StartTime = bundle.StartTime
	existing.EndTime = bundle.EndTime

	return s.homepageRepo.UpdateBundleDeal(ctx, existing)
}

func (s *HomepageService) DeleteBundleDeal(ctx context.Context, bundleID primitive.ObjectID) error {
	return s.homepageRepo.DeleteBundleDeal(ctx, bundleID)
}

