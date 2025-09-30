package handlers

import (
	"net/http"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

type GuestHandler struct {
	guestService services.GuestSessionService
}

func NewGuestHandler(guestService services.GuestSessionService) *GuestHandler {
	return &GuestHandler{
		guestService: guestService,
	}
}

// CreateSession creates a new guest session
// @Summary Create guest session
// @Description Create a new guest session for anonymous users
// @Tags Guest
// @Accept json
// @Produce json
// @Success 201 {object} map[string]interface{} "Guest session created successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /guest/session [post]
func (h *GuestHandler) CreateSession(c *gin.Context) {
	session, err := h.guestService.CreateSession()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to create guest session",
			"code":    "SESSION_CREATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    session.ToResponse(),
		"message": "Guest session created successfully",
	})
}

// GetSession gets a guest session by ID
// @Summary Get guest session
// @Description Get a guest session by its ID
// @Tags Guest
// @Accept json
// @Produce json
// @Param id path string true "Guest session ID"
// @Success 200 {object} map[string]interface{} "Guest session retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid session ID"
// @Failure 404 {object} map[string]interface{} "Session not found"
// @Router /guest/session/{id} [get]
func (h *GuestHandler) GetSession(c *gin.Context) {
	sessionID := c.Param("id")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Session ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	session, err := h.guestService.GetSession(sessionID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Session not found or expired",
			"code":    "SESSION_NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    session.ToResponse(),
	})
}

// UpdateSession updates a guest session
// @Summary Update guest session
// @Description Update a guest session
// @Tags Guest
// @Accept json
// @Produce json
// @Param id path string true "Guest session ID"
// @Param request body object true "Session update data"
// @Success 200 {object} map[string]interface{} "Guest session updated successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 404 {object} map[string]interface{} "Session not found"
// @Router /guest/session/{id} [put]
func (h *GuestHandler) UpdateSession(c *gin.Context) {
	sessionID := c.Param("id")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Session ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.UpdateGuestSessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	// Validate request
	if err := req.Validate(); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Validation failed: " + err.Error(),
			"code":    "VALIDATION_ERROR",
		})
		return
	}

	session, err := h.guestService.UpdateSession(sessionID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "SESSION_UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    session.ToResponse(),
		"message": "Guest session updated successfully",
	})
}

// DeleteSession deletes a guest session
// @Summary Delete guest session
// @Description Delete a guest session
// @Tags Guest
// @Accept json
// @Produce json
// @Param id path string true "Guest session ID"
// @Success 200 {object} map[string]interface{} "Guest session deleted successfully"
// @Failure 400 {object} map[string]interface{} "Invalid session ID"
// @Failure 404 {object} map[string]interface{} "Session not found"
// @Router /guest/session/{id} [delete]
func (h *GuestHandler) DeleteSession(c *gin.Context) {
	sessionID := c.Param("id")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Session ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.guestService.DeleteSession(sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to delete guest session",
			"code":    "SESSION_DELETION_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Guest session deleted successfully",
	})
}
