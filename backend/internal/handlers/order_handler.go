package handlers

import (
	"net/http"
	"strconv"

	"thyne-jewels-backend/internal/middleware"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

type OrderHandler struct {
	orderService   services.OrderService
	paymentService services.PaymentService
	authService    services.AuthService
}

func NewOrderHandler(orderService services.OrderService, paymentService services.PaymentService, authService services.AuthService) *OrderHandler {
	return &OrderHandler{
		orderService:   orderService,
		paymentService: paymentService,
		authService:    authService,
	}
}

// CreateOrder creates a new order
// @Summary Create order
// @Description Create a new order from cart items
// @Tags Orders
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body models.CreateOrderRequest true "Order creation data"
// @Success 201 {object} map[string]interface{} "Order created successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /orders [post]
func (h *OrderHandler) CreateOrder(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	var req models.CreateOrderRequest
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

	order, err := h.orderService.CreateOrder(userID, guestSessionID, &req)
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
		"message": "Order created successfully",
	})
}

// GetOrders gets user's orders
// @Summary Get orders
// @Description Get all orders for the authenticated user or guest
// @Tags Orders
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(10)
// @Success 200 {object} map[string]interface{} "Orders retrieved successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /orders [get]
func (h *OrderHandler) GetOrders(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	orders, total, err := h.orderService.GetOrders(userID, guestSessionID, page, limit)
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

// GetOrder gets a specific order
// @Summary Get order
// @Description Get a single order by its ID
// @Tags Orders
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param id path string true "Order ID"
// @Success 200 {object} map[string]interface{} "Order retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid order ID"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /orders/{id} [get]
func (h *OrderHandler) GetOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	order, err := h.orderService.GetOrder(orderID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Order not found",
			"code":    "NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
	})
}

// CancelOrder cancels an order
// @Summary Cancel order
// @Description Cancel an existing order
// @Tags Orders
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param id path string true "Order ID"
// @Success 200 {object} map[string]interface{} "Order cancelled successfully"
// @Failure 400 {object} map[string]interface{} "Invalid order ID"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /orders/{id} [delete]
func (h *OrderHandler) CancelOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req struct {
		Reason string `json:"reason"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		req.Reason = "Order cancelled by customer"
	}

	err := h.orderService.CancelOrder(orderID, req.Reason)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "ORDER_CANCELLATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Order cancelled successfully",
	})
}

// TrackOrder tracks an order
// @Summary Track order
// @Description Get tracking information for an order
// @Tags Orders
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param id path string true "Order ID"
// @Success 200 {object} map[string]interface{} "Order tracking retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid order ID"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /orders/{id}/track [get]
func (h *OrderHandler) TrackOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	order, err := h.orderService.TrackOrder(orderID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Order not found",
			"code":    "NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
	})
}

// SearchOrders searches orders by order number
// @Summary Search orders
// @Description Search orders by order number
// @Tags Orders
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param orderNumber query string true "Order number to search for"
// @Success 200 {object} map[string]interface{} "Order found successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 404 {object} map[string]interface{} "Order not found"
// @Router /orders/search [get]
func (h *OrderHandler) SearchOrders(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")
	
	orderNumber := c.Query("orderNumber")
	if orderNumber == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order number is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	order, err := h.orderService.GetOrderByNumber(orderNumber)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Order not found",
			"code":    "NOT_FOUND",
		})
		return
	}

	// Check if the order belongs to the current user or guest session
	if userID != "" {
		if order.UserID.IsZero() || order.UserID.Hex() != userID {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Order not found",
				"code":    "NOT_FOUND",
			})
			return
		}
	} else if guestSessionID != "" {
		if order.GuestSessionID != guestSessionID {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Order not found",
				"code":    "NOT_FOUND",
			})
			return
		}
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Authentication required",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
	})
}

// CreatePaymentOrder creates a Razorpay payment order
// @Summary Create payment order
// @Description Create a payment order for Razorpay
// @Tags Payment
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body object true "Payment order creation data"
// @Success 200 {object} map[string]interface{} "Payment order created successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /payment/create-order [post]
func (h *OrderHandler) CreatePaymentOrder(c *gin.Context) {
	var req struct {
		OrderID  string  `json:"orderId" binding:"required"`
		Amount   float64 `json:"amount" binding:"required"`
		Currency string  `json:"currency" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	paymentOrder, err := h.paymentService.CreatePaymentOrder(req.OrderID, req.Amount, req.Currency)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to create payment order",
			"code":    "PAYMENT_CREATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    paymentOrder,
	})
}

// VerifyPayment verifies Razorpay payment
// @Summary Verify payment
// @Description Verify a Razorpay payment
// @Tags Payment
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body object true "Payment verification data"
// @Success 200 {object} map[string]interface{} "Payment verified successfully"
// @Failure 400 {object} map[string]interface{} "Invalid payment data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /payment/verify [post]
func (h *OrderHandler) VerifyPayment(c *gin.Context) {
	var req struct {
		RazorpayOrderID   string `json:"razorpayOrderId" binding:"required"`
		RazorpayPaymentID string `json:"razorpayPaymentId" binding:"required"`
		RazorpaySignature string `json:"razorpaySignature" binding:"required"`
		OrderID           string `json:"orderId" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.paymentService.VerifyPayment(req.RazorpayPaymentID, req.RazorpayOrderID, req.RazorpaySignature)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Payment verification failed",
			"code":    "PAYMENT_VERIFICATION_FAILED",
		})
		return
	}

	// Complete the order and award loyalty points
	if err := h.orderService.CompleteOrder(req.OrderID); err != nil {
		// Log error but don't fail the payment verification
		// The payment is verified, but loyalty points might not be awarded
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Payment verified successfully",
			"warning": "Order completion partially failed",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Payment verified and order completed successfully",
	})
}

// HandleWebhook handles Razorpay webhooks
func (h *OrderHandler) HandleWebhook(c *gin.Context) {
	payload, err := c.GetRawData()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid webhook payload",
			"code":    "INVALID_PAYLOAD",
		})
		return
	}

	signature := c.GetHeader("X-Razorpay-Signature")
	if signature == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Missing webhook signature",
			"code":    "MISSING_SIGNATURE",
		})
		return
	}

	err = h.paymentService.HandleWebhook(payload, signature)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Webhook processing failed",
			"code":    "WEBHOOK_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Webhook processed successfully",
	})
}

// Admin endpoints

// GetAllOrders gets all orders for admin (admin only)
func (h *OrderHandler) GetAllOrders(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	status := c.Query("status")

	// TODO: Implement admin order retrieval with filters
	// For now, return mock data
	orders := []map[string]interface{}{
		{
			"id":           "ord_001",
			"customerName": "John Doe",
			"total":        25000.0,
			"status":       "pending",
			"createdAt":    "2024-01-15T10:30:00Z",
		},
		{
			"id":           "ord_002",
			"customerName": "Jane Smith",
			"total":        15000.0,
			"status":       "completed",
			"createdAt":    "2024-01-14T14:20:00Z",
		},
	}

	// Filter by status if provided
	if status != "" {
		var filteredOrders []map[string]interface{}
		for _, order := range orders {
			if order["status"] == status {
				filteredOrders = append(filteredOrders, order)
			}
		}
		orders = filteredOrders
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"orders": orders,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      len(orders),
				"totalPages": 1,
			},
		},
	})
}


// ReturnOrder handles order return requests
func (h *OrderHandler) ReturnOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.orderService.ReturnOrder(orderID, req.Reason)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "RETURN_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Return request submitted successfully",
	})
}

// RefundOrder handles order refund requests
func (h *OrderHandler) RefundOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.orderService.RefundOrder(orderID, req.Reason)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "REFUND_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Refund request processed successfully",
	})
}

// UpdateOrderStatus updates order status (admin only)
func (h *OrderHandler) UpdateOrderStatus(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.UpdateOrderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.orderService.UpdateOrderStatus(orderID, req.Status, req.TrackingNumber)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "STATUS_UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Order status updated successfully",
	})
}
