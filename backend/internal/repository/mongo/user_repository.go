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

type userRepository struct {
	collection     *mongo.Collection
	auditCollection *mongo.Collection
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *mongo.Database) repository.UserRepository {
	return &userRepository{
		collection:      db.Collection("users"),
		auditCollection: db.Collection("audit_logs"),
	}
}

func (r *userRepository) Create(ctx context.Context, user *models.User) error {
	user.ID = primitive.NewObjectID()
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, user)
	if err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	// Create audit log
	r.createAuditLog(ctx, user.ID, "create", "user", user.ID.Hex(), "User created", nil)

	return nil
}

func (r *userRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.User, error) {
	var user models.User
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user by ID: %w", err)
	}
	return &user, nil
}

func (r *userRepository) GetByEmail(ctx context.Context, email string) (*models.User, error) {
	var user models.User
	err := r.collection.FindOne(ctx, bson.M{"email": email}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}
	return &user, nil
}

func (r *userRepository) GetByPhone(ctx context.Context, phone string) (*models.User, error) {
	var user models.User
	err := r.collection.FindOne(ctx, bson.M{"phone": phone}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user by phone: %w", err)
	}
	return &user, nil
}

func (r *userRepository) Update(ctx context.Context, user *models.User) error {
	user.UpdatedAt = time.Now()

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": user.ID},
		bson.M{"$set": user},
	)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	// Create audit log
	r.createAuditLog(ctx, user.ID, "update", "user", user.ID.Hex(), "User updated", nil)

	return nil
}

func (r *userRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	// Create audit log
	r.createAuditLog(ctx, id, "delete", "user", id.Hex(), "User deleted", nil)

	return nil
}

func (r *userRepository) List(ctx context.Context, page, limit int, filters map[string]interface{}) ([]models.User, int64, error) {
	// Build filter
	filter := bson.M{}
	for key, value := range filters {
		switch key {
		case "isActive":
			filter["isActive"] = value
		case "isEmailVerified":
			filter["isEmailVerified"] = value
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
		case "search":
			filter["$or"] = []bson.M{
				{"firstName": bson.M{"$regex": value, "$options": "i"}},
				{"lastName": bson.M{"$regex": value, "$options": "i"}},
				{"email": bson.M{"$regex": value, "$options": "i"}},
			}
		}
	}

	// Get total count
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count users: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find users
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find users: %w", err)
	}
	defer cursor.Close(ctx)

	var users []models.User
	if err = cursor.All(ctx, &users); err != nil {
		return nil, 0, fmt.Errorf("failed to decode users: %w", err)
	}

	return users, total, nil
}

func (r *userRepository) GetUserStatistics(ctx context.Context) (*models.UserStatistics, error) {
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

	// Total users
	total, err := r.collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count total users: %w", err)
	}

	// Active users (logged in within last 30 days)
	activeUsers, err := r.collection.CountDocuments(ctx, bson.M{
		"lastLoginAt": bson.M{"$gte": time.Now().AddDate(0, 0, -30)},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count active users: %w", err)
	}

	// New users today
	newUsersToday, err := r.collection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{"$gte": today},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count new users today: %w", err)
	}

	// New users this month
	newUsersThisMonth, err := r.collection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{"$gte": monthStart},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count new users this month: %w", err)
	}

	// Calculate growth rate (simplified)
	lastMonthStart := monthStart.AddDate(0, -1, 0)
	lastMonthEnd := monthStart.Add(-time.Second)
	lastMonthUsers, _ := r.collection.CountDocuments(ctx, bson.M{
		"createdAt": bson.M{
			"$gte": lastMonthStart,
			"$lte": lastMonthEnd,
		},
	})

	var growthRate float64
	if lastMonthUsers > 0 {
		growthRate = (float64(newUsersThisMonth-lastMonthUsers) / float64(lastMonthUsers)) * 100
	}

	// Get daily registrations for the last 30 days
	dailyRegistrations, err := r.getDailyRegistrations(ctx, 30)
	if err != nil {
		dailyRegistrations = []models.DailyRegistration{}
	}

	// Get top spending users
	topSpendingUsers, err := r.getTopSpendingUsers(ctx, 10)
	if err != nil {
		topSpendingUsers = []models.TopUser{}
	}

	return &models.UserStatistics{
		TotalUsers:        total,
		ActiveUsers:       activeUsers,
		NewUsersToday:     newUsersToday,
		NewUsersThisMonth: newUsersThisMonth,
		UserGrowthRate:    growthRate,
		UserRegistrations: dailyRegistrations,
		TopSpendingUsers:  topSpendingUsers,
	}, nil
}

func (r *userRepository) GetRecentUsers(ctx context.Context, limit int) ([]models.User, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find recent users: %w", err)
	}
	defer cursor.Close(ctx)

	var users []models.User
	if err = cursor.All(ctx, &users); err != nil {
		return nil, fmt.Errorf("failed to decode recent users: %w", err)
	}

	return users, nil
}

func (r *userRepository) ExportUsers(ctx context.Context, format string, startDate, endDate time.Time, filters map[string]interface{}) (string, error) {
	// Implementation would depend on your export service
	// This is a simplified placeholder
	return fmt.Sprintf("users_export_%s.%s", time.Now().Format("20060102"), format), nil
}

func (r *userRepository) GetAuditLogs(ctx context.Context, page, limit int, action, userID string) ([]models.AuditLog, int64, error) {
	filter := bson.M{}

	if action != "" {
		filter["action"] = action
	}

	if userID != "" {
		if objID, err := primitive.ObjectIDFromHex(userID); err == nil {
			filter["userId"] = objID
		}
	}

	// Get total count
	total, err := r.auditCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count audit logs: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find audit logs
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"timestamp": -1})

	cursor, err := r.auditCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find audit logs: %w", err)
	}
	defer cursor.Close(ctx)

	var logs []models.AuditLog
	if err = cursor.All(ctx, &logs); err != nil {
		return nil, 0, fmt.Errorf("failed to decode audit logs: %w", err)
	}

	return logs, total, nil
}

func (r *userRepository) CreateAuditLog(ctx context.Context, log *models.AuditLog) error {
	log.ID = primitive.NewObjectID()
	log.Timestamp = time.Now()

	_, err := r.auditCollection.InsertOne(ctx, log)
	return err
}

// Helper methods

func (r *userRepository) createAuditLog(ctx context.Context, userID primitive.ObjectID, action, resource, resourceID, description string, metadata map[string]interface{}) {
	log := &models.AuditLog{
		UserID:      &userID,
		Action:      action,
		Resource:    resource,
		ResourceID:  resourceID,
		Description: description,
		Metadata:    metadata,
	}
	r.CreateAuditLog(ctx, log)
}

func (r *userRepository) getDailyRegistrations(ctx context.Context, days int) ([]models.DailyRegistration, error) {
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"createdAt": bson.M{
					"$gte": time.Now().AddDate(0, 0, -days),
				},
			},
		},
		{
			"$group": bson.M{
				"_id": bson.M{
					"$dateToString": bson.M{
						"format": "%Y-%m-%d",
						"date":   "$createdAt",
					},
				},
				"count": bson.M{"$sum": 1},
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

	var registrations []models.DailyRegistration
	for cursor.Next(ctx) {
		var result struct {
			ID    string `bson:"_id"`
			Count int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		registrations = append(registrations, models.DailyRegistration{
			Date:  result.ID,
			Count: result.Count,
		})
	}

	return registrations, nil
}

func (r *userRepository) getTopSpendingUsers(ctx context.Context, limit int) ([]models.TopUser, error) {
	// This would typically require joining with orders collection
	// For now, return empty slice as it requires aggregation across collections
	return []models.TopUser{}, nil
}