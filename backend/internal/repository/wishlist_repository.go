package repository

import (
	"context"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type wishlistRepository struct {
	collection        *mongo.Collection
	productCollection *mongo.Collection
}

func NewWishlistRepository(db *mongo.Database) WishlistRepository {
	return &wishlistRepository{
		collection:        db.Collection("wishlist"),
		productCollection: db.Collection("products"),
	}
}

func (r *wishlistRepository) Create(ctx context.Context, wishlist *models.Wishlist) error {
	wishlist.ID = primitive.NewObjectID()
	wishlist.CreatedAt = time.Now()
	wishlist.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, wishlist)
	if err != nil {
		return fmt.Errorf("failed to create wishlist: %w", err)
	}

	return nil
}

func (r *wishlistRepository) GetByUserID(ctx context.Context, userID primitive.ObjectID) (*models.Wishlist, error) {
	var wishlist models.Wishlist
	err := r.collection.FindOne(ctx, bson.M{"userId": userID}).Decode(&wishlist)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Create a new wishlist if it doesn't exist
			wishlist = models.Wishlist{
				UserID: userID,
				Items:  []models.WishlistItem{},
			}
			if createErr := r.Create(ctx, &wishlist); createErr != nil {
				return nil, fmt.Errorf("failed to create new wishlist: %w", createErr)
			}
			return &wishlist, nil
		}
		return nil, fmt.Errorf("failed to get wishlist: %w", err)
	}
	return &wishlist, nil
}

func (r *wishlistRepository) AddItem(ctx context.Context, userID, productID primitive.ObjectID) error {
	wishlistItem := models.WishlistItem{
		ID:        primitive.NewObjectID(),
		UserID:    userID,
		ProductID: productID,
		CreatedAt: time.Now(),
	}
	
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"userId": userID},
		bson.M{
			"$addToSet": bson.M{"items": wishlistItem},
			"$set":      bson.M{"updatedAt": time.Now()},
		},
		options.Update().SetUpsert(true),
	)
	if err != nil {
		return fmt.Errorf("failed to add item to wishlist: %w", err)
	}

	return nil
}

func (r *wishlistRepository) RemoveItem(ctx context.Context, userID, productID primitive.ObjectID) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"userId": userID},
		bson.M{
			"$pull": bson.M{"items": bson.M{"productId": productID}},
			"$set":  bson.M{"updatedAt": time.Now()},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to remove item from wishlist: %w", err)
	}

	return nil
}

func (r *wishlistRepository) IsInWishlist(ctx context.Context, userID, productID primitive.ObjectID) (bool, error) {
	count, err := r.collection.CountDocuments(ctx, bson.M{
		"userId": userID,
		"items.productId": productID,
	})
	if err != nil {
		return false, fmt.Errorf("failed to check wishlist: %w", err)
	}

	return count > 0, nil
}

func (r *wishlistRepository) GetWishlistItems(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Product, int64, error) {
	// Get wishlist
	wishlist, err := r.GetByUserID(ctx, userID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get wishlist: %w", err)
	}

	total := int64(len(wishlist.Items))
	if total == 0 {
		return []models.Product{}, 0, nil
	}

	// Calculate pagination
	skip := (page - 1) * limit
	if skip >= int(total) {
		return []models.Product{}, total, nil
	}

	end := skip + limit
	if end > int(total) {
		end = int(total)
	}

	// Get product IDs for this page
	var productIDs []primitive.ObjectID
	for i := skip; i < end; i++ {
		productIDs = append(productIDs, wishlist.Items[i].ProductID)
	}

	// Get products
	filter := bson.M{"_id": bson.M{"$in": productIDs}}
	opts := options.Find().SetSort(bson.M{"name": 1})

	cursor, err := r.productCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find wishlist products: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err = cursor.All(ctx, &products); err != nil {
		return nil, 0, fmt.Errorf("failed to decode products: %w", err)
	}

	return products, total, nil
}

func (r *wishlistRepository) GetWishlistItemsByProduct(ctx context.Context, productID primitive.ObjectID) ([]models.WishlistItem, error) {
	cursor, err := r.collection.Find(ctx, bson.M{"items.productId": productID})
	if err != nil {
		return nil, fmt.Errorf("failed to find wishlist items by product: %w", err)
	}
	defer cursor.Close(ctx)

	var wishlists []models.Wishlist
	if err = cursor.All(ctx, &wishlists); err != nil {
		return nil, fmt.Errorf("failed to decode wishlists: %w", err)
	}

	var items []models.WishlistItem
	for _, wishlist := range wishlists {
		for _, item := range wishlist.Items {
			if item.ProductID == productID {
				items = append(items, item)
			}
		}
	}

	return items, nil
}

func (r *wishlistRepository) ClearWishlist(ctx context.Context, userID primitive.ObjectID) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"userId": userID},
		bson.M{
			"$set": bson.M{
				"items":     []models.WishlistItem{},
				"updatedAt": time.Now(),
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to clear wishlist: %w", err)
	}

	return nil
}
