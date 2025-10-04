package repository

import (
	"context"
	"fmt"

	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// GetProductStatistics method for productRepository
func (r *productRepository) GetProductStatistics(ctx context.Context) (*models.ProductStatistics, error) {
	// Total products
	total, err := r.collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count total products: %w", err)
	}

	// Products in stock
	inStock, err := r.collection.CountDocuments(ctx, bson.M{"stockQuantity": bson.M{"$gt": 0}})
	if err != nil {
		return nil, fmt.Errorf("failed to count in-stock products: %w", err)
	}

	// Products out of stock
	outOfStock := total - inStock

	// Featured products
	featured, err := r.collection.CountDocuments(ctx, bson.M{"isFeatured": true})
	if err != nil {
		return nil, fmt.Errorf("failed to count featured products: %w", err)
	}

	// New products today - for now return 0 as we don't have createdAt field in basic implementation
	newToday := int64(0)

	// Get category distribution
	categoryDistribution, err := r.getCategoryDistribution(ctx)
	if err != nil {
		categoryDistribution = make(map[string]int64)
	}

	// Get top selling products - for now return empty slice
	topSellingProducts := []models.TopProduct{}

	// Get low stock products
	lowStockProducts, err := r.getLowStockProducts(ctx, 20)
	if err != nil {
		lowStockProducts = []models.LowStockProduct{}
	}

	// Calculate average rating
	avgRating, totalReviews, err := r.getAverageRating(ctx)
	if err != nil {
		avgRating = 0
		totalReviews = 0
	}

	return &models.ProductStatistics{
		TotalProducts:        total,
		ProductsInStock:      inStock,
		ProductsOutOfStock:   outOfStock,
		FeaturedProducts:     featured,
		NewProductsToday:     newToday,
		TopSellingProducts:   topSellingProducts,
		CategoryDistribution: categoryDistribution,
		LowStockProducts:     lowStockProducts,
		AverageRating:        avgRating,
		TotalReviews:         totalReviews,
	}, nil
}

// Helper methods for GetProductStatistics
func (r *productRepository) getCategoryDistribution(ctx context.Context) (map[string]int64, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":   "$category",
				"count": bson.M{"$sum": 1},
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	distribution := make(map[string]int64)
	for cursor.Next(ctx) {
		var result struct {
			ID    string `bson:"_id"`
			Count int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		distribution[result.ID] = result.Count
	}

	return distribution, nil
}

func (r *productRepository) getLowStockProducts(ctx context.Context, limit int) ([]models.LowStockProduct, error) {
	// Find products with stock quantity <= 10 (low stock threshold)
	filter := bson.M{"stockQuantity": bson.M{"$lte": 10, "$gt": 0}}
	opts := options.Find().SetLimit(int64(limit))

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var lowStockProducts []models.LowStockProduct
	for cursor.Next(ctx) {
		var product models.Product
		if err := cursor.Decode(&product); err != nil {
			continue
		}

		lowStockProduct := models.LowStockProduct{
			ProductID:    product.ID,
			Name:         product.Name,
			SKU:          product.Name, // Use name as SKU since SKU field doesn't exist
			Category:     product.Category,
			CurrentStock: product.StockQuantity,
			MinimumStock: 10, // Default minimum stock threshold
			Price:        product.Price,
		}
		lowStockProducts = append(lowStockProducts, lowStockProduct)
	}

	return lowStockProducts, nil
}

func (r *productRepository) getAverageRating(ctx context.Context) (float64, int64, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":       nil,
				"avgRating": bson.M{"$avg": "$rating"},
				"count":     bson.M{"$sum": "$reviewCount"},
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, 0, err
	}
	defer cursor.Close(ctx)

	var result struct {
		AvgRating float64 `bson:"avgRating"`
		Count     int64   `bson:"count"`
	}

	if cursor.Next(ctx) {
		if err := cursor.Decode(&result); err != nil {
			return 0, 0, err
		}
	}

	return result.AvgRating, result.Count, nil
}
