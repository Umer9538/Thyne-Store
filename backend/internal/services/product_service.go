package services

import (
	"context"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type ProductService interface {
	GetProducts(filter models.ProductFilter) ([]models.Product, int64, error)
	GetProduct(id string) (*models.Product, error)
	GetCategories() ([]string, error)
	GetFeaturedProducts() ([]models.Product, error)
	SearchProducts(query string) ([]models.Product, error)
	// Admin methods
	CreateProduct(ctx context.Context, req *models.CreateProductRequest) (*models.Product, error)
	UpdateProduct(ctx context.Context, id string, req *models.UpdateProductRequest) (*models.Product, error)
	DeleteProduct(ctx context.Context, id string) error
	UpdateProductStock(ctx context.Context, id string, quantity int, reason string) error
	GetProductStatistics(ctx context.Context) (*models.ProductStatistics, error)
	GetRecentProducts(ctx context.Context, limit int) ([]models.Product, error)
	ExportProducts(ctx context.Context, format string, filters map[string]interface{}) (string, error)
	BulkCreateProducts(ctx context.Context, products []models.CreateProductRequest) ([]models.Product, []models.BulkCreateError, error)
}

type productService struct {
	productRepo        repository.ProductRepository
	reviewRepo         repository.ReviewRepository
	notificationService *NotificationService
	wishlistRepo       repository.WishlistRepository
}

func NewProductService(productRepo repository.ProductRepository, reviewRepo repository.ReviewRepository) ProductService {
	return &productService{
		productRepo: productRepo,
		reviewRepo:  reviewRepo,
	}
}

func (s *productService) SetNotificationService(notificationService *NotificationService) {
	s.notificationService = notificationService
}

func (s *productService) SetWishlistRepository(wishlistRepo repository.WishlistRepository) {
	s.wishlistRepo = wishlistRepo
}

func (s *productService) GetProducts(filter models.ProductFilter) ([]models.Product, int64, error) {
	return s.productRepo.GetAll(nil, filter)
}

func (s *productService) GetProduct(id string) (*models.Product, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	return s.productRepo.GetByID(nil, objectID)
}

func (s *productService) GetCategories() ([]string, error) {
	return s.productRepo.GetCategories(nil)
}

func (s *productService) GetFeaturedProducts() ([]models.Product, error) {
	return s.productRepo.GetFeatured(nil)
}

func (s *productService) SearchProducts(query string) ([]models.Product, error) {
	return s.productRepo.Search(nil, query)
}

// Admin methods implementation
func (s *productService) CreateProduct(ctx context.Context, req *models.CreateProductRequest) (*models.Product, error) {
	product := &models.Product{
		ID:             primitive.NewObjectID(),
		Name:           req.Name,
		Description:    req.Description,
		Price:          req.Price,
		OriginalPrice:  req.OriginalPrice,
		Images:         req.Images,
		Category:       req.Category,
		Subcategory:    req.Subcategory,
		MetalType:      req.MetalType,
		StoneType:      req.StoneType,
		Weight:         req.Weight,
		Size:           req.Size,
		StockQuantity:  req.StockQuantity,
		Rating:         0.0,
		ReviewCount:    0,
		Tags:           req.Tags,
		IsAvailable:    req.IsAvailable,
		IsFeatured:     req.IsFeatured,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}

	err := s.productRepo.Create(ctx, product)
	if err != nil {
		return nil, err
	}

	return product, nil
}

func (s *productService) UpdateProduct(ctx context.Context, id string, req *models.UpdateProductRequest) (*models.Product, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	// Get existing product
	existingProduct, err := s.productRepo.GetByID(ctx, objectID)
	if err != nil {
		return nil, err
	}

	// Update fields (handle pointer fields)
	if req.Name != nil {
		existingProduct.Name = *req.Name
	}
	if req.Description != nil {
		existingProduct.Description = *req.Description
	}
	if req.Price != nil {
		existingProduct.Price = *req.Price
	}
	if req.OriginalPrice != nil {
		existingProduct.OriginalPrice = req.OriginalPrice
	}
	if req.Images != nil {
		existingProduct.Images = req.Images
	}
	if req.Category != nil {
		existingProduct.Category = *req.Category
	}
	if req.Subcategory != nil {
		existingProduct.Subcategory = *req.Subcategory
	}
	if req.MetalType != nil {
		existingProduct.MetalType = *req.MetalType
	}
	if req.StoneType != nil {
		existingProduct.StoneType = req.StoneType
	}
	if req.Weight != nil {
		existingProduct.Weight = req.Weight
	}
	if req.Size != nil {
		existingProduct.Size = req.Size
	}
	if req.StockQuantity != nil {
		existingProduct.StockQuantity = *req.StockQuantity
	}
	if req.Tags != nil {
		existingProduct.Tags = req.Tags
	}
	if req.IsAvailable != nil {
		existingProduct.IsAvailable = *req.IsAvailable
	}
	if req.IsFeatured != nil {
		existingProduct.IsFeatured = *req.IsFeatured
	}
	existingProduct.UpdatedAt = time.Now()

	err = s.productRepo.Update(ctx, existingProduct)
	if err != nil {
		return nil, err
	}

	return existingProduct, nil
}

func (s *productService) DeleteProduct(ctx context.Context, id string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	return s.productRepo.Delete(ctx, objectID)
}

func (s *productService) UpdateProductStock(ctx context.Context, id string, quantity int, reason string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	// Get existing product
	product, err := s.productRepo.GetByID(ctx, objectID)
	if err != nil {
		return err
	}

	// Check if product was out of stock and is now back in stock
	wasOutOfStock := product.StockQuantity == 0
	isBackInStock := quantity > 0

	// Update stock quantity
	product.StockQuantity = quantity
	product.UpdatedAt = time.Now()

	err = s.productRepo.Update(ctx, product)
	if err != nil {
		return err
	}

	// Send back-in-stock notifications if product was out of stock and is now available
	if wasOutOfStock && isBackInStock && s.notificationService != nil && s.wishlistRepo != nil {
		go func() {
			// Get all users who have this product in their wishlist
			wishlistItems, err := s.wishlistRepo.GetWishlistItemsByProduct(ctx, objectID)
			if err != nil {
				return
			}

			// Send notifications to all users who have this product in their wishlist
			for _, item := range wishlistItems {
				if err := s.notificationService.SendBackInStockNotification(ctx, item.UserID, product.Name, product.ID.Hex()); err != nil {
					// Log error but continue processing other users
					_ = err
				}
			}
		}()
	}

	return nil
}

func (s *productService) GetProductStatistics(ctx context.Context) (*models.ProductStatistics, error) {
	return s.productRepo.GetProductStatistics(ctx)
}

func (s *productService) GetRecentProducts(ctx context.Context, limit int) ([]models.Product, error) {
	filter := models.ProductFilter{
		Limit:  limit,
		SortBy: "newest",
	}
	products, _, err := s.productRepo.GetAll(ctx, filter)
	return products, err
}

func (s *productService) ExportProducts(ctx context.Context, format string, filters map[string]interface{}) (string, error) {
	// Placeholder implementation - would generate and return file URL
	return "/exports/products_" + format + "_" + time.Now().Format("20060102150405") + "." + format, nil
}

func (s *productService) BulkCreateProducts(ctx context.Context, products []models.CreateProductRequest) ([]models.Product, []models.BulkCreateError, error) {
	var createdProducts []models.Product
	var failedProducts []models.BulkCreateError

	for i, productReq := range products {
		// Validate the product request
		if err := productReq.Validate(); err != nil {
			failedProducts = append(failedProducts, models.BulkCreateError{
				Index:   i,
				Product: productReq,
				Error:   "Validation failed: " + err.Error(),
			})
			continue
		}

		// Create the product
		product := &models.Product{
			ID:            primitive.NewObjectID(),
			Name:          productReq.Name,
			Description:   productReq.Description,
			Price:         productReq.Price,
			OriginalPrice: productReq.OriginalPrice,
			Images:        productReq.Images,
			Category:      productReq.Category,
			Subcategory:   productReq.Subcategory,
			MetalType:     productReq.MetalType,
			StoneType:     productReq.StoneType,
			Weight:        productReq.Weight,
			Size:          productReq.Size,
			StockQuantity: productReq.StockQuantity,
			Tags:          productReq.Tags,
			IsAvailable:   productReq.IsAvailable,
			IsFeatured:    productReq.IsFeatured,
			Rating:        0.0,
			ReviewCount:   0,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
		}

		// Attempt to create the product in the database
		err := s.productRepo.Create(ctx, product)
		if err != nil {
			failedProducts = append(failedProducts, models.BulkCreateError{
				Index:   i,
				Product: productReq,
				Error:   "Database error: " + err.Error(),
			})
			continue
		}

		createdProducts = append(createdProducts, *product)
	}

	return createdProducts, failedProducts, nil
}
