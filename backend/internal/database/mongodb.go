package database

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var (
	client   *mongo.Client
	database *mongo.Database
)

// Connect establishes a connection to MongoDB
func Connect(uri, dbName string) (*mongo.Database, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Set client options
	clientOptions := options.Client().ApplyURI(uri)
	
	// Set additional options
	clientOptions.SetMaxPoolSize(100)
	clientOptions.SetMinPoolSize(5)
	clientOptions.SetMaxConnIdleTime(30 * time.Second)
	clientOptions.SetServerSelectionTimeout(5 * time.Second)

	// Connect to MongoDB
	var err error
	client, err = mongo.Connect(ctx, clientOptions)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to MongoDB: %w", err)
	}

	// Ping the database to verify connection
	if err := client.Ping(ctx, nil); err != nil {
		return nil, fmt.Errorf("failed to ping MongoDB: %w", err)
	}

	database = client.Database(dbName)
	
	// Create indexes - temporarily disabled for compatibility
	// if err := createIndexes(); err != nil {
	//	return nil, fmt.Errorf("failed to create indexes: %w", err)
	// }

	fmt.Printf("Successfully connected to MongoDB database: %s\n", dbName)
	return database, nil
}

// Disconnect closes the MongoDB connection
func Disconnect() error {
	if client != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		
		if err := client.Disconnect(ctx); err != nil {
			return fmt.Errorf("failed to disconnect from MongoDB: %w", err)
		}
	}
	return nil
}

// GetDatabase returns the database instance
func GetDatabase() *mongo.Database {
	return database
}

// GetClient returns the MongoDB client
func GetClient() *mongo.Client {
	return client
}

// createIndexes creates necessary indexes for the collections
func createIndexes() error {
	ctx := context.Background()
	
	// Users collection indexes
	usersCollection := database.Collection("users")
	_, err := usersCollection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"email": 1,
			},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: map[string]interface{}{
				"phone": 1,
			},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: map[string]interface{}{
				"createdAt": -1,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create users indexes: %w", err)
	}

	// Products collection indexes
	productsCollection := database.Collection("products")
	_, err = productsCollection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"category": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"subcategory": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"metalType": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"stoneType": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"price": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"isFeatured": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"isAvailable": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"createdAt": -1,
			},
		},
		// Text search index commented out temporarily due to compatibility issues
		// {
		//	Keys: map[string]interface{}{
		//		"name": "text",
		//		"description": "text",
		//		"tags": "text",
		//	},
		// },
	})
	if err != nil {
		return fmt.Errorf("failed to create products indexes: %w", err)
	}

	// Cart collection indexes
	cartCollection := database.Collection("carts")
	_, err = cartCollection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"userId": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"guestSessionId": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"updatedAt": -1,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create cart indexes: %w", err)
	}

	// Orders collection indexes
	ordersCollection := database.Collection("orders")
	_, err = ordersCollection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"orderNumber": 1,
			},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: map[string]interface{}{
				"userId": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"guestSessionId": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"status": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"paymentStatus": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"createdAt": -1,
			},
		},
		{
			Keys: map[string]interface{}{
				"razorpayOrderId": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"razorpayPaymentId": 1,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create orders indexes: %w", err)
	}

	// Reviews collection indexes
	reviewsCollection := database.Collection("reviews")
	_, err = reviewsCollection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"productId": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"userId": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"productId": 1,
				"userId": 1,
			},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: map[string]interface{}{
				"createdAt": -1,
			},
		},
		{
			Keys: map[string]interface{}{
				"rating": -1,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create reviews indexes: %w", err)
	}

	// Guest sessions collection indexes
	guestSessionsCollection := database.Collection("guest_sessions")
	_, err = guestSessionsCollection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"sessionId": 1,
			},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: map[string]interface{}{
				"expiresAt": 1,
			},
			Options: options.Index().SetExpireAfterSeconds(0),
		},
		{
			Keys: map[string]interface{}{
				"lastActivity": -1,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create guest_sessions indexes: %w", err)
	}

	// Coupons collection indexes
	couponsCollection := database.Collection("coupons")
	_, err = couponsCollection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"code": 1,
			},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: map[string]interface{}{
				"isActive": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"validFrom": 1,
				"validUntil": 1,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create coupons indexes: %w", err)
	}

	// Wishlist collection indexes
	wishlistCollection := database.Collection("wishlist")
	_, err = wishlistCollection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"userId": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"userId": 1,
				"productId": 1,
			},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: map[string]interface{}{
				"createdAt": -1,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create wishlist indexes: %w", err)
	}

	return nil
}

// GetCollection returns a collection by name
func GetCollection(name string) *mongo.Collection {
	return database.Collection(name)
}

// WithTransaction executes a function within a transaction
func WithTransaction(fn func(mongo.SessionContext) error) error {
	if client == nil {
		return fmt.Errorf("database client is not initialized")
	}

	session, err := client.StartSession()
	if err != nil {
		return fmt.Errorf("failed to start session: %w", err)
	}
	defer session.EndSession(context.Background())

	ctx := mongo.NewSessionContext(context.Background(), session)
	
	return mongo.WithSession(ctx, session, func(sc mongo.SessionContext) error {
		if err := session.StartTransaction(); err != nil {
			return fmt.Errorf("failed to start transaction: %w", err)
		}

		if err := fn(sc); err != nil {
			if abortErr := session.AbortTransaction(sc); abortErr != nil {
				return fmt.Errorf("failed to abort transaction: %w", abortErr)
			}
			return err
		}

		if err := session.CommitTransaction(sc); err != nil {
			return fmt.Errorf("failed to commit transaction: %w", err)
		}

		return nil
	})
}
