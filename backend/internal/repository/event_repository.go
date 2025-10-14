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

// EventRepository handles event-related database operations
type EventRepository struct {
	eventsCollection     *mongo.Collection
	bannersCollection    *mongo.Collection
	themesCollection     *mongo.Collection
	promotionsCollection *mongo.Collection
}

// NewEventRepository creates a new event repository
func NewEventRepository(db *mongo.Database) *EventRepository {
	return &EventRepository{
		eventsCollection:     db.Collection("events"),
		bannersCollection:    db.Collection("banners"),
		themesCollection:     db.Collection("themes"),
		promotionsCollection: db.Collection("event_promotions"),
	}
}

// Event operations

// CreateEvent creates a new event
func (r *EventRepository) CreateEvent(ctx context.Context, event *models.Event) error {
	event.ID = primitive.NewObjectID()
	event.CreatedAt = time.Now()
	event.UpdatedAt = time.Now()

	_, err := r.eventsCollection.InsertOne(ctx, event)
	return err
}

// GetEventByID gets an event by ID
func (r *EventRepository) GetEventByID(ctx context.Context, id primitive.ObjectID) (*models.Event, error) {
	var event models.Event
	err := r.eventsCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&event)
	if err != nil {
		return nil, err
	}
	return &event, nil
}

// GetAllEvents gets all events
func (r *EventRepository) GetAllEvents(ctx context.Context, activeOnly bool) ([]models.Event, error) {
	filter := bson.M{}
	if activeOnly {
		filter["isActive"] = true
	}

	opts := options.Find().SetSort(bson.D{{Key: "date", Value: 1}})
	cursor, err := r.eventsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var events []models.Event
	if err := cursor.All(ctx, &events); err != nil {
		return nil, err
	}

	return events, nil
}

// GetUpcomingEvents gets upcoming events
func (r *EventRepository) GetUpcomingEvents(ctx context.Context, limit int) ([]models.Event, error) {
	filter := bson.M{
		"isActive": true,
		"date":     bson.M{"$gte": time.Now()},
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "date", Value: 1}}).
		SetLimit(int64(limit))

	cursor, err := r.eventsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var events []models.Event
	if err := cursor.All(ctx, &events); err != nil {
		return nil, err
	}

	return events, nil
}

// UpdateEvent updates an event
func (r *EventRepository) UpdateEvent(ctx context.Context, id primitive.ObjectID, event *models.Event) error {
	event.UpdatedAt = time.Now()
	
	update := bson.M{
		"$set": event,
	}

	_, err := r.eventsCollection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// DeleteEvent deletes an event
func (r *EventRepository) DeleteEvent(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.eventsCollection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// Banner operations

// CreateBanner creates a new banner
func (r *EventRepository) CreateBanner(ctx context.Context, banner *models.Banner) error {
	banner.ID = primitive.NewObjectID()
	banner.CreatedAt = time.Now()
	banner.UpdatedAt = time.Now()

	_, err := r.bannersCollection.InsertOne(ctx, banner)
	return err
}

// GetBannerByID gets a banner by ID
func (r *EventRepository) GetBannerByID(ctx context.Context, id primitive.ObjectID) (*models.Banner, error) {
	var banner models.Banner
	err := r.bannersCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&banner)
	if err != nil {
		return nil, err
	}
	return &banner, nil
}

// GetAllBanners gets all banners
func (r *EventRepository) GetAllBanners(ctx context.Context) ([]models.Banner, error) {
	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: -1}, {Key: "createdAt", Value: -1}})
	cursor, err := r.bannersCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var banners []models.Banner
	if err := cursor.All(ctx, &banners); err != nil {
		return nil, err
	}

	return banners, nil
}

// GetActiveBanners gets currently active banners
func (r *EventRepository) GetActiveBanners(ctx context.Context) ([]models.Banner, error) {
	now := time.Now()
	filter := bson.M{
		"isActive":  true,
		"startDate": bson.M{"$lte": now},
		"$or": []bson.M{
			{"endDate": bson.M{"$gte": now}},
			{"endDate": nil},
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: -1}})
	cursor, err := r.bannersCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var banners []models.Banner
	if err := cursor.All(ctx, &banners); err != nil {
		return nil, err
	}

	return banners, nil
}

// GetBannersByFestival gets banners for a specific festival
func (r *EventRepository) GetBannersByFestival(ctx context.Context, festivalTag string) ([]models.Banner, error) {
	filter := bson.M{
		"festivalTag": festivalTag,
		"isActive":    true,
	}

	opts := options.Find().SetSort(bson.D{{Key: "priority", Value: -1}})
	cursor, err := r.bannersCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var banners []models.Banner
	if err := cursor.All(ctx, &banners); err != nil {
		return nil, err
	}

	return banners, nil
}

// UpdateBanner updates a banner
func (r *EventRepository) UpdateBanner(ctx context.Context, id primitive.ObjectID, banner *models.Banner) error {
	banner.UpdatedAt = time.Now()
	
	update := bson.M{
		"$set": banner,
	}

	_, err := r.bannersCollection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// DeleteBanner deletes a banner
func (r *EventRepository) DeleteBanner(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.bannersCollection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// Theme operations

// CreateTheme creates a new theme configuration
func (r *EventRepository) CreateTheme(ctx context.Context, theme *models.ThemeConfiguration) error {
	theme.ID = primitive.NewObjectID()
	theme.CreatedAt = time.Now()
	theme.UpdatedAt = time.Now()

	_, err := r.themesCollection.InsertOne(ctx, theme)
	return err
}

// GetThemeByID gets a theme by ID
func (r *EventRepository) GetThemeByID(ctx context.Context, id primitive.ObjectID) (*models.ThemeConfiguration, error) {
	var theme models.ThemeConfiguration
	err := r.themesCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&theme)
	if err != nil {
		return nil, err
	}
	return &theme, nil
}

// GetActiveTheme gets the currently active theme
func (r *EventRepository) GetActiveTheme(ctx context.Context) (*models.ThemeConfiguration, error) {
	var theme models.ThemeConfiguration
	err := r.themesCollection.FindOne(ctx, bson.M{"isActive": true}).Decode(&theme)
	if err != nil {
		return nil, err
	}
	return &theme, nil
}

// GetAllThemes gets all themes
func (r *EventRepository) GetAllThemes(ctx context.Context) ([]models.ThemeConfiguration, error) {
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := r.themesCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var themes []models.ThemeConfiguration
	if err := cursor.All(ctx, &themes); err != nil {
		return nil, err
	}

	return themes, nil
}

// GetThemeByName gets a theme by its name
func (r *EventRepository) GetThemeByName(ctx context.Context, name string) (*models.ThemeConfiguration, error) {
	var theme models.ThemeConfiguration
	err := r.themesCollection.FindOne(ctx, bson.M{"name": name}).Decode(&theme)
	if err != nil {
		return nil, err
	}
	return &theme, nil
}

// ActivateTheme activates a theme and deactivates all others
func (r *EventRepository) ActivateTheme(ctx context.Context, id primitive.ObjectID) error {
	// Deactivate all themes first
	_, err := r.themesCollection.UpdateMany(
		ctx,
		bson.M{},
		bson.M{"$set": bson.M{"isActive": false, "updatedAt": time.Now()}},
	)
	if err != nil {
		return err
	}

	// Activate the specified theme
	_, err = r.themesCollection.UpdateOne(
		ctx,
		bson.M{"_id": id},
		bson.M{"$set": bson.M{"isActive": true, "updatedAt": time.Now()}},
	)
	
	return err
}

// UpdateTheme updates a theme
func (r *EventRepository) UpdateTheme(ctx context.Context, id primitive.ObjectID, theme *models.ThemeConfiguration) error {
	theme.UpdatedAt = time.Now()
	
	update := bson.M{
		"$set": theme,
	}

	_, err := r.themesCollection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// DeleteTheme deletes a theme
func (r *EventRepository) DeleteTheme(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.themesCollection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// Promotion operations

// CreatePromotion creates a new event promotion
func (r *EventRepository) CreatePromotion(ctx context.Context, promotion *models.EventPromotion) error {
	promotion.ID = primitive.NewObjectID()
	promotion.CreatedAt = time.Now()
	promotion.UpdatedAt = time.Now()

	_, err := r.promotionsCollection.InsertOne(ctx, promotion)
	return err
}

// GetPromotionByID gets a promotion by ID
func (r *EventRepository) GetPromotionByID(ctx context.Context, id primitive.ObjectID) (*models.EventPromotion, error) {
	var promotion models.EventPromotion
	err := r.promotionsCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&promotion)
	if err != nil {
		return nil, err
	}
	return &promotion, nil
}

// GetActivePromotions gets currently active promotions
func (r *EventRepository) GetActivePromotions(ctx context.Context) ([]models.EventPromotion, error) {
	now := time.Now()
	filter := bson.M{
		"isActive":  true,
		"startDate": bson.M{"$lte": now},
		"endDate":   bson.M{"$gte": now},
	}

	cursor, err := r.promotionsCollection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var promotions []models.EventPromotion
	if err := cursor.All(ctx, &promotions); err != nil {
		return nil, err
	}

	return promotions, nil
}

// GetPromotionsByEvent gets promotions for a specific event
func (r *EventRepository) GetPromotionsByEvent(ctx context.Context, eventID primitive.ObjectID) ([]models.EventPromotion, error) {
	filter := bson.M{"eventId": eventID}

	cursor, err := r.promotionsCollection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var promotions []models.EventPromotion
	if err := cursor.All(ctx, &promotions); err != nil {
		return nil, err
	}

	return promotions, nil
}

// GetPopupPromotions gets promotions that should be shown as popups
func (r *EventRepository) GetPopupPromotions(ctx context.Context) ([]models.EventPromotion, error) {
	now := time.Now()
	filter := bson.M{
		"isActive":    true,
		"showAsPopup": true,
		"startDate":   bson.M{"$lte": now},
		"endDate":     bson.M{"$gte": now},
	}

	cursor, err := r.promotionsCollection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var promotions []models.EventPromotion
	if err := cursor.All(ctx, &promotions); err != nil {
		return nil, err
	}

	return promotions, nil
}

// UpdatePromotion updates a promotion
func (r *EventRepository) UpdatePromotion(ctx context.Context, id primitive.ObjectID, promotion *models.EventPromotion) error {
	promotion.UpdatedAt = time.Now()
	
	update := bson.M{
		"$set": promotion,
	}

	_, err := r.promotionsCollection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// DeletePromotion deletes a promotion
func (r *EventRepository) DeletePromotion(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.promotionsCollection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

