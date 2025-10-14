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

type wishlistRepository struct {
	collection        *mongo.Collection
	productCollection *mongo.Collection
}

// NewWishlistRepository creates a new wishlist repository
func NewWishlistRepository(db *mongo.Database) repository.WishlistRepository {
	return &wishlistRepository{
		collection:        db.Collection("wishlists"),
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
	item := models.WishlistItem{
		ID:        primitive.NewObjectID(),
		UserID:    userID,
		ProductID: productID,
		CreatedAt: time.Now(),
	}

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"userId": userID},
		bson.M{
			"$push": bson.M{"items": item},
			"$set":  bson.M{"updatedAt": time.Now()},
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
		"userId":           userID,
		"items.productId":  productID,
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
	itemsPage := wishlist.Items[skip:end]
	productIDs := make([]primitive.ObjectID, len(itemsPage))
	for i, item := range itemsPage {
		productIDs[i] = item.ProductID
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

func (r *wishlistRepository) GetWishlistItemsByProduct(ctx context.Context, productID primitive.ObjectID) ([]models.WishlistItem, error) {
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"items.productId": productID,
			},
		},
		{
			"$unwind": "$items",
		},
		{
			"$match": bson.M{
				"items.productId": productID,
			},
		},
		{
			"$replaceRoot": bson.M{
				"newRoot": "$items",
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to find wishlist items: %w", err)
	}
	defer cursor.Close(ctx)

	var items []models.WishlistItem
	if err = cursor.All(ctx, &items); err != nil {
		return nil, fmt.Errorf("failed to decode wishlist items: %w", err)
	}

	return items, nil
}