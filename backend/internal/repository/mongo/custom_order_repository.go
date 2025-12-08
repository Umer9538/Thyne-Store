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

type customOrderRepository struct {
	collection *mongo.Collection
}

// NewCustomOrderRepository creates a new MongoDB custom order repository
func NewCustomOrderRepository(db *mongo.Database) repository.CustomOrderRepository {
	return &customOrderRepository{
		collection: db.Collection("custom_orders"),
	}
}

// Create creates a new custom order
func (r *customOrderRepository) Create(ctx context.Context, order *models.CustomOrder) error {
	if order.ID.IsZero() {
		order.ID = primitive.NewObjectID()
	}
	if order.OrderNumber == "" {
		order.OrderNumber = generateCustomOrderNumber()
	}
	order.CreatedAt = time.Now()
	order.UpdatedAt = time.Now()
	if order.Status == "" {
		order.Status = models.CustomOrderStatusPendingContact
	}
	if order.PriceInfo.Currency == "" {
		order.PriceInfo.Currency = "INR"
	}

	_, err := r.collection.InsertOne(ctx, order)
	return err
}

// GetByID retrieves a custom order by ID
func (r *customOrderRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.CustomOrder, error) {
	var order models.CustomOrder
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&order)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("custom order not found")
		}
		return nil, err
	}
	return &order, nil
}

// GetByOrderNumber retrieves a custom order by order number
func (r *customOrderRepository) GetByOrderNumber(ctx context.Context, orderNumber string) (*models.CustomOrder, error) {
	var order models.CustomOrder
	err := r.collection.FindOne(ctx, bson.M{"orderNumber": orderNumber}).Decode(&order)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("custom order not found")
		}
		return nil, err
	}
	return &order, nil
}

// GetByUserID retrieves custom orders by user ID
func (r *customOrderRepository) GetByUserID(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.CustomOrder, int64, error) {
	filter := bson.M{"userId": userID}

	// Count total
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// Find with pagination
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetSkip(int64((page - 1) * limit)).
		SetLimit(int64(limit))

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var orders []models.CustomOrder
	if err := cursor.All(ctx, &orders); err != nil {
		return nil, 0, err
	}

	return orders, total, nil
}

// GetAll retrieves all custom orders with filters
func (r *customOrderRepository) GetAll(ctx context.Context, filter models.CustomOrderFilter) ([]models.CustomOrder, int64, error) {
	query := bson.M{}

	if filter.Status != nil {
		query["status"] = *filter.Status
	}
	if filter.UserID != nil {
		query["userId"] = *filter.UserID
	}
	if filter.DateFrom != nil || filter.DateTo != nil {
		dateFilter := bson.M{}
		if filter.DateFrom != nil {
			dateFilter["$gte"] = *filter.DateFrom
		}
		if filter.DateTo != nil {
			dateFilter["$lte"] = *filter.DateTo
		}
		query["createdAt"] = dateFilter
	}

	// Count total
	total, err := r.collection.CountDocuments(ctx, query)
	if err != nil {
		return nil, 0, err
	}

	// Set defaults
	page := filter.Page
	if page < 1 {
		page = 1
	}
	limit := filter.Limit
	if limit < 1 {
		limit = 20
	}

	// Find with pagination
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetSkip(int64((page - 1) * limit)).
		SetLimit(int64(limit))

	cursor, err := r.collection.Find(ctx, query, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var orders []models.CustomOrder
	if err := cursor.All(ctx, &orders); err != nil {
		return nil, 0, err
	}

	return orders, total, nil
}

// Update updates a custom order
func (r *customOrderRepository) Update(ctx context.Context, order *models.CustomOrder) error {
	order.UpdatedAt = time.Now()
	_, err := r.collection.ReplaceOne(ctx, bson.M{"_id": order.ID}, order)
	return err
}

// UpdateStatus updates only the status of a custom order
func (r *customOrderRepository) UpdateStatus(ctx context.Context, id primitive.ObjectID, status models.CustomOrderStatus) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": id},
		bson.M{
			"$set": bson.M{
				"status":    status,
				"updatedAt": time.Now(),
			},
		},
	)
	return err
}

// Delete deletes a custom order
func (r *customOrderRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// GetByStatus retrieves custom orders by status
func (r *customOrderRepository) GetByStatus(ctx context.Context, status models.CustomOrderStatus, page, limit int) ([]models.CustomOrder, int64, error) {
	filter := bson.M{"status": status}

	// Count total
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// Find with pagination
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetSkip(int64((page - 1) * limit)).
		SetLimit(int64(limit))

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var orders []models.CustomOrder
	if err := cursor.All(ctx, &orders); err != nil {
		return nil, 0, err
	}

	return orders, total, nil
}

// GetStatistics retrieves custom order statistics
func (r *customOrderRepository) GetStatistics(ctx context.Context) (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Total orders
	total, err := r.collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	stats["total"] = total

	// Count by status
	statuses := []models.CustomOrderStatus{
		models.CustomOrderStatusPendingContact,
		models.CustomOrderStatusContacted,
		models.CustomOrderStatusConfirmed,
		models.CustomOrderStatusProcessing,
		models.CustomOrderStatusShipped,
		models.CustomOrderStatusDelivered,
		models.CustomOrderStatusCancelled,
	}

	statusCounts := make(map[string]int64)
	for _, status := range statuses {
		count, err := r.collection.CountDocuments(ctx, bson.M{"status": status})
		if err != nil {
			return nil, err
		}
		statusCounts[string(status)] = count
	}
	stats["byStatus"] = statusCounts

	// Orders in last 7 days
	sevenDaysAgo := time.Now().AddDate(0, 0, -7)
	recentCount, err := r.collection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{"$gte": sevenDaysAgo},
	})
	if err != nil {
		return nil, err
	}
	stats["lastWeek"] = recentCount

	// Orders in last 30 days
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30)
	monthCount, err := r.collection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{"$gte": thirtyDaysAgo},
	})
	if err != nil {
		return nil, err
	}
	stats["lastMonth"] = monthCount

	return stats, nil
}

// generateCustomOrderNumber generates a unique order number for custom orders
func generateCustomOrderNumber() string {
	timestamp := time.Now().Format("20060102150405")
	return fmt.Sprintf("CUS-%s", timestamp)
}
