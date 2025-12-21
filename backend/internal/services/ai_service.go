package services

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	openai "github.com/sashabaranov/go-openai"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type AIService struct {
	aiRepo repository.AIRepository
}

func NewAIService(aiRepo repository.AIRepository) *AIService {
	return &AIService{
		aiRepo: aiRepo,
	}
}

// ==================== Intent Filtering ====================

// AnalyzeIntent uses OpenAI to intelligently classify user intent
func (s *AIService) AnalyzeIntent(ctx context.Context, prompt string) (*models.IntentAnalysisResponse, error) {
	prompt = strings.TrimSpace(prompt)

	// Get OpenAI API key
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		// Fallback to simple heuristics if no API key
		fmt.Println("OPENAI_API_KEY not set, using fallback")
		return s.analyzeIntentFallback(prompt)
	}

	// Create OpenAI client
	client := openai.NewClient(apiKey)

	// Create classification prompt
	classificationPrompt := fmt.Sprintf(`You are an intent classifier for a jewelry e-commerce app. Analyze the user's query and determine their intent.

User Query: "%s"

Classify as one of two intents:
1. "search" - User wants to FIND, BROWSE, or BUY existing products from the catalog
   Examples: "show me rings under 50k", "find gold necklaces", "what earrings do you have", "budget friendly bangles"

2. "generate" - User wants to CREATE, DESIGN, or IMAGINE a new custom jewelry piece
   Examples: "design a vintage ruby ring", "create a modern minimalist bracelet", "imagine a floral pendant"

IMPORTANT RULES:
- If the user mentions price, budget, cost, or any monetary terms (lakh, rupees, k, thousand) → classify as "search"
- If the user asks to "show", "find", "get", "give", "list" products → classify as "search"
- If the user asks to "create", "design", "generate", "make", "imagine" → classify as "generate"
- When in doubt, prefer "search" (safer default)

Respond ONLY with valid JSON in this exact format:
{"intent": "search" or "generate", "confidence": 0-100, "reason": "brief explanation"}`, prompt)

	// Call OpenAI
	resp, err := client.CreateChatCompletion(
		ctx,
		openai.ChatCompletionRequest{
			Model: openai.GPT4oMini,
			Messages: []openai.ChatCompletionMessage{
				{
					Role:    openai.ChatMessageRoleUser,
					Content: classificationPrompt,
				},
			},
			Temperature: 0.1, // Low temperature for consistent classification
		},
	)
	if err != nil {
		fmt.Printf("OpenAI API error: %v, using fallback\n", err)
		return s.analyzeIntentFallback(prompt)
	}

	// Parse response
	if len(resp.Choices) == 0 {
		return s.analyzeIntentFallback(prompt)
	}

	responseText := resp.Choices[0].Message.Content

	// Clean up response (remove markdown code blocks if present)
	responseText = strings.TrimSpace(responseText)
	responseText = strings.TrimPrefix(responseText, "```json")
	responseText = strings.TrimPrefix(responseText, "```")
	responseText = strings.TrimSuffix(responseText, "```")
	responseText = strings.TrimSpace(responseText)

	// Parse JSON response
	var result struct {
		Intent     string  `json:"intent"`
		Confidence float64 `json:"confidence"`
		Reason     string  `json:"reason"`
	}

	if err := json.Unmarshal([]byte(responseText), &result); err != nil {
		fmt.Printf("Failed to parse OpenAI response: %v, response: %s\n", err, responseText)
		return s.analyzeIntentFallback(prompt)
	}

	// Map to our intent types
	var intent models.IntentType
	var textConfidence, imageConfidence float64

	if result.Intent == "search" {
		intent = models.IntentTypeText
		textConfidence = result.Confidence
		imageConfidence = 100 - result.Confidence
	} else {
		intent = models.IntentTypeImage
		imageConfidence = result.Confidence
		textConfidence = 100 - result.Confidence
	}

	// Enhance prompt for image generation if needed
	enhancedPrompt := ""
	if intent == models.IntentTypeImage {
		enhancedPrompt = enhanceForProfileView(prompt)
	}

	return &models.IntentAnalysisResponse{
		Intent:          intent,
		TextConfidence:  textConfidence,
		ImageConfidence: imageConfidence,
		Reason:          result.Reason,
		EnhancedPrompt:  enhancedPrompt,
		IsProfileView:   intent == models.IntentTypeImage,
	}, nil
}

// GenerateChatResponse generates a chat response using OpenAI
func (s *AIService) GenerateChatResponse(ctx context.Context, req *models.ChatGenerateRequest) (*models.ChatGenerateResponse, error) {
	// Get OpenAI API key
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		return &models.ChatGenerateResponse{
			Message: "I'm sorry, the AI service is currently unavailable. Please try again later.",
			Success: false,
		}, nil
	}

	// Create OpenAI client
	client := openai.NewClient(apiKey)

	// Build system prompt based on request type
	var systemPrompt string
	if req.Type == "product_recommendation" {
		systemPrompt = `You are a friendly jewelry shopping assistant at Thyne Jewels, an Indian jewelry store.
Your role is to help customers find the perfect jewelry pieces.
Be warm, helpful, and knowledgeable about jewelry (metals, stones, designs, traditions).
Keep responses concise (3-4 sentences max).
Don't include prices in your response - customers will see them in product cards.
Consider Indian jewelry traditions and preferences when relevant.`
	} else {
		systemPrompt = `You are a knowledgeable jewelry expert assistant at Thyne Jewels, an Indian jewelry store.
Provide helpful, informative responses about jewelry (materials, care, traditions, styling).
Be friendly and conversational.
Keep responses concise (3-5 sentences).
Consider Indian jewelry traditions and preferences when relevant.
If customers seem interested in buying, suggest they ask for product recommendations with their budget and preferences.`
	}

	// Build user prompt
	userPrompt := req.UserMessage
	if req.ProductContext != "" {
		userPrompt = fmt.Sprintf("User asked: \"%s\"\n\nHere are matching products:\n%s\n\nProvide a helpful response highlighting 2-3 top recommendations.", req.UserMessage, req.ProductContext)
	}

	// Call OpenAI
	resp, err := client.CreateChatCompletion(
		ctx,
		openai.ChatCompletionRequest{
			Model: openai.GPT4oMini,
			Messages: []openai.ChatCompletionMessage{
				{
					Role:    openai.ChatMessageRoleSystem,
					Content: systemPrompt,
				},
				{
					Role:    openai.ChatMessageRoleUser,
					Content: userPrompt,
				},
			},
			Temperature: 0.7,
			MaxTokens:   500,
		},
	)
	if err != nil {
		fmt.Printf("OpenAI API error in chat generation: %v\n", err)
		return &models.ChatGenerateResponse{
			Message: "I'm sorry, I encountered an error. Please try again.",
			Success: false,
		}, nil
	}

	if len(resp.Choices) == 0 {
		return &models.ChatGenerateResponse{
			Message: "I'm sorry, I couldn't generate a response. Please try again.",
			Success: false,
		}, nil
	}

	return &models.ChatGenerateResponse{
		Message: resp.Choices[0].Message.Content,
		Success: true,
	}, nil
}

// AnalyzeAndRespond combines intent analysis and response generation in one call
func (s *AIService) AnalyzeAndRespond(ctx context.Context, req *models.ChatFullRequest, userID primitive.ObjectID) (*models.ChatFullResponse, error) {
	// Get current token usage for the user
	var tokensUsed, tokensRemaining, tokenLimit int64 = 0, models.DefaultMonthlyTokenLimit, models.DefaultMonthlyTokenLimit

	if userID != primitive.NilObjectID {
		usage, err := s.GetTokenUsage(ctx, userID)
		if err == nil {
			tokensUsed = usage.TokensUsed
			tokensRemaining = usage.TokensRemaining
			tokenLimit = usage.TokenLimit
		}

		// Check if user has tokens remaining
		if tokensRemaining <= 0 {
			return &models.ChatFullResponse{
				Message:         "You've used all your free tokens for this month. Your tokens will reset on the 1st of next month.",
				Intent:          "general",
				Confidence:      0,
				Success:         false,
				TokensUsed:      tokensUsed,
				TokensRemaining: 0,
				TokenLimit:      tokenLimit,
			}, nil
		}
	}

	// Get OpenAI API key
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		return &models.ChatFullResponse{
			Message:         "I'm sorry, the AI service is currently unavailable.",
			Intent:          "general",
			Confidence:      0,
			Success:         false,
			TokensUsed:      tokensUsed,
			TokensRemaining: tokensRemaining,
			TokenLimit:      tokenLimit,
		}, nil
	}

	// Create OpenAI client
	client := openai.NewClient(apiKey)

	// Combined prompt for intent analysis and response
	prompt := fmt.Sprintf(`You are a helpful jewelry shopping assistant at Thyne Jewels (Indian jewelry store).

User message: "%s"

Analyze the user's intent and provide a helpful response.

Return a JSON response with:
{
  "intent": "search" (wants to find/buy products) or "general" (question/advice),
  "confidence": 0-100,
  "response": "your helpful response here",
  "filters": {
    "category": "rings/necklaces/earrings/bracelets/pendants/bangles" or null,
    "minPrice": number or null,
    "maxPrice": number or null,
    "metalType": "gold/silver/platinum" or null
  }
}

Rules:
- If user mentions price/budget → intent is "search"
- If user asks to show/find/list products → intent is "search"
- Keep response concise (2-4 sentences)
- Be friendly and knowledgeable about jewelry`, req.Message)

	resp, err := client.CreateChatCompletion(
		ctx,
		openai.ChatCompletionRequest{
			Model: openai.GPT4oMini,
			Messages: []openai.ChatCompletionMessage{
				{
					Role:    openai.ChatMessageRoleUser,
					Content: prompt,
				},
			},
			Temperature: 0.3,
		},
	)
	if err != nil {
		fmt.Printf("OpenAI API error: %v\n", err)
		return &models.ChatFullResponse{
			Message:         "I'm sorry, I encountered an error. Please try again.",
			Intent:          "general",
			Confidence:      0,
			Success:         false,
			TokensUsed:      tokensUsed,
			TokensRemaining: tokensRemaining,
			TokenLimit:      tokenLimit,
		}, nil
	}

	if len(resp.Choices) == 0 {
		return &models.ChatFullResponse{
			Message:         "I couldn't process your request. Please try again.",
			Intent:          "general",
			Confidence:      0,
			Success:         false,
			TokensUsed:      tokensUsed,
			TokensRemaining: tokensRemaining,
			TokenLimit:      tokenLimit,
		}, nil
	}

	// Track token usage if user is authenticated
	actualTokensUsed := int64(resp.Usage.TotalTokens)
	if userID != primitive.NilObjectID {
		_ = s.RecordTokenUsage(ctx, userID, actualTokensUsed)
		tokensUsed += actualTokensUsed
		tokensRemaining -= actualTokensUsed
		if tokensRemaining < 0 {
			tokensRemaining = 0
		}
	}

	// Parse response
	responseText := strings.TrimSpace(resp.Choices[0].Message.Content)
	responseText = strings.TrimPrefix(responseText, "```json")
	responseText = strings.TrimPrefix(responseText, "```")
	responseText = strings.TrimSuffix(responseText, "```")
	responseText = strings.TrimSpace(responseText)

	var result struct {
		Intent     string  `json:"intent"`
		Confidence float64 `json:"confidence"`
		Response   string  `json:"response"`
		Filters    struct {
			Category  *string  `json:"category"`
			MinPrice  *float64 `json:"minPrice"`
			MaxPrice  *float64 `json:"maxPrice"`
			MetalType *string  `json:"metalType"`
		} `json:"filters"`
	}

	if err := json.Unmarshal([]byte(responseText), &result); err != nil {
		// If parsing fails, return the raw response as general
		return &models.ChatFullResponse{
			Message:         responseText,
			Intent:          "general",
			Confidence:      50,
			Success:         true,
			TokensUsed:      tokensUsed,
			TokensRemaining: tokensRemaining,
			TokenLimit:      tokenLimit,
		}, nil
	}

	return &models.ChatFullResponse{
		Message:         result.Response,
		Intent:          result.Intent,
		Confidence:      result.Confidence,
		Category:        result.Filters.Category,
		MinPrice:        result.Filters.MinPrice,
		MaxPrice:        result.Filters.MaxPrice,
		MetalType:       result.Filters.MetalType,
		Success:         true,
		TokensUsed:      tokensUsed,
		TokensRemaining: tokensRemaining,
		TokenLimit:      tokenLimit,
	}, nil
}

// analyzeIntentFallback provides simple keyword-based fallback when Gemini is unavailable
func (s *AIService) analyzeIntentFallback(prompt string) (*models.IntentAnalysisResponse, error) {
	prompt = strings.ToLower(prompt)

	// Simple check: if contains price/budget indicators, it's a search
	searchIndicators := []string{
		"show", "find", "search", "browse", "list", "get", "give",
		"under", "below", "above", "budget", "price", "cost",
		"lakh", "lakhs", "thousand", "rupees", "rs", "₹", "k",
		"buy", "purchase", "available", "stock", "any", "all",
	}

	generateIndicators := []string{
		"create", "design", "generate", "make", "imagine",
		"visualize", "draw", "sketch", "concept", "custom design",
	}

	searchScore := 0
	generateScore := 0

	for _, indicator := range searchIndicators {
		if strings.Contains(prompt, indicator) {
			searchScore++
		}
	}

	for _, indicator := range generateIndicators {
		if strings.Contains(prompt, indicator) {
			generateScore++
		}
	}

	var intent models.IntentType
	var textConfidence, imageConfidence float64
	var reason string

	if searchScore > generateScore || searchScore > 0 {
		intent = models.IntentTypeText
		textConfidence = 70
		imageConfidence = 30
		reason = "Query indicates product search (fallback)"
	} else if generateScore > 0 {
		intent = models.IntentTypeImage
		textConfidence = 30
		imageConfidence = 70
		reason = "Query indicates design generation (fallback)"
	} else {
		// Default to search
		intent = models.IntentTypeText
		textConfidence = 60
		imageConfidence = 40
		reason = "Defaulting to search for safety (fallback)"
	}

	enhancedPrompt := ""
	if intent == models.IntentTypeImage {
		enhancedPrompt = enhanceForProfileView(prompt)
	}

	return &models.IntentAnalysisResponse{
		Intent:          intent,
		TextConfidence:  textConfidence,
		ImageConfidence: imageConfidence,
		Reason:          reason,
		EnhancedPrompt:  enhancedPrompt,
		IsProfileView:   intent == models.IntentTypeImage,
	}, nil
}

// enhanceForProfileView enhances the prompt to ensure profile view output
func enhanceForProfileView(prompt string) string {
	return prompt + " - IMPORTANT: Generate as a side profile view (profile/side angle), suitable for CAD designers to work with. Show the jewelry piece from a side angle that clearly displays depth, dimension, and silhouette for technical design reference."
}

// ==================== Token Tracking ====================

// GetTokenUsage gets the current month's token usage for a user
func (s *AIService) GetTokenUsage(ctx context.Context, userID primitive.ObjectID) (*models.TokenUsageResponse, error) {
	currentMonth := time.Now().Format("2006-01")

	usage, err := s.aiRepo.GetTokenUsage(ctx, userID, currentMonth)
	if err != nil {
		// Create new usage record if doesn't exist
		usage = &models.TokenUsage{
			UserID:     userID,
			Month:      currentMonth,
			TokensUsed: 0,
			TokenLimit: models.DefaultMonthlyTokenLimit,
			ImageCount: 0,
			CreatedAt:  time.Now(),
			UpdatedAt:  time.Now(),
		}
		if err := s.aiRepo.CreateTokenUsage(ctx, usage); err != nil {
			return nil, fmt.Errorf("failed to create token usage: %w", err)
		}
	}

	tokensRemaining := usage.TokenLimit - usage.TokensUsed
	if tokensRemaining < 0 {
		tokensRemaining = 0
	}

	usagePercent := float64(usage.TokensUsed) / float64(usage.TokenLimit) * 100
	canGenerate := usage.TokensUsed+models.EstimatedTokensPerImage <= usage.TokenLimit

	// Calculate reset date (first day of next month)
	now := time.Now()
	nextMonth := now.AddDate(0, 1, 0)
	resetDate := time.Date(nextMonth.Year(), nextMonth.Month(), 1, 0, 0, 0, 0, nextMonth.Location())

	return &models.TokenUsageResponse{
		TokensUsed:      usage.TokensUsed,
		TokenLimit:      usage.TokenLimit,
		TokensRemaining: tokensRemaining,
		UsagePercent:    usagePercent,
		ImageCount:      usage.ImageCount,
		CanGenerate:     canGenerate,
		ResetDate:       resetDate.Format("2006-01-02"),
		Month:           currentMonth,
	}, nil
}

// CheckCanGenerate checks if a user can generate an image based on token limits
func (s *AIService) CheckCanGenerate(ctx context.Context, userID primitive.ObjectID) (bool, string, error) {
	usage, err := s.GetTokenUsage(ctx, userID)
	if err != nil {
		return false, "", err
	}

	if !usage.CanGenerate {
		return false, fmt.Sprintf("Monthly token limit reached. You've used %d of %d tokens. Resets on %s.",
			usage.TokensUsed, usage.TokenLimit, usage.ResetDate), nil
	}

	return true, "", nil
}

// RecordTokenUsage records token usage after an image generation
func (s *AIService) RecordTokenUsage(ctx context.Context, userID primitive.ObjectID, tokensUsed int64) error {
	currentMonth := time.Now().Format("2006-01")
	now := time.Now()

	return s.aiRepo.IncrementTokenUsage(ctx, userID, currentMonth, tokensUsed, &now)
}

// ==================== Price Estimation ====================

// EstimatePrice calculates the estimated price range for a custom AI design
func (s *AIService) EstimatePrice(ctx context.Context, prompt string, jewelryType models.JewelryType, metalType models.MetalType) (*models.PriceEstimate, error) {
	// Default to ring and 18K gold if not specified
	if jewelryType == "" {
		jewelryType = s.detectJewelryType(prompt)
	}
	if metalType == "" {
		metalType = s.detectMetalType(prompt)
	}

	// Get weight range
	weightRange, ok := models.EstimatedWeights[jewelryType]
	if !ok {
		weightRange = models.EstimatedWeights[models.JewelryTypeOther]
	}

	// Get metal price per gram
	metalPrice, ok := models.MetalPrices[metalType]
	if !ok {
		metalPrice = models.MetalPrices[models.MetalTypeGold18K] // default
	}

	// Calculate min and max prices
	minWeight := weightRange.Min
	maxWeight := weightRange.Max
	avgWeight := (minWeight + maxWeight) / 2

	// Base calculation
	minBasePrice := minWeight * metalPrice
	maxBasePrice := maxWeight * metalPrice
	avgBasePrice := avgWeight * metalPrice

	// Making charges (15% of metal cost)
	minMaking := minBasePrice * models.MakingChargePercent
	maxMaking := maxBasePrice * models.MakingChargePercent

	// Stone estimate (if prompt mentions stones)
	stoneEstimate := s.estimateStonePrice(prompt)

	// Calculate final prices
	minPrice := minBasePrice + minMaking + models.CustomBuildFee + (stoneEstimate * 0.5)
	maxPrice := maxBasePrice + maxMaking + models.CustomBuildFee + (stoneEstimate * 1.5)

	// Round to nearest 500
	minPrice = float64(int(minPrice/500) * 500)
	maxPrice = float64(int(maxPrice/500+1) * 500)

	// Create breakdown string
	breakdown := fmt.Sprintf(
		"Metal (%s): ₹%.0f/g × %.1f-%.1fg = ₹%.0f-%.0f\n"+
			"Making Charges (15%%): ₹%.0f-%.0f\n"+
			"Custom Build Fee: ₹%.0f\n"+
			"Stones (estimated): ₹%.0f",
		metalType, metalPrice, minWeight, maxWeight, minBasePrice, maxBasePrice,
		minMaking, maxMaking,
		models.CustomBuildFee,
		stoneEstimate,
	)

	return &models.PriceEstimate{
		JewelryType:     jewelryType,
		MetalType:       metalType,
		EstimatedWeight: avgWeight,
		MetalPrice:      metalPrice,
		BasePrice:       avgBasePrice,
		MakingCharges:   avgBasePrice * models.MakingChargePercent,
		CustomBuildFee:  models.CustomBuildFee,
		StoneEstimate:   stoneEstimate,
		MinPrice:        minPrice,
		MaxPrice:        maxPrice,
		Currency:        "INR",
		PriceBreakdown:  breakdown,
	}, nil
}

// detectJewelryType detects jewelry type from prompt
func (s *AIService) detectJewelryType(prompt string) models.JewelryType {
	prompt = strings.ToLower(prompt)

	typeKeywords := map[models.JewelryType][]string{
		models.JewelryTypeRing:     {"ring", "band", "engagement", "wedding ring", "solitaire"},
		models.JewelryTypeNecklace: {"necklace", "chain", "choker", "collar"},
		models.JewelryTypeBracelet: {"bracelet", "cuff", "tennis bracelet", "charm bracelet"},
		models.JewelryTypeEarring:  {"earring", "studs", "hoops", "drops", "danglers"},
		models.JewelryTypePendant:  {"pendant", "locket", "medallion"},
		models.JewelryTypeBangle:   {"bangle", "kada"},
	}

	for jType, keywords := range typeKeywords {
		for _, keyword := range keywords {
			if strings.Contains(prompt, keyword) {
				return jType
			}
		}
	}

	return models.JewelryTypeOther
}

// detectMetalType detects metal type from prompt
func (s *AIService) detectMetalType(prompt string) models.MetalType {
	prompt = strings.ToLower(prompt)

	if strings.Contains(prompt, "platinum") {
		return models.MetalTypePlatinum
	}
	if strings.Contains(prompt, "silver") || strings.Contains(prompt, "sterling") {
		return models.MetalTypeSilver
	}
	if strings.Contains(prompt, "rose gold") || strings.Contains(prompt, "rosegold") {
		return models.MetalTypeRoseGold
	}
	if strings.Contains(prompt, "white gold") || strings.Contains(prompt, "whitegold") {
		return models.MetalTypeWhiteGold
	}
	if strings.Contains(prompt, "22k") || strings.Contains(prompt, "22 karat") {
		return models.MetalTypeGold22K
	}
	if strings.Contains(prompt, "14k") || strings.Contains(prompt, "14 karat") {
		return models.MetalTypeGold14K
	}

	// Default to 18K gold
	return models.MetalTypeGold18K
}

// estimateStonePrice estimates stone price based on prompt
func (s *AIService) estimateStonePrice(prompt string) float64 {
	prompt = strings.ToLower(prompt)
	var estimate float64 = 0

	// Diamond keywords
	if strings.Contains(prompt, "diamond") || strings.Contains(prompt, "solitaire") {
		estimate += 15000 // Base diamond estimate
		if strings.Contains(prompt, "large") || strings.Contains(prompt, "big") {
			estimate += 20000
		}
	}

	// Precious stones
	if strings.Contains(prompt, "ruby") || strings.Contains(prompt, "emerald") || strings.Contains(prompt, "sapphire") {
		estimate += 8000
	}

	// Semi-precious
	if strings.Contains(prompt, "amethyst") || strings.Contains(prompt, "topaz") ||
		strings.Contains(prompt, "garnet") || strings.Contains(prompt, "peridot") {
		estimate += 3000
	}

	// Pearls
	if strings.Contains(prompt, "pearl") {
		estimate += 5000
	}

	return estimate
}

// ==================== AI Creations ====================

// SaveCreation saves a new AI creation for a user
func (s *AIService) SaveCreation(ctx context.Context, userID primitive.ObjectID, req *models.CreateAICreationRequest) (*models.AICreation, error) {
	creation := &models.AICreation{
		UserID:       userID,
		Prompt:       req.Prompt,
		ImageURL:     req.ImageURL,
		IsSuccessful: req.IsSuccessful,
		ErrorMessage: req.ErrorMessage,
		Metadata:     req.Metadata,
	}

	err := s.aiRepo.CreateCreation(ctx, creation)
	if err != nil {
		return nil, err
	}

	return creation, nil
}

// GetCreations retrieves all creations for a user with pagination
func (s *AIService) GetCreations(ctx context.Context, userID primitive.ObjectID, page, limit int) (*models.AICreationsResponse, error) {
	creations, total, err := s.aiRepo.GetCreationsByUserID(ctx, userID, page, limit)
	if err != nil {
		return nil, err
	}

	totalPages := int(total) / limit
	if int(total)%limit > 0 {
		totalPages++
	}

	return &models.AICreationsResponse{
		Creations:  creations,
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: totalPages,
	}, nil
}

// GetCreation retrieves a single creation by ID
func (s *AIService) GetCreation(ctx context.Context, id primitive.ObjectID) (*models.AICreation, error) {
	return s.aiRepo.GetCreationByID(ctx, id)
}

// DeleteCreation deletes a creation
func (s *AIService) DeleteCreation(ctx context.Context, id primitive.ObjectID) error {
	return s.aiRepo.DeleteCreation(ctx, id)
}

// ClearCreations deletes all creations for a user
func (s *AIService) ClearCreations(ctx context.Context, userID primitive.ObjectID) error {
	return s.aiRepo.ClearCreationsByUserID(ctx, userID)
}

// ==================== Chat ====================

// SendChatMessage saves a chat message
func (s *AIService) SendChatMessage(ctx context.Context, userID primitive.ObjectID, req *models.SendChatMessageRequest) (*models.ChatMessage, error) {
	// Create or get session ID
	sessionID := req.SessionID
	if sessionID == "" {
		// Create a new session
		session := &models.ChatSession{
			UserID: userID,
			Title:  "New Chat",
		}
		if len(req.Text) > 50 {
			session.Preview = req.Text[:50] + "..."
		} else {
			session.Preview = req.Text
		}

		err := s.aiRepo.CreateChatSession(ctx, session)
		if err != nil {
			return nil, err
		}
		sessionID = session.ID.Hex()
	}

	message := &models.ChatMessage{
		UserID:    userID,
		SessionID: sessionID,
		Text:      req.Text,
		IsUser:    req.IsUser,
		Products:  req.Products,
	}

	err := s.aiRepo.CreateChatMessage(ctx, message)
	if err != nil {
		return nil, err
	}

	return message, nil
}

// GetChatMessages retrieves chat messages for a session
func (s *AIService) GetChatMessages(ctx context.Context, sessionID string, page, limit int) (*models.ChatMessagesResponse, error) {
	messages, total, err := s.aiRepo.GetChatMessagesBySession(ctx, sessionID, page, limit)
	if err != nil {
		return nil, err
	}

	return &models.ChatMessagesResponse{
		Messages: messages,
		Total:    total,
	}, nil
}

// GetChatHistory retrieves all chat messages for a user
func (s *AIService) GetChatHistory(ctx context.Context, userID primitive.ObjectID, page, limit int) (*models.ChatMessagesResponse, error) {
	messages, total, err := s.aiRepo.GetChatMessagesByUserID(ctx, userID, page, limit)
	if err != nil {
		return nil, err
	}

	return &models.ChatMessagesResponse{
		Messages: messages,
		Total:    total,
	}, nil
}

// GetChatSessions retrieves all chat sessions for a user
func (s *AIService) GetChatSessions(ctx context.Context, userID primitive.ObjectID, page, limit int) (*models.ChatSessionsResponse, error) {
	sessions, total, err := s.aiRepo.GetChatSessionsByUserID(ctx, userID, page, limit)
	if err != nil {
		return nil, err
	}

	return &models.ChatSessionsResponse{
		Sessions: sessions,
		Total:    total,
	}, nil
}

// ClearChat deletes all chat messages for a user
func (s *AIService) ClearChat(ctx context.Context, userID primitive.ObjectID) error {
	return s.aiRepo.ClearChatByUserID(ctx, userID)
}

// DeleteChatSession deletes a chat session and its messages
func (s *AIService) DeleteChatSession(ctx context.Context, sessionID primitive.ObjectID) error {
	return s.aiRepo.DeleteChatSession(ctx, sessionID)
}

// ==================== Search History ====================

// AddSearchHistory adds a search to history
func (s *AIService) AddSearchHistory(ctx context.Context, userID primitive.ObjectID, prompt, searchType string) error {
	history := &models.SearchHistory{
		UserID: userID,
		Prompt: prompt,
		Type:   searchType,
	}
	return s.aiRepo.AddSearchHistory(ctx, history)
}

// GetSearchHistory retrieves search history for a user
func (s *AIService) GetSearchHistory(ctx context.Context, userID primitive.ObjectID, limit int) ([]models.SearchHistory, error) {
	return s.aiRepo.GetSearchHistoryByUserID(ctx, userID, limit)
}

// ClearSearchHistory clears search history for a user
func (s *AIService) ClearSearchHistory(ctx context.Context, userID primitive.ObjectID) error {
	return s.aiRepo.ClearSearchHistoryByUserID(ctx, userID)
}

// ==================== Statistics ====================

// GetStatistics retrieves AI usage statistics for a user
func (s *AIService) GetStatistics(ctx context.Context, userID primitive.ObjectID) (*models.AIStatistics, error) {
	return s.aiRepo.GetUserAIStatistics(ctx, userID)
}
