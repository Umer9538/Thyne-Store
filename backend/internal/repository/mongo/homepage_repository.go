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

type homepageRepository struct {
	configCollection         *mongo.Collection
	layoutCollection         *mongo.Collection
	dealCollection           *mongo.Collection
	flashSaleCollection      *mongo.Collection
	brandCollection          *mongo.Collection
	recentlyViewedCollection *mongo.Collection
	showcase360Collection    *mongo.Collection
	bundleDealCollection     *mongo.Collection
}

// NewHomepageRepository creates a new homepage repository
func NewHomepageRepository(db *mongo.Database) repository.HomepageRepository {
	return &homepageRepository{
		configCollection:         db.Collection("homepage_config"),
		layoutCollection:         db.Collection("homepage_layout"),
		dealCollection:           db.Collection("deals_of_day"),
		flashSaleCollection:      db.Collection("flash_sales"),
		brandCollection:          db.Collection("brands"),
		recentlyViewedCollection: db.Collection("recently_viewed"),
		showcase360Collection:    db.Collection("showcases_360"),
		bundleDealCollection:     db.Collection("bundle_deals"),
	}
}

// Homepage Configuration

func (r *homepageRepository) GetHomepageConfig(ctx context.Context) (*models.HomepageConfig, error) {
	var config models.HomepageConfig

	// Get the first (and should be only) config document
	opts := options.FindOne().SetSort(bson.D{{Key: "updatedAt", Value: -1}})
	err := r.configCollection.FindOne(ctx, bson.M{}, opts).Decode(&config)

	if err == mongo.ErrNoDocuments {
		// Return default config if none exists
		return r.createDefaultConfig(ctx)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get homepage config: %w", err)
	}

	return &config, nil
}

func (r *homepageRepository) createDefaultConfig(ctx context.Context) (*models.HomepageConfig, error) {
	config := &models.HomepageConfig{
		ID: primitive.NewObjectID(),
		Sections: []models.HomepageSection{
			{
				ID:       primitive.NewObjectID(),
				Type:     models.SectionBannerCarousel,
				Title:    "Featured",
				Priority: 1,
				IsActive: true,
				Config:   make(map[string]interface{}),
			},
			{
				ID:       primitive.NewObjectID(),
				Type:     models.SectionCategories,
				Title:    "Shop by Category",
				Priority: 2,
				IsActive: true,
				Config:   make(map[string]interface{}),
			},
			{
				ID:       primitive.NewObjectID(),
				Type:     models.SectionFeatured,
				Title:    "Featured Products",
				Priority: 3,
				IsActive: true,
				Config:   make(map[string]interface{}),
			},
		},
		UpdatedAt: time.Now(),
	}

	_, err := r.configCollection.InsertOne(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create default config: %w", err)
	}

	return config, nil
}

func (r *homepageRepository) UpdateHomepageConfig(ctx context.Context, config *models.HomepageConfig) error {
	config.UpdatedAt = time.Now()

	filter := bson.M{"_id": config.ID}
	update := bson.M{"$set": config}

	_, err := r.configCollection.UpdateOne(ctx, filter, update, options.Update().SetUpsert(true))
	if err != nil {
		return fmt.Errorf("failed to update homepage config: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetActiveSections(ctx context.Context) ([]models.HomepageSection, error) {
	config, err := r.GetHomepageConfig(ctx)
	if err != nil {
		return nil, err
	}

	// Filter active sections
	now := time.Now()
	var activeSections []models.HomepageSection

	for _, section := range config.Sections {
		if !section.IsActive {
			continue
		}

		if section.StartDate != nil && now.Before(*section.StartDate) {
			continue
		}

		if section.EndDate != nil && now.After(*section.EndDate) {
			continue
		}

		activeSections = append(activeSections, section)
	}

	return activeSections, nil
}

// Homepage Layout

func (r *homepageRepository) GetHomepageLayout(ctx context.Context) (*models.HomepageLayout, error) {
	var layout models.HomepageLayout

	// Get the first (and should be only) layout document
	opts := options.FindOne().SetSort(bson.D{{Key: "updatedAt", Value: -1}})
	err := r.layoutCollection.FindOne(ctx, bson.M{}, opts).Decode(&layout)

	if err == mongo.ErrNoDocuments {
		// Create default layout if none exists
		return r.createDefaultLayoutInternal(ctx)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get homepage layout: %w", err)
	}

	return &layout, nil
}

func (r *homepageRepository) createDefaultLayoutInternal(ctx context.Context) (*models.HomepageLayout, error) {
	layout := &models.HomepageLayout{
		ID: primitive.NewObjectID(),
		Layout: []models.SectionLayoutItem{
			{SectionType: models.SectionBannerCarousel, Order: 0, IsVisible: true, Title: ""},
			{SectionType: models.SectionDealOfDay, Order: 1, IsVisible: true, Title: ""},
			{SectionType: models.SectionFlashSale, Order: 2, IsVisible: true, Title: ""},
			{SectionType: models.SectionCategories, Order: 3, IsVisible: true, Title: ""},
			{SectionType: models.SectionShowcase360, Order: 4, IsVisible: true, Title: ""},
			{SectionType: models.SectionBundleDeals, Order: 5, IsVisible: true, Title: ""},
			{SectionType: models.SectionFeatured, Order: 6, IsVisible: true, Title: ""},
			{SectionType: models.SectionRecentlyViewed, Order: 7, IsVisible: true, Title: ""},
			{SectionType: models.SectionNewArrivals, Order: 8, IsVisible: true, Title: ""},
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	_, err := r.layoutCollection.InsertOne(ctx, layout)
	if err != nil {
		return nil, fmt.Errorf("failed to create default layout: %w", err)
	}

	return layout, nil
}

func (r *homepageRepository) UpdateHomepageLayout(ctx context.Context, layout *models.HomepageLayout) error {
	layout.UpdatedAt = time.Now()

	filter := bson.M{"_id": layout.ID}
	update := bson.M{"$set": layout}

	_, err := r.layoutCollection.UpdateOne(ctx, filter, update, options.Update().SetUpsert(true))
	if err != nil {
		return fmt.Errorf("failed to update homepage layout: %w", err)
	}

	return nil
}

func (r *homepageRepository) CreateDefaultLayout(ctx context.Context) error {
	_, err := r.createDefaultLayoutInternal(ctx)
	return err
}

// Deal of Day

func (r *homepageRepository) CreateDealOfDay(ctx context.Context, deal *models.DealOfDay) error {
	deal.ID = primitive.NewObjectID()
	deal.CreatedAt = time.Now()
	deal.UpdatedAt = time.Now()

	_, err := r.dealCollection.InsertOne(ctx, deal)
	if err != nil {
		return fmt.Errorf("failed to create deal of day: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetActiveDealOfDay(ctx context.Context) (*models.DealOfDay, error) {
	now := time.Now()
	filter := bson.M{
		"isActive":  true,
		"startTime": bson.M{"$lte": now},
		"endTime":   bson.M{"$gte": now},
		"$expr":     bson.M{"$lt": bson.A{"$soldCount", "$stock"}},
	}

	var deal models.DealOfDay
	err := r.dealCollection.FindOne(ctx, filter, options.FindOne().SetSort(bson.D{{Key: "startTime", Value: -1}})).Decode(&deal)

	if err == mongo.ErrNoDocuments {
		return nil, nil
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get active deal: %w", err)
	}

	return &deal, nil
}

func (r *homepageRepository) GetDealByID(ctx context.Context, dealID primitive.ObjectID) (*models.DealOfDay, error) {
	var deal models.DealOfDay
	err := r.dealCollection.FindOne(ctx, bson.M{"_id": dealID}).Decode(&deal)

	if err == mongo.ErrNoDocuments {
		return nil, fmt.Errorf("deal not found")
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get deal: %w", err)
	}

	return &deal, nil
}

func (r *homepageRepository) UpdateDealOfDay(ctx context.Context, deal *models.DealOfDay) error {
	deal.UpdatedAt = time.Now()

	filter := bson.M{"_id": deal.ID}
	update := bson.M{"$set": deal}

	_, err := r.dealCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to update deal: %w", err)
	}

	return nil
}

func (r *homepageRepository) IncrementDealSold(ctx context.Context, dealID primitive.ObjectID) error {
	filter := bson.M{"_id": dealID}
	update := bson.M{
		"$inc": bson.M{"soldCount": 1},
		"$set": bson.M{"updatedAt": time.Now()},
	}

	_, err := r.dealCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to increment deal sold count: %w", err)
	}

	return nil
}

// Flash Sales

func (r *homepageRepository) CreateFlashSale(ctx context.Context, sale *models.FlashSale) error {
	sale.ID = primitive.NewObjectID()
	sale.CreatedAt = time.Now()
	sale.UpdatedAt = time.Now()

	_, err := r.flashSaleCollection.InsertOne(ctx, sale)
	if err != nil {
		return fmt.Errorf("failed to create flash sale: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetActiveFlashSales(ctx context.Context) ([]models.FlashSale, error) {
	now := time.Now()
	filter := bson.M{
		"isActive":  true,
		"startTime": bson.M{"$lte": now},
		"endTime":   bson.M{"$gte": now},
	}

	cursor, err := r.flashSaleCollection.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "startTime", Value: -1}}))
	if err != nil {
		return nil, fmt.Errorf("failed to get active flash sales: %w", err)
	}
	defer cursor.Close(ctx)

	var sales []models.FlashSale
	if err := cursor.All(ctx, &sales); err != nil {
		return nil, fmt.Errorf("failed to decode flash sales: %w", err)
	}

	return sales, nil
}

func (r *homepageRepository) GetFlashSaleByID(ctx context.Context, saleID primitive.ObjectID) (*models.FlashSale, error) {
	var sale models.FlashSale
	err := r.flashSaleCollection.FindOne(ctx, bson.M{"_id": saleID}).Decode(&sale)

	if err == mongo.ErrNoDocuments {
		return nil, fmt.Errorf("flash sale not found")
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get flash sale: %w", err)
	}

	return &sale, nil
}

func (r *homepageRepository) UpdateFlashSale(ctx context.Context, sale *models.FlashSale) error {
	sale.UpdatedAt = time.Now()

	filter := bson.M{"_id": sale.ID}
	update := bson.M{"$set": sale}

	_, err := r.flashSaleCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to update flash sale: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetAllFlashSales(ctx context.Context) ([]models.FlashSale, error) {
	cursor, err := r.flashSaleCollection.Find(ctx, bson.M{}, options.Find().SetSort(bson.D{{Key: "startTime", Value: -1}}))
	if err != nil {
		return nil, fmt.Errorf("failed to get flash sales: %w", err)
	}
	defer cursor.Close(ctx)

	var sales []models.FlashSale
	if err := cursor.All(ctx, &sales); err != nil {
		return nil, fmt.Errorf("failed to decode flash sales: %w", err)
	}

	return sales, nil
}

func (r *homepageRepository) DeleteFlashSale(ctx context.Context, saleID string) error {
	objectID, err := primitive.ObjectIDFromHex(saleID)
	if err != nil {
		return fmt.Errorf("invalid flash sale ID: %w", err)
	}

	result, err := r.flashSaleCollection.DeleteOne(ctx, bson.M{"_id": objectID})
	if err != nil {
		return fmt.Errorf("failed to delete flash sale: %w", err)
	}

	if result.DeletedCount == 0 {
		return fmt.Errorf("flash sale not found")
	}

	return nil
}

// Brands

func (r *homepageRepository) CreateBrand(ctx context.Context, brand *models.Brand) error {
	brand.ID = primitive.NewObjectID()
	brand.CreatedAt = time.Now()
	brand.UpdatedAt = time.Now()

	_, err := r.brandCollection.InsertOne(ctx, brand)
	if err != nil {
		return fmt.Errorf("failed to create brand: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetActiveBrands(ctx context.Context) ([]models.Brand, error) {
	filter := bson.M{"isActive": true}
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})

	cursor, err := r.brandCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get active brands: %w", err)
	}
	defer cursor.Close(ctx)

	var brands []models.Brand
	if err := cursor.All(ctx, &brands); err != nil {
		return nil, fmt.Errorf("failed to decode brands: %w", err)
	}

	return brands, nil
}

func (r *homepageRepository) GetBrandByID(ctx context.Context, brandID primitive.ObjectID) (*models.Brand, error) {
	var brand models.Brand
	err := r.brandCollection.FindOne(ctx, bson.M{"_id": brandID}).Decode(&brand)

	if err == mongo.ErrNoDocuments {
		return nil, fmt.Errorf("brand not found")
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get brand: %w", err)
	}

	return &brand, nil
}

func (r *homepageRepository) UpdateBrand(ctx context.Context, brand *models.Brand) error {
	brand.UpdatedAt = time.Now()

	filter := bson.M{"_id": brand.ID}
	update := bson.M{"$set": brand}

	_, err := r.brandCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to update brand: %w", err)
	}

	return nil
}

func (r *homepageRepository) DeleteBrand(ctx context.Context, brandID primitive.ObjectID) error {
	_, err := r.brandCollection.DeleteOne(ctx, bson.M{"_id": brandID})
	if err != nil {
		return fmt.Errorf("failed to delete brand: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetAllBrands(ctx context.Context) ([]models.Brand, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})

	cursor, err := r.brandCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get brands: %w", err)
	}
	defer cursor.Close(ctx)

	var brands []models.Brand
	if err := cursor.All(ctx, &brands); err != nil {
		return nil, fmt.Errorf("failed to decode brands: %w", err)
	}

	return brands, nil
}

// Recently Viewed

func (r *homepageRepository) TrackProductView(ctx context.Context, userID *primitive.ObjectID, sessionID *string, productID primitive.ObjectID) error {
	filter := bson.M{}
	if userID != nil {
		filter["userId"] = userID
	} else if sessionID != nil {
		filter["sessionId"] = sessionID
	} else {
		return fmt.Errorf("either userID or sessionID must be provided")
	}

	// Add product to the beginning of the array and limit to last 20 items
	update := bson.M{
		"$push": bson.M{
			"productIds": bson.M{
				"$each":     []primitive.ObjectID{productID},
				"$position": 0,
				"$slice":    20, // Keep only last 20 items
			},
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
		"$setOnInsert": bson.M{
			"userId":    userID,
			"sessionId": sessionID,
		},
	}

	opts := options.Update().SetUpsert(true)
	_, err := r.recentlyViewedCollection.UpdateOne(ctx, filter, update, opts)
	if err != nil {
		return fmt.Errorf("failed to track product view: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetRecentlyViewed(ctx context.Context, userID *primitive.ObjectID, sessionID *string, limit int) ([]primitive.ObjectID, error) {
	filter := bson.M{}
	if userID != nil {
		filter["userId"] = userID
	} else if sessionID != nil {
		filter["sessionId"] = sessionID
	} else {
		return nil, nil
	}

	var recentlyViewed models.RecentlyViewed
	err := r.recentlyViewedCollection.FindOne(ctx, filter).Decode(&recentlyViewed)

	if err == mongo.ErrNoDocuments {
		return []primitive.ObjectID{}, nil
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get recently viewed: %w", err)
	}

	// Return only requested number of items
	if limit > 0 && limit < len(recentlyViewed.ProductIDs) {
		return recentlyViewed.ProductIDs[:limit], nil
	}

	return recentlyViewed.ProductIDs, nil
}

// 360° Showcase

func (r *homepageRepository) CreateShowcase(ctx context.Context, showcase *models.Showcase360) error {
	showcase.ID = primitive.NewObjectID()
	showcase.CreatedAt = time.Now()
	showcase.UpdatedAt = time.Now()

	_, err := r.showcase360Collection.InsertOne(ctx, showcase)
	if err != nil {
		return fmt.Errorf("failed to create showcase 360: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetActiveShowcases(ctx context.Context) ([]models.Showcase360, error) {
	filter := bson.M{"isActive": true}

	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: -1}})
	cursor, err := r.showcase360Collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get active showcases: %w", err)
	}
	defer cursor.Close(ctx)

	var showcases []models.Showcase360
	if err := cursor.All(ctx, &showcases); err != nil {
		return nil, fmt.Errorf("failed to decode showcases: %w", err)
	}

	// Filter in code for better control with date logic
	var activeShowcases []models.Showcase360
	for _, s := range showcases {
		if s.IsLive() {
			activeShowcases = append(activeShowcases, s)
		}
	}

	return activeShowcases, nil
}

func (r *homepageRepository) GetAllShowcases(ctx context.Context) ([]models.Showcase360, error) {
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := r.showcase360Collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get all showcases: %w", err)
	}
	defer cursor.Close(ctx)

	var showcases []models.Showcase360
	if err := cursor.All(ctx, &showcases); err != nil {
		return nil, fmt.Errorf("failed to decode showcases: %w", err)
	}

	return showcases, nil
}

func (r *homepageRepository) GetShowcaseByID(ctx context.Context, showcaseID primitive.ObjectID) (*models.Showcase360, error) {
	var showcase models.Showcase360
	err := r.showcase360Collection.FindOne(ctx, bson.M{"_id": showcaseID}).Decode(&showcase)

	if err == mongo.ErrNoDocuments {
		return nil, fmt.Errorf("showcase not found")
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get showcase: %w", err)
	}

	return &showcase, nil
}

func (r *homepageRepository) UpdateShowcase(ctx context.Context, showcase *models.Showcase360) error {
	showcase.UpdatedAt = time.Now()

	filter := bson.M{"_id": showcase.ID}
	update := bson.M{"$set": showcase}

	_, err := r.showcase360Collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to update showcase: %w", err)
	}

	return nil
}

func (r *homepageRepository) DeleteShowcase(ctx context.Context, showcaseID primitive.ObjectID) error {
	_, err := r.showcase360Collection.DeleteOne(ctx, bson.M{"_id": showcaseID})
	if err != nil {
		return fmt.Errorf("failed to delete showcase: %w", err)
	}

	return nil
}

// Bundle Deals

func (r *homepageRepository) CreateBundleDeal(ctx context.Context, bundle *models.BundleDeal) error {
	bundle.ID = primitive.NewObjectID()
	bundle.CreatedAt = time.Now()
	bundle.UpdatedAt = time.Now()

	_, err := r.bundleDealCollection.InsertOne(ctx, bundle)
	if err != nil {
		return fmt.Errorf("failed to create bundle deal: %w", err)
	}

	return nil
}

func (r *homepageRepository) GetActiveBundleDeals(ctx context.Context) ([]models.BundleDeal, error) {
	now := time.Now()
	filter := bson.M{
		"isActive": true,
		"$expr":    bson.M{"$lt": bson.A{"$soldCount", "$stock"}},
	}

	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: 1}})
	cursor, err := r.bundleDealCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get active bundle deals: %w", err)
	}
	defer cursor.Close(ctx)

	var bundles []models.BundleDeal
	if err := cursor.All(ctx, &bundles); err != nil {
		return nil, fmt.Errorf("failed to decode bundle deals: %w", err)
	}

	// Filter for currently active deals
	var activeBundles []models.BundleDeal
	for _, b := range bundles {
		if b.StartTime == nil || !now.Before(*b.StartTime) {
			if b.EndTime == nil || !now.After(*b.EndTime) {
				activeBundles = append(activeBundles, b)
			}
		}
	}

	return activeBundles, nil
}

func (r *homepageRepository) GetBundleDealByID(ctx context.Context, bundleID primitive.ObjectID) (*models.BundleDeal, error) {
	var bundle models.BundleDeal
	err := r.bundleDealCollection.FindOne(ctx, bson.M{"_id": bundleID}).Decode(&bundle)

	if err == mongo.ErrNoDocuments {
		return nil, fmt.Errorf("bundle deal not found")
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get bundle deal: %w", err)
	}

	return &bundle, nil
}

func (r *homepageRepository) UpdateBundleDeal(ctx context.Context, bundle *models.BundleDeal) error {
	bundle.UpdatedAt = time.Now()

	filter := bson.M{"_id": bundle.ID}
	update := bson.M{"$set": bundle}

	_, err := r.bundleDealCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to update bundle deal: %w", err)
	}

	return nil
}

func (r *homepageRepository) DeleteBundleDeal(ctx context.Context, bundleID primitive.ObjectID) error {
	_, err := r.bundleDealCollection.DeleteOne(ctx, bson.M{"_id": bundleID})
	if err != nil {
		return fmt.Errorf("failed to delete bundle deal: %w", err)
	}

	return nil
}

func (r *homepageRepository) IncrementBundleSold(ctx context.Context, bundleID primitive.ObjectID) error {
	filter := bson.M{"_id": bundleID}
	update := bson.M{
		"$inc": bson.M{"soldCount": 1},
		"$set": bson.M{"updatedAt": time.Now()},
	}

	_, err := r.bundleDealCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to increment bundle sold count: %w", err)
	}

	return nil
}
