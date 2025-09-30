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

type orderRepository struct {
	collection *mongo.Collection
}

// NewOrderRepository creates a new order repository
func NewOrderRepository(db *mongo.Database) repository.OrderRepository {
	return &orderRepository{
		collection: db.Collection("orders"),
	}
}

func (r *orderRepository) Create(ctx context.Context, order *models.Order) error {
	order.ID = primitive.NewObjectID()
	order.CreatedAt = time.Now()
	order.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, order)
	if err != nil {
		return fmt.Errorf("failed to create order: %w", err)
	}

	return nil
}

func (r *orderRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Order, error) {
	var order models.Order
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&order)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("order not found")
		}
		return nil, fmt.Errorf("failed to get order by ID: %w", err)
	}
	return &order, nil
}

func (r *orderRepository) GetByOrderNumber(ctx context.Context, orderNumber string) (*models.Order, error) {
	var order models.Order
	err := r.collection.FindOne(ctx, bson.M{"orderNumber": orderNumber}).Decode(&order)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("order not found")
		}
		return nil, fmt.Errorf("failed to get order by number: %w", err)
	}
	return &order, nil
}

func (r *orderRepository) Update(ctx context.Context, order *models.Order) error {
	order.UpdatedAt = time.Now()

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": order.ID},
		bson.M{"$set": order},
	)
	if err != nil {
		return fmt.Errorf("failed to update order: %w", err)
	}

	return nil
}

func (r *orderRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete order: %w", err)
	}

	return nil
}

func (r *orderRepository) GetUserOrders(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Order, int64, error) {
	filter := bson.M{"userId": userID}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count user orders: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find orders
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find user orders: %w", err)
	}
	defer cursor.Close(ctx)

	var orders []models.Order
	if err = cursor.All(ctx, &orders); err != nil {
		return nil, 0, fmt.Errorf("failed to decode user orders: %w", err)
	}

	return orders, total, nil
}

func (r *orderRepository) List(ctx context.Context, page, limit int, filters map[string]interface{}) ([]models.Order, int64, error) {
	// Build filter
	filter := bson.M{}
	for key, value := range filters {
		switch key {
		case "status":
			filter["status"] = value
		case "paymentStatus":
			filter["paymentStatus"] = value
		case "paymentMethod":
			filter["paymentMethod"] = value
		case "dateFrom":
			if filter["createdAt"] == nil {
				filter["createdAt"] = bson.M{}
			}
			filter["createdAt"].(bson.M)["$gte"] = value
		case "dateTo":
			if filter["createdAt"] == nil {
				filter["createdAt"] = bson.M{}
			}
			filter["createdAt"].(bson.M)["$lte"] = value
		case "minAmount":
			if filter["total"] == nil {
				filter["total"] = bson.M{}
			}
			filter["total"].(bson.M)["$gte"] = value
		case "maxAmount":
			if filter["total"] == nil {
				filter["total"] = bson.M{}
			}
			filter["total"].(bson.M)["$lte"] = value
		case "userID":
			if userID, ok := value.(string); ok {
				if objID, err := primitive.ObjectIDFromHex(userID); err == nil {
					filter["userId"] = objID
				}
			}
		case "search":
			filter["$or"] = []bson.M{
				{"orderNumber": bson.M{"$regex": value, "$options": "i"}},
				{"customerName": bson.M{"$regex": value, "$options": "i"}},
				{"customerEmail": bson.M{"$regex": value, "$options": "i"}},
			}
		}
	}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count orders: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Build sort
	sort := bson.M{"createdAt": -1}
	if sortBy, exists := filters["sortBy"]; exists {
		switch sortBy {
		case "amount_asc":
			sort = bson.M{"total": 1}
		case "amount_desc":
			sort = bson.M{"total": -1}
		case "date_asc":
			sort = bson.M{"createdAt": 1}
		case "date_desc":
			sort = bson.M{"createdAt": -1}
		case "status":
			sort = bson.M{"status": 1, "createdAt": -1}
		}
	}

	// Find orders
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(sort)

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find orders: %w", err)
	}
	defer cursor.Close(ctx)

	var orders []models.Order
	if err = cursor.All(ctx, &orders); err != nil {
		return nil, 0, fmt.Errorf("failed to decode orders: %w", err)
	}

	return orders, total, nil
}

func (r *orderRepository) GetOrderStatistics(ctx context.Context) (*models.OrderStatistics, error) {
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

	// Total orders
	total, err := r.collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count total orders: %w", err)
	}

	// Orders by status
	ordersByStatus, err := r.getOrdersByStatus(ctx)
	if err != nil {
		ordersByStatus = make(map[string]int64)
	}

	// Today's orders and revenue
	todaysOrders, err := r.collection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{"$gte": today},
	})
	if err != nil {
		todaysOrders = 0
	}

	todaysRevenue, err := r.getTodaysRevenue(ctx, today)
	if err != nil {
		todaysRevenue = 0
	}

	// Monthly revenue
	monthlyRevenue, err := r.getMonthlyRevenue(ctx, monthStart)
	if err != nil {
		monthlyRevenue = 0
	}

	// Average order value
	avgOrderValue, err := r.getAverageOrderValue(ctx)
	if err != nil {
		avgOrderValue = 0
	}

	// Growth rates (simplified calculation)
	lastMonthStart := monthStart.AddDate(0, -1, 0)
	lastMonthEnd := monthStart.Add(-time.Second)
	lastMonthOrders, _ := r.collection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{
			"$gte": lastMonthStart,
			"$lte": lastMonthEnd,
		},
	})

	var orderGrowthRate float64
	if lastMonthOrders > 0 {
		currentMonthOrders := ordersByStatus["pending"] + ordersByStatus["processing"] + ordersByStatus["shipped"] + ordersByStatus["delivered"]
		orderGrowthRate = (float64(currentMonthOrders-lastMonthOrders) / float64(lastMonthOrders)) * 100
	}

	// Revenue by month for the last 12 months
	revenueByMonth, err := r.getRevenueByMonth(ctx, 12)
	if err != nil {
		revenueByMonth = []models.MonthlyRevenue{}
	}

	// Top payment methods
	topPaymentMethods, err := r.getTopPaymentMethods(ctx)
	if err != nil {
		topPaymentMethods = []models.PaymentMethodStats{}
	}

	return &models.OrderStatistics{
		TotalOrders:       total,
		PendingOrders:     ordersByStatus["pending"],
		CompletedOrders:   ordersByStatus["delivered"],
		CancelledOrders:   ordersByStatus["cancelled"],
		TodaysOrders:      todaysOrders,
		TodaysRevenue:     todaysRevenue,
		MonthlyRevenue:    monthlyRevenue,
		AverageOrderValue: avgOrderValue,
		OrderGrowthRate:   orderGrowthRate,
		RevenueGrowthRate: 0, // Calculate based on revenue comparison
		OrdersByStatus:    ordersByStatus,
		RevenueByMonth:    revenueByMonth,
		TopPaymentMethods: topPaymentMethods,
	}, nil
}

func (r *orderRepository) GetRecentOrders(ctx context.Context, limit int) ([]models.Order, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find recent orders: %w", err)
	}
	defer cursor.Close(ctx)

	var orders []models.Order
	if err = cursor.All(ctx, &orders); err != nil {
		return nil, fmt.Errorf("failed to decode recent orders: %w", err)
	}

	return orders, nil
}

func (r *orderRepository) ExportOrders(ctx context.Context, format string, startDate, endDate time.Time, filters map[string]interface{}) (string, error) {
	// Implementation would depend on your export service
	return fmt.Sprintf("orders_export_%s.%s", time.Now().Format("20060102"), format), nil
}

func (r *orderRepository) UpdateStatus(ctx context.Context, orderID primitive.ObjectID, status string) error {
	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": orderID},
		bson.M{
			"$set": bson.M{
				"status":    status,
				"updatedAt": time.Now(),
			},
		},
	)
	if err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}

	return nil
}

func (r *orderRepository) GetOrdersByStatus(ctx context.Context, status string, page, limit int) ([]models.Order, int64, error) {
	filter := bson.M{"status": status}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count orders by status: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find orders
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find orders by status: %w", err)
	}
	defer cursor.Close(ctx)

	var orders []models.Order
	if err = cursor.All(ctx, &orders); err != nil {
		return nil, 0, fmt.Errorf("failed to decode orders: %w", err)
	}

	return orders, total, nil
}

// Helper methods

func (r *orderRepository) getOrdersByStatus(ctx context.Context) (map[string]int64, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":   "$status",
				"count": bson.M{"$sum": 1},
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	ordersByStatus := make(map[string]int64)
	for cursor.Next(ctx) {
		var result struct {
			Status string `bson:"_id"`
			Count  int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		ordersByStatus[result.Status] = result.Count
	}

	return ordersByStatus, nil
}

func (r *orderRepository) getTodaysRevenue(ctx context.Context, today time.Time) (float64, error) {
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"createdAt": bson.M{"$gte": today},
				"status": bson.M{"$in": []string{"processing", "shipped", "delivered"}},
			},
		},
		{
			"$group": bson.M{
				"_id":     nil,
				"revenue": bson.M{"$sum": "$total"},
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)

	var result struct {
		Revenue float64 `bson:"revenue"`
	}

	if cursor.Next(ctx) {
		if err := cursor.Decode(&result); err != nil {
			return 0, err
		}
	}

	return result.Revenue, nil
}

func (r *orderRepository) getMonthlyRevenue(ctx context.Context, monthStart time.Time) (float64, error) {
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"createdAt": bson.M{"$gte": monthStart},
				"status": bson.M{"$in": []string{"processing", "shipped", "delivered"}},
			},
		},
		{
			"$group": bson.M{
				"_id":     nil,
				"revenue": bson.M{"$sum": "$total"},
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)

	var result struct {
		Revenue float64 `bson:"revenue"`
	}

	if cursor.Next(ctx) {
		if err := cursor.Decode(&result); err != nil {
			return 0, err
		}
	}

	return result.Revenue, nil
}

func (r *orderRepository) getAverageOrderValue(ctx context.Context) (float64, error) {
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"status": bson.M{"$in": []string{"processing", "shipped", "delivered"}},
			},
		},
		{
			"$group": bson.M{
				"_id":        nil,
				"avgValue":   bson.M{"$avg": "$total"},
			},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)

	var result struct {
		AvgValue float64 `bson:"avgValue"`
	}

	if cursor.Next(ctx) {
		if err := cursor.Decode(&result); err != nil {
			return 0, err
		}
	}

	return result.AvgValue, nil
}

func (r *orderRepository) getRevenueByMonth(ctx context.Context, months int) ([]models.MonthlyRevenue, error) {
	startDate := time.Now().AddDate(0, -months, 0)

	pipeline := []bson.M{
		{
			"$match": bson.M{
				"createdAt": bson.M{"$gte": startDate},
				"status": bson.M{"$in": []string{"processing", "shipped", "delivered"}},
			},
		},
		{
			"$group": bson.M{
				"_id": bson.M{
					"$dateToString": bson.M{
						"format": "%Y-%m",
						"date":   "$createdAt",
					},
				},
				"revenue": bson.M{"$sum": "$total"},
				"orders":  bson.M{"$sum": 1},
			},
		},
		{
			"$sort": bson.M{"_id": 1},
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var revenueByMonth []models.MonthlyRevenue
	for cursor.Next(ctx) {
		var result struct {
			Month   string  `bson:"_id"`
			Revenue float64 `bson:"revenue"`
			Orders  int64   `bson:"orders"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		revenueByMonth = append(revenueByMonth, models.MonthlyRevenue{
			Month:   result.Month,
			Revenue: result.Revenue,
			Orders:  result.Orders,
		})
	}

	return revenueByMonth, nil
}

func (r *orderRepository) getTopPaymentMethods(ctx context.Context) ([]models.PaymentMethodStats, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":         "$paymentMethod",
				"count":       bson.M{"$sum": 1},
				"totalAmount": bson.M{"$sum": "$total"},
			},
		},
		{
			"$sort": bson.M{"count": -1},
		},
		{
			"$limit": 10,
		},
	}

	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	// Get total orders for percentage calculation
	totalOrders, _ := r.collection.CountDocuments(ctx, bson.M{})

	var paymentMethods []models.PaymentMethodStats
	for cursor.Next(ctx) {
		var result struct {
			Method      string  `bson:"_id"`
			Count       int64   `bson:"count"`
			TotalAmount float64 `bson:"totalAmount"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}

		percentage := float64(0)
		if totalOrders > 0 {
			percentage = (float64(result.Count) / float64(totalOrders)) * 100
		}

		paymentMethods = append(paymentMethods, models.PaymentMethodStats{
			Method:      result.Method,
			Count:       result.Count,
			Percentage:  percentage,
			TotalAmount: result.TotalAmount,
		})
	}

	return paymentMethods, nil
}