package handlers

import (
	"net/http"
	"strconv"

	"thyne-jewels-backend/internal/middleware"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

type InvoiceHandler struct {
	invoiceService services.InvoiceService
}

func NewInvoiceHandler(invoiceService services.InvoiceService) *InvoiceHandler {
	return &InvoiceHandler{
		invoiceService: invoiceService,
	}
}

// GenerateInvoice generates an invoice for an order
// @Summary Generate invoice
// @Description Generate an invoice for a specific order
// @Tags Invoices
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body models.CreateInvoiceRequest true "Invoice creation data"
// @Success 201 {object} map[string]interface{} "Invoice generated successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /invoices/generate [post]
func (h *InvoiceHandler) GenerateInvoice(c *gin.Context) {
	var req models.CreateInvoiceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	invoice, err := h.invoiceService.GenerateInvoice(c.Request.Context(), req.OrderID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "INVOICE_GENERATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    invoice,
		"message": "Invoice generated successfully",
	})
}

// GetInvoice retrieves a specific invoice
// @Summary Get invoice
// @Description Get a single invoice by its ID
// @Tags Invoices
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param id path string true "Invoice ID"
// @Success 200 {object} map[string]interface{} "Invoice retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid invoice ID"
// @Failure 404 {object} map[string]interface{} "Invoice not found"
// @Router /invoices/{id} [get]
func (h *InvoiceHandler) GetInvoice(c *gin.Context) {
	invoiceID := c.Param("id")
	if invoiceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invoice ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	invoice, err := h.invoiceService.GetInvoice(c.Request.Context(), invoiceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Invoice not found",
			"code":    "NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    invoice,
	})
}

// GetInvoiceByOrderID retrieves an invoice by order ID
// @Summary Get invoice by order ID
// @Description Get an invoice for a specific order
// @Tags Invoices
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param orderId path string true "Order ID"
// @Success 200 {object} map[string]interface{} "Invoice retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid order ID"
// @Failure 404 {object} map[string]interface{} "Invoice not found"
// @Router /invoices/order/{orderId} [get]
func (h *InvoiceHandler) GetInvoiceByOrderID(c *gin.Context) {
	orderID := c.Param("orderId")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Order ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	invoice, err := h.invoiceService.GetInvoiceByOrderID(c.Request.Context(), orderID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Invoice not found for this order",
			"code":    "NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    invoice,
	})
}

// GetUserInvoices retrieves all invoices for a user
// @Summary Get user invoices
// @Description Get all invoices for the authenticated user or guest
// @Tags Invoices
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(10)
// @Success 200 {object} map[string]interface{} "Invoices retrieved successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /invoices [get]
func (h *InvoiceHandler) GetUserInvoices(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	var invoices []models.Invoice
	var total int64
	var err error

	if userID != "" {
		invoices, total, err = h.invoiceService.GetInvoicesByUser(c.Request.Context(), userID, page, limit)
	} else if guestSessionID != "" {
		invoices, total, err = h.invoiceService.GetInvoicesByGuestSession(c.Request.Context(), guestSessionID, page, limit)
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Authentication required",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch invoices",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"invoices": invoices,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"totalPages": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// MarkInvoiceAsDownloaded marks an invoice as downloaded
// @Summary Mark invoice as downloaded
// @Description Mark an invoice as downloaded
// @Tags Invoices
// @Accept json
// @Produce json
// @Param id path string true "Invoice ID"
// @Success 200 {object} map[string]interface{} "Invoice marked as downloaded"
// @Failure 400 {object} map[string]interface{} "Invalid invoice ID"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /invoices/{id}/download [post]
func (h *InvoiceHandler) MarkInvoiceAsDownloaded(c *gin.Context) {
	invoiceID := c.Param("id")
	if invoiceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invoice ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.invoiceService.MarkAsDownloaded(c.Request.Context(), invoiceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Invoice marked as downloaded",
	})
}

// Admin endpoints

// ListAllInvoices retrieves all invoices (admin only)
// @Summary List all invoices
// @Description Get all invoices with filters (admin only)
// @Tags Invoices
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(20)
// @Param status query string false "Filter by status"
// @Param dateFrom query string false "Filter by date from (YYYY-MM-DD)"
// @Param dateTo query string false "Filter by date to (YYYY-MM-DD)"
// @Success 200 {object} map[string]interface{} "Invoices retrieved successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /admin/invoices [get]
// @Security Bearer
func (h *InvoiceHandler) ListAllInvoices(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	filter := &models.InvoiceFilter{
		Page:  page,
		Limit: limit,
	}

	// Parse optional filters
	if status := c.Query("status"); status != "" {
		invoiceStatus := models.InvoiceStatus(status)
		filter.Status = &invoiceStatus
	}

	invoices, total, err := h.invoiceService.ListInvoices(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch invoices",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"invoices": invoices,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"totalPages": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// ExportInvoicesCSV exports invoices to CSV (admin only)
// @Summary Export invoices to CSV
// @Description Export all invoices to CSV format (admin only)
// @Tags Invoices
// @Accept json
// @Produce text/csv
// @Param status query string false "Filter by status"
// @Param dateFrom query string false "Filter by date from (YYYY-MM-DD)"
// @Param dateTo query string false "Filter by date to (YYYY-MM-DD)"
// @Success 200 {file} file "CSV file downloaded"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /admin/invoices/export/csv [get]
// @Security Bearer
func (h *InvoiceHandler) ExportInvoicesCSV(c *gin.Context) {
	filter := &models.InvoiceFilter{
		Page:  1,
		Limit: 10000, // Large limit to get all invoices
	}

	// Parse optional filters
	if status := c.Query("status"); status != "" {
		invoiceStatus := models.InvoiceStatus(status)
		filter.Status = &invoiceStatus
	}

	invoices, _, err := h.invoiceService.ListInvoices(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch invoices",
			"code":    "FETCH_FAILED",
		})
		return
	}

	csvData, err := h.invoiceService.GenerateCSVData(c.Request.Context(), invoices)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to generate CSV",
			"code":    "CSV_GENERATION_FAILED",
		})
		return
	}

	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", "attachment; filename=invoices.csv")
	c.Data(http.StatusOK, "text/csv", csvData)
}

// DeleteInvoice deletes an invoice (admin only)
// @Summary Delete invoice
// @Description Delete an invoice (admin only)
// @Tags Invoices
// @Accept json
// @Produce json
// @Param id path string true "Invoice ID"
// @Success 200 {object} map[string]interface{} "Invoice deleted successfully"
// @Failure 400 {object} map[string]interface{} "Invalid invoice ID"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /admin/invoices/{id} [delete]
// @Security Bearer
func (h *InvoiceHandler) DeleteInvoice(c *gin.Context) {
	invoiceID := c.Param("id")
	if invoiceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invoice ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.invoiceService.DeleteInvoice(c.Request.Context(), invoiceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "DELETE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Invoice deleted successfully",
	})
}
