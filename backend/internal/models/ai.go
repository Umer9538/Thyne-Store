package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// AICreation represents a user's AI-generated jewelry image
type AICreation struct {
	ID           primitive.ObjectID     `json:"id" bson:"_id,omitempty"`
	UserID       primitive.ObjectID     `json:"userId" bson:"userId"`
	Prompt       string                 `json:"prompt" bson:"prompt"`
	ImageURL     string                 `json:"imageUrl" bson:"imageUrl"`
	IsSuccessful bool                   `json:"isSuccessful" bson:"isSuccessful"`
	ErrorMessage string                 `json:"errorMessage,omitempty" bson:"errorMessage,omitempty"`
	Metadata     map[string]interface{} `json:"metadata,omitempty" bson:"metadata,omitempty"`
	CreatedAt    time.Time              `json:"createdAt" bson:"createdAt"`
	UpdatedAt    time.Time              `json:"updatedAt" bson:"updatedAt"`
}

// ChatMessage represents a single chat message in a conversation
type ChatMessage struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId"`
	SessionID string             `json:"sessionId" bson:"sessionId"` // Groups messages into conversations
	Text      string             `json:"text" bson:"text"`
	IsUser    bool               `json:"isUser" bson:"isUser"`
	Products  []ProductRef       `json:"products,omitempty" bson:"products,omitempty"` // Referenced products
	CreatedAt time.Time          `json:"createdAt" bson:"createdAt"`
}

// ProductRef is a lightweight reference to a product in chat
type ProductRef struct {
	ProductID primitive.ObjectID `json:"productId" bson:"productId"`
	Name      string             `json:"name" bson:"name"`
	Price     float64            `json:"price" bson:"price"`
	ImageURL  string             `json:"imageUrl" bson:"imageUrl"`
}

// ChatSession represents a chat conversation session
type ChatSession struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId"`
	Title     string             `json:"title" bson:"title"`
	Preview   string             `json:"preview" bson:"preview"` // First message preview
	CreatedAt time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// SearchHistory represents a user's AI search/prompt history
type SearchHistory struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId"`
	Prompt    string             `json:"prompt" bson:"prompt"`
	Type      string             `json:"type" bson:"type"` // "image" or "chat"
	CreatedAt time.Time          `json:"createdAt" bson:"createdAt"`
}

// CreateAICreationRequest is the request to save a new AI creation
type CreateAICreationRequest struct {
	Prompt       string                 `json:"prompt" validate:"required,min=3"`
	ImageURL     string                 `json:"imageUrl"`
	IsSuccessful bool                   `json:"isSuccessful"`
	ErrorMessage string                 `json:"errorMessage,omitempty"`
	Metadata     map[string]interface{} `json:"metadata,omitempty"`
}

// SendChatMessageRequest is the request to send a chat message
type SendChatMessageRequest struct {
	SessionID string       `json:"sessionId,omitempty"` // Optional, creates new session if empty
	Text      string       `json:"text" validate:"required,min=1"`
	IsUser    bool         `json:"isUser"`
	Products  []ProductRef `json:"products,omitempty"`
}

// AICreationsResponse is the response for listing creations
type AICreationsResponse struct {
	Creations  []AICreation `json:"creations"`
	Total      int64        `json:"total"`
	Page       int          `json:"page"`
	Limit      int          `json:"limit"`
	TotalPages int          `json:"totalPages"`
}

// ChatMessagesResponse is the response for listing chat messages
type ChatMessagesResponse struct {
	Messages []ChatMessage `json:"messages"`
	Session  *ChatSession  `json:"session,omitempty"`
	Total    int64         `json:"total"`
}

// ChatSessionsResponse is the response for listing chat sessions
type ChatSessionsResponse struct {
	Sessions []ChatSession `json:"sessions"`
	Total    int64         `json:"total"`
}

// AIStatistics represents user's AI usage statistics
type AIStatistics struct {
	TotalCreations      int64   `json:"totalCreations"`
	SuccessfulCreations int64   `json:"successfulCreations"`
	FailedCreations     int64   `json:"failedCreations"`
	TotalChats          int64   `json:"totalChats"`
	TotalSearches       int64   `json:"totalSearches"`
	SuccessRate         float64 `json:"successRate"`
}

// IntentType represents the type of AI intent
type IntentType string

const (
	IntentTypeText  IntentType = "text"
	IntentTypeImage IntentType = "image"
)

// IntentAnalysisRequest is the request to analyze prompt intent
type IntentAnalysisRequest struct {
	Prompt string `json:"prompt" validate:"required,min=3"`
}

// IntentAnalysisResponse is the response from intent analysis
type IntentAnalysisResponse struct {
	Intent           IntentType `json:"intent"`
	TextConfidence   float64    `json:"textConfidence"`
	ImageConfidence  float64    `json:"imageConfidence"`
	Reason           string     `json:"reason"`
	EnhancedPrompt   string     `json:"enhancedPrompt,omitempty"`
	IsProfileView    bool       `json:"isProfileView"`
}

// UnifiedAIRequest is the request for the unified AI endpoint
type UnifiedAIRequest struct {
	Prompt string `json:"prompt" validate:"required,min=3"`
}

// UnifiedAIResponse is the unified response for both text and image results
type UnifiedAIResponse struct {
	Intent           IntentType          `json:"intent"`
	TextConfidence   float64             `json:"textConfidence"`
	ImageConfidence  float64             `json:"imageConfidence"`

	// Text results (product search)
	Products         []ProductRef        `json:"products,omitempty"`
	TextResponse     string              `json:"textResponse,omitempty"`

	// Image generation result
	ImageURL         string              `json:"imageUrl,omitempty"`
	ImageDescription string              `json:"imageDescription,omitempty"`
	IsProfileView    bool                `json:"isProfileView"`

	// Metadata
	ProcessingTime   int64               `json:"processingTimeMs"`
}

// LibraryImage represents an image in the user's library
type LibraryImage struct {
	ID           primitive.ObjectID     `json:"id" bson:"_id,omitempty"`
	UserID       primitive.ObjectID     `json:"userId" bson:"userId"`
	Prompt       string                 `json:"prompt" bson:"prompt"`
	ImageURL     string                 `json:"imageUrl" bson:"imageUrl"`
	ThumbnailURL string                 `json:"thumbnailUrl,omitempty" bson:"thumbnailUrl,omitempty"`
	IsProfileView bool                  `json:"isProfileView" bson:"isProfileView"`
	ViewType     string                 `json:"viewType" bson:"viewType"` // "profile", "front", "top", etc.
	Metadata     map[string]interface{} `json:"metadata,omitempty" bson:"metadata,omitempty"`
	Tags         []string               `json:"tags,omitempty" bson:"tags,omitempty"`
	IsFavorite   bool                   `json:"isFavorite" bson:"isFavorite"`
	CreatedAt    time.Time              `json:"createdAt" bson:"createdAt"`
	UpdatedAt    time.Time              `json:"updatedAt" bson:"updatedAt"`
}

// LibraryResponse is the response for listing library images
type LibraryResponse struct {
	Images     []LibraryImage `json:"images"`
	Total      int64          `json:"total"`
	Page       int            `json:"page"`
	Limit      int            `json:"limit"`
	TotalPages int            `json:"totalPages"`
}

// ==================== Token Tracking ====================

// TokenUsage tracks a user's AI token consumption
type TokenUsage struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID         primitive.ObjectID `json:"userId" bson:"userId"`
	Month          string             `json:"month" bson:"month"`           // Format: "2025-01"
	TokensUsed     int64              `json:"tokensUsed" bson:"tokensUsed"` // Total tokens used this month
	TokenLimit     int64              `json:"tokenLimit" bson:"tokenLimit"` // Monthly limit (default 1M)
	ImageCount     int                `json:"imageCount" bson:"imageCount"` // Number of images generated
	LastGeneratedAt *time.Time        `json:"lastGeneratedAt,omitempty" bson:"lastGeneratedAt,omitempty"`
	CreatedAt      time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt      time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// Default monthly token limit (1 million tokens)
const DefaultMonthlyTokenLimit int64 = 1000000

// Estimated tokens per image generation (Gemini 2.5 Flash)
const EstimatedTokensPerImage int64 = 5000

// TokenUsageResponse is the response for token usage queries
type TokenUsageResponse struct {
	TokensUsed      int64   `json:"tokensUsed"`
	TokenLimit      int64   `json:"tokenLimit"`
	TokensRemaining int64   `json:"tokensRemaining"`
	UsagePercent    float64 `json:"usagePercent"`
	ImageCount      int     `json:"imageCount"`
	CanGenerate     bool    `json:"canGenerate"`
	ResetDate       string  `json:"resetDate"` // First day of next month
	Month           string  `json:"month"`
}

// ==================== AI Price Estimation ====================

// JewelryType for price estimation
type JewelryType string

const (
	JewelryTypeRing      JewelryType = "ring"
	JewelryTypeNecklace  JewelryType = "necklace"
	JewelryTypeBracelet  JewelryType = "bracelet"
	JewelryTypeEarring   JewelryType = "earring"
	JewelryTypePendant   JewelryType = "pendant"
	JewelryTypeBangle    JewelryType = "bangle"
	JewelryTypeOther     JewelryType = "other"
)

// MetalType for price estimation
type MetalType string

const (
	MetalTypeGold14K    MetalType = "gold_14k"
	MetalTypeGold18K    MetalType = "gold_18k"
	MetalTypeGold22K    MetalType = "gold_22k"
	MetalTypeSilver     MetalType = "silver"
	MetalTypePlatinum   MetalType = "platinum"
	MetalTypeRoseGold   MetalType = "rose_gold"
	MetalTypeWhiteGold  MetalType = "white_gold"
)

// PriceEstimate represents estimated pricing for a custom AI design
type PriceEstimate struct {
	JewelryType      JewelryType `json:"jewelryType"`
	MetalType        MetalType   `json:"metalType"`
	EstimatedWeight  float64     `json:"estimatedWeight"`  // in grams
	MetalPrice       float64     `json:"metalPrice"`       // per gram
	BasePrice        float64     `json:"basePrice"`        // metal cost
	MakingCharges    float64     `json:"makingCharges"`    // craftsmanship
	CustomBuildFee   float64     `json:"customBuildFee"`   // fixed ₹2000
	StoneEstimate    float64     `json:"stoneEstimate"`    // if stones detected
	MinPrice         float64     `json:"minPrice"`         // budget range low
	MaxPrice         float64     `json:"maxPrice"`         // budget range high
	Currency         string      `json:"currency"`
	PriceBreakdown   string      `json:"priceBreakdown"`   // human-readable
}

// Custom build fee (fixed)
const CustomBuildFee float64 = 2000.0

// Base metal prices per gram (approximate market rates in INR)
var MetalPrices = map[MetalType]float64{
	MetalTypeGold14K:   4500,
	MetalTypeGold18K:   5800,
	MetalTypeGold22K:   6500,
	MetalTypeSilver:    75,
	MetalTypePlatinum:  3200,
	MetalTypeRoseGold:  5500,
	MetalTypeWhiteGold: 5600,
}

// Estimated weights by jewelry type (in grams)
var EstimatedWeights = map[JewelryType]struct{ Min, Max float64 }{
	JewelryTypeRing:     {2.0, 8.0},
	JewelryTypeNecklace: {8.0, 25.0},
	JewelryTypeBracelet: {6.0, 20.0},
	JewelryTypeEarring:  {2.0, 6.0},
	JewelryTypePendant:  {2.0, 10.0},
	JewelryTypeBangle:   {10.0, 30.0},
	JewelryTypeOther:    {3.0, 15.0},
}

// Making charges percentage by jewelry complexity
const MakingChargePercent float64 = 0.15 // 15% of metal cost

// AIOrderRequest is the request to place a custom order from AI design
type AIOrderRequest struct {
	CreationID    string      `json:"creationId" validate:"required"`
	JewelryType   JewelryType `json:"jewelryType"`
	MetalType     MetalType   `json:"metalType"`
	Size          string      `json:"size,omitempty"`
	Notes         string      `json:"notes,omitempty"`
	ContactPhone  string      `json:"contactPhone" validate:"required"`
	ContactEmail  string      `json:"contactEmail" validate:"required"`
}
