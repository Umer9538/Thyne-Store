package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// VoucherHandler handles voucher and rewards endpoints
type VoucherHandler struct {
	voucherService *services.VoucherService
}

// NewVoucherHandler creates a new voucher handler
func NewVoucherHandler(voucherService *services.VoucherService) *VoucherHandler {
	return &VoucherHandler{
		voucherService: voucherService,
	}
}

// CreateVoucherRequest represents a voucher creation request
type CreateVoucherRequest struct {
	Code             string                 `json:"code"`
	Title            string                 `json:"title" binding:"required"`
	Description      string                 `json:"description"`
	Type             string                 `json:"type" binding:"required"`
	DiscountType     string                 `json:"discountType" binding:"required"`
	Value            float64                `json:"value" binding:"required,gt=0"`
	MinOrderValue    float64                `json:"minOrderValue"`
	MaxDiscount      float64                `json:"maxDiscount"`
	PointsCost       int                    `json:"pointsCost"`
	MaxRedemptions   int                    `json:"maxRedemptions"`
	MaxPerUser       int                    `json:"maxPerUser"`
	ValidFrom        *string                `json:"validFrom"`
	ValidUntil       *string                `json:"validUntil"`
	UsageConditions  map[string]interface{} `json:"usageConditions"`
	ImageURL         string                 `json:"imageUrl"`
	Terms            []string               `json:"terms"`
}

// CreateVoucher creates a new voucher (Admin only)
// @Summary Create voucher
// @Description Create a new voucher template (Admin only)
// @Tags vouchers
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateVoucherRequest true "Voucher creation request"
// @Success 200 {object} models.Voucher
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /vouchers [post]
func (h *VoucherHandler) CreateVoucher(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	var req CreateVoucherRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	voucher := &models.Voucher{
		Code:            req.Code,
		Title:           req.Title,
		Description:     req.Description,
		Type:            req.Type,
		DiscountType:    req.DiscountType,
		Value:           req.Value,
		MinOrderValue:   req.MinOrderValue,
		MaxDiscount:     req.MaxDiscount,
		PointsCost:      req.PointsCost,
		MaxRedemptions:  req.MaxRedemptions,
		MaxPerUser:      req.MaxPerUser,
		UsageConditions: req.UsageConditions,
		ImageURL:        req.ImageURL,
		Terms:           req.Terms,
	}

	// Parse dates
	if req.ValidFrom != nil {
		if validFrom, err := time.Parse("2006-01-02", *req.ValidFrom); err == nil {
			voucher.ValidFrom = &validFrom
		}
	}

	if req.ValidUntil != nil {
		if validUntil, err := time.Parse("2006-01-02", *req.ValidUntil); err == nil {
			voucher.ValidUntil = &validUntil
		}
	}

	err := h.voucherService.CreateVoucher(c.Request.Context(), voucher)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    voucher,
		"message": "Voucher created successfully",
	})
}

// GetAvailableVouchers gets all available vouchers for redemption
// @Summary Get available vouchers
// @Description Get all vouchers available for points redemption
// @Tags vouchers
// @Produce json
// @Success 200 {array} models.Voucher
// @Failure 500 {object} map[string]interface{}
// @Router /vouchers/available [get]
func (h *VoucherHandler) GetAvailableVouchers(c *gin.Context) {
	vouchers, err := h.voucherService.GetAvailableVouchers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    vouchers,
	})
}

// VoucherRedeemRequest represents a voucher redemption request
type VoucherRedeemRequest struct {
	VoucherID primitive.ObjectID `json:"voucherId" binding:"required"`
}

// RedeemVoucher redeems a voucher for points
// @Summary Redeem voucher
// @Description Redeem a voucher using loyalty points
// @Tags vouchers
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body RedeemVoucherRequest true "Voucher redemption request"
// @Success 200 {object} models.UserVoucher
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /vouchers/redeem [post]
func (h *VoucherHandler) RedeemVoucher(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	var req VoucherRedeemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	userVoucher, err := h.voucherService.RedeemVoucher(c.Request.Context(), userID.(primitive.ObjectID), req.VoucherID)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    userVoucher,
		"message": "Voucher redeemed successfully",
	})
}

// GetUserVouchers gets vouchers owned by the user
// @Summary Get user vouchers
// @Description Get vouchers owned by the authenticated user
// @Tags vouchers
// @Security BearerAuth
// @Produce json
// @Param unused_only query bool false "Get only unused vouchers" default(false)
// @Success 200 {array} models.UserVoucher
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /vouchers/my [get]
func (h *VoucherHandler) GetUserVouchers(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	onlyUnused, _ := strconv.ParseBool(c.DefaultQuery("unused_only", "false"))

	vouchers, err := h.voucherService.GetUserVouchers(c.Request.Context(), userID.(primitive.ObjectID), onlyUnused)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    vouchers,
	})
}

// ValidateVoucherRequest represents a voucher validation request
type ValidateVoucherRequest struct {
	Code       string  `json:"code" binding:"required"`
	OrderValue float64 `json:"orderValue" binding:"required,gt=0"`
}

// ValidateVoucher validates a voucher code for order
// @Summary Validate voucher
// @Description Validate a voucher code for an order
// @Tags vouchers
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body ValidateVoucherRequest true "Voucher validation request"
// @Success 200 {object} models.VoucherValidation
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Router /vouchers/validate [post]
func (h *VoucherHandler) ValidateVoucher(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	var req ValidateVoucherRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	validation, err := h.voucherService.ValidateVoucherCode(c.Request.Context(), userID.(primitive.ObjectID), req.Code, req.OrderValue)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    validation,
	})
}

// VoucherUseRequest represents a voucher usage request
type VoucherUseRequest struct {
	Code string `json:"code" binding:"required"`
}

// UseVoucher marks a voucher as used
// @Summary Use voucher
// @Description Mark a user voucher as used during checkout
// @Tags vouchers
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body UseVoucherRequest true "Voucher usage request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /vouchers/use [post]
func (h *VoucherHandler) UseVoucher(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	var req VoucherUseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	err := h.voucherService.UseVoucher(c.Request.Context(), userID.(primitive.ObjectID), req.Code)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Voucher used successfully",
	})
}

// CreateRewardRequest represents a reward creation request
type CreateRewardRequest struct {
	UserID     string                 `json:"userId" binding:"required"`
	Type       string                 `json:"type" binding:"required"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// CreateReward creates a reward for user actions (Admin only)
// @Summary Create reward
// @Description Create a reward for user actions (Admin only)
// @Tags rewards
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateRewardRequest true "Reward creation request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /rewards [post]
func (h *VoucherHandler) CreateReward(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	var req CreateRewardRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	userID, err := primitive.ObjectIDFromHex(req.UserID)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid user ID"})
		return
	}

	err = h.voucherService.CreateReward(c.Request.Context(), userID, req.Type, req.Metadata)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Reward created successfully",
	})
}

// GetUserRewards gets rewards for the authenticated user
// @Summary Get user rewards
// @Description Get rewards for the authenticated user
// @Tags rewards
// @Security BearerAuth
// @Produce json
// @Param status query string false "Filter by status: earned, claimed, expired"
// @Success 200 {array} models.Reward
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /rewards/my [get]
func (h *VoucherHandler) GetUserRewards(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	status := c.Query("status")

	rewards, err := h.voucherService.GetUserRewards(c.Request.Context(), userID.(primitive.ObjectID), status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    rewards,
	})
}

// ClaimReward claims a pending reward
// @Summary Claim reward
// @Description Claim a pending reward
// @Tags rewards
// @Security BearerAuth
// @Produce json
// @Param rewardId path string true "Reward ID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /rewards/{rewardId}/claim [post]
func (h *VoucherHandler) ClaimReward(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	rewardIDStr := c.Param("rewardId")
	rewardID, err := primitive.ObjectIDFromHex(rewardIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid reward ID"})
		return
	}

	err = h.voucherService.ClaimReward(c.Request.Context(), userID.(primitive.ObjectID), rewardID)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Reward claimed successfully",
	})
}

// ProcessOrderRewards processes rewards for order completion (Internal API)
// @Summary Process order rewards
// @Description Process rewards for order completion (Internal API)
// @Tags rewards
// @Security BearerAuth
// @Produce json
// @Param orderId path string true "Order ID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /rewards/order/{orderId}/process [post]
func (h *VoucherHandler) ProcessOrderRewards(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	orderIDStr := c.Param("orderId")
	orderID, err := primitive.ObjectIDFromHex(orderIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid order ID"})
		return
	}

	err = h.voucherService.ProcessOrderRewards(c.Request.Context(), userID.(primitive.ObjectID), orderID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Order rewards processed successfully",
	})
}

// UpdateVoucherRequest represents a voucher update request
type UpdateVoucherRequest struct {
	Title            string                 `json:"title"`
	Description      string                 `json:"description"`
	Type             string                 `json:"type"`
	DiscountType     string                 `json:"discountType"`
	Value            float64                `json:"value"`
	MinOrderValue    float64                `json:"minOrderValue"`
	MaxDiscount      float64                `json:"maxDiscount"`
	PointsCost       int                    `json:"pointsCost"`
	MaxRedemptions   int                    `json:"maxRedemptions"`
	MaxPerUser       int                    `json:"maxPerUser"`
	ValidFrom        *string                `json:"validFrom"`
	ValidUntil       *string                `json:"validUntil"`
	UsageConditions  map[string]interface{} `json:"usageConditions"`
	IsActive         bool                   `json:"isActive"`
	ImageURL         string                 `json:"imageUrl"`
	Terms            []string               `json:"terms"`
}

// UpdateVoucher updates an existing voucher (Admin only)
// @Summary Update voucher
// @Description Update an existing voucher (Admin only)
// @Tags vouchers
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param voucherId path string true "Voucher ID"
// @Param request body UpdateVoucherRequest true "Voucher update request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /vouchers/{voucherId} [put]
func (h *VoucherHandler) UpdateVoucher(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	voucherIDStr := c.Param("voucherId")
	voucherID, err := primitive.ObjectIDFromHex(voucherIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid voucher ID"})
		return
	}

	var req UpdateVoucherRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	voucher := &models.Voucher{
		ID:              voucherID,
		Title:           req.Title,
		Description:     req.Description,
		Type:            req.Type,
		DiscountType:    req.DiscountType,
		Value:           req.Value,
		MinOrderValue:   req.MinOrderValue,
		MaxDiscount:     req.MaxDiscount,
		PointsCost:      req.PointsCost,
		MaxRedemptions:  req.MaxRedemptions,
		MaxPerUser:      req.MaxPerUser,
		UsageConditions: req.UsageConditions,
		IsActive:        req.IsActive,
		ImageURL:        req.ImageURL,
		Terms:           req.Terms,
	}

	// Parse dates
	if req.ValidFrom != nil {
		if validFrom, err := time.Parse("2006-01-02", *req.ValidFrom); err == nil {
			voucher.ValidFrom = &validFrom
		}
	}

	if req.ValidUntil != nil {
		if validUntil, err := time.Parse("2006-01-02", *req.ValidUntil); err == nil {
			voucher.ValidUntil = &validUntil
		}
	}

	err = h.voucherService.UpdateVoucher(c.Request.Context(), voucher)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Voucher updated successfully",
	})
}

// DeactivateVoucher deactivates a voucher (Admin only)
// @Summary Deactivate voucher
// @Description Deactivate a voucher (Admin only)
// @Tags vouchers
// @Security BearerAuth
// @Produce json
// @Param voucherId path string true "Voucher ID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /vouchers/{voucherId}/deactivate [post]
func (h *VoucherHandler) DeactivateVoucher(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	voucherIDStr := c.Param("voucherId")
	voucherID, err := primitive.ObjectIDFromHex(voucherIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid voucher ID"})
		return
	}

	err = h.voucherService.DeactivateVoucher(c.Request.Context(), voucherID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Voucher deactivated successfully",
	})
}

// GetVoucherAnalytics gets voucher usage analytics (Admin only)
// @Summary Get voucher analytics
// @Description Get voucher usage analytics (Admin only)
// @Tags vouchers
// @Security BearerAuth
// @Produce json
// @Param startDate query string false "Start date (YYYY-MM-DD)"
// @Param endDate query string false "End date (YYYY-MM-DD)"
// @Success 200 {object} models.VoucherAnalytics
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /vouchers/analytics [get]
func (h *VoucherHandler) GetVoucherAnalytics(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	// Parse date range
	startDateStr := c.Query("startDate")
	endDateStr := c.Query("endDate")

	var startDate, endDate time.Time
	var err error

	if startDateStr != "" {
		startDate, err = time.Parse("2006-01-02", startDateStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid start date format. Use YYYY-MM-DD"})
			return
		}
	} else {
		startDate = time.Now().AddDate(0, 0, -30) // Default to last 30 days
	}

	if endDateStr != "" {
		endDate, err = time.Parse("2006-01-02", endDateStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid end date format. Use YYYY-MM-DD"})
			return
		}
	} else {
		endDate = time.Now()
	}

	analytics, err := h.voucherService.GetVoucherAnalytics(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    analytics,
	})
}