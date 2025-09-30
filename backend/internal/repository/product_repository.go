package repository

import (
	"context"
	"errors"

	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)


type productRepository struct {
	collection *mongo.Collection
}

func NewProductRepository(db *mongo.Database) ProductRepository {
	return &productRepository{
		collection: db.Collection("products"),
	}
}

func (r *productRepository) Create(ctx context.Context, product *models.Product) error {
	_, err := r.collection.InsertOne(ctx, product)
	return err
}

func (r *productRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Product, error) {
	var product models.Product
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&product)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("product not found")
		}
		return nil, err
	}
	return &product, nil
}

func (r *productRepository) GetAll(ctx context.Context, filter models.ProductFilter) ([]models.Product, int64, error) {
	// Build MongoDB filter
	mongoFilter := bson.M{}

	if filter.Category != "" && filter.Category != "All" {
		mongoFilter["category"] = filter.Category
	}
	if filter.Subcategory != "" {
		mongoFilter["subcategory"] = filter.Subcategory
	}
	if len(filter.MetalType) > 0 {
		mongoFilter["metalType"] = bson.M{"$in": filter.MetalType}
	}
	if len(filter.StoneType) > 0 {
		mongoFilter["stoneType"] = bson.M{"$in": filter.StoneType}
	}
	if filter.MinPrice != nil || filter.MaxPrice != nil {
		priceFilter := bson.M{}
		if filter.MinPrice != nil {
			priceFilter["$gte"] = *filter.MinPrice
		}
		if filter.MaxPrice != nil {
			priceFilter["$lte"] = *filter.MaxPrice
		}
		mongoFilter["price"] = priceFilter
	}
	if filter.MinRating != nil {
		mongoFilter["rating"] = bson.M{"$gte": *filter.MinRating}
	}
	if filter.InStock != nil && *filter.InStock {
		mongoFilter["isAvailable"] = true
		mongoFilter["stockQuantity"] = bson.M{"$gt": 0}
	}
	if filter.IsFeatured != nil {
		mongoFilter["isFeatured"] = *filter.IsFeatured
	}
	if len(filter.Tags) > 0 {
		mongoFilter["tags"] = bson.M{"$in": filter.Tags}
	}
	if filter.Search != "" {
		mongoFilter["$text"] = bson.M{"$search": filter.Search}
	}

	// Count total documents
	total, err := r.collection.CountDocuments(ctx, mongoFilter)
	if err != nil {
		return nil, 0, err
	}

	// Set up pagination
	page := filter.Page
	if page < 1 {
		page = 1
	}
	limit := filter.Limit
	if limit < 1 {
		limit = 20
	}
	skip := (page - 1) * limit

	// Set up sorting
	sort := bson.M{"createdAt": -1} // Default sort
	switch filter.SortBy {
	case "price_low":
		sort = bson.M{"price": 1}
	case "price_high":
		sort = bson.M{"price": -1}
	case "rating":
		sort = bson.M{"rating": -1}
	case "newest":
		sort = bson.M{"createdAt": -1}
	case "popularity":
		sort = bson.M{"reviewCount": -1}
	}

	// Find products
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(sort)

	cursor, err := r.collection.Find(ctx, mongoFilter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, 0, err
	}

	return products, total, nil
}

func (r *productRepository) Update(ctx context.Context, product *models.Product) error {
	filter := bson.M{"_id": product.ID}
	update := bson.M{
		"$set": bson.M{
			"name":           product.Name,
			"description":    product.Description,
			"price":          product.Price,
			"originalPrice":  product.OriginalPrice,
			"images":         product.Images,
			"category":       product.Category,
			"subcategory":    product.Subcategory,
			"metalType":      product.MetalType,
			"stoneType":      product.StoneType,
			"weight":         product.Weight,
			"size":           product.Size,
			"stockQuantity":  product.StockQuantity,
			"rating":         product.Rating,
			"reviewCount":    product.ReviewCount,
			"tags":           product.Tags,
			"isAvailable":    product.IsAvailable,
			"isFeatured":     product.IsFeatured,
			"updatedAt":      product.UpdatedAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *productRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}
	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}

func (r *productRepository) GetFeatured(ctx context.Context) ([]models.Product, error) {
	filter := bson.M{"isFeatured": true, "isAvailable": true}
	opts := options.Find().SetLimit(10).SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, err
	}

	return products, nil
}

func (r *productRepository) GetCategories(ctx context.Context) ([]string, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id": "$category",
			},
		},
		{
			"$sort": bson.M{"_id": 1},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []struct {
		ID string `bson:"_id"`
	}
	if err = cursor.All(ctx, &results); err != nil {
		return nil, err
	}

	categories := make([]string, len(results))
	for i, result := range results {
		categories[i] = result.ID
	}

	return categories, nil
}

func (r *productRepository) Search(ctx context.Context, query string) ([]models.Product, error) {
	filter := bson.M{
		"$text": bson.M{"$search": query},
		"isAvailable": true,
	}
	opts := options.Find().SetLimit(20).SetSort(bson.M{"score": bson.M{"$meta": "textScore"}})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, err
	}

	return products, nil
}
