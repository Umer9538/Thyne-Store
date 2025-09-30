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


type reviewRepository struct {
	collection *mongo.Collection
}

func NewReviewRepository(db *mongo.Database) ReviewRepository {
	return &reviewRepository{
		collection: db.Collection("reviews"),
	}
}

func (r *reviewRepository) Create(ctx context.Context, review *models.Review) error {
	_, err := r.collection.InsertOne(ctx, review)
	return err
}

func (r *reviewRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Review, error) {
	var review models.Review
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&review)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("review not found")
		}
		return nil, err
	}
	return &review, nil
}

func (r *reviewRepository) GetByProductID(ctx context.Context, productID primitive.ObjectID, page, limit int) ([]models.Review, int64, error) {
	// Count total documents
	total, err := r.collection.CountDocuments(ctx, bson.M{"productId": productID})
	if err != nil {
		return nil, 0, err
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find reviews with pagination
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, bson.M{"productId": productID}, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var reviews []models.Review
	if err = cursor.All(ctx, &reviews); err != nil {
		return nil, 0, err
	}

	return reviews, total, nil
}

func (r *reviewRepository) GetByUserID(ctx context.Context, userID primitive.ObjectID) ([]models.Review, error) {
	cursor, err := r.collection.Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var reviews []models.Review
	if err = cursor.All(ctx, &reviews); err != nil {
		return nil, err
	}

	return reviews, nil
}

func (r *reviewRepository) Update(ctx context.Context, review *models.Review) error {
	filter := bson.M{"_id": review.ID}
	update := bson.M{
		"$set": bson.M{
			"rating":    review.Rating,
			"comment":   review.Comment,
			"images":    review.Images,
			"updatedAt": review.UpdatedAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *reviewRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}
	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}

func (r *reviewRepository) GetAverageRating(ctx context.Context, productID primitive.ObjectID) (float64, int64, error) {
	pipeline := []bson.M{
		{
			"$match": bson.M{"productId": productID},
		},
		{
			"$group": bson.M{
				"_id":   nil,
				"avgRating": bson.M{"$avg": "$rating"},
				"count": bson.M{"$sum": 1},
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
