package handlers

import (
	"net/http"

	"thyne-jewels-backend/internal/middleware"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

type ReviewHandler struct {
	reviewService services.ReviewService
	authService   services.AuthService
}

func NewReviewHandler(reviewService services.ReviewService, authService services.AuthService) *ReviewHandler {
	return &ReviewHandler{
		reviewService: reviewService,
		authService:   authService,
	}
}

// CreateReview creates a new product review
// @Summary Create review
// @Description Create a new product review
// @Tags Reviews
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body object true "Review creation data"
// @Success 201 {object} map[string]interface{} "Review created successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /reviews [post]
func (h *ReviewHandler) CreateReview(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Authentication required",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	var req models.CreateReviewRequest
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

	review, err := h.reviewService.CreateReview(userID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "REVIEW_CREATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    review,
		"message": "Review created successfully",
	})
}

// UpdateReview updates an existing review
// @Summary Update review
// @Description Update an existing product review
// @Tags Reviews
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Review ID"
// @Param request body object true "Review update data"
// @Success 200 {object} map[string]interface{} "Review updated successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 404 {object} map[string]interface{} "Review not found"
// @Router /reviews/{id} [put]
func (h *ReviewHandler) UpdateReview(c *gin.Context) {
	_, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Authentication required",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	reviewID := c.Param("id")
	if reviewID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Review ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.UpdateReviewRequest
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

	review, err := h.reviewService.UpdateReview(reviewID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "REVIEW_UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    review,
		"message": "Review updated successfully",
	})
}

// DeleteReview deletes a review
// @Summary Delete review
// @Description Delete an existing product review
// @Tags Reviews
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Review ID"
// @Success 200 {object} map[string]interface{} "Review deleted successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 404 {object} map[string]interface{} "Review not found"
// @Router /reviews/{id} [delete]
func (h *ReviewHandler) DeleteReview(c *gin.Context) {
	_, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Authentication required",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	reviewID := c.Param("id")
	if reviewID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Review ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.reviewService.DeleteReview(reviewID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "REVIEW_DELETION_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Review deleted successfully",
	})
}
