package repository

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"thyne-jewels-backend/internal/models"
)

type StorefrontDataRepository struct {
	occasionsCollection    *mongo.Collection
	budgetRangesCollection *mongo.Collection
	collectionsCollection  *mongo.Collection
	settingsCollection     *mongo.Collection
}

func NewStorefrontDataRepository(db *mongo.Database) *StorefrontDataRepository {
	return &StorefrontDataRepository{
		occasionsCollection:    db.Collection("occasions"),
		budgetRangesCollection: db.Collection("budget_ranges"),
		collectionsCollection:  db.Collection("collections"),
		settingsCollection:     db.Collection("store_settings"),
	}
}

// ==================== Occasions ====================

func (r *StorefrontDataRepository) CreateOccasion(ctx context.Context, occasion *models.Occasion) error {
	occasion.ID = primitive.NewObjectID()
	occasion.CreatedAt = time.Now()
	occasion.UpdatedAt = time.Now()

	_, err := r.occasionsCollection.InsertOne(ctx, occasion)
	return err
}

func (r *StorefrontDataRepository) GetOccasionByID(ctx context.Context, id string) (*models.Occasion, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	var occasion models.Occasion
	err = r.occasionsCollection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&occasion)
	if err != nil {
		return nil, err
	}

	return &occasion, nil
}

func (r *StorefrontDataRepository) GetAllOccasions(ctx context.Context) ([]models.Occasion, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})
	cursor, err := r.occasionsCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var occasions []models.Occasion
	if err = cursor.All(ctx, &occasions); err != nil {
		return nil, err
	}

	return occasions, nil
}

func (r *StorefrontDataRepository) GetActiveOccasions(ctx context.Context) ([]models.Occasion, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})
	cursor, err := r.occasionsCollection.Find(ctx, bson.M{"isActive": true}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var occasions []models.Occasion
	if err = cursor.All(ctx, &occasions); err != nil {
		return nil, err
	}

	return occasions, nil
}

func (r *StorefrontDataRepository) UpdateOccasion(ctx context.Context, id string, occasion *models.Occasion) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	occasion.UpdatedAt = time.Now()
	update := bson.M{
		"$set": bson.M{
			"name":        occasion.Name,
			"icon":        occasion.Icon,
			"description": occasion.Description,
			"itemCount":   occasion.ItemCount,
			"tags":        occasion.Tags,
			"isActive":    occasion.IsActive,
			"priority":    occasion.Priority,
			"updatedAt":   occasion.UpdatedAt,
		},
	}

	_, err = r.occasionsCollection.UpdateOne(ctx, bson.M{"_id": objectID}, update)
	return err
}

func (r *StorefrontDataRepository) DeleteOccasion(ctx context.Context, id string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	_, err = r.occasionsCollection.DeleteOne(ctx, bson.M{"_id": objectID})
	return err
}

// ==================== Budget Ranges ====================

func (r *StorefrontDataRepository) CreateBudgetRange(ctx context.Context, budgetRange *models.BudgetRange) error {
	budgetRange.ID = primitive.NewObjectID()
	budgetRange.CreatedAt = time.Now()
	budgetRange.UpdatedAt = time.Now()

	_, err := r.budgetRangesCollection.InsertOne(ctx, budgetRange)
	return err
}

func (r *StorefrontDataRepository) GetBudgetRangeByID(ctx context.Context, id string) (*models.BudgetRange, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	var budgetRange models.BudgetRange
	err = r.budgetRangesCollection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&budgetRange)
	if err != nil {
		return nil, err
	}

	return &budgetRange, nil
}

func (r *StorefrontDataRepository) GetAllBudgetRanges(ctx context.Context) ([]models.BudgetRange, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})
	cursor, err := r.budgetRangesCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var budgetRanges []models.BudgetRange
	if err = cursor.All(ctx, &budgetRanges); err != nil {
		return nil, err
	}

	return budgetRanges, nil
}

func (r *StorefrontDataRepository) GetActiveBudgetRanges(ctx context.Context) ([]models.BudgetRange, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})
	cursor, err := r.budgetRangesCollection.Find(ctx, bson.M{"isActive": true}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var budgetRanges []models.BudgetRange
	if err = cursor.All(ctx, &budgetRanges); err != nil {
		return nil, err
	}

	return budgetRanges, nil
}

func (r *StorefrontDataRepository) UpdateBudgetRange(ctx context.Context, id string, budgetRange *models.BudgetRange) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	budgetRange.UpdatedAt = time.Now()
	update := bson.M{
		"$set": bson.M{
			"label":      budgetRange.Label,
			"minPrice":   budgetRange.MinPrice,
			"maxPrice":   budgetRange.MaxPrice,
			"itemCount":  budgetRange.ItemCount,
			"isPopular":  budgetRange.IsPopular,
			"priority":   budgetRange.Priority,
			"updatedAt":  budgetRange.UpdatedAt,
		},
	}

	_, err = r.budgetRangesCollection.UpdateOne(ctx, bson.M{"_id": objectID}, update)
	return err
}

func (r *StorefrontDataRepository) DeleteBudgetRange(ctx context.Context, id string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	_, err = r.budgetRangesCollection.DeleteOne(ctx, bson.M{"_id": objectID})
	return err
}

// ==================== Collections ====================

func (r *StorefrontDataRepository) CreateCollection(ctx context.Context, collection *models.Collection) error {
	collection.ID = primitive.NewObjectID()
	collection.CreatedAt = time.Now()
	collection.UpdatedAt = time.Now()

	_, err := r.collectionsCollection.InsertOne(ctx, collection)
	return err
}

func (r *StorefrontDataRepository) GetCollectionByID(ctx context.Context, id string) (*models.Collection, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	var collection models.Collection
	err = r.collectionsCollection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&collection)
	if err != nil {
		return nil, err
	}

	return &collection, nil
}

func (r *StorefrontDataRepository) GetAllCollections(ctx context.Context) ([]models.Collection, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})
	cursor, err := r.collectionsCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var collections []models.Collection
	if err = cursor.All(ctx, &collections); err != nil {
		return nil, err
	}

	return collections, nil
}

func (r *StorefrontDataRepository) GetActiveCollections(ctx context.Context) ([]models.Collection, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})
	cursor, err := r.collectionsCollection.Find(ctx, bson.M{"isActive": true}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var collections []models.Collection
	if err = cursor.All(ctx, &collections); err != nil {
		return nil, err
	}

	return collections, nil
}

func (r *StorefrontDataRepository) GetFeaturedCollections(ctx context.Context) ([]models.Collection, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})
	filter := bson.M{
		"isActive":    true,
		"isFeatured":  true,
	}
	cursor, err := r.collectionsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var collections []models.Collection
	if err = cursor.All(ctx, &collections); err != nil {
		return nil, err
	}

	return collections, nil
}

func (r *StorefrontDataRepository) UpdateCollection(ctx context.Context, id string, collection *models.Collection) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	collection.UpdatedAt = time.Now()
	update := bson.M{
		"$set": bson.M{
			"title":       collection.Title,
			"subtitle":    collection.Subtitle,
			"description": collection.Description,
			"imageUrls":   collection.ImageURLs,
			"productIds":  collection.ProductIDs,
			"itemCount":   collection.ItemCount,
			"tags":        collection.Tags,
			"isActive":    collection.IsActive,
			"isFeatured":  collection.IsFeatured,
			"priority":    collection.Priority,
			"updatedAt":   collection.UpdatedAt,
		},
	}

	_, err = r.collectionsCollection.UpdateOne(ctx, bson.M{"_id": objectID}, update)
	return err
}

func (r *StorefrontDataRepository) DeleteCollection(ctx context.Context, id string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	_, err = r.collectionsCollection.DeleteOne(ctx, bson.M{"_id": objectID})
	return err
}

// GetCollectionProducts returns all products in a collection
func (r *StorefrontDataRepository) GetCollectionProducts(ctx context.Context, collectionID string) ([]models.Product, error) {
	// First, get the collection to find product IDs
	objectID, err := primitive.ObjectIDFromHex(collectionID)
	if err != nil {
		return nil, err
	}

	var collection models.Collection
	err = r.collectionsCollection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&collection)
	if err != nil {
		return nil, err
	}

	// If no product IDs in collection, return empty slice
	if len(collection.ProductIDs) == 0 {
		return []models.Product{}, nil
	}

	// Get the products database (need to get it from the same database)
	productsCollection := r.collectionsCollection.Database().Collection("products")

	// Fetch products with those IDs
	filter := bson.M{
		"_id": bson.M{"$in": collection.ProductIDs},
		"isActive": true,
	}

	cursor, err := productsCollection.Find(ctx, filter, options.Find().SetSort(bson.M{"createdAt": -1}))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var products []models.Product
	if err := cursor.All(ctx, &products); err != nil {
		return nil, err
	}

	return products, nil
}

// ==================== Store Settings ====================

// GetStoreSettings retrieves the store settings (creates default if not exists)
func (r *StorefrontDataRepository) GetStoreSettings(ctx context.Context) (*models.StoreSettings, error) {
	var settings models.StoreSettings
	err := r.settingsCollection.FindOne(ctx, bson.M{}).Decode(&settings)

	if err == mongo.ErrNoDocuments {
		// Create default settings if not exists
		defaultSettings := models.DefaultStoreSettings()
		defaultSettings.ID = primitive.NewObjectID()
		_, err := r.settingsCollection.InsertOne(ctx, defaultSettings)
		if err != nil {
			return nil, err
		}
		return defaultSettings, nil
	}

	if err != nil {
		return nil, err
	}

	return &settings, nil
}

// UpdateStoreSettings updates the store settings
func (r *StorefrontDataRepository) UpdateStoreSettings(ctx context.Context, settings *models.StoreSettings) error {
	settings.UpdatedAt = time.Now()

	// Try to find existing settings
	var existingSettings models.StoreSettings
	err := r.settingsCollection.FindOne(ctx, bson.M{}).Decode(&existingSettings)

	if err == mongo.ErrNoDocuments {
		// Insert new settings
		settings.ID = primitive.NewObjectID()
		_, err := r.settingsCollection.InsertOne(ctx, settings)
		return err
	}

	if err != nil {
		return err
	}

	// Update existing settings
	update := bson.M{
		"$set": bson.M{
			"gstRate":               settings.GSTRate,
			"gstNumber":             settings.GSTNumber,
			"enableGst":             settings.EnableGST,
			"freeShippingThreshold": settings.FreeShippingThreshold,
			"shippingCost":          settings.ShippingCost,
			"enableFreeShipping":    settings.EnableFreeShipping,
			"enableCod":             settings.EnableCOD,
			"codCharge":             settings.CODCharge,
			"codMaxAmount":          settings.CODMaxAmount,
			"storeName":             settings.StoreName,
			"storeEmail":            settings.StoreEmail,
			"storePhone":            settings.StorePhone,
			"storeAddress":          settings.StoreAddress,
			"currency":              settings.Currency,
			"currencySymbol":        settings.CurrencySymbol,
			"updatedAt":             settings.UpdatedAt,
			"updatedBy":             settings.UpdatedBy,
		},
	}

	_, err = r.settingsCollection.UpdateOne(ctx, bson.M{"_id": existingSettings.ID}, update)
	return err
}
