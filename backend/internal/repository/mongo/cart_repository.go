//go:build exclude

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

type cartRepository struct {
	collection *mongo.Collection
}

// NewCartRepository creates a new cart repository
func NewCartRepository(db *mongo.Database) repository.CartRepository {
	return &cartRepository{
		collection: db.Collection("carts"),
	}
}

func (r *cartRepository) Create(ctx context.Context, cart *models.Cart) error {
	cart.ID = primitive.NewObjectID()
	cart.CreatedAt = time.Now()
	cart.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, cart)
	if err != nil {
		return fmt.Errorf("failed to create cart: %w", err)
	}

	return nil
}

func (r *cartRepository) GetByUserID(ctx context.Context, userID primitive.ObjectID) (*models.Cart, error) {
	var cart models.Cart
	err := r.collection.FindOne(ctx, bson.M{"userId": userID}).Decode(&cart)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Create a new cart if it doesn't exist
			cart = models.Cart{
				UserID: &userID,
				Items:  []models.CartItem{},
			}
			if createErr := r.Create(ctx, &cart); createErr != nil {
				return nil, fmt.Errorf("failed to create new cart: %w", createErr)
			}
			return &cart, nil
		}
		return nil, fmt.Errorf("failed to get cart: %w", err)
	}
	return &cart, nil
}

func (r *cartRepository) GetByGuestID(ctx context.Context, guestID string) (*models.Cart, error) {
	var cart models.Cart
	err := r.collection.FindOne(ctx, bson.M{"guestId": guestID}).Decode(&cart)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Create a new cart if it doesn't exist
			cart = models.Cart{
				GuestID: &guestID,
				Items:   []models.CartItem{},
			}
			if createErr := r.Create(ctx, &cart); createErr != nil {
				return nil, fmt.Errorf("failed to create new guest cart: %w", createErr)
			}
			return &cart, nil
		}
		return nil, fmt.Errorf("failed to get guest cart: %w", err)
	}
	return &cart, nil
}

func (r *cartRepository) Update(ctx context.Context, cart *models.Cart) error {
	cart.UpdatedAt = time.Now()

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": cart.ID},
		bson.M{"$set": cart},
	)
	if err != nil {
		return fmt.Errorf("failed to update cart: %w", err)
	}

	return nil
}

func (r *cartRepository) AddItem(ctx context.Context, cartID primitive.ObjectID, item *models.CartItem) error {
	// Check if item already exists in cart
	filter := bson.M{
		"_id":               cartID,
		"items.productId":   item.ProductID,
		"items.variantId":   item.VariantID,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return fmt.Errorf("failed to check existing item: %w", err)
	}

	if count > 0 {
		// Update existing item quantity
		_, err = r.collection.UpdateOne(
			ctx,
			filter,
			bson.M{
				"$inc": bson.M{"items.$.quantity": item.Quantity},
				"$set": bson.M{"updatedAt": time.Now()},
			},
		)
	} else {
		// Add new item
		_, err = r.collection.UpdateOne(
			ctx,
			bson.M{"_id": cartID},
			bson.M{
				"$push": bson.M{"items": item},
				"$set":  bson.M{"updatedAt": time.Now()},
			},
		)
	}

	if err != nil {
		return fmt.Errorf("failed to add item to cart: %w", err)
	}

	return nil
}

func (r *cartRepository) UpdateItem(ctx context.Context, cartID primitive.ObjectID, productID primitive.ObjectID, quantity int) error {
	if quantity <= 0 {
		return r.RemoveItem(ctx, cartID, productID)
	}

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{
			"_id":             cartID,
			"items.productId": productID,
		},
		bson.M{
			"$set": bson.M{
				"items.$.quantity": quantity,
				"updatedAt":        time.Now(),
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to update cart item: %w", err)
	}

	return nil
}

func (r *cartRepository) RemoveItem(ctx context.Context, cartID primitive.ObjectID, productID primitive.ObjectID) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": cartID},
		bson.M{
			"$pull": bson.M{"items": bson.M{"productId": productID}},
			"$set":  bson.M{"updatedAt": time.Now()},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to remove item from cart: %w", err)
	}

	return nil
}

func (r *cartRepository) ClearCart(ctx context.Context, cartID primitive.ObjectID) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": cartID},
		bson.M{
			"$set": bson.M{
				"items":     []models.CartItem{},
				"updatedAt": time.Now(),
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to clear cart: %w", err)
	}

	return nil
}

func (r *cartRepository) MergeGuestCart(ctx context.Context, guestID string, userID primitive.ObjectID) error {
	// Get guest cart
	guestCart, err := r.GetByGuestID(ctx, guestID)
	if err != nil {
		return fmt.Errorf("failed to get guest cart: %w", err)
	}

	if len(guestCart.Items) == 0 {
		return nil // Nothing to merge
	}

	// Get user cart
	userCart, err := r.GetByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get user cart: %w", err)
	}

	// Merge items
	for _, guestItem := range guestCart.Items {
		// Check if item already exists in user cart
		found := false
		for i, userItem := range userCart.Items {
			if userItem.ProductID == guestItem.ProductID && userItem.VariantID == guestItem.VariantID {
				// Update quantity
				userCart.Items[i].Quantity += guestItem.Quantity
				found = true
				break
			}
		}
		if !found {
			// Add new item
			userCart.Items = append(userCart.Items, guestItem)
		}
	}

	// Update user cart
	if err := r.Update(ctx, userCart); err != nil {
		return fmt.Errorf("failed to update user cart: %w", err)
	}

	// Delete guest cart
	_, err = r.collection.DeleteOne(ctx, bson.M{"_id": guestCart.ID})
	if err != nil {
		return fmt.Errorf("failed to delete guest cart: %w", err)
	}

	return nil
}