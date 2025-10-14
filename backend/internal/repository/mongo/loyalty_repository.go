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

type loyaltyRepository struct {
	programCollection     *mongo.Collection
	transactionCollection *mongo.Collection
	configCollection      *mongo.Collection
}

// NewLoyaltyRepository creates a new loyalty repository
func NewLoyaltyRepository(db *mongo.Database) repository.LoyaltyRepository {
	return &loyaltyRepository{
		programCollection:     db.Collection("loyalty_programs"),
		transactionCollection: db.Collection("credit_transactions"),
		configCollection:      db.Collection("loyalty_config"),
	}
}

func (r *loyaltyRepository) CreateProgram(ctx context.Context, program *models.LoyaltyProgram) error {
	program.ID = primitive.NewObjectID()
	program.JoinedAt = time.Now()
	program.UpdatedAt = time.Now()

	_, err := r.programCollection.InsertOne(ctx, program)
	if err != nil {
		return fmt.Errorf("failed to create loyalty program: %w", err)
	}

	return nil
}

func (r *loyaltyRepository) GetProgramByUserID(ctx context.Context, userID primitive.ObjectID) (*models.LoyaltyProgram, error) {
	var program models.LoyaltyProgram
	err := r.programCollection.FindOne(ctx, bson.M{"userId": userID}).Decode(&program)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("loyalty program not found")
		}
		return nil, fmt.Errorf("failed to get loyalty program: %w", err)
	}
	return &program, nil
}

func (r *loyaltyRepository) UpdateProgram(ctx context.Context, program *models.LoyaltyProgram) error {
	program.UpdatedAt = time.Now()

	_, err := r.programCollection.UpdateOne(
		ctx,
		bson.M{"_id": program.ID},
		bson.M{"$set": program},
	)
	if err != nil {
		return fmt.Errorf("failed to update loyalty program: %w", err)
	}

	return nil
}

func (r *loyaltyRepository) AddTransaction(ctx context.Context, transaction *models.PointTransaction) error {
	transaction.ID = primitive.NewObjectID()
	transaction.CreatedAt = time.Now()

	_, err := r.transactionCollection.InsertOne(ctx, transaction)
	if err != nil {
		return fmt.Errorf("failed to add credit transaction: %w", err)
	}

	return nil
}

func (r *loyaltyRepository) GetTransactionHistory(ctx context.Context, userID primitive.ObjectID, limit, offset int) ([]models.PointTransaction, error) {
	filter := bson.M{"userId": userID}

	opts := options.Find().
		SetSkip(int64(offset)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.transactionCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get transaction history: %w", err)
	}
	defer cursor.Close(ctx)

	var transactions []models.PointTransaction
	if err = cursor.All(ctx, &transactions); err != nil {
		return nil, fmt.Errorf("failed to decode transactions: %w", err)
	}

	return transactions, nil
}

func (r *loyaltyRepository) GetConfig(ctx context.Context) (*models.LoyaltyConfig, error) {
	var config models.LoyaltyConfig
	err := r.configCollection.FindOne(ctx, bson.M{}).Decode(&config)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Return default config
			defaultConfig := models.DefaultLoyaltyConfig()
			// Save default config
			if createErr := r.UpdateConfig(ctx, defaultConfig); createErr != nil {
				return nil, fmt.Errorf("failed to create default config: %w", createErr)
			}
			return defaultConfig, nil
		}
		return nil, fmt.Errorf("failed to get loyalty config: %w", err)
	}
	return &config, nil
}

func (r *loyaltyRepository) UpdateConfig(ctx context.Context, config *models.LoyaltyConfig) error {
	config.UpdatedAt = time.Now()

	opts := options.Replace().SetUpsert(true)
	_, err := r.configCollection.ReplaceOne(ctx, bson.M{}, config, opts)
	if err != nil {
		return fmt.Errorf("failed to update loyalty config: %w", err)
	}

	return nil
}

func (r *loyaltyRepository) GetLoyaltyStatistics(ctx context.Context) (*models.LoyaltyStatistics, error) {
	// Total members
	totalMembers, err := r.programCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count total members: %w", err)
	}

	// Active members (those with activity in last 30 days)
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30)
	activeMembers, err := r.programCollection.CountDocuments(ctx, bson.M{
		"lastLoginDate": bson.M{"$gte": thirtyDaysAgo},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to count active members: %w", err)
	}

	// Total credits issued and redeemed
	creditsStats, err := r.getCreditsStatistics(ctx)
	if err != nil {
		creditsStats = &struct {
			Issued   int64
			Redeemed int64
		}{}
	}

	// Members by tier
	tierDistribution, err := r.getMembersByTier(ctx)
	if err != nil {
		tierDistribution = make(map[string]int64)
	}

	// Average credits balance
	avgCredits, err := r.getAverageCreditsBalance(ctx)
	if err != nil {
		avgCredits = 0
	}

	return &models.LoyaltyStatistics{
		TotalMembers:          totalMembers,
		ActiveMembers:         activeMembers,
		TotalCreditsIssued:    creditsStats.Issued,
		TotalCreditsRedeemed:  creditsStats.Redeemed,
		TierDistribution:      tierDistribution,
		AverageCreditsPerUser: avgCredits,
	}, nil
}

func (r *loyaltyRepository) ExportLoyaltyData(ctx context.Context, format string, startDate, endDate time.Time) (string, error) {
	// Implementation would depend on your export service
	return fmt.Sprintf("loyalty_export_%s.%s", time.Now().Format("20060102"), format), nil
}

func (r *loyaltyRepository) GetTopLoyaltyMembers(ctx context.Context, limit int) ([]models.TopLoyaltyMember, error) {
	return r.getTopLoyaltyMembers(ctx, limit)
}

// Helper methods

func (r *loyaltyRepository) getCreditsStatistics(ctx context.Context) (*struct {
	Issued   int64
	Redeemed int64
}, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id": "$type",
				"totalCredits": bson.M{"$sum": "$credits"},
			},
		},
	}

	cursor, err := r.transactionCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	stats := &struct {
		Issued   int64
		Redeemed int64
	}{}

	for cursor.Next(ctx) {
		var result struct {
			Type         string `bson:"_id"`
			TotalCredits int64  `bson:"totalCredits"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}

		switch result.Type {
		case "earned", "login_bonus", "streak_bonus", "welcome_bonus":
			stats.Issued += result.TotalCredits
		case "redeemed":
			// Credits are stored as negative for redemptions
			if result.TotalCredits < 0 {
				stats.Redeemed += -result.TotalCredits
			} else {
				stats.Redeemed += result.TotalCredits
			}
		}
	}

	return stats, nil
}

func (r *loyaltyRepository) getMembersByTier(ctx context.Context) (map[string]int64, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":   "$tier",
				"count": bson.M{"$sum": 1},
			},
		},
	}

	cursor, err := r.programCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	membersByTier := make(map[string]int64)
	for cursor.Next(ctx) {
		var result struct {
			Tier  string `bson:"_id"`
			Count int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		membersByTier[result.Tier] = result.Count
	}

	return membersByTier, nil
}

func (r *loyaltyRepository) getAverageCreditsBalance(ctx context.Context) (float64, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":        nil,
				"avgCredits": bson.M{"$avg": "$availableCredits"},
			},
		},
	}

	cursor, err := r.programCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)

	var result struct {
		AvgCredits float64 `bson:"avgCredits"`
	}

	if cursor.Next(ctx) {
		if err := cursor.Decode(&result); err != nil {
			return 0, err
		}
	}

	return result.AvgCredits, nil
}

func (r *loyaltyRepository) getTopLoyaltyMembers(ctx context.Context, limit int) ([]models.TopLoyaltyMember, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.M{"totalCredits": -1})

	cursor, err := r.programCollection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var topMembers []models.TopLoyaltyMember
	for cursor.Next(ctx) {
		var program models.LoyaltyProgram
		if err := cursor.Decode(&program); err != nil {
			continue
		}

		topMembers = append(topMembers, models.TopLoyaltyMember{
			UserID:           program.UserID,
			TotalCredits:     program.TotalCredits,
			AvailableCredits: program.AvailableCredits,
			Tier:             program.Tier,
			TotalSpent:       program.TotalSpent,
		})
	}

	return topMembers, nil
}