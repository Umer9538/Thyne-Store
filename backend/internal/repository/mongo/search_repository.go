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

type searchRepository struct {
	popularCollection       *mongo.Collection
	analyticsCollection     *mongo.Collection
	synonymCollection       *mongo.Collection
	configCollection        *mongo.Collection
	personalizationCollection *mongo.Collection
	cacheCollection         *mongo.Collection
}

// NewSearchRepository creates a new search repository
func NewSearchRepository(db *mongo.Database) repository.SearchRepository {
	return &searchRepository{
		popularCollection:       db.Collection("popular_searches"),
		analyticsCollection:     db.Collection("search_analytics"),
		synonymCollection:       db.Collection("search_synonyms"),
		configCollection:        db.Collection("search_config"),
		personalizationCollection: db.Collection("search_personalization"),
		cacheCollection:         db.Collection("search_cache"),
	}
}

func (r *searchRepository) GetPopularSearches(ctx context.Context, category string, limit int) ([]models.PopularSearch, error) {
	filter := bson.M{}
	if category != "" {
		filter["category"] = category
	}

	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"count": -1})

	cursor, err := r.popularCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find popular searches: %w", err)
	}
	defer cursor.Close(ctx)

	var searches []models.PopularSearch
	if err = cursor.All(ctx, &searches); err != nil {
		return nil, fmt.Errorf("failed to decode popular searches: %w", err)
	}

	return searches, nil
}

func (r *searchRepository) GetTrendingSearches(ctx context.Context, period string, limit int) ([]models.TrendingSearch, error) {
	// Calculate date range based on period
	var startDate time.Time
	now := time.Now()

	switch period {
	case "daily":
		startDate = now.AddDate(0, 0, -1)
	case "weekly":
		startDate = now.AddDate(0, 0, -7)
	case "monthly":
		startDate = now.AddDate(0, -1, 0)
	default:
		startDate = now.AddDate(0, 0, -1)
	}

	// Aggregate trending searches
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"timestamp": bson.M{"$gte": startDate},
			},
		},
		{
			"$group": bson.M{
				"_id":      "$query",
				"count":    bson.M{"$sum": 1},
				"category": bson.M{"$first": "$category"},
			},
		},
		{
			"$sort": bson.M{"count": -1},
		},
		{
			"$limit": limit,
		},
	}

	cursor, err := r.analyticsCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get trending searches: %w", err)
	}
	defer cursor.Close(ctx)

	var trending []models.TrendingSearch
	for cursor.Next(ctx) {
		var result struct {
			Query    string `bson:"_id"`
			Count    int64  `bson:"count"`
			Category string `bson:"category"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}

		trending = append(trending, models.TrendingSearch{
			Query:     result.Query,
			Count:     result.Count,
			Growth:    0, // Calculate growth based on comparison
			Category:  result.Category,
			Period:    period,
			Timestamp: time.Now(),
		})
	}

	return trending, nil
}

func (r *searchRepository) UpdatePopularSearch(ctx context.Context, query, category string) error {
	filter := bson.M{"query": query}
	if category != "" {
		filter["category"] = category
	}

	update := bson.M{
		"$inc": bson.M{"count": 1},
		"$set": bson.M{"updatedAt": time.Now()},
		"$setOnInsert": bson.M{
			"_id":       primitive.NewObjectID(),
			"query":     query,
			"category":  category,
		},
	}

	opts := options.Update().SetUpsert(true)
	_, err := r.popularCollection.UpdateOne(ctx, filter, update, opts)
	if err != nil {
		return fmt.Errorf("failed to update popular search: %w", err)
	}

	return nil
}

func (r *searchRepository) RecordSearchAnalytics(ctx context.Context, analytics *models.SearchAnalytics) error {
	analytics.ID = primitive.NewObjectID()
	analytics.Timestamp = time.Now()

	_, err := r.analyticsCollection.InsertOne(ctx, analytics)
	if err != nil {
		return fmt.Errorf("failed to record search analytics: %w", err)
	}

	return nil
}

func (r *searchRepository) GetSearchAnalytics(ctx context.Context, startDate, endDate time.Time) ([]models.SearchAnalytics, error) {
	filter := bson.M{
		"timestamp": bson.M{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	opts := options.Find().SetSort(bson.M{"timestamp": -1})

	cursor, err := r.analyticsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find search analytics: %w", err)
	}
	defer cursor.Close(ctx)

	var analytics []models.SearchAnalytics
	if err = cursor.All(ctx, &analytics); err != nil {
		return nil, fmt.Errorf("failed to decode search analytics: %w", err)
	}

	return analytics, nil
}

func (r *searchRepository) CreateSynonym(ctx context.Context, synonym *models.SearchSynonym) error {
	synonym.ID = primitive.NewObjectID()
	synonym.CreatedAt = time.Now()
	synonym.UpdatedAt = time.Now()

	_, err := r.synonymCollection.InsertOne(ctx, synonym)
	if err != nil {
		return fmt.Errorf("failed to create synonym: %w", err)
	}

	return nil
}

func (r *searchRepository) GetSynonyms(ctx context.Context, term string) ([]string, error) {
	filter := bson.M{
		"term":     term,
		"isActive": true,
	}

	var synonym models.SearchSynonym
	err := r.synonymCollection.FindOne(ctx, filter).Decode(&synonym)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return []string{}, nil
		}
		return nil, fmt.Errorf("failed to get synonyms: %w", err)
	}

	return synonym.Synonyms, nil
}

func (r *searchRepository) UpdateSearchConfig(ctx context.Context, config *models.SearchConfig) error {
	config.UpdatedAt = time.Now()
	if config.ID.IsZero() {
		config.ID = primitive.NewObjectID()
		config.CreatedAt = time.Now()
	}

	opts := options.Replace().SetUpsert(true)
	_, err := r.configCollection.ReplaceOne(ctx, bson.M{}, config, opts)
	if err != nil {
		return fmt.Errorf("failed to update search config: %w", err)
	}

	return nil
}

func (r *searchRepository) GetSearchConfig(ctx context.Context) (*models.SearchConfig, error) {
	var config models.SearchConfig
	err := r.configCollection.FindOne(ctx, bson.M{}).Decode(&config)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Return default config
			defaultConfig := models.GetDefaultSearchConfig()
			if createErr := r.UpdateSearchConfig(ctx, defaultConfig); createErr != nil {
				return nil, fmt.Errorf("failed to create default config: %w", createErr)
			}
			return defaultConfig, nil
		}
		return nil, fmt.Errorf("failed to get search config: %w", err)
	}
	return &config, nil
}

func (r *searchRepository) GetPersonalization(ctx context.Context, userID primitive.ObjectID) (*models.SearchPersonalization, error) {
	var personalization models.SearchPersonalization
	err := r.personalizationCollection.FindOne(ctx, bson.M{"userId": userID}).Decode(&personalization)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("personalization not found")
		}
		return nil, fmt.Errorf("failed to get personalization: %w", err)
	}
	return &personalization, nil
}

func (r *searchRepository) UpdatePersonalization(ctx context.Context, personalization *models.SearchPersonalization) error {
	personalization.UpdatedAt = time.Now()
	if personalization.ID.IsZero() {
		personalization.ID = primitive.NewObjectID()
		personalization.CreatedAt = time.Now()
	}

	opts := options.Replace().SetUpsert(true)
	_, err := r.personalizationCollection.ReplaceOne(
		ctx,
		bson.M{"userId": personalization.UserID},
		personalization,
		opts,
	)
	if err != nil {
		return fmt.Errorf("failed to update personalization: %w", err)
	}

	return nil
}

func (r *searchRepository) RecordProductClick(ctx context.Context, query string, productID primitive.ObjectID, userID *primitive.ObjectID) error {
	// Record click in analytics
	analytics := &models.SearchAnalytics{
		Query:         query,
		UserID:        userID,
		ClickedResults: []string{productID.Hex()},
		Timestamp:     time.Now(),
	}

	return r.RecordSearchAnalytics(ctx, analytics)
}

func (r *searchRepository) GetCategorySuggestions(ctx context.Context, query string, limit int) ([]models.CategorySuggestion, error) {
	// This would typically require a categories collection
	// For now, return empty slice
	return []models.CategorySuggestion{}, nil
}

// Facet methods - these would typically use aggregation pipelines
func (r *searchRepository) GetCategoryFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error) {
	// This would require access to products collection via aggregation
	// For now, return empty slice
	return []models.FacetItem{}, nil
}

func (r *searchRepository) GetBrandFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error) {
	return []models.FacetItem{}, nil
}

func (r *searchRepository) GetMetalTypeFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error) {
	return []models.FacetItem{}, nil
}

func (r *searchRepository) GetGemstoneTypeFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error) {
	return []models.FacetItem{}, nil
}

func (r *searchRepository) GetPriceRangeFacets(ctx context.Context, baseMatch interface{}) ([]models.PriceRange, error) {
	return []models.PriceRange{}, nil
}

func (r *searchRepository) GetPurityFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error) {
	return []models.FacetItem{}, nil
}

func (r *searchRepository) GetTagFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error) {
	return []models.FacetItem{}, nil
}

func (r *searchRepository) CacheResults(ctx context.Context, cache *models.SearchCache) error {
	cache.ID = primitive.NewObjectID()
	cache.CreatedAt = time.Now()

	_, err := r.cacheCollection.InsertOne(ctx, cache)
	if err != nil {
		return fmt.Errorf("failed to cache results: %w", err)
	}

	return nil
}

func (r *searchRepository) GetCachedResults(ctx context.Context, queryHash string) (*models.SearchCache, error) {
	var cache models.SearchCache
	err := r.cacheCollection.FindOne(ctx, bson.M{
		"queryHash": queryHash,
		"expiresAt": bson.M{"$gt": time.Now()},
	}).Decode(&cache)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("cache not found")
		}
		return nil, fmt.Errorf("failed to get cached results: %w", err)
	}
	return &cache, nil
}

func (r *searchRepository) UpdateCacheHit(ctx context.Context, queryHash string) error {
	_, err := r.cacheCollection.UpdateOne(
		ctx,
		bson.M{"queryHash": queryHash},
		bson.M{
			"$inc": bson.M{"hitCount": 1},
			"$set": bson.M{"lastHit": time.Now()},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to update cache hit: %w", err)
	}

	return nil
}