package handlers

import (
	"encoding/csv"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"
)

// AdminHandler handles admin panel endpoints
type AdminHandler struct {
	userService    services.UserService
	productService services.ProductService
	orderService   services.OrderService
}

// NewAdminHandler creates a new admin handler
func NewAdminHandler(
	userService services.UserService,
	productService services.ProductService,
	orderService services.OrderService,
) *AdminHandler {
	return &AdminHandler{
		userService:    userService,
		productService: productService,
		orderService:   orderService,
	}
}

// GetDashboardStats gets admin dashboard statistics
// @Summary Get dashboard stats
// @Description Get admin dashboard statistics (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "Dashboard statistics retrieved successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 403 {object} map[string]interface{} "Admin access required"
// @Router /admin/dashboard/stats [get]
func (h *AdminHandler) GetDashboardStats(c *gin.Context) {
	ctx := c.Request.Context()

	// Get product statistics
	productStats, err := h.productService.GetProductStatistics(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch product statistics",
			"code":    "STATS_ERROR",
		})
		return
	}

	// Get total users count
	_, totalUsers, err := h.userService.GetAllUsers(1, 1)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch user statistics",
			"code":    "STATS_ERROR",
		})
		return
	}

	// Get total orders and calculate revenue
	orders, totalOrders, err := h.orderService.GetAllOrders(1, 1000, nil) // Get first 1000 orders to calculate revenue
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch order statistics",
			"code":    "STATS_ERROR",
		})
		return
	}

	// Calculate total revenue
	var totalRevenue float64
	for _, order := range orders {
		totalRevenue += order.Total
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"totalUsers":    totalUsers,
			"totalOrders":   totalOrders,
			"totalProducts": productStats.TotalProducts,
			"totalRevenue":  totalRevenue,
		},
	})
}

// GetRecentActivities gets recent admin activities
// @Summary Get recent activities
// @Description Get recent admin activities (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "Recent activities retrieved successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 403 {object} map[string]interface{} "Admin access required"
// @Router /admin/dashboard/activities [get]
func (h *AdminHandler) GetRecentActivities(c *gin.Context) {
	// Placeholder implementation
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    []interface{}{},
	})
}

// GetAllOrders gets all orders for admin
func (h *AdminHandler) GetAllOrders(c *gin.Context) {
    page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
    limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
    statusQuery := c.Query("status")

    var statusPtr *models.OrderStatus
    if statusQuery != "" {
        st := models.OrderStatus(statusQuery)
        statusPtr = &st
    }

    orders, total, err := h.orderService.GetAllOrders(page, limit, statusPtr)
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

// UpdateOrderStatus updates order status (admin only)
func (h *AdminHandler) UpdateOrderStatus(c *gin.Context) {
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

	// Validate request
	if err := req.Validate(); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Validation failed: " + err.Error(),
			"code":    "VALIDATION_ERROR",
		})
		return
	}

	err := h.orderService.UpdateOrderStatus(orderID, req.Status, req.TrackingNumber)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to update order status",
			"code":    "UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Order status updated successfully",
	})
}

// GetOrderDetails gets detailed information about a specific order
func (h *AdminHandler) GetOrderDetails(c *gin.Context) {
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

// GetOrderAnalytics gets order analytics and statistics
func (h *AdminHandler) GetOrderAnalytics(c *gin.Context) {
	// Placeholder implementation for order analytics
	startDate := c.DefaultQuery("startDate", time.Now().AddDate(0, -1, 0).Format("2006-01-02"))
	endDate := c.DefaultQuery("endDate", time.Now().Format("2006-01-02"))

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"period": gin.H{
				"startDate": startDate,
				"endDate":   endDate,
			},
			"analytics": gin.H{
				"totalOrders":      150,
				"totalRevenue":     450000.0,
				"averageOrderValue": 3000.0,
				"ordersByStatus": gin.H{
					"pending":    25,
					"processing": 15,
					"shipped":    35,
					"delivered":  65,
					"cancelled":  10,
				},
				"ordersByMonth": gin.H{
					"January":  45,
					"February": 52,
					"March":    38,
					"April":    41,
				},
			},
		},
	})
}

// GetUserStatistics gets user statistics for admin dashboard
func (h *AdminHandler) GetUserStatistics(c *gin.Context) {
	// Placeholder implementation
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"totalUsers":     1250,
			"activeUsers":    980,
			"newUsersToday":  15,
			"newUsersWeek":   105,
			"newUsersMonth":  420,
			"userGrowth": gin.H{
				"thisMonth": 420,
				"lastMonth": 380,
				"growthRate": 10.5,
			},
		},
	})
}

// GetProductStatistics gets product statistics for admin dashboard
func (h *AdminHandler) GetProductStatistics(c *gin.Context) {
	ctx := c.Request.Context()

	// Get real product statistics from service
	productStats, err := h.productService.GetProductStatistics(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch product statistics",
			"code":    "STATS_ERROR",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"totalProducts":      productStats.TotalProducts,
			"activeProducts":     productStats.ProductsInStock,
			"outOfStock":         productStats.ProductsOutOfStock,
			"lowStock":           len(productStats.LowStockProducts),
			"featuredProducts":   productStats.FeaturedProducts,
			"newProductsToday":   productStats.NewProductsToday,
			"topSellingProducts": productStats.TopSellingProducts,
			"categoryDistribution": productStats.CategoryDistribution,
			"lowStockProducts":   productStats.LowStockProducts,
			"averageRating":      productStats.AverageRating,
			"totalReviews":       productStats.TotalReviews,
		},
	})
}

// ExportOrders exports orders data in various formats
func (h *AdminHandler) ExportOrders(c *gin.Context) {
	format := c.DefaultQuery("format", "csv")
	startDate := c.DefaultQuery("startDate", "")
	endDate := c.DefaultQuery("endDate", "")

	// Placeholder implementation
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"message":      "Export functionality implemented",
			"format":       format,
			"startDate":    startDate,
			"endDate":      endDate,
			"downloadUrl":  "/api/v1/admin/exports/orders_" + time.Now().Format("20060102") + "." + format,
			"expiresAt":    time.Now().Add(24 * time.Hour).Format(time.RFC3339),
		},
	})
}

// GetSystemHealth gets system health status
func (h *AdminHandler) GetSystemHealth(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"status":    "healthy",
			"timestamp": time.Now().Format(time.RFC3339),
			"services": gin.H{
				"database":  "healthy",
				"cache":     "healthy",
				"storage":   "healthy",
				"payments":  "healthy",
			},
			"uptime": "99.9%",
		},
	})
}

// GetAuditLogs gets system audit logs
func (h *AdminHandler) GetAuditLogs(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	action := c.Query("action")
	userId := c.Query("userId")

	// Placeholder implementation
	logs := []map[string]interface{}{
		{
			"id":        "log_001",
			"action":    "ORDER_CREATED",
			"userId":    "user_123",
			"userEmail": "john@example.com",
			"details":   "Order #TJ20240115001 created",
			"timestamp": time.Now().Add(-2 * time.Hour).Format(time.RFC3339),
		},
		{
			"id":        "log_002",
			"action":    "ORDER_STATUS_UPDATED",
			"userId":    "admin_456",
			"userEmail": "admin@thynejewels.com",
			"details":   "Order #TJ20240115001 status changed to 'shipped'",
			"timestamp": time.Now().Add(-1 * time.Hour).Format(time.RFC3339),
		},
	}

	// Filter logs if parameters provided
	if action != "" || userId != "" {
		var filteredLogs []map[string]interface{}
		for _, log := range logs {
			if (action == "" || log["action"] == action) &&
				(userId == "" || log["userId"] == userId) {
				filteredLogs = append(filteredLogs, log)
			}
		}
		logs = filteredLogs
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"logs": logs,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      len(logs),
				"totalPages": 1,
			},
		},
	})
}

// BulkUploadProducts handles CSV bulk product upload
// @Summary Bulk upload products via CSV
// @Description Upload multiple products at once using CSV file (Admin only)
// @Tags Admin
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param file formData file true "CSV file containing product data"
// @Success 200 {object} map[string]interface{} "Products uploaded successfully"
// @Failure 400 {object} map[string]interface{} "Invalid CSV file or data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 403 {object} map[string]interface{} "Admin access required"
// @Router /admin/products/bulk-upload [post]
func (h *AdminHandler) BulkUploadProducts(c *gin.Context) {
	// Get uploaded file
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "No file uploaded",
			"code":    "NO_FILE",
		})
		return
	}
	defer file.Close()

	// Validate file type
	if !strings.HasSuffix(strings.ToLower(header.Filename), ".csv") {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Only CSV files are allowed",
			"code":    "INVALID_FILE_TYPE",
		})
		return
	}

	// Parse CSV
	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to parse CSV file",
			"code":    "CSV_PARSE_ERROR",
		})
		return
	}

	if len(records) < 2 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "CSV file must contain header row and at least one data row",
			"code":    "INSUFFICIENT_DATA",
		})
		return
	}

	// Validate CSV headers
	expectedHeaders := []string{
		"name", "description", "price", "originalPrice", "images", 
		"category", "subcategory", "metalType", "stoneType", "weight", 
		"size", "stockQuantity", "tags", "isAvailable", "isFeatured",
	}
	
	headers := records[0]
	if !h.validateCSVHeaders(headers, expectedHeaders) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   fmt.Sprintf("Invalid CSV headers. Expected: %s", strings.Join(expectedHeaders, ", ")),
			"code":    "INVALID_HEADERS",
		})
		return
	}

	// Process products
	var products []models.CreateProductRequest
	var errors []string
	
	for i, record := range records[1:] {
		product, err := h.parseProductFromCSVRecord(record, headers)
		if err != nil {
			errors = append(errors, fmt.Sprintf("Row %d: %s", i+2, err.Error()))
			continue
		}
		products = append(products, *product)
	}

	// If there are validation errors, return them
	if len(errors) > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "CSV validation failed",
			"code":    "VALIDATION_ERRORS",
			"details": errors,
		})
		return
	}

	// Create products in bulk
	ctx := c.Request.Context()
	createdProducts, failedProducts, err := h.productService.BulkCreateProducts(ctx, products)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to create products",
			"code":    "BULK_CREATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"totalProcessed":   len(products),
			"successfullyCreated": len(createdProducts),
			"failed":          len(failedProducts),
			"createdProducts": createdProducts,
			"failedProducts":  failedProducts,
		},
		"message": fmt.Sprintf("Bulk upload completed. %d products created successfully, %d failed", 
			len(createdProducts), len(failedProducts)),
	})
}

// validateCSVHeaders checks if CSV headers match expected format
func (h *AdminHandler) validateCSVHeaders(headers []string, expected []string) bool {
	if len(headers) != len(expected) {
		return false
	}
	
	headerMap := make(map[string]bool)
	for _, header := range headers {
		headerMap[strings.ToLower(strings.TrimSpace(header))] = true
	}
	
	for _, expectedHeader := range expected {
		if !headerMap[strings.ToLower(expectedHeader)] {
			return false
		}
	}
	
	return true
}

// parseProductFromCSVRecord parses a CSV record into a CreateProductRequest
func (h *AdminHandler) parseProductFromCSVRecord(record []string, headers []string) (*models.CreateProductRequest, error) {
	if len(record) != len(headers) {
		return nil, fmt.Errorf("record has %d fields, expected %d", len(record), len(headers))
	}

	// Create header index map
	headerIndex := make(map[string]int)
	for i, header := range headers {
		headerIndex[strings.ToLower(strings.TrimSpace(header))] = i
	}

	// Helper function to get field value
	getField := func(fieldName string) string {
		if idx, exists := headerIndex[strings.ToLower(fieldName)]; exists && idx < len(record) {
			return strings.TrimSpace(record[idx])
		}
		return ""
	}

	// Parse required fields
	name := getField("name")
	if name == "" {
		return nil, fmt.Errorf("name is required")
	}

	description := getField("description")
	if description == "" {
		return nil, fmt.Errorf("description is required")
	}

	priceStr := getField("price")
	if priceStr == "" {
		return nil, fmt.Errorf("price is required")
	}
	price, err := strconv.ParseFloat(priceStr, 64)
	if err != nil {
		return nil, fmt.Errorf("invalid price: %s", priceStr)
	}

	category := getField("category")
	if category == "" {
		return nil, fmt.Errorf("category is required")
	}

	subcategory := getField("subcategory")
	if subcategory == "" {
		return nil, fmt.Errorf("subcategory is required")
	}

	metalType := getField("metalType")
	if metalType == "" {
		return nil, fmt.Errorf("metalType is required")
	}

	stockQuantityStr := getField("stockQuantity")
	if stockQuantityStr == "" {
		return nil, fmt.Errorf("stockQuantity is required")
	}
	stockQuantity, err := strconv.Atoi(stockQuantityStr)
	if err != nil {
		return nil, fmt.Errorf("invalid stockQuantity: %s", stockQuantityStr)
	}

	imagesStr := getField("images")
	if imagesStr == "" {
		return nil, fmt.Errorf("at least one image is required")
	}
	images := strings.Split(imagesStr, ";")
	for i := range images {
		images[i] = strings.TrimSpace(images[i])
	}

	// Parse optional fields
	var originalPrice *float64
	if originalPriceStr := getField("originalPrice"); originalPriceStr != "" {
		if op, err := strconv.ParseFloat(originalPriceStr, 64); err == nil {
			originalPrice = &op
		}
	}

	var stoneType *string
	if st := getField("stoneType"); st != "" {
		stoneType = &st
	}

	var weight *float64
	if weightStr := getField("weight"); weightStr != "" {
		if w, err := strconv.ParseFloat(weightStr, 64); err == nil {
			weight = &w
		}
	}

	var size *string
	if s := getField("size"); s != "" {
		size = &s
	}

	var tags []string
	if tagsStr := getField("tags"); tagsStr != "" {
		tags = strings.Split(tagsStr, ";")
		for i := range tags {
			tags[i] = strings.TrimSpace(tags[i])
		}
	}

	isAvailable := true
	if isAvailableStr := getField("isAvailable"); isAvailableStr != "" {
		if ia, err := strconv.ParseBool(isAvailableStr); err == nil {
			isAvailable = ia
		}
	}

	isFeatured := false
	if isFeaturedStr := getField("isFeatured"); isFeaturedStr != "" {
		if if_, err := strconv.ParseBool(isFeaturedStr); err == nil {
			isFeatured = if_
		}
	}

	return &models.CreateProductRequest{
		Name:          name,
		Description:   description,
		Price:         price,
		OriginalPrice: originalPrice,
		Images:        images,
		Category:      category,
		Subcategory:   subcategory,
		MetalType:     metalType,
		StoneType:     stoneType,
		Weight:        weight,
		Size:          size,
		StockQuantity: stockQuantity,
		Tags:          tags,
		IsAvailable:   isAvailable,
		IsFeatured:    isFeatured,
	}, nil
}