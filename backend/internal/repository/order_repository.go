package repository

import (
	"context"
	"errors"
	"time"

	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)


type orderRepository struct {
	collection *mongo.Collection
}

func NewOrderRepository(db *mongo.Database) OrderRepository {
	return &orderRepository{
		collection: db.Collection("orders"),
	}
}

func (r *orderRepository) Create(ctx context.Context, order *models.Order) error {
	order.CreatedAt = time.Now()
	order.UpdatedAt = time.Now()
	
	_, err := r.collection.InsertOne(ctx, order)
	return err
}

func (r *orderRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Order, error) {
	var order models.Order
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&order)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("order not found")
		}
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) GetByOrderNumber(ctx context.Context, orderNumber string) (*models.Order, error) {
	var order models.Order
	err := r.collection.FindOne(ctx, bson.M{"orderNumber": orderNumber}).Decode(&order)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("order not found")
		}
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) GetByUserID(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Order, int64, error) {
	// Count total documents
	total, err := r.collection.CountDocuments(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, 0, err
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find orders with pagination
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var orders []models.Order
	if err = cursor.All(ctx, &orders); err != nil {
		return nil, 0, err
	}

	return orders, total, nil
}

func (r *orderRepository) GetByGuestSessionID(ctx context.Context, sessionID string, page, limit int) ([]models.Order, int64, error) {
	// Count total documents
	total, err := r.collection.CountDocuments(ctx, bson.M{"guestSessionId": sessionID})
	if err != nil {
		return nil, 0, err
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find orders with pagination
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, bson.M{"guestSessionId": sessionID}, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var orders []models.Order
	if err = cursor.All(ctx, &orders); err != nil {
		return nil, 0, err
	}

	return orders, total, nil
}

// GetAll lists orders for admin with optional status filter and pagination
func (r *orderRepository) GetAll(ctx context.Context, page, limit int, status *models.OrderStatus) ([]models.Order, int64, error) {
    filter := bson.M{}
    if status != nil {
        filter["status"] = *status
    }

    total, err := r.collection.CountDocuments(ctx, filter)
    if err != nil {
        return nil, 0, err
    }

    skip := (page - 1) * limit
    opts := options.Find().
        SetSkip(int64(skip)).
        SetLimit(int64(limit)).
        SetSort(bson.M{"createdAt": -1})

    cursor, err := r.collection.Find(ctx, filter, opts)
    if err != nil {
        return nil, 0, err
    }
    defer cursor.Close(ctx)

    var orders []models.Order
    if err = cursor.All(ctx, &orders); err != nil {
        return nil, 0, err
    }

    return orders, total, nil
}

func (r *orderRepository) Update(ctx context.Context, order *models.Order) error {
	order.UpdatedAt = time.Now()
	
	filter := bson.M{"_id": order.ID}
	update := bson.M{
		"$set": bson.M{
			"items":              order.Items,
			"shippingAddress":    order.ShippingAddress,
			"paymentMethod":      order.PaymentMethod,
			"paymentStatus":      order.PaymentStatus,
			"razorpayOrderId":    order.RazorpayOrderID,
			"razorpayPaymentId":  order.RazorpayPaymentID,
			"status":             order.Status,
			"subtotal":           order.Subtotal,
			"tax":                order.Tax,
			"shipping":           order.Shipping,
			"discount":           order.Discount,
			"total":              order.Total,
			"trackingNumber":     order.TrackingNumber,
			"deliveredAt":        order.DeliveredAt,
			"processedAt":        order.ProcessedAt,
			"shippedAt":          order.ShippedAt,
			"cancellationReason": order.CancellationReason,
			"returnReason":       order.ReturnReason,
			"refundStatus":       order.RefundStatus,
			"refundAmount":       order.RefundAmount,
			"refundedAt":         order.RefundedAt,
			"updatedAt":          order.UpdatedAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *orderRepository) UpdateStatus(ctx context.Context, id primitive.ObjectID, status models.OrderStatus) error {
	filter := bson.M{"_id": id}
	update := bson.M{
		"$set": bson.M{
			"status":    status,
			"updatedAt": time.Now(),
		},
	}

	if status == models.OrderStatusDelivered {
		update["$set"].(bson.M)["deliveredAt"] = time.Now()
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *orderRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}
	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}

func (r *orderRepository) ExportOrders(ctx context.Context, format string, startDate, endDate time.Time, filters map[string]interface{}) (string, error) {
	// Placeholder implementation - would generate export file
	return "", errors.New("export orders not implemented")
}
