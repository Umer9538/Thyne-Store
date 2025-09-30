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

type adminRepository struct {
	userCollection         *mongo.Collection
	orderCollection        *mongo.Collection
	productCollection      *mongo.Collection
	reviewCollection       *mongo.Collection
	loyaltyCollection      *mongo.Collection
	notificationCollection *mongo.Collection
	storeCfgCollection     *mongo.Collection
	voucherCollection      *mongo.Collection
}

// NewAdminRepository creates a new admin repository
func NewAdminRepository(db *mongo.Database) repository.AdminRepository {
	return &adminRepository{
		userCollection:         db.Collection("users"),
		orderCollection:        db.Collection("orders"),
		productCollection:      db.Collection("products"),
		reviewCollection:       db.Collection("reviews"),
		loyaltyCollection:      db.Collection("loyalty_members"),
		notificationCollection: db.Collection("notifications"),
		storeCfgCollection:     db.Collection("storefront_configs"),
		voucherCollection:      db.Collection("vouchers"),
	}
}

func (r *adminRepository) GetDashboardStats(ctx context.Context) (*models.DashboardStats, error) {
	stats := &models.DashboardStats{}

	// Get total users
	totalUsers, err := r.userCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count users: %w", err)
	}
	stats.TotalUsers = totalUsers

	// Get new users this month
	startOfMonth := time.Now().AddDate(0, 0, -time.Now().Day()+1)
	newUsers, err := r.userCollection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{"$gte": startOfMonth},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count new users: %w", err)
	}
	stats.NewUsers = newUsers

	// Get total orders
	totalOrders, err := r.orderCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count orders: %w", err)
	}
	stats.TotalOrders = totalOrders

	// Get pending orders
	pendingOrders, err := r.orderCollection.CountDocuments(ctx, bson.M{
		"status": "pending",
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count pending orders: %w", err)
	}
	stats.PendingOrders = pendingOrders

	// Get total revenue
	revenuePipeline := []bson.M{
		{"$match": bson.M{"status": bson.M{"$in": []string{"confirmed", "shipped", "delivered"}}}},
		{"$group": bson.M{
			"_id":   nil,
			"total": bson.M{"$sum": "$totalAmount"},
		}},
	}
	revenueCursor, err := r.orderCollection.Aggregate(ctx, revenuePipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get revenue: %w", err)
	}
	defer revenueCursor.Close(ctx)

	var revenueResult struct {
		Total float64 `bson:"total"`
	}
	if revenueCursor.Next(ctx) {
		if err := revenueCursor.Decode(&revenueResult); err != nil {
			return nil, fmt.Errorf("failed to decode revenue: %w", err)
		}
	}
	stats.TotalRevenue = revenueResult.Total

	// Get monthly revenue
	monthlyRevenuePipeline := []bson.M{
		{"$match": bson.M{
			"status":    bson.M{"$in": []string{"confirmed", "shipped", "delivered"}},
			"createdAt": bson.M{"$gte": startOfMonth},
		}},
		{"$group": bson.M{
			"_id":   nil,
			"total": bson.M{"$sum": "$totalAmount"},
		}},
	}
	monthlyRevenueCursor, err := r.orderCollection.Aggregate(ctx, monthlyRevenuePipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get monthly revenue: %w", err)
	}
	defer monthlyRevenueCursor.Close(ctx)

	var monthlyRevenueResult struct {
		Total float64 `bson:"total"`
	}
	if monthlyRevenueCursor.Next(ctx) {
		if err := monthlyRevenueCursor.Decode(&monthlyRevenueResult); err != nil {
			return nil, fmt.Errorf("failed to decode monthly revenue: %w", err)
		}
	}
	stats.MonthlyRevenue = monthlyRevenueResult.Total

	// Get total products
	totalProducts, err := r.productCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count products: %w", err)
	}
	stats.TotalProducts = totalProducts

	// Get low stock products
	lowStockProducts, err := r.productCollection.CountDocuments(ctx, bson.M{
		"stock": bson.M{"$lt": 10},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count low stock products: %w", err)
	}
	stats.LowStockProducts = lowStockProducts

	// Get pending reviews
	pendingReviews, err := r.reviewCollection.CountDocuments(ctx, bson.M{
		"status": "pending",
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count pending reviews: %w", err)
	}
	stats.PendingReviews = pendingReviews

	return stats, nil
}

func (r *adminRepository) GetRecentActivity(ctx context.Context, limit int) ([]models.AdminActivity, error) {
	activities := []models.AdminActivity{}

	// Get recent orders
	ordersCursor, err := r.orderCollection.Find(ctx, bson.M{},
		options.Find().SetSort(bson.M{"createdAt": -1}).SetLimit(int64(limit/3)))
	if err != nil {
		return nil, fmt.Errorf("failed to get recent orders: %w", err)
	}
	defer ordersCursor.Close(ctx)

	for ordersCursor.Next(ctx) {
		var order models.Order
		if err := ordersCursor.Decode(&order); err != nil {
			return nil, fmt.Errorf("failed to decode order: %w", err)
		}
		activities = append(activities, models.AdminActivity{
			Type:        "order",
			Description: fmt.Sprintf("New order #%s for $%.2f", order.ID.Hex()[:8], order.Total),
			Timestamp:   order.CreatedAt,
			EntityID:    order.ID.Hex(),
		})
	}

	// Get recent users
	usersCursor, err := r.userCollection.Find(ctx, bson.M{},
		options.Find().SetSort(bson.M{"createdAt": -1}).SetLimit(int64(limit/3)))
	if err != nil {
		return nil, fmt.Errorf("failed to get recent users: %w", err)
	}
	defer usersCursor.Close(ctx)

	for usersCursor.Next(ctx) {
		var user models.User
		if err := usersCursor.Decode(&user); err != nil {
			return nil, fmt.Errorf("failed to decode user: %w", err)
		}
		activities = append(activities, models.AdminActivity{
			Type:        "user",
			Description: fmt.Sprintf("New user registered: %s", user.Name),
			Timestamp:   user.CreatedAt,
			EntityID:    user.ID.Hex(),
		})
	}

	// Get recent reviews
	reviewsCursor, err := r.reviewCollection.Find(ctx, bson.M{},
		options.Find().SetSort(bson.M{"createdAt": -1}).SetLimit(int64(limit/3)))
	if err != nil {
		return nil, fmt.Errorf("failed to get recent reviews: %w", err)
	}
	defer reviewsCursor.Close(ctx)

	for reviewsCursor.Next(ctx) {
		var review models.Review
		if err := reviewsCursor.Decode(&review); err != nil {
			return nil, fmt.Errorf("failed to decode review: %w", err)
		}
		activities = append(activities, models.AdminActivity{
			Type:        "review",
			Description: fmt.Sprintf("New review with %d stars", review.Rating),
			Timestamp:   review.CreatedAt,
			EntityID:    review.ID.Hex(),
		})
	}

	// Sort activities by timestamp
	for i := 0; i < len(activities)-1; i++ {
		for j := 0; j < len(activities)-i-1; j++ {
			if activities[j].Timestamp.Before(activities[j+1].Timestamp) {
				activities[j], activities[j+1] = activities[j+1], activities[j]
			}
		}
	}

	// Limit to requested count
	if len(activities) > limit {
		activities = activities[:limit]
	}

	return activities, nil
}

func (r *adminRepository) GetTopSellingProducts(ctx context.Context, limit int) ([]models.ProductSales, error) {
	pipeline := []bson.M{
		{"$unwind": "$items"},
		{"$group": bson.M{
			"_id":        "$items.productId",
			"totalSold":  bson.M{"$sum": "$items.quantity"},
			"totalValue": bson.M{"$sum": bson.M{"$multiply": []string{"$items.quantity", "$items.price"}}},
		}},
		{"$sort": bson.M{"totalSold": -1}},
		{"$limit": limit},
		{"$lookup": bson.M{
			"from":         "products",
			"localField":   "_id",
			"foreignField": "_id",
			"as":           "product",
		}},
		{"$unwind": "$product"},
		{"$project": bson.M{
			"productId":   "$_id",
			"productName": "$product.name",
			"imageUrl":    "$product.imageUrls",
			"totalSold":   1,
			"totalValue":  1,
		}},
	}

	cursor, err := r.orderCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get top selling products: %w", err)
	}
	defer cursor.Close(ctx)

	var products []models.ProductSales
	if err = cursor.All(ctx, &products); err != nil {
		return nil, fmt.Errorf("failed to decode product sales: %w", err)
	}

	return products, nil
}

func (r *adminRepository) GetUserGrowth(ctx context.Context, days int) ([]models.UserGrowthData, error) {
	startDate := time.Now().AddDate(0, 0, -days)

	pipeline := []bson.M{
		{"$match": bson.M{"createdAt": bson.M{"$gte": startDate}}},
		{"$project": bson.M{
			"date": bson.M{
				"$dateToString": bson.M{
					"format": "%Y-%m-%d",
					"date":   "$createdAt",
				},
			},
		}},
		{"$group": bson.M{
			"_id":   "$date",
			"count": bson.M{"$sum": 1},
		}},
		{"$sort": bson.M{"_id": 1}},
	}

	cursor, err := r.userCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get user growth: %w", err)
	}
	defer cursor.Close(ctx)

	var growthData []models.UserGrowthData
	if err = cursor.All(ctx, &growthData); err != nil {
		return nil, fmt.Errorf("failed to decode user growth: %w", err)
	}

	return growthData, nil
}

func (r *adminRepository) GetRevenueGrowth(ctx context.Context, days int) ([]models.RevenueGrowthData, error) {
	startDate := time.Now().AddDate(0, 0, -days)

	pipeline := []bson.M{
		{"$match": bson.M{
			"createdAt": bson.M{"$gte": startDate},
			"status":    bson.M{"$in": []string{"confirmed", "shipped", "delivered"}},
		}},
		{"$project": bson.M{
			"date": bson.M{
				"$dateToString": bson.M{
					"format": "%Y-%m-%d",
					"date":   "$createdAt",
				},
			},
			"totalAmount": 1,
		}},
		{"$group": bson.M{
			"_id":     "$date",
			"revenue": bson.M{"$sum": "$totalAmount"},
		}},
		{"$sort": bson.M{"_id": 1}},
	}

	cursor, err := r.orderCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get revenue growth: %w", err)
	}
	defer cursor.Close(ctx)

	var revenueData []models.RevenueGrowthData
	if err = cursor.All(ctx, &revenueData); err != nil {
		return nil, fmt.Errorf("failed to decode revenue growth: %w", err)
	}

	return revenueData, nil
}

func (r *adminRepository) GetSystemHealth(ctx context.Context) (*models.SystemHealth, error) {
	health := &models.SystemHealth{}

	// Check database connectivity
	if err := r.userCollection.Database().Client().Ping(ctx, nil); err != nil {
		health.DatabaseStatus = "down"
	} else {
		health.DatabaseStatus = "up"
	}

	// Get active users (users who made an order in last 30 days)
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30)
	activeUsersPipeline := []bson.M{
		{"$match": bson.M{"createdAt": bson.M{"$gte": thirtyDaysAgo}}},
		{"$group": bson.M{"_id": "$userId"}},
		{"$count": "activeUsers"},
	}

	activeUsersCursor, err := r.orderCollection.Aggregate(ctx, activeUsersPipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get active users: %w", err)
	}
	defer activeUsersCursor.Close(ctx)

	var activeUsersResult struct {
		ActiveUsers int64 `bson:"activeUsers"`
	}
	if activeUsersCursor.Next(ctx) {
		if err := activeUsersCursor.Decode(&activeUsersResult); err != nil {
			return nil, fmt.Errorf("failed to decode active users: %w", err)
		}
	}
	health.ActiveUsers = activeUsersResult.ActiveUsers

	// Get pending notifications
	pendingNotifications, err := r.notificationCollection.CountDocuments(ctx, bson.M{
		"status": "pending",
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count pending notifications: %w", err)
	}
	health.PendingNotifications = pendingNotifications

	// Get error logs (you might have a separate logs collection)
	health.ErrorRate = 0.0 // Default - you can implement based on your logging strategy

	// System uptime (you might track this separately)
	health.SystemUptime = "99.9%" // Default - implement based on your monitoring

	return health, nil
}

func (r *adminRepository) BulkUpdateProductStatus(ctx context.Context, productIDs []primitive.ObjectID, isActive bool) error {
	filter := bson.M{"_id": bson.M{"$in": productIDs}}
	update := bson.M{
		"$set": bson.M{
			"isActive":  isActive,
			"updatedAt": time.Now(),
		},
	}

	_, err := r.productCollection.UpdateMany(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to bulk update product status: %w", err)
	}

	return nil
}

func (r *adminRepository) BulkUpdateUserStatus(ctx context.Context, userIDs []primitive.ObjectID, isActive bool) error {
	filter := bson.M{"_id": bson.M{"$in": userIDs}}
	update := bson.M{
		"$set": bson.M{
			"isActive":  isActive,
			"updatedAt": time.Now(),
		},
	}

	_, err := r.userCollection.UpdateMany(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to bulk update user status: %w", err)
	}

	return nil
}

func (r *adminRepository) GetLoyaltyStatistics(ctx context.Context) (*models.LoyaltyStatistics, error) {
	stats := &models.LoyaltyStatistics{}

	// Get total loyalty members
	totalMembers, err := r.loyaltyCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count loyalty members: %w", err)
	}
	stats.TotalMembers = totalMembers

	// Get tier distribution
	tierPipeline := []bson.M{
		{"$group": bson.M{
			"_id":   "$tier",
			"count": bson.M{"$sum": 1},
		}},
	}

	tierCursor, err := r.loyaltyCollection.Aggregate(ctx, tierPipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get tier distribution: %w", err)
	}
	defer tierCursor.Close(ctx)

	tierDistribution := make(map[string]int64)
	for tierCursor.Next(ctx) {
		var result struct {
			ID    string `bson:"_id"`
			Count int64  `bson:"count"`
		}
		if err := tierCursor.Decode(&result); err != nil {
			return nil, fmt.Errorf("failed to decode tier distribution: %w", err)
		}
		tierDistribution[result.ID] = result.Count
	}
	stats.MembersByTier = tierDistribution

	// Get total points issued
	pointsPipeline := []bson.M{
		{"$group": bson.M{
			"_id":    nil,
			"total":  bson.M{"$sum": "$points"},
			"redeemed": bson.M{"$sum": "$redeemedPoints"},
		}},
	}

	pointsCursor, err := r.loyaltyCollection.Aggregate(ctx, pointsPipeline)
	if err != nil {
		return nil, fmt.Errorf("failed to get points statistics: %w", err)
	}
	defer pointsCursor.Close(ctx)

	var pointsResult struct {
		Total    int64 `bson:"total"`
		Redeemed int64 `bson:"redeemed"`
	}
	if pointsCursor.Next(ctx) {
		if err := pointsCursor.Decode(&pointsResult); err != nil {
			return nil, fmt.Errorf("failed to decode points statistics: %w", err)
		}
	}
	stats.TotalPointsIssued = pointsResult.Total
	stats.TotalPointsRedeemed = pointsResult.Redeemed

	return stats, nil
}

func (r *adminRepository) GetNotificationStatistics(ctx context.Context) (*models.NotificationStatistics, error) {
	stats := &models.NotificationStatistics{}

	// Get total notifications sent
	totalSent, err := r.notificationCollection.CountDocuments(ctx, bson.M{
		"status": "sent",
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count sent notifications: %w", err)
	}
	stats.TotalSent = totalSent

	// Note: Pending and Failed fields not available in NotificationStatistics model

	// Get delivery rate
	if totalSent > 0 {
		delivered, err := r.notificationCollection.CountDocuments(ctx, bson.M{
			"status": "delivered",
		})
		if err != nil {
			return nil, fmt.Errorf("failed to count delivered notifications: %w", err)
		}
		stats.DeliveryRate = float64(delivered) / float64(totalSent) * 100
	}

	return stats, nil
}