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

type voucherRepository struct {
	voucherCollection     *mongo.Collection
	userVoucherCollection *mongo.Collection
	rewardCollection      *mongo.Collection
}

// NewVoucherRepository creates a new voucher repository
func NewVoucherRepository(db *mongo.Database) repository.VoucherRepository {
	return &voucherRepository{
		voucherCollection:     db.Collection("vouchers"),
		userVoucherCollection: db.Collection("user_vouchers"),
		rewardCollection:      db.Collection("rewards"),
	}
}

func (r *voucherRepository) Create(ctx context.Context, voucher *models.Voucher) error {
	voucher.ID = primitive.NewObjectID()
	voucher.CreatedAt = time.Now()
	voucher.UpdatedAt = time.Now()

	_, err := r.voucherCollection.InsertOne(ctx, voucher)
	if err != nil {
		return fmt.Errorf("failed to create voucher: %w", err)
	}

	return nil
}

func (r *voucherRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Voucher, error) {
	var voucher models.Voucher
	err := r.voucherCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&voucher)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("voucher not found")
		}
		return nil, fmt.Errorf("failed to get voucher: %w", err)
	}
	return &voucher, nil
}

func (r *voucherRepository) GetByCode(ctx context.Context, code string) (*models.Voucher, error) {
	var voucher models.Voucher
	err := r.voucherCollection.FindOne(ctx, bson.M{"code": code}).Decode(&voucher)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("voucher not found")
		}
		return nil, fmt.Errorf("failed to get voucher by code: %w", err)
	}
	return &voucher, nil
}

func (r *voucherRepository) Update(ctx context.Context, voucher *models.Voucher) error {
	voucher.UpdatedAt = time.Now()

	_, err := r.voucherCollection.UpdateOne(
		ctx,
		bson.M{"_id": voucher.ID},
		bson.M{"$set": voucher},
	)
	if err != nil {
		return fmt.Errorf("failed to update voucher: %w", err)
	}

	return nil
}

func (r *voucherRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.voucherCollection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete voucher: %w", err)
	}

	return nil
}

func (r *voucherRepository) GetAvailable(ctx context.Context) ([]models.Voucher, error) {
	now := time.Now()
	filter := bson.M{
		"isActive": true,
		"$or": []bson.M{
			{"validFrom": bson.M{"$lte": now}},
			{"validFrom": nil},
		},
		"$or": []bson.M{
			{"validUntil": bson.M{"$gte": now}},
			{"validUntil": nil},
		},
	}

	cursor, err := r.voucherCollection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("failed to find available vouchers: %w", err)
	}
	defer cursor.Close(ctx)

	var vouchers []models.Voucher
	if err = cursor.All(ctx, &vouchers); err != nil {
		return nil, fmt.Errorf("failed to decode vouchers: %w", err)
	}

	return vouchers, nil
}

func (r *voucherRepository) GetRedemptionCount(ctx context.Context, voucherID primitive.ObjectID) (int, error) {
	count, err := r.userVoucherCollection.CountDocuments(ctx, bson.M{"voucherId": voucherID})
	if err != nil {
		return 0, fmt.Errorf("failed to count redemptions: %w", err)
	}

	return int(count), nil
}

func (r *voucherRepository) GetUserRedemptionCount(ctx context.Context, userID, voucherID primitive.ObjectID) (int, error) {
	count, err := r.userVoucherCollection.CountDocuments(ctx, bson.M{
		"userId":    userID,
		"voucherId": voucherID,
	})
	if err != nil {
		return 0, fmt.Errorf("failed to count user redemptions: %w", err)
	}

	return int(count), nil
}

func (r *voucherRepository) CreateUserVoucher(ctx context.Context, userVoucher *models.UserVoucher) error {
	userVoucher.ID = primitive.NewObjectID()

	_, err := r.userVoucherCollection.InsertOne(ctx, userVoucher)
	if err != nil {
		return fmt.Errorf("failed to create user voucher: %w", err)
	}

	return nil
}

func (r *voucherRepository) GetUserVouchers(ctx context.Context, userID primitive.ObjectID, onlyUnused bool) ([]models.UserVoucher, error) {
	filter := bson.M{"userId": userID}
	if onlyUnused {
		filter["isUsed"] = false
		filter["$or"] = []bson.M{
			{"expiresAt": bson.M{"$gt": time.Now()}},
			{"expiresAt": nil},
		}
	}

	opts := options.Find().SetSort(bson.M{"issuedAt": -1})

	cursor, err := r.userVoucherCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find user vouchers: %w", err)
	}
	defer cursor.Close(ctx)

	var vouchers []models.UserVoucher
	if err = cursor.All(ctx, &vouchers); err != nil {
		return nil, fmt.Errorf("failed to decode user vouchers: %w", err)
	}

	return vouchers, nil
}

func (r *voucherRepository) GetUserVoucherByCode(ctx context.Context, userID primitive.ObjectID, code string) (*models.UserVoucher, error) {
	var voucher models.UserVoucher
	err := r.userVoucherCollection.FindOne(ctx, bson.M{
		"userId": userID,
		"code":   code,
	}).Decode(&voucher)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("user voucher not found")
		}
		return nil, fmt.Errorf("failed to get user voucher: %w", err)
	}
	return &voucher, nil
}

func (r *voucherRepository) UpdateUserVoucher(ctx context.Context, userVoucher *models.UserVoucher) error {
	_, err := r.userVoucherCollection.UpdateOne(
		ctx,
		bson.M{"_id": userVoucher.ID},
		bson.M{"$set": userVoucher},
	)
	if err != nil {
		return fmt.Errorf("failed to update user voucher: %w", err)
	}

	return nil
}

func (r *voucherRepository) CreateReward(ctx context.Context, reward *models.Reward) error {
	reward.ID = primitive.NewObjectID()
	reward.CreatedAt = time.Now()
	reward.UpdatedAt = time.Now()

	_, err := r.rewardCollection.InsertOne(ctx, reward)
	if err != nil {
		return fmt.Errorf("failed to create reward: %w", err)
	}

	return nil
}

func (r *voucherRepository) GetRewardByID(ctx context.Context, id primitive.ObjectID) (*models.Reward, error) {
	var reward models.Reward
	err := r.rewardCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&reward)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("reward not found")
		}
		return nil, fmt.Errorf("failed to get reward: %w", err)
	}
	return &reward, nil
}

func (r *voucherRepository) UpdateReward(ctx context.Context, reward *models.Reward) error {
	reward.UpdatedAt = time.Now()

	_, err := r.rewardCollection.UpdateOne(
		ctx,
		bson.M{"_id": reward.ID},
		bson.M{"$set": reward},
	)
	if err != nil {
		return fmt.Errorf("failed to update reward: %w", err)
	}

	return nil
}

func (r *voucherRepository) GetUserRewards(ctx context.Context, userID primitive.ObjectID, status string) ([]models.Reward, error) {
	filter := bson.M{"userId": userID}
	if status != "" {
		filter["status"] = status
	}

	opts := options.Find().SetSort(bson.M{"earnedAt": -1})

	cursor, err := r.rewardCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find user rewards: %w", err)
	}
	defer cursor.Close(ctx)

	var rewards []models.Reward
	if err = cursor.All(ctx, &rewards); err != nil {
		return nil, fmt.Errorf("failed to decode rewards: %w", err)
	}

	return rewards, nil
}

func (r *voucherRepository) GetAnalytics(ctx context.Context, startDate, endDate time.Time) (*models.VoucherAnalytics, error) {
	// Total vouchers
	totalVouchers, err := r.voucherCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count total vouchers: %w", err)
	}

	// Active vouchers
	activeVouchers, err := r.voucherCollection.CountDocuments(ctx, bson.M{"isActive": true})
	if err != nil {
		return nil, fmt.Errorf("failed to count active vouchers: %w", err)
	}

	// Total redemptions
	totalRedemptions, err := r.userVoucherCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("failed to count total redemptions: %w", err)
	}

	// Total usage
	totalUsage, err := r.userVoucherCollection.CountDocuments(ctx, bson.M{"isUsed": true})
	if err != nil {
		return nil, fmt.Errorf("failed to count total usage: %w", err)
	}

	// Get popular vouchers
	popularVouchers, err := r.getPopularVouchers(ctx, 10)
	if err != nil {
		popularVouchers = []models.VoucherPopularity{}
	}

	// Get redemptions by type
	redemptionsByType, err := r.getRedemptionsByType(ctx)
	if err != nil {
		redemptionsByType = make(map[string]int64)
	}

	// Get usage by month
	usageByMonth, err := r.getUsageByMonth(ctx, 12)
	if err != nil {
		usageByMonth = []models.MonthlyVoucherUsage{}
	}

	// Calculate conversion rate
	var conversionRate float64
	if totalRedemptions > 0 {
		conversionRate = (float64(totalUsage) / float64(totalRedemptions)) * 100
	}

	return &models.VoucherAnalytics{
		TotalVouchers:     totalVouchers,
		ActiveVouchers:    activeVouchers,
		TotalRedemptions:  totalRedemptions,
		TotalUsage:        totalUsage,
		PopularVouchers:   popularVouchers,
		RedemptionsByType: redemptionsByType,
		UsageByMonth:      usageByMonth,
		ConversionRate:    conversionRate,
	}, nil
}

// Helper methods

func (r *voucherRepository) getPopularVouchers(ctx context.Context, limit int) ([]models.VoucherPopularity, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":         "$voucherId",
				"redemptions": bson.M{"$sum": 1},
				"usage":       bson.M{"$sum": bson.M{"$cond": []interface{}{"$isUsed", 1, 0}}},
			},
		},
		{
			"$sort": bson.M{"redemptions": -1},
		},
		{
			"$limit": limit,
		},
	}

	cursor, err := r.userVoucherCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var popular []models.VoucherPopularity
	for cursor.Next(ctx) {
		var result struct {
			VoucherID   primitive.ObjectID `bson:"_id"`
			Redemptions int64              `bson:"redemptions"`
			Usage       int64              `bson:"usage"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}

		// Get voucher details
		voucher, err := r.GetByID(ctx, result.VoucherID)
		if err != nil {
			continue
		}

		popular = append(popular, models.VoucherPopularity{
			VoucherID:    result.VoucherID,
			VoucherTitle: voucher.Title,
			Redemptions:  result.Redemptions,
			Usage:        result.Usage,
		})
	}

	return popular, nil
}

func (r *voucherRepository) getRedemptionsByType(ctx context.Context) (map[string]int64, error) {
	pipeline := []bson.M{
		{
			"$lookup": bson.M{
				"from":         "vouchers",
				"localField":   "voucherId",
				"foreignField": "_id",
				"as":           "voucher",
			},
		},
		{
			"$unwind": "$voucher",
		},
		{
			"$group": bson.M{
				"_id":   "$voucher.type",
				"count": bson.M{"$sum": 1},
			},
		},
	}

	cursor, err := r.userVoucherCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	redemptionsByType := make(map[string]int64)
	for cursor.Next(ctx) {
		var result struct {
			Type  string `bson:"_id"`
			Count int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		redemptionsByType[result.Type] = result.Count
	}

	return redemptionsByType, nil
}

func (r *voucherRepository) getUsageByMonth(ctx context.Context, months int) ([]models.MonthlyVoucherUsage, error) {
	startDate := time.Now().AddDate(0, -months, 0)

	pipeline := []bson.M{
		{
			"$match": bson.M{
				"issuedAt": bson.M{"$gte": startDate},
			},
		},
		{
			"$group": bson.M{
				"_id": bson.M{
					"$dateToString": bson.M{
						"format": "%Y-%m",
						"date":   "$issuedAt",
					},
				},
				"redemptions": bson.M{"$sum": 1},
				"usage":       bson.M{"$sum": bson.M{"$cond": []interface{}{"$isUsed", 1, 0}}},
			},
		},
		{
			"$sort": bson.M{"_id": 1},
		},
	}

	cursor, err := r.userVoucherCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var usageByMonth []models.MonthlyVoucherUsage
	for cursor.Next(ctx) {
		var result struct {
			Month       string `bson:"_id"`
			Redemptions int64  `bson:"redemptions"`
			Usage       int64  `bson:"usage"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}

		usageByMonth = append(usageByMonth, models.MonthlyVoucherUsage{
			Month:       result.Month,
			Redemptions: result.Redemptions,
			Usage:       result.Usage,
		})
	}

	return usageByMonth, nil
}