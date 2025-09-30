package repository

import (
	"context"

	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type categoryRepository struct {
	collection *mongo.Collection
}

func NewCategoryRepository(db *mongo.Database) CategoryRepository {
	return &categoryRepository{collection: db.Collection("categories")}
}

func (r *categoryRepository) Create(ctx context.Context, category *models.Category) error {
	_, err := r.collection.InsertOne(ctx, category)
	return err
}

func (r *categoryRepository) Update(ctx context.Context, category *models.Category) error {
	filter := bson.M{"_id": category.ID}
	update := bson.M{"$set": bson.M{
		"name":        category.Name,
		"slug":        category.Slug,
		"description": category.Description,
		"image":       category.Image,
		"isActive":    category.IsActive,
		"sortOrder":   category.SortOrder,
		"updatedAt":   category.UpdatedAt,
	}}
	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *categoryRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

func (r *categoryRepository) GetAll(ctx context.Context) ([]models.Category, error) {
    findOpts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}, {Key: "name", Value: 1}})
	cursor, err := r.collection.Find(ctx, bson.M{}, findOpts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var categories []models.Category
	if err := cursor.All(ctx, &categories); err != nil {
		return nil, err
	}
	return categories, nil
}

func (r *categoryRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Category, error) {
	var category models.Category
	if err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&category); err != nil {
		return nil, err
	}
	return &category, nil
}

// Additional methods to satisfy the broader CategoryRepository interface in interfaces.go
func (r *categoryRepository) GetBySlug(ctx context.Context, slug string) (*models.Category, error) {
	var category models.Category
	if err := r.collection.FindOne(ctx, bson.M{"slug": slug}).Decode(&category); err != nil {
		return nil, err
	}
	return &category, nil
}

func (r *categoryRepository) List(ctx context.Context, page, limit int) ([]models.Category, int64, error) {
	if page < 1 { page = 1 }
	if limit < 1 { limit = 20 }
	skip := int64((page - 1) * limit)
    opts := options.Find().SetSkip(skip).SetLimit(int64(limit)).SetSort(bson.D{{Key: "sortOrder", Value: 1}, {Key: "name", Value: 1}})

	total, err := r.collection.CountDocuments(ctx, bson.M{})
	if err != nil { return nil, 0, err }

	cursor, err := r.collection.Find(ctx, bson.M{}, opts)
	if err != nil { return nil, 0, err }
	defer cursor.Close(ctx)

	var categories []models.Category
	if err := cursor.All(ctx, &categories); err != nil { return nil, 0, err }
	return categories, total, nil
}

func (r *categoryRepository) GetActive(ctx context.Context) ([]models.Category, error) {
    cursor, err := r.collection.Find(ctx, bson.M{"isActive": true}, options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}, {Key: "name", Value: 1}}))
	if err != nil { return nil, err }
	defer cursor.Close(ctx)
	var categories []models.Category
	if err := cursor.All(ctx, &categories); err != nil { return nil, err }
	return categories, nil
}

func (r *categoryRepository) GetHierarchy(ctx context.Context) ([]models.Category, error) {
	// No explicit hierarchy field in model; return all ordered as a flat list
	return r.GetAll(ctx)
}

func (r *categoryRepository) GetByParentID(ctx context.Context, parentID primitive.ObjectID) ([]models.Category, error) {
	// ParentID not modeled; return empty set for now
	return []models.Category{}, nil
}


