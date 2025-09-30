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

type categoryRepository struct {
	collection *mongo.Collection
}

// NewCategoryRepository creates a new category repository
func NewCategoryRepository(db *mongo.Database) repository.CategoryRepository {
	return &categoryRepository{
		collection: db.Collection("categories"),
	}
}

func (r *categoryRepository) Create(ctx context.Context, category *models.Category) error {
	category.ID = primitive.NewObjectID()
	category.CreatedAt = time.Now()
	category.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, category)
	if err != nil {
		return fmt.Errorf("failed to create category: %w", err)
	}

	return nil
}

func (r *categoryRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Category, error) {
	var category models.Category
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&category)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("category not found")
		}
		return nil, fmt.Errorf("failed to get category: %w", err)
	}
	return &category, nil
}

func (r *categoryRepository) GetBySlug(ctx context.Context, slug string) (*models.Category, error) {
	var category models.Category
	err := r.collection.FindOne(ctx, bson.M{"slug": slug}).Decode(&category)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("category not found")
		}
		return nil, fmt.Errorf("failed to get category by slug: %w", err)
	}
	return &category, nil
}

func (r *categoryRepository) Update(ctx context.Context, category *models.Category) error {
	category.UpdatedAt = time.Now()

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": category.ID},
		bson.M{"$set": category},
	)
	if err != nil {
		return fmt.Errorf("failed to update category: %w", err)
	}

	return nil
}

func (r *categoryRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete category: %w", err)
	}

	return nil
}

func (r *categoryRepository) List(ctx context.Context, page, limit int) ([]models.Category, int64, error) {
	// Get total count
	total, err := r.collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count categories: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find categories
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"order": 1, "name": 1})

	cursor, err := r.collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find categories: %w", err)
	}
	defer cursor.Close(ctx)

	var categories []models.Category
	if err = cursor.All(ctx, &categories); err != nil {
		return nil, 0, fmt.Errorf("failed to decode categories: %w", err)
	}

	return categories, total, nil
}

func (r *categoryRepository) GetActive(ctx context.Context) ([]models.Category, error) {
	filter := bson.M{"isActive": true}
	opts := options.Find().SetSort(bson.M{"order": 1, "name": 1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find active categories: %w", err)
	}
	defer cursor.Close(ctx)

	var categories []models.Category
	if err = cursor.All(ctx, &categories); err != nil {
		return nil, fmt.Errorf("failed to decode categories: %w", err)
	}

	return categories, nil
}

func (r *categoryRepository) GetHierarchy(ctx context.Context) ([]models.Category, error) {
	opts := options.Find().SetSort(bson.M{"parentId": 1, "order": 1, "name": 1})

	cursor, err := r.collection.Find(ctx, bson.M{"isActive": true}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find category hierarchy: %w", err)
	}
	defer cursor.Close(ctx)

	var categories []models.Category
	if err = cursor.All(ctx, &categories); err != nil {
		return nil, fmt.Errorf("failed to decode categories: %w", err)
	}

	return categories, nil
}

func (r *categoryRepository) GetByParentID(ctx context.Context, parentID primitive.ObjectID) ([]models.Category, error) {
	filter := bson.M{
		"parentId": parentID,
		"isActive": true,
	}
	opts := options.Find().SetSort(bson.M{"order": 1, "name": 1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find categories by parent: %w", err)
	}
	defer cursor.Close(ctx)

	var categories []models.Category
	if err = cursor.All(ctx, &categories); err != nil {
		return nil, fmt.Errorf("failed to decode categories: %w", err)
	}

	return categories, nil
}