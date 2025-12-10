package handlers

import (
	"fmt"
	"io"
	"net/http"

	"thyne-jewels-backend/internal/middleware"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

// CashfreeHandler handles Cashfree payment operations
type CashfreeHandler struct {
	cashfreeService *services.CashfreeService
	orderService    services.OrderService
	authService     services.AuthService
}

// NewCashfreeHandler creates a new Cashfree handler
func NewCashfreeHandler(cashfreeService *services.CashfreeService, orderService services.OrderService, authService services.AuthService) *CashfreeHandler {
	return &CashfreeHandler{
		cashfreeService: cashfreeService,
		orderService:    orderService,
		authService:     authService,
	}
}

// CreatePaymentOrderRequest represents the request to create a payment order
type CreatePaymentOrderRequest struct {
	OrderID       string  `json:"orderId" binding:"required"`
	Amount        float64 `json:"amount" binding:"required"`
	Currency      string  `json:"currency"`
	CustomerPhone string  `json:"customerPhone" binding:"required"`
	CustomerEmail string  `json:"customerEmail"`
	CustomerName  string  `json:"customerName"`
	ReturnURL     string  `json:"returnUrl"`
	NotifyURL     string  `json:"notifyUrl"`
}

// VerifyPaymentRequest represents the request to verify payment
type VerifyPaymentRequest struct {
	OrderID string `json:"orderId" binding:"required"`
}

// CreatePaymentOrder creates a Cashfree payment order
// @Summary Create Cashfree payment order
// @Description Create a payment order for Cashfree checkout
// @Tags Payment
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body CreatePaymentOrderRequest true "Payment order creation data"
// @Success 200 {object} map[string]interface{} "Payment order created successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /payment/cashfree/create-order [post]
func (h *CashfreeHandler) CreatePaymentOrder(c *gin.Context) {
	var req CreatePaymentOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data: " + err.Error(),
			"code":    "INVALID_INPUT",
		})
		return
	}

	// Check if Cashfree is enabled
	if h.cashfreeService == nil || !h.cashfreeService.IsEnabled() {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"success": false,
			"error":   "Cashfree payment service is not configured",
			"code":    "SERVICE_UNAVAILABLE",
		})
		return
	}

	// Get user ID if authenticated
	userID, _ := middleware.GetUserIDFromContext(c)
	customerID := userID
	if customerID == "" {
		customerID = "guest_" + req.OrderID
	}

	// Set default currency
	currency := req.Currency
	if currency == "" {
		currency = "INR"
	}

	// Create Cashfree order
	cashfreeReq := &services.CashfreeOrderRequest{
		OrderID:       req.OrderID,
		OrderAmount:   req.Amount,
		OrderCurrency: currency,
		CustomerDetails: services.CashfreeCustomerDetails{
			CustomerID:    customerID,
			CustomerPhone: req.CustomerPhone,
			CustomerEmail: req.CustomerEmail,
			CustomerName:  req.CustomerName,
		},
	}

	// Add order meta if provided
	if req.ReturnURL != "" || req.NotifyURL != "" {
		cashfreeReq.OrderMeta = &services.CashfreeOrderMeta{
			ReturnURL: req.ReturnURL,
			NotifyURL: req.NotifyURL,
		}
	}

	orderResp, err := h.cashfreeService.CreateOrder(c.Request.Context(), cashfreeReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to create payment order: " + err.Error(),
			"code":    "PAYMENT_CREATION_FAILED",
		})
		return
	}

	// Update order with Cashfree order ID
	cfOrderIDStr := fmt.Sprintf("%v", orderResp.CFOrderID) // Handle interface{} type
	if err := h.orderService.UpdatePaymentDetails(req.OrderID, cfOrderIDStr, orderResp.PaymentSessionID); err != nil {
		// Log but don't fail - the payment order is already created
		fmt.Printf("Warning: Failed to update order payment details: %v\n", err)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"cfOrderId":        orderResp.CFOrderID,
			"orderId":          orderResp.OrderID,
			"orderAmount":      orderResp.OrderAmount,
			"orderCurrency":    orderResp.OrderCurrency,
			"orderStatus":      orderResp.OrderStatus,
			"paymentSessionId": orderResp.PaymentSessionID,
			"environment":      h.cashfreeService.GetEnvironment(),
		},
		"message": "Payment order created successfully",
	})
}

// VerifyPayment verifies a Cashfree payment by checking order status
// @Summary Verify Cashfree payment
// @Description Verify a Cashfree payment by checking order status
// @Tags Payment
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body VerifyPaymentRequest true "Payment verification data"
// @Success 200 {object} map[string]interface{} "Payment verified successfully"
// @Failure 400 {object} map[string]interface{} "Invalid payment data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /payment/cashfree/verify [post]
func (h *CashfreeHandler) VerifyPayment(c *gin.Context) {
	var req VerifyPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	// Check if Cashfree is enabled
	if h.cashfreeService == nil || !h.cashfreeService.IsEnabled() {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"success": false,
			"error":   "Cashfree payment service is not configured",
			"code":    "SERVICE_UNAVAILABLE",
		})
		return
	}

	// Get order status from Cashfree
	orderResp, err := h.cashfreeService.GetOrder(c.Request.Context(), req.OrderID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to verify payment: " + err.Error(),
			"code":    "VERIFICATION_FAILED",
		})
		return
	}

	// Check if order is paid
	if !h.cashfreeService.IsOrderPaid(orderResp.OrderStatus) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Payment not completed",
			"code":    "PAYMENT_NOT_COMPLETED",
			"data": gin.H{
				"orderStatus": orderResp.OrderStatus,
			},
		})
		return
	}

	// Get payment details
	payments, err := h.cashfreeService.GetPaymentsForOrder(c.Request.Context(), req.OrderID)
	if err != nil {
		fmt.Printf("Warning: Failed to get payment details: %v\n", err)
	}

	// Complete the order
	if err := h.orderService.CompleteOrder(req.OrderID); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Payment verified successfully",
			"warning": "Order completion partially failed: " + err.Error(),
			"data": gin.H{
				"orderStatus": orderResp.OrderStatus,
				"payments":    payments,
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Payment verified and order completed successfully",
		"data": gin.H{
			"orderStatus": orderResp.OrderStatus,
			"payments":    payments,
		},
	})
}

// GetOrderStatus gets the current status of a Cashfree order
// @Summary Get Cashfree order status
// @Description Get the current payment status of an order
// @Tags Payment
// @Produce json
// @Param orderId path string true "Order ID"
// @Success 200 {object} map[string]interface{} "Order status retrieved"
// @Failure 400 {object} map[string]interface{} "Invalid order ID"
// @Failure 500 {object} map[string]interface{} "Failed to get status"
// @Router /payment/cashfree/status/{orderId} [get]
func (h *CashfreeHandler) GetOrderStatus(c *gin.Context) {
	orderID := c.Param("orderId")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	// Check if Cashfree is enabled
	if h.cashfreeService == nil || !h.cashfreeService.IsEnabled() {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"success": false,
			"error":   "Cashfree payment service is not configured",
			"code":    "SERVICE_UNAVAILABLE",
		})
		return
	}

	orderResp, err := h.cashfreeService.GetOrder(c.Request.Context(), orderID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to get order status: " + err.Error(),
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"orderId":     orderResp.OrderID,
			"cfOrderId":   orderResp.CFOrderID,
			"orderStatus": orderResp.OrderStatus,
			"orderAmount": orderResp.OrderAmount,
			"isPaid":      h.cashfreeService.IsOrderPaid(orderResp.OrderStatus),
		},
	})
}

// HandleWebhook handles Cashfree payment webhooks
// @Summary Handle Cashfree webhook
// @Description Process Cashfree payment webhooks for payment status updates
// @Tags Payment
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{} "Webhook processed"
// @Failure 400 {object} map[string]interface{} "Invalid webhook"
// @Router /payment/cashfree/webhook [post]
func (h *CashfreeHandler) HandleWebhook(c *gin.Context) {
	// Read raw payload
	payload, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to read webhook payload",
			"code":    "INVALID_PAYLOAD",
		})
		return
	}

	// Get signature headers
	timestamp := c.GetHeader("x-webhook-timestamp")
	signature := c.GetHeader("x-webhook-signature")

	// Verify signature (if webhook secret is configured)
	if h.cashfreeService != nil && signature != "" {
		if !h.cashfreeService.VerifyWebhookSignature(payload, timestamp, signature) {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid webhook signature",
				"code":    "INVALID_SIGNATURE",
			})
			return
		}
	}

	// Parse webhook payload
	webhookData, err := h.cashfreeService.ParseWebhookPayload(payload)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to parse webhook payload: " + err.Error(),
			"code":    "PARSE_ERROR",
		})
		return
	}

	// Process based on event type
	switch webhookData.Type {
	case "PAYMENT_SUCCESS_WEBHOOK":
		// Payment successful - complete the order
		orderID := webhookData.Data.Order.OrderID
		if orderID != "" {
			if err := h.orderService.CompleteOrder(orderID); err != nil {
				fmt.Printf("Warning: Failed to complete order %s: %v\n", orderID, err)
			} else {
				fmt.Printf("Order %s completed via webhook\n", orderID)
			}
		}

	case "PAYMENT_FAILED_WEBHOOK":
		// Payment failed - cancel the order
		orderID := webhookData.Data.Order.OrderID
		if orderID != "" {
			if err := h.orderService.CancelOrder(orderID, "Payment failed via Cashfree"); err != nil {
				fmt.Printf("Warning: Failed to cancel order %s: %v\n", orderID, err)
			}
		}

	case "PAYMENT_USER_DROPPED_WEBHOOK":
		// User dropped/cancelled payment
		orderID := webhookData.Data.Order.OrderID
		if orderID != "" {
			if err := h.orderService.CancelOrder(orderID, "Payment cancelled by user via Cashfree"); err != nil {
				fmt.Printf("Warning: Failed to cancel order %s: %v\n", orderID, err)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Webhook processed successfully",
	})
}

// GetPaymentServiceStatus returns the status of the Cashfree service
// @Summary Get payment service status
// @Description Check if Cashfree payment service is enabled
// @Tags Payment
// @Produce json
// @Success 200 {object} map[string]interface{} "Service status"
// @Router /payment/cashfree/status [get]
func (h *CashfreeHandler) GetPaymentServiceStatus(c *gin.Context) {
	enabled := h.cashfreeService != nil && h.cashfreeService.IsEnabled()
	environment := ""
	if enabled {
		environment = h.cashfreeService.GetEnvironment()
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"enabled":     enabled,
			"provider":    "Cashfree",
			"environment": environment,
		},
	})
}

// CreatePaymentLink creates a Cashfree payment link
// @Summary Create payment link
// @Description Create a shareable payment link
// @Tags Payment
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body object true "Payment link creation data"
// @Success 200 {object} map[string]interface{} "Payment link created"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 500 {object} map[string]interface{} "Failed to create link"
// @Router /payment/cashfree/create-link [post]
func (h *CashfreeHandler) CreatePaymentLink(c *gin.Context) {
	var req struct {
		LinkID        string  `json:"linkId" binding:"required"`
		Amount        float64 `json:"amount" binding:"required"`
		CustomerPhone string  `json:"customerPhone" binding:"required"`
		CustomerEmail string  `json:"customerEmail"`
		CustomerName  string  `json:"customerName"`
		Purpose       string  `json:"purpose"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	if h.cashfreeService == nil || !h.cashfreeService.IsEnabled() {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"success": false,
			"error":   "Cashfree payment service is not configured",
			"code":    "SERVICE_UNAVAILABLE",
		})
		return
	}

	purpose := req.Purpose
	if purpose == "" {
		purpose = "Payment for Thyne Jewels order"
	}

	linkURL, err := h.cashfreeService.CreatePaymentLink(
		c.Request.Context(),
		req.LinkID,
		req.Amount,
		req.CustomerPhone,
		req.CustomerEmail,
		req.CustomerName,
		purpose,
		nil,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to create payment link: " + err.Error(),
			"code":    "LINK_CREATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"linkUrl": linkURL,
			"linkId":  req.LinkID,
		},
		"message": "Payment link created successfully",
	})
}
