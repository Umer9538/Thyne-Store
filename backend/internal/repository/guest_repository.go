package repository

import (
	"context"
	"errors"
	"time"

	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)


type guestSessionRepository struct {
	collection *mongo.Collection
}

func NewGuestSessionRepository(db *mongo.Database) GuestSessionRepository {
	return &guestSessionRepository{
		collection: db.Collection("guest_sessions"),
	}
}

func (r *guestSessionRepository) Create(ctx context.Context, session *models.GuestSession) error {
	_, err := r.collection.InsertOne(ctx, session)
	return err
}

func (r *guestSessionRepository) GetBySessionID(ctx context.Context, sessionID string) (*models.GuestSession, error) {
	var session models.GuestSession
	err := r.collection.FindOne(ctx, bson.M{"sessionId": sessionID}).Decode(&session)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("session not found")
		}
		return nil, err
	}
	return &session, nil
}

func (r *guestSessionRepository) Update(ctx context.Context, session *models.GuestSession) error {
	filter := bson.M{"sessionId": session.SessionID}
	update := bson.M{
		"$set": bson.M{
			"email":        session.Email,
			"phone":        session.Phone,
			"name":         session.Name,
			"cartItems":    session.CartItems,
			"lastActivity": session.LastActivity,
			"expiresAt":    session.ExpiresAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *guestSessionRepository) DeleteBySessionID(ctx context.Context, sessionID string) error {
	filter := bson.M{"sessionId": sessionID}
	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}

func (r *guestSessionRepository) DeleteExpired(ctx context.Context) error {
	now := bson.M{"$lt": time.Now()}
	filter := bson.M{"expiresAt": now}
	_, err := r.collection.DeleteMany(ctx, filter)
	return err
}
