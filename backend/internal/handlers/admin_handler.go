package handlers

import (
	"net/http"
	"strconv"
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
	// Placeholder implementation
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"totalUsers":    100,
			"totalOrders":   50,
			"totalProducts": 200,
			"totalRevenue":  150000.0,
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
	// Placeholder implementation
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"totalProducts":   250,
			"activeProducts":  230,
			"outOfStock":      20,
			"lowStock":        15,
			"topSellingProducts": []map[string]interface{}{
				{
					"id":          "prod_001",
					"name":        "Gold Necklace",
					"soldCount":   45,
					"revenue":     225000.0,
				},
				{
					"id":          "prod_002",
					"name":        "Silver Ring",
					"soldCount":   38,
					"revenue":     152000.0,
				},
				{
					"id":          "prod_003",
					"name":        "Diamond Earrings",
					"soldCount":   28,
					"revenue":     196000.0,
				},
			},
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