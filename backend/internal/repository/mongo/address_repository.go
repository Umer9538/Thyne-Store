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

type addressRepository struct {
	collection *mongo.Collection
}

// NewAddressRepository creates a new address repository
func NewAddressRepository(db *mongo.Database) repository.AddressRepository {
	return &addressRepository{
		collection: db.Collection("addresses"),
	}
}

func (r *addressRepository) Create(ctx context.Context, address *models.Address) error {
	if address.ID.IsZero() {
		address.ID = primitive.NewObjectID()
	}
	address.CreatedAt = time.Now()
	address.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, address)
	if err != nil {
		return fmt.Errorf("failed to create address: %w", err)
	}

	return nil
}

func (r *addressRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Address, error) {
	var address models.Address
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&address)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("address not found")
		}
		return nil, fmt.Errorf("failed to get address: %w", err)
	}
	return &address, nil
}

func (r *addressRepository) Update(ctx context.Context, address *models.Address) error {
	address.UpdatedAt = time.Now()

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": address.ID},
		bson.M{"$set": address},
	)
	if err != nil {
		return fmt.Errorf("failed to update address: %w", err)
	}

	return nil
}

func (r *addressRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete address: %w", err)
	}

	return nil
}

func (r *addressRepository) GetUserAddresses(ctx context.Context, userID primitive.ObjectID) ([]models.Address, error) {
	filter := bson.M{"userId": userID}
	opts := options.Find().SetSort(bson.M{"isDefault": -1, "createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find user addresses: %w", err)
	}
	defer cursor.Close(ctx)

	var addresses []models.Address
	if err = cursor.All(ctx, &addresses); err != nil {
		return nil, fmt.Errorf("failed to decode addresses: %w", err)
	}

	return addresses, nil
}

func (r *addressRepository) SetDefault(ctx context.Context, userID, addressID primitive.ObjectID) error {
	// First, unset all default addresses for the user
	_, err := r.collection.UpdateMany(
		ctx,
		bson.M{"userId": userID},
		bson.M{
			"$set": bson.M{
				"isDefault": false,
				"updatedAt": time.Now(),
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to unset default addresses: %w", err)
	}

	// Then set the specified address as default
	_, err = r.collection.UpdateOne(
		ctx,
		bson.M{"_id": addressID, "userId": userID},
		bson.M{
			"$set": bson.M{
				"isDefault": true,
				"updatedAt": time.Now(),
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to set default address: %w", err)
	}

	return nil
}

func (r *addressRepository) GetDefault(ctx context.Context, userID primitive.ObjectID) (*models.Address, error) {
	var address models.Address
	err := r.collection.FindOne(ctx, bson.M{
		"userId":    userID,
		"isDefault": true,
	}).Decode(&address)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("default address not found")
		}
		return nil, fmt.Errorf("failed to get default address: %w", err)
	}
	return &address, nil
}