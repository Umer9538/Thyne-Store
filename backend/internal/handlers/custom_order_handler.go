package handlers

import (
	"net/http"
	"strconv"

	"thyne-jewels-backend/internal/middleware"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

// CustomOrderHandler handles custom order API requests
type CustomOrderHandler struct {
	service     services.CustomOrderService
	authService services.AuthService
}

// NewCustomOrderHandler creates a new custom order handler
func NewCustomOrderHandler(service services.CustomOrderService, authService services.AuthService) *CustomOrderHandler {
	return &CustomOrderHandler{
		service:     service,
		authService: authService,
	}
}

// CreateOrder creates a new custom order
// @Summary Create custom order
// @Description Create a new custom AI jewelry order
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Param request body models.CreateCustomOrderRequest true "Custom order data"
// @Success 201 {object} map[string]interface{} "Order created successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /custom-orders [post]
func (h *CustomOrderHandler) CreateOrder(c *gin.Context) {
	userIDStr, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	var req models.CreateCustomOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data: " + err.Error(),
			"code":    "INVALID_INPUT",
		})
		return
	}

	order, err := h.service.CreateOrder(c.Request.Context(), userIDStr, guestSessionID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "ORDER_CREATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    order,
		"message": "Custom order created successfully. Our team will contact you soon.",
	})
}

// GetOrder retrieves a custom order by ID
// @Summary Get custom order
// @Description Get a custom order by its ID
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Param id path string true "Order ID"
// @Success 200 {object} map[string]interface{} "Order retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid order ID"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /custom-orders/{id} [get]
func (h *CustomOrderHandler) GetOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	order, err := h.service.GetOrder(c.Request.Context(), orderID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "ORDER_NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
	})
}

// GetUserOrders retrieves custom orders for the current user
// @Summary Get user's custom orders
// @Description Get all custom orders for the authenticated user
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Success 200 {object} map[string]interface{} "Orders retrieved successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /custom-orders/my-orders [get]
func (h *CustomOrderHandler) GetUserOrders(c *gin.Context) {
	userIDStr, exists := middleware.GetUserIDFromContext(c)
	if !exists || userIDStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Authentication required",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	orders, total, err := h.service.GetUserOrders(c.Request.Context(), userIDStr, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch orders",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"orders": orders,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"totalPages": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// AdminGetAllOrders retrieves all custom orders (admin only)
// @Summary Get all custom orders (Admin)
// @Description Get all custom orders with optional filters
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Param status query string false "Filter by status"
// @Success 200 {object} map[string]interface{} "Orders retrieved successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 403 {object} map[string]interface{} "Forbidden"
// @Router /admin/custom-orders [get]
func (h *CustomOrderHandler) AdminGetAllOrders(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	statusStr := c.Query("status")

	filter := models.CustomOrderFilter{
		Page:  page,
		Limit: limit,
	}

	if statusStr != "" {
		status := models.CustomOrderStatus(statusStr)
		filter.Status = &status
	}

	orders, total, err := h.service.GetAllOrders(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch orders",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"orders": orders,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"totalPages": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// AdminMarkAsContacted marks an order as contacted (admin only)
// @Summary Mark order as contacted (Admin)
// @Description Mark a custom order as contacted by the team
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Order ID"
// @Param request body models.MarkContactedRequest true "Contact info"
// @Success 200 {object} map[string]interface{} "Order marked as contacted"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /admin/custom-orders/{id}/contacted [post]
func (h *CustomOrderHandler) AdminMarkAsContacted(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.MarkContactedRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	order, err := h.service.MarkAsContacted(c.Request.Context(), orderID, req.ContactedBy, req.AdminNotes)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
		"message": "Order marked as contacted",
	})
}

// AdminConfirmOrder confirms an order with final price (admin only)
// @Summary Confirm custom order (Admin)
// @Description Confirm a custom order with the final price
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Order ID"
// @Param request body models.ConfirmOrderRequest true "Confirmation data"
// @Success 200 {object} map[string]interface{} "Order confirmed"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /admin/custom-orders/{id}/confirm [post]
func (h *CustomOrderHandler) AdminConfirmOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.ConfirmOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	order, err := h.service.ConfirmOrder(c.Request.Context(), orderID, req.FinalPrice, req.AdminNotes)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "CONFIRM_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
		"message": "Order confirmed with final price",
	})
}

// AdminUpdateStatus updates order status (admin only)
// @Summary Update custom order status (Admin)
// @Description Update the status of a custom order
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Order ID"
// @Param request body models.UpdateCustomOrderStatusRequest true "Status update data"
// @Success 200 {object} map[string]interface{} "Status updated"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /admin/custom-orders/{id}/status [put]
func (h *CustomOrderHandler) AdminUpdateStatus(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.UpdateCustomOrderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	order, err := h.service.UpdateStatus(c.Request.Context(), orderID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
		"message": "Order status updated",
	})
}

// AdminCancelOrder cancels an order (admin only)
// @Summary Cancel custom order (Admin)
// @Description Cancel a custom order
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Order ID"
// @Param reason query string false "Cancellation reason"
// @Success 200 {object} map[string]interface{} "Order cancelled"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /admin/custom-orders/{id}/cancel [post]
func (h *CustomOrderHandler) AdminCancelOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	reason := c.Query("reason")
	if reason == "" {
		var body struct {
			Reason string `json:"reason"`
		}
		c.ShouldBindJSON(&body)
		reason = body.Reason
	}

	order, err := h.service.CancelOrder(c.Request.Context(), orderID, reason)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "CANCEL_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
		"message": "Order cancelled",
	})
}

// AdminGetStatistics gets custom order statistics (admin only)
// @Summary Get custom order statistics (Admin)
// @Description Get statistics for custom orders
// @Tags Custom Orders
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "Statistics retrieved"
// @Router /admin/custom-orders/statistics [get]
func (h *CustomOrderHandler) AdminGetStatistics(c *gin.Context) {
	stats, err := h.service.GetStatistics(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch statistics",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}
