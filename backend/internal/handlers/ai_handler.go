package handlers

import (
	"net/http"
	"strconv"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type AIHandler struct {
	aiService *services.AIService
}

func NewAIHandler(aiService *services.AIService) *AIHandler {
	return &AIHandler{
		aiService: aiService,
	}
}

// Helper to get user ID from context
func (h *AIHandler) getUserID(c *gin.Context) (primitive.ObjectID, error) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		return primitive.NilObjectID, nil
	}
	return primitive.ObjectIDFromHex(userIDStr.(string))
}

// ==================== Intent Filtering ====================

// AnalyzeIntent analyzes a prompt to determine text vs image intent
// POST /api/v1/ai/analyze-intent
func (h *AIHandler) AnalyzeIntent(c *gin.Context) {
	var req models.IntentAnalysisRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.aiService.AnalyzeIntent(c.Request.Context(), req.Prompt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to analyze intent"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// ==================== AI Creations ====================

// SaveCreation saves a new AI creation
// POST /api/v1/ai/creations
func (h *AIHandler) SaveCreation(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req models.CreateAICreationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	creation, err := h.aiService.SaveCreation(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save creation"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    creation,
	})
}

// GetCreations retrieves all creations for the user
// GET /api/v1/ai/creations
func (h *AIHandler) GetCreations(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	response, err := h.aiService.GetCreations(c.Request.Context(), userID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get creations"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// GetCreation retrieves a single creation
// GET /api/v1/ai/creations/:id
func (h *AIHandler) GetCreation(c *gin.Context) {
	creationID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid creation ID"})
		return
	}

	creation, err := h.aiService.GetCreation(c.Request.Context(), creationID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Creation not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    creation,
	})
}

// DeleteCreation deletes a creation
// DELETE /api/v1/ai/creations/:id
func (h *AIHandler) DeleteCreation(c *gin.Context) {
	creationID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid creation ID"})
		return
	}

	err = h.aiService.DeleteCreation(c.Request.Context(), creationID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete creation"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Creation deleted successfully",
	})
}

// ClearCreations deletes all creations for the user
// DELETE /api/v1/ai/creations
func (h *AIHandler) ClearCreations(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	err = h.aiService.ClearCreations(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clear creations"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "All creations cleared",
	})
}

// ==================== Chat ====================

// SendChatMessage sends a chat message
// POST /api/v1/ai/chat/messages
func (h *AIHandler) SendChatMessage(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req models.SendChatMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	message, err := h.aiService.SendChatMessage(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    message,
	})
}

// GetChatMessages retrieves chat messages for a session
// GET /api/v1/ai/chat/sessions/:sessionId/messages
func (h *AIHandler) GetChatMessages(c *gin.Context) {
	sessionID := c.Param("sessionId")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Session ID required"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))

	response, err := h.aiService.GetChatMessages(c.Request.Context(), sessionID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get messages"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// GetChatHistory retrieves all chat messages for the user
// GET /api/v1/ai/chat/history
func (h *AIHandler) GetChatHistory(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))

	response, err := h.aiService.GetChatHistory(c.Request.Context(), userID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get chat history"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// GetChatSessions retrieves all chat sessions for the user
// GET /api/v1/ai/chat/sessions
func (h *AIHandler) GetChatSessions(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	response, err := h.aiService.GetChatSessions(c.Request.Context(), userID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get sessions"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// ClearChat clears all chat history for the user
// DELETE /api/v1/ai/chat
func (h *AIHandler) ClearChat(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	err = h.aiService.ClearChat(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clear chat"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Chat history cleared",
	})
}

// DeleteChatSession deletes a chat session
// DELETE /api/v1/ai/chat/sessions/:sessionId
func (h *AIHandler) DeleteChatSession(c *gin.Context) {
	sessionID, err := primitive.ObjectIDFromHex(c.Param("sessionId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid session ID"})
		return
	}

	err = h.aiService.DeleteChatSession(c.Request.Context(), sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete session"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Session deleted",
	})
}

// ==================== Search History ====================

// AddSearchHistory adds a search to history
// POST /api/v1/ai/search-history
func (h *AIHandler) AddSearchHistory(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		Prompt string `json:"prompt" binding:"required"`
		Type   string `json:"type"` // "image" or "chat"
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Type == "" {
		req.Type = "image"
	}

	err = h.aiService.AddSearchHistory(c.Request.Context(), userID, req.Prompt, req.Type)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add search history"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Search added to history",
	})
}

// GetSearchHistory retrieves search history for the user
// GET /api/v1/ai/search-history
func (h *AIHandler) GetSearchHistory(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	history, err := h.aiService.GetSearchHistory(c.Request.Context(), userID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get search history"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    history,
	})
}

// ClearSearchHistory clears search history for the user
// DELETE /api/v1/ai/search-history
func (h *AIHandler) ClearSearchHistory(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	err = h.aiService.ClearSearchHistory(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clear search history"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Search history cleared",
	})
}

// ==================== Statistics ====================

// GetStatistics retrieves AI usage statistics for the user
// GET /api/v1/ai/statistics
func (h *AIHandler) GetStatistics(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	stats, err := h.aiService.GetStatistics(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get statistics"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

// ==================== Token Tracking ====================

// GetTokenUsage gets current token usage for the authenticated user
// GET /api/v1/ai/tokens
func (h *AIHandler) GetTokenUsage(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	usage, err := h.aiService.GetTokenUsage(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get token usage"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    usage,
	})
}

// CheckCanGenerate checks if user can generate an image
// GET /api/v1/ai/tokens/can-generate
func (h *AIHandler) CheckCanGenerate(c *gin.Context) {
	userID, err := h.getUserID(c)
	if err != nil || userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	canGenerate, message, err := h.aiService.CheckCanGenerate(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check generation limit"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":     true,
		"canGenerate": canGenerate,
		"message":     message,
	})
}

// ==================== Price Estimation ====================

// EstimatePrice estimates price for an AI-generated jewelry design
// POST /api/v1/ai/estimate-price
func (h *AIHandler) EstimatePrice(c *gin.Context) {
	var req struct {
		Prompt      string `json:"prompt" binding:"required"`
		JewelryType string `json:"jewelryType,omitempty"`
		MetalType   string `json:"metalType,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	estimate, err := h.aiService.EstimatePrice(
		c.Request.Context(),
		req.Prompt,
		models.JewelryType(req.JewelryType),
		models.MetalType(req.MetalType),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to estimate price"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    estimate,
	})
}
