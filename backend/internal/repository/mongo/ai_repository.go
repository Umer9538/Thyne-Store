package mongo

import (
	"context"
	"time"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type aiRepository struct {
	creationsCollection     *mongo.Collection
	chatMessagesCollection  *mongo.Collection
	chatSessionsCollection  *mongo.Collection
	searchHistoryCollection *mongo.Collection
	tokenUsageCollection    *mongo.Collection
}

// NewAIRepository creates a new AI repository
func NewAIRepository(db *mongo.Database) repository.AIRepository {
	return &aiRepository{
		creationsCollection:     db.Collection("ai_creations"),
		chatMessagesCollection:  db.Collection("ai_chat_messages"),
		chatSessionsCollection:  db.Collection("ai_chat_sessions"),
		searchHistoryCollection: db.Collection("ai_search_history"),
		tokenUsageCollection:    db.Collection("ai_token_usage"),
	}
}

// ==================== AI Creations ====================

// CreateCreation saves a new AI creation
func (r *aiRepository) CreateCreation(ctx context.Context, creation *models.AICreation) error {
	creation.ID = primitive.NewObjectID()
	creation.CreatedAt = time.Now()
	creation.UpdatedAt = time.Now()

	_, err := r.creationsCollection.InsertOne(ctx, creation)
	return err
}

// GetCreationByID retrieves a creation by ID
func (r *aiRepository) GetCreationByID(ctx context.Context, id primitive.ObjectID) (*models.AICreation, error) {
	var creation models.AICreation
	err := r.creationsCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&creation)
	if err != nil {
		return nil, err
	}
	return &creation, nil
}

// GetCreationsByUserID retrieves all creations for a user with pagination
func (r *aiRepository) GetCreationsByUserID(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.AICreation, int64, error) {
	skip := (page - 1) * limit

	filter := bson.M{"userId": userID}
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "createdAt", Value: -1}}) // Newest first

	cursor, err := r.creationsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var creations []models.AICreation
	if err = cursor.All(ctx, &creations); err != nil {
		return nil, 0, err
	}

	total, err := r.creationsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	return creations, total, nil
}

// DeleteCreation deletes a creation by ID
func (r *aiRepository) DeleteCreation(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.creationsCollection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// ClearCreationsByUserID deletes all creations for a user
func (r *aiRepository) ClearCreationsByUserID(ctx context.Context, userID primitive.ObjectID) error {
	_, err := r.creationsCollection.DeleteMany(ctx, bson.M{"userId": userID})
	return err
}

// ==================== Chat Messages ====================

// CreateChatMessage saves a new chat message
func (r *aiRepository) CreateChatMessage(ctx context.Context, message *models.ChatMessage) error {
	message.ID = primitive.NewObjectID()
	message.CreatedAt = time.Now()

	_, err := r.chatMessagesCollection.InsertOne(ctx, message)
	return err
}

// GetChatMessagesBySession retrieves messages for a session
func (r *aiRepository) GetChatMessagesBySession(ctx context.Context, sessionID string, page, limit int) ([]models.ChatMessage, int64, error) {
	skip := (page - 1) * limit

	filter := bson.M{"sessionId": sessionID}
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "createdAt", Value: 1}}) // Oldest first for chat

	cursor, err := r.chatMessagesCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var messages []models.ChatMessage
	if err = cursor.All(ctx, &messages); err != nil {
		return nil, 0, err
	}

	total, err := r.chatMessagesCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	return messages, total, nil
}

// GetChatMessagesByUserID retrieves all messages for a user
func (r *aiRepository) GetChatMessagesByUserID(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.ChatMessage, int64, error) {
	skip := (page - 1) * limit

	filter := bson.M{"userId": userID}
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := r.chatMessagesCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var messages []models.ChatMessage
	if err = cursor.All(ctx, &messages); err != nil {
		return nil, 0, err
	}

	total, err := r.chatMessagesCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	return messages, total, nil
}

// DeleteChatMessage deletes a chat message
func (r *aiRepository) DeleteChatMessage(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.chatMessagesCollection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// ClearChatBySessionID deletes all messages in a session
func (r *aiRepository) ClearChatBySessionID(ctx context.Context, sessionID string) error {
	_, err := r.chatMessagesCollection.DeleteMany(ctx, bson.M{"sessionId": sessionID})
	return err
}

// ClearChatByUserID deletes all messages for a user
func (r *aiRepository) ClearChatByUserID(ctx context.Context, userID primitive.ObjectID) error {
	_, err := r.chatMessagesCollection.DeleteMany(ctx, bson.M{"userId": userID})
	return err
}

// ==================== Chat Sessions ====================

// CreateChatSession creates a new chat session
func (r *aiRepository) CreateChatSession(ctx context.Context, session *models.ChatSession) error {
	session.ID = primitive.NewObjectID()
	session.CreatedAt = time.Now()
	session.UpdatedAt = time.Now()

	_, err := r.chatSessionsCollection.InsertOne(ctx, session)
	return err
}

// GetChatSessionByID retrieves a session by ID
func (r *aiRepository) GetChatSessionByID(ctx context.Context, id primitive.ObjectID) (*models.ChatSession, error) {
	var session models.ChatSession
	err := r.chatSessionsCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&session)
	if err != nil {
		return nil, err
	}
	return &session, nil
}

// GetChatSessionsByUserID retrieves all sessions for a user
func (r *aiRepository) GetChatSessionsByUserID(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.ChatSession, int64, error) {
	skip := (page - 1) * limit

	filter := bson.M{"userId": userID}
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "updatedAt", Value: -1}}) // Most recent first

	cursor, err := r.chatSessionsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var sessions []models.ChatSession
	if err = cursor.All(ctx, &sessions); err != nil {
		return nil, 0, err
	}

	total, err := r.chatSessionsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	return sessions, total, nil
}

// UpdateChatSession updates a chat session
func (r *aiRepository) UpdateChatSession(ctx context.Context, session *models.ChatSession) error {
	session.UpdatedAt = time.Now()
	_, err := r.chatSessionsCollection.UpdateOne(
		ctx,
		bson.M{"_id": session.ID},
		bson.M{"$set": session},
	)
	return err
}

// DeleteChatSession deletes a chat session and its messages
func (r *aiRepository) DeleteChatSession(ctx context.Context, id primitive.ObjectID) error {
	// First get session to get sessionID
	session, err := r.GetChatSessionByID(ctx, id)
	if err != nil {
		return err
	}

	// Delete all messages in this session
	if err := r.ClearChatBySessionID(ctx, session.ID.Hex()); err != nil {
		return err
	}

	// Delete the session
	_, err = r.chatSessionsCollection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// ==================== Search History ====================

// AddSearchHistory adds a search to history
func (r *aiRepository) AddSearchHistory(ctx context.Context, history *models.SearchHistory) error {
	history.ID = primitive.NewObjectID()
	history.CreatedAt = time.Now()

	_, err := r.searchHistoryCollection.InsertOne(ctx, history)
	return err
}

// GetSearchHistoryByUserID retrieves search history for a user
func (r *aiRepository) GetSearchHistoryByUserID(ctx context.Context, userID primitive.ObjectID, limit int) ([]models.SearchHistory, error) {
	filter := bson.M{"userId": userID}
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := r.searchHistoryCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var history []models.SearchHistory
	if err = cursor.All(ctx, &history); err != nil {
		return nil, err
	}

	return history, nil
}

// ClearSearchHistoryByUserID clears search history for a user
func (r *aiRepository) ClearSearchHistoryByUserID(ctx context.Context, userID primitive.ObjectID) error {
	_, err := r.searchHistoryCollection.DeleteMany(ctx, bson.M{"userId": userID})
	return err
}

// ==================== Statistics ====================

// GetUserAIStatistics gets AI usage statistics for a user
func (r *aiRepository) GetUserAIStatistics(ctx context.Context, userID primitive.ObjectID) (*models.AIStatistics, error) {
	filter := bson.M{"userId": userID}

	// Count creations
	totalCreations, err := r.creationsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, err
	}

	// Count successful creations
	successFilter := bson.M{"userId": userID, "isSuccessful": true}
	successfulCreations, err := r.creationsCollection.CountDocuments(ctx, successFilter)
	if err != nil {
		return nil, err
	}

	// Count chat messages
	totalChats, err := r.chatMessagesCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, err
	}

	// Count searches
	totalSearches, err := r.searchHistoryCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, err
	}

	// Calculate success rate
	var successRate float64
	if totalCreations > 0 {
		successRate = float64(successfulCreations) / float64(totalCreations) * 100
	}

	return &models.AIStatistics{
		TotalCreations:      totalCreations,
		SuccessfulCreations: successfulCreations,
		FailedCreations:     totalCreations - successfulCreations,
		TotalChats:          totalChats,
		TotalSearches:       totalSearches,
		SuccessRate:         successRate,
	}, nil
}

// ==================== Token Tracking ====================

// GetTokenUsage retrieves token usage for a user for a specific month
func (r *aiRepository) GetTokenUsage(ctx context.Context, userID primitive.ObjectID, month string) (*models.TokenUsage, error) {
	filter := bson.M{
		"userId": userID,
		"month":  month,
	}

	var usage models.TokenUsage
	err := r.tokenUsageCollection.FindOne(ctx, filter).Decode(&usage)
	if err != nil {
		return nil, err
	}
	return &usage, nil
}

// CreateTokenUsage creates a new token usage record
func (r *aiRepository) CreateTokenUsage(ctx context.Context, usage *models.TokenUsage) error {
	usage.ID = primitive.NewObjectID()
	usage.CreatedAt = time.Now()
	usage.UpdatedAt = time.Now()

	_, err := r.tokenUsageCollection.InsertOne(ctx, usage)
	return err
}

// IncrementTokenUsage increments token usage for a user
func (r *aiRepository) IncrementTokenUsage(ctx context.Context, userID primitive.ObjectID, month string, tokens int64, lastGenerated *time.Time) error {
	filter := bson.M{
		"userId": userID,
		"month":  month,
	}

	update := bson.M{
		"$inc": bson.M{
			"tokensUsed": tokens,
			"imageCount": 1,
		},
		"$set": bson.M{
			"updatedAt":       time.Now(),
			"lastGeneratedAt": lastGenerated,
		},
		"$setOnInsert": bson.M{
			"userId":     userID,
			"month":      month,
			"tokenLimit": models.DefaultMonthlyTokenLimit,
			"createdAt":  time.Now(),
		},
	}

	opts := options.Update().SetUpsert(true)
	_, err := r.tokenUsageCollection.UpdateOne(ctx, filter, update, opts)
	return err
}
