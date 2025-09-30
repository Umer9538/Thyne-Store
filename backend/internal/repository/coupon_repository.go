package repository

import (
	"context"
	"errors"

	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)


type couponRepository struct {
	collection *mongo.Collection
}

func NewCouponRepository(db *mongo.Database) CouponRepository {
	return &couponRepository{
		collection: db.Collection("coupons"),
	}
}

func (r *couponRepository) Create(ctx context.Context, coupon *models.Coupon) error {
	_, err := r.collection.InsertOne(ctx, coupon)
	return err
}

func (r *couponRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Coupon, error) {
	var coupon models.Coupon
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&coupon)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("coupon not found")
		}
		return nil, err
	}
	return &coupon, nil
}

func (r *couponRepository) GetByCode(ctx context.Context, code string) (*models.Coupon, error) {
	var coupon models.Coupon
	err := r.collection.FindOne(ctx, bson.M{"code": code}).Decode(&coupon)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("coupon not found")
		}
		return nil, err
	}
	return &coupon, nil
}

func (r *couponRepository) GetAll(ctx context.Context) ([]models.Coupon, error) {
	cursor, err := r.collection.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var coupons []models.Coupon
	if err = cursor.All(ctx, &coupons); err != nil {
		return nil, err
	}

	return coupons, nil
}

func (r *couponRepository) Update(ctx context.Context, coupon *models.Coupon) error {
	filter := bson.M{"_id": coupon.ID}
	update := bson.M{
		"$set": bson.M{
			"code":        coupon.Code,
			"name":        coupon.Name,
			"description": coupon.Description,
			"type":        coupon.Type,
			"value":       coupon.Value,
			"minAmount":   coupon.MinAmount,
			"maxDiscount": coupon.MaxDiscount,
			"usageLimit":  coupon.UsageLimit,
			"usedCount":   coupon.UsedCount,
			"isActive":    coupon.IsActive,
			"validFrom":   coupon.ValidFrom,
			"validUntil":  coupon.ValidUntil,
			"updatedAt":   coupon.UpdatedAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *couponRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}
	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}
