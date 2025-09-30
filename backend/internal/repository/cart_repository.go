package repository

import (
	"context"
	"errors"
	"time"

	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)


type cartRepository struct {
	collection *mongo.Collection
}

func NewCartRepository(db *mongo.Database) CartRepository {
	return &cartRepository{
		collection: db.Collection("carts"),
	}
}

func (r *cartRepository) Create(ctx context.Context, cart *models.Cart) error {
	cart.CreatedAt = time.Now()
	cart.UpdatedAt = time.Now()
	
	_, err := r.collection.InsertOne(ctx, cart)
	return err
}

func (r *cartRepository) GetByUserID(ctx context.Context, userID primitive.ObjectID) (*models.Cart, error) {
	var cart models.Cart
	err := r.collection.FindOne(ctx, bson.M{"userId": userID}).Decode(&cart)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("cart not found")
		}
		return nil, err
	}
	return &cart, nil
}

func (r *cartRepository) GetByGuestSessionID(ctx context.Context, sessionID string) (*models.Cart, error) {
	var cart models.Cart
	err := r.collection.FindOne(ctx, bson.M{"guestSessionId": sessionID}).Decode(&cart)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("cart not found")
		}
		return nil, err
	}
	return &cart, nil
}

func (r *cartRepository) Update(ctx context.Context, cart *models.Cart) error {
	cart.UpdatedAt = time.Now()
	
	filter := bson.M{"_id": cart.ID}
	update := bson.M{
		"$set": bson.M{
			"items":          cart.Items,
			"couponCode":     cart.CouponCode,
			"discount":       cart.Discount,
			"updatedAt":      cart.UpdatedAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *cartRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}
	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}

func (r *cartRepository) ClearUserCart(ctx context.Context, userID primitive.ObjectID) error {
	filter := bson.M{"userId": userID}
	update := bson.M{
		"$set": bson.M{
			"items":      []models.CartItem{},
			"couponCode": nil,
			"discount":   0,
			"updatedAt":  time.Now(),
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *cartRepository) ClearGuestCart(ctx context.Context, sessionID string) error {
	filter := bson.M{"guestSessionId": sessionID}
	update := bson.M{
		"$set": bson.M{
			"items":      []models.CartItem{},
			"couponCode": nil,
			"discount":   0,
			"updatedAt":  time.Now(),
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

// Implement interface methods expected by CartRepository
func (r *cartRepository) ClearByUserID(ctx context.Context, userID primitive.ObjectID) error {
    return r.ClearUserCart(ctx, userID)
}

func (r *cartRepository) ClearByGuestSessionID(ctx context.Context, sessionID string) error {
    return r.ClearGuestCart(ctx, sessionID)
}

func (r *cartRepository) GetAbandonedCarts(ctx context.Context, cutoffTime time.Time) ([]models.Cart, error) {
    filter := bson.M{"updatedAt": bson.M{"$lt": cutoffTime}}
    cursor, err := r.collection.Find(ctx, filter)
    if err != nil {
        return nil, err
    }
    defer cursor.Close(ctx)

    var carts []models.Cart
    for cursor.Next(ctx) {
        var cart models.Cart
        if err := cursor.Decode(&cart); err != nil {
            return nil, err
        }
        carts = append(carts, cart)
    }
    if err := cursor.Err(); err != nil {
        return nil, err
    }
    return carts, nil
}
