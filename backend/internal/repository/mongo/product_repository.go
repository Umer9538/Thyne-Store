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

type productRepository struct {
	collection *mongo.Collection
}

// NewProductRepository creates a new product repository
func NewProductRepository(db *mongo.Database) repository.ProductRepository {
	return &productRepository{
		collection: db.Collection("products"),
	}
}

func (r *productRepository) Create(ctx context.Context, product *models.Product) error {
	product.ID = primitive.NewObjectID()
	product.CreatedAt = time.Now()
	product.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, product)
	if err != nil {
		return fmt.Errorf("failed to create product: %w", err)
	}

	return nil
}

func (r *productRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Product, error) {
	var product models.Product
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&product)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("product not found")
		}
		return nil, fmt.Errorf("failed to get product by ID: %w", err)
	}
	return &product, nil
}

func (r *productRepository) GetBySKU(ctx context.Context, sku string) (*models.Product, error) {
	var product models.Product
	err := r.collection.FindOne(ctx, bson.M{"sku": sku}).Decode(&product)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("product not found")
		}
		return nil, fmt.Errorf("failed to get product by SKU: %w", err)
	}
	return &product, nil
}

func (r *productRepository) Update(ctx context.Context, product *models.Product) error {
	product.UpdatedAt = time.Now()

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": product.ID},
		bson.M{"$set": product},
	)
	if err != nil {
		return fmt.Errorf("failed to update product: %w", err)
	}

	return nil
}

func (r *productRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete product: %w", err)
	}

	return nil
}

func (r *productRepository) List(ctx context.Context, page, limit int, filters map[string]interface{}) ([]models.Product, int64, error) {
	// Build filter
	filter := bson.M{}
	for key, value := range filters {
		switch key {
		case "category":
			filter["category"] = value
		case "subCategory":
			filter["subCategory"] = value
		case "brand":
			filter["brand"] = value
		case "metalType":
			filter["metalType"] = value
		case "gemstoneType":
			filter["gemstoneType"] = value
		case "featured":
			filter["featured"] = value
		case "inStock":
			if value.(bool) {
				filter["stockQuantity"] = bson.M{"$gt": 0}
			} else {
				filter["stockQuantity"] = bson.M{"$lte": 0}
			}
		case "minPrice":
			if filter["price"] == nil {
				filter["price"] = bson.M{}
			}
			filter["price"].(bson.M)["$gte"] = value
		case "maxPrice":
			if filter["price"] == nil {
				filter["price"] = bson.M{}
			}
			filter["price"].(bson.M)["$lte"] = value
		case "search":
			filter["$text"] = bson.M{"$search": value}
		}
	}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count products: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Build sort
	sort := bson.M{"createdAt": -1}
	if sortBy, exists := filters["sortBy"]; exists {
		switch sortBy {
		case "price_asc":
			sort = bson.M{"price": 1}
		case "price_desc":
			sort = bson.M{"price": -1}
		case "name_asc":
			sort = bson.M{"name": 1}
		case "name_desc":
			sort = bson.M{"name": -1}
		case "rating_desc":
			sort = bson.M{"rating": -1}
		case "newest":
			sort = bson.M{"createdAt": -1}
		}
	}

	// Find products
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(sort)

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find products: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, 0, fmt.Errorf("failed to decode products: %w", err)
	}

	return products, total, nil
}

func (r *productRepository) GetByIDs(ctx context.Context, ids []primitive.ObjectID) ([]models.Product, error) {
	filter := bson.M{"_id": bson.M{"$in": ids}}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("failed to find products by IDs: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, fmt.Errorf("failed to decode products: %w", err)
	}

	return products, nil
}

func (r *productRepository) GetFeaturedProducts(ctx context.Context, limit int) ([]models.Product, error) {
	filter := bson.M{
		"featured":      true,
		"stockQuantity": bson.M{"$gt": 0},
	}

	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"rating": -1, "salesCount": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find featured products: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, fmt.Errorf("failed to decode featured products: %w", err)
	}

	return products, nil
}

func (r *productRepository) GetNewArrivals(ctx context.Context, limit int) ([]models.Product, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	filter := bson.M{"stockQuantity": bson.M{"$gt": 0}}

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find new arrivals: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, fmt.Errorf("failed to decode new arrivals: %w", err)
	}

	return products, nil
}

func (r *productRepository) GetBestSellers(ctx context.Context, limit int) ([]models.Product, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"salesCount": -1, "rating": -1})

	filter := bson.M{"stockQuantity": bson.M{"$gt": 0}}

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find best sellers: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, fmt.Errorf("failed to decode best sellers: %w", err)
	}

	return products, nil
}

func (r *productRepository) GetPopularProducts(ctx context.Context, limit int) ([]models.Product, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"viewCount": -1, "rating": -1})

	filter := bson.M{"stockQuantity": bson.M{"$gt": 0}}

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find popular products: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, fmt.Errorf("failed to decode popular products: %w", err)
	}

	return products, nil
}

func (r *productRepository) SearchWithPipeline(ctx context.Context, pipeline []interface{}, page, limit int) ([]models.Product, int64, error) {
	// Add pagination to pipeline
	skip := (page - 1) * limit
	pipelineWithPagination := append(pipeline,
		bson.M{"$skip": skip},
		bson.M{"$limit": limit},
	)

	// Execute aggregation
	cursor, err := r.collection.Aggregate(ctx, pipelineWithPagination)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to execute search pipeline: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, 0, fmt.Errorf("failed to decode search results: %w", err)
	}

	// Get total count (without pagination)
	countPipeline := append(pipeline, bson.M{"$count": "total"})
	countCursor, err := r.collection.Aggregate(ctx, countPipeline)
	if err != nil {
		return products, int64(len(products)), nil // Return products even if count fails
	}
	defer countCursor.Close(ctx)

	var countResult []bson.M
	if err = countCursor.All(ctx, &countResult); err != nil || len(countResult) == 0 {
		return products, int64(len(products)), nil
	}

	total := int64(countResult[0]["total"].(int32))
	return products, total, nil
}

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
	featured, err := r.collection.CountDocuments(ctx, bson.M{"featured": true})
	if err != nil {
		return nil, fmt.Errorf("failed to count featured products: %w", err)
	}

	// New products today
	today := time.Date(time.Now().Year(), time.Now().Month(), time.Now().Day(), 0, 0, 0, 0, time.Now().Location())
	newToday, err := r.collection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{"$gte": today},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count new products today: %w", err)
	}

	// Get category distribution
	categoryDistribution, err := r.getCategoryDistribution(ctx)
	if err != nil {
		categoryDistribution = make(map[string]int64)
	}

	// Get top selling products
	topSellingProducts, err := r.getTopSellingProducts(ctx, 10)
	if err != nil {
		topSellingProducts = []models.TopProduct{}
	}

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

func (r *productRepository) GetRecentProducts(ctx context.Context, limit int) ([]models.Product, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find recent products: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, fmt.Errorf("failed to decode recent products: %w", err)
	}

	return products, nil
}

func (r *productRepository) ExportProducts(ctx context.Context, format string, filters map[string]interface{}) (string, error) {
	// Implementation would depend on your export service
	return fmt.Sprintf("products_export_%s.%s", time.Now().Format("20060102"), format), nil
}

func (r *productRepository) UpdateStock(ctx context.Context, productID primitive.ObjectID, quantity int) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": productID},
		bson.M{"$inc": bson.M{"stockQuantity": quantity}},
	)
	if err != nil {
		return fmt.Errorf("failed to update stock: %w", err)
	}

	return nil
}

func (r *productRepository) GetByCategory(ctx context.Context, category string, page, limit int) ([]models.Product, int64, error) {
	filter := bson.M{"category": category}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count products in category: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find products
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"featured": -1, "rating": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find products by category: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, 0, fmt.Errorf("failed to decode products: %w", err)
	}

	return products, total, nil
}

// Helper methods

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
			Category string `bson:"_id"`
			Count    int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		distribution[result.Category] = result.Count
	}

	return distribution, nil
}

func (r *productRepository) getTopSellingProducts(ctx context.Context, limit int) ([]models.TopProduct, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"salesCount": -1})

	cursor, err := r.collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var topProducts []models.TopProduct
	for cursor.Next(ctx) {
		var product models.Product
		if err := cursor.Decode(&product); err != nil {
			continue
		}

		topProducts = append(topProducts, models.TopProduct{
			ProductID:  product.ID,
			Name:       product.Name,
			Category:   product.Category,
			Price:      product.Price,
			SalesCount: int64(product.SalesCount),
			Revenue:    product.Price * float64(product.SalesCount),
			Rating:     product.Rating,
		})
	}

	return topProducts, nil
}

func (r *productRepository) getLowStockProducts(ctx context.Context, limit int) ([]models.LowStockProduct, error) {
	filter := bson.M{
		"$expr": bson.M{
			"$lte": []interface{}{"$stockQuantity", "$minimumStock"},
		},
	}

	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"stockQuantity": 1})

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

		lowStockProducts = append(lowStockProducts, models.LowStockProduct{
			ProductID:    product.ID,
			Name:         product.Name,
			SKU:          product.SKU,
			Category:     product.Category,
			CurrentStock: product.StockQuantity,
			MinimumStock: product.MinimumStock,
			Price:        product.Price,
		})
	}

	return lowStockProducts, nil
}

func (r *productRepository) getAverageRating(ctx context.Context) (float64, int64, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":          nil,
				"avgRating":    bson.M{"$avg": "$rating"},
				"totalReviews": bson.M{"$sum": "$reviewCount"},
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, 0, err
	}
	defer cursor.Close(ctx)

	var result struct {
		AvgRating    float64 `bson:"avgRating"`
		TotalReviews int64   `bson:"totalReviews"`
	}

	if cursor.Next(ctx) {
		if err := cursor.Decode(&result); err != nil {
			return 0, 0, err
		}
	}

	return result.AvgRating, result.TotalReviews, nil
}