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

type reviewRepository struct {
	collection *mongo.Collection
}

// NewReviewRepository creates a new review repository
func NewReviewRepository(db *mongo.Database) repository.ReviewRepository {
	return &reviewRepository{
		collection: db.Collection("reviews"),
	}
}

func (r *reviewRepository) Create(ctx context.Context, review *models.Review) error {
	review.ID = primitive.NewObjectID()
	review.CreatedAt = time.Now()
	review.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, review)
	if err != nil {
		return fmt.Errorf("failed to create review: %w", err)
	}

	return nil
}

func (r *reviewRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Review, error) {
	var review models.Review
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&review)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("review not found")
		}
		return nil, fmt.Errorf("failed to get review: %w", err)
	}
	return &review, nil
}

func (r *reviewRepository) Update(ctx context.Context, review *models.Review) error {
	review.UpdatedAt = time.Now()

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": review.ID},
		bson.M{"$set": review},
	)
	if err != nil {
		return fmt.Errorf("failed to update review: %w", err)
	}

	return nil
}

func (r *reviewRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete review: %w", err)
	}

	return nil
}

func (r *reviewRepository) GetProductReviews(ctx context.Context, productID primitive.ObjectID, page, limit int) ([]models.Review, int64, error) {
	filter := bson.M{
		"productId": productID,
		"status":    "approved",
	}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count product reviews: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find reviews
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"helpfulCount": -1, "createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find product reviews: %w", err)
	}
	defer cursor.Close(ctx)

	var reviews []models.Review
	if err = cursor.All(ctx, &reviews); err != nil {
		return nil, 0, fmt.Errorf("failed to decode reviews: %w", err)
	}

	return reviews, total, nil
}

func (r *reviewRepository) GetUserReviews(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Review, int64, error) {
	filter := bson.M{"userId": userID}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count user reviews: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find reviews
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find user reviews: %w", err)
	}
	defer cursor.Close(ctx)

	var reviews []models.Review
	if err = cursor.All(ctx, &reviews); err != nil {
		return nil, 0, fmt.Errorf("failed to decode reviews: %w", err)
	}

	return reviews, total, nil
}

func (r *reviewRepository) GetProductRating(ctx context.Context, productID primitive.ObjectID) (float64, int64, error) {
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"productId": productID,
				"status":    "approved",
			},
		},
		{
			"$group": bson.M{
				"_id":         nil,
				"avgRating":   bson.M{"$avg": "$rating"},
				"totalCount":  bson.M{"$sum": 1},
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to get product rating: %w", err)
	}
	defer cursor.Close(ctx)

	var result struct {
		AvgRating  float64 `bson:"avgRating"`
		TotalCount int64   `bson:"totalCount"`
	}

	if cursor.Next(ctx) {
		if err := cursor.Decode(&result); err != nil {
			return 0, 0, fmt.Errorf("failed to decode rating result: %w", err)
		}
	}

	return result.AvgRating, result.TotalCount, nil
}

func (r *reviewRepository) MarkAsHelpful(ctx context.Context, reviewID, userID primitive.ObjectID) error {
	// First check if user already marked this review
	count, err := r.collection.CountDocuments(ctx, bson.M{
		"_id":           reviewID,
		"helpfulUsers":  userID,
	})
	if err != nil {
		return fmt.Errorf("failed to check helpful status: %w", err)
	}

	if count > 0 {
		return fmt.Errorf("user already marked this review as helpful")
	}

	// Add user to helpful list and increment count
	_, err = r.collection.UpdateOne(
		ctx,
		bson.M{"_id": reviewID},
		bson.M{
			"$addToSet": bson.M{"helpfulUsers": userID},
			"$inc":      bson.M{"helpfulCount": 1},
			"$set":      bson.M{"updatedAt": time.Now()},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to mark review as helpful: %w", err)
	}

	return nil
}

func (r *reviewRepository) MarkAsUnhelpful(ctx context.Context, reviewID, userID primitive.ObjectID) error {
	// Remove user from helpful list and decrement count
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": reviewID},
		bson.M{
			"$pull": bson.M{"helpfulUsers": userID},
			"$inc":  bson.M{"helpfulCount": -1},
			"$set":  bson.M{"updatedAt": time.Now()},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to mark review as unhelpful: %w", err)
	}

	return nil
}

func (r *reviewRepository) GetPendingReviews(ctx context.Context, page, limit int) ([]models.Review, int64, error) {
	filter := bson.M{"status": "pending"}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count pending reviews: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find reviews
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": 1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find pending reviews: %w", err)
	}
	defer cursor.Close(ctx)

	var reviews []models.Review
	if err = cursor.All(ctx, &reviews); err != nil {
		return nil, 0, fmt.Errorf("failed to decode reviews: %w", err)
	}

	return reviews, total, nil
}

func (r *reviewRepository) ApproveReview(ctx context.Context, reviewID primitive.ObjectID) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": reviewID},
		bson.M{
			"$set": bson.M{
				"status":    "approved",
				"updatedAt": time.Now(),
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to approve review: %w", err)
	}

	return nil
}

func (r *reviewRepository) RejectReview(ctx context.Context, reviewID primitive.ObjectID) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": reviewID},
		bson.M{
			"$set": bson.M{
				"status":    "rejected",
				"updatedAt": time.Now(),
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to reject review: %w", err)
	}

	return nil
}