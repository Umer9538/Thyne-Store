package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LoyaltyHandler handles loyalty program endpoints
type LoyaltyHandler struct {
	loyaltyService *services.LoyaltyService
}

// NewLoyaltyHandler creates a new loyalty handler
func NewLoyaltyHandler(loyaltyService *services.LoyaltyService) *LoyaltyHandler {
	return &LoyaltyHandler{
		loyaltyService: loyaltyService,
	}
}

// GetLoyaltyProgram gets user's loyalty program
// @Summary Get loyalty program
// @Description Get user's loyalty program information
// @Tags loyalty
// @Security BearerAuth
// @Produce json
// @Success 200 {object} models.LoyaltyProgram
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/program [get]
func (h *LoyaltyHandler) GetLoyaltyProgram(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	program, err := h.loyaltyService.GetLoyaltyProgram(c.Request.Context(), userID.(primitive.ObjectID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    program,
	})
}

// GetPointsHistory gets user's points transaction history
// @Summary Get points history
// @Description Get user's loyalty points transaction history
// @Tags loyalty
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {array} models.PointTransaction
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/points/history [get]
func (h *LoyaltyHandler) GetPointsHistory(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	transactions, err := h.loyaltyService.GetPointsHistory(c.Request.Context(), userID.(primitive.ObjectID), limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    transactions,
	})
}

// GetAvailableVouchers gets all available vouchers for redemption
// @Summary Get available vouchers
// @Description Get all vouchers available for points redemption
// @Tags loyalty
// @Produce json
// @Success 200 {array} models.Voucher
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/vouchers/available [get]
func (h *LoyaltyHandler) GetAvailableVouchers(c *gin.Context) {
	vouchers, err := h.loyaltyService.GetAvailableVouchers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    vouchers,
	})
}

// RedeemVoucherRequest represents a voucher redemption request
type RedeemVoucherRequest struct {
	VoucherID primitive.ObjectID `json:"voucherId" binding:"required"`
}

// RedeemVoucher redeems a voucher for points
// @Summary Redeem voucher
// @Description Redeem a voucher using loyalty points
// @Tags loyalty
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body RedeemVoucherRequest true "Voucher redemption request"
// @Success 200 {object} models.UserVoucher
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/vouchers/redeem [post]
func (h *LoyaltyHandler) RedeemVoucher(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	var req RedeemVoucherRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	userVoucher, err := h.loyaltyService.RedeemVoucher(c.Request.Context(), userID.(primitive.ObjectID), req.VoucherID)
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

// GetUserVouchers gets user's vouchers
// @Summary Get user vouchers
// @Description Get vouchers owned by the user
// @Tags loyalty
// @Security BearerAuth
// @Produce json
// @Param unused_only query bool false "Get only unused vouchers" default(false)
// @Success 200 {array} models.UserVoucher
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/vouchers/my [get]
func (h *LoyaltyHandler) GetUserVouchers(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	onlyUnused, _ := strconv.ParseBool(c.DefaultQuery("unused_only", "false"))

	vouchers, err := h.loyaltyService.GetUserVouchers(c.Request.Context(), userID.(primitive.ObjectID), onlyUnused)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    vouchers,
	})
}

// UseVoucherRequest represents a voucher usage request
type UseVoucherRequest struct {
	VoucherCode string `json:"voucherCode" binding:"required"`
}

// UseVoucher marks a voucher as used
// @Summary Use voucher
// @Description Mark a user voucher as used during checkout
// @Tags loyalty
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body UseVoucherRequest true "Voucher usage request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/vouchers/use [post]
func (h *LoyaltyHandler) UseVoucher(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	var req UseVoucherRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	err := h.loyaltyService.UseVoucher(c.Request.Context(), userID.(primitive.ObjectID), req.VoucherCode)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Voucher used successfully",
	})
}

// CheckDailyLogin checks and awards daily login bonus
// @Summary Check daily login
// @Description Check and award daily login bonus for the user
// @Tags loyalty
// @Security BearerAuth
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/daily-login [post]
func (h *LoyaltyHandler) CheckDailyLogin(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	err := h.loyaltyService.CheckDailyLogin(c.Request.Context(), userID.(primitive.ObjectID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Daily login checked successfully",
	})
}

// GetLoyaltyConfig gets loyalty program configuration
// @Summary Get loyalty configuration
// @Description Get loyalty program configuration
// @Tags loyalty
// @Produce json
// @Success 200 {object} models.LoyaltyConfig
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/config [get]
func (h *LoyaltyHandler) GetLoyaltyConfig(c *gin.Context) {
	config, err := h.loyaltyService.GetLoyaltyConfig(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    config,
	})
}

// UpdateLoyaltyConfigRequest represents a loyalty config update request
type UpdateLoyaltyConfigRequest struct {
	BasePointsPerDollar float64 `json:"basePointsPerDollar" binding:"required,min=0"`
	DailyLoginBonus     int     `json:"dailyLoginBonus" binding:"required,min=0"`
	StreakBonusPoints   int     `json:"streakBonusPoints" binding:"required,min=0"`
	StreakBonusDays     int     `json:"streakBonusDays" binding:"required,min=1"`
	ReferralBonus       int     `json:"referralBonus" binding:"required,min=0"`
	ReviewBonus         int     `json:"reviewBonus" binding:"required,min=0"`
	WelcomeBonus        int     `json:"welcomeBonus" binding:"required,min=0"`
}

// UpdateLoyaltyConfig updates loyalty program configuration (Admin only)
// @Summary Update loyalty configuration
// @Description Update loyalty program configuration (Admin only)
// @Tags loyalty
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body UpdateLoyaltyConfigRequest true "Loyalty config update request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/config [put]
func (h *LoyaltyHandler) UpdateLoyaltyConfig(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	var req UpdateLoyaltyConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	config := &models.LoyaltyConfig{
		BasePointsPerDollar: req.BasePointsPerDollar,
		DailyLoginBonus:     req.DailyLoginBonus,
		StreakBonusPoints:   req.StreakBonusPoints,
		StreakBonusDays:     req.StreakBonusDays,
		ReferralBonus:       req.ReferralBonus,
		ReviewBonus:         req.ReviewBonus,
		WelcomeBonus:        req.WelcomeBonus,
	}

	err := h.loyaltyService.UpdateLoyaltyConfig(c.Request.Context(), config)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Loyalty configuration updated successfully",
	})
}

// AddPointsRequest represents an add points request (for admin use)
type AddPointsRequest struct {
	UserID      primitive.ObjectID      `json:"userId" binding:"required"`
	Points      int                     `json:"points" binding:"required"`
	Description string                  `json:"description" binding:"required"`
	Type        models.TransactionType  `json:"type" binding:"required"`
}

// AddPoints adds points to a user's account (Admin only)
// @Summary Add points to user
// @Description Add loyalty points to a user's account (Admin only)
// @Tags loyalty
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body AddPointsRequest true "Add points request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/points/add [post]
func (h *LoyaltyHandler) AddPoints(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	var req AddPointsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	err := h.loyaltyService.AddPoints(c.Request.Context(), req.UserID, req.Points, req.Description, req.Type, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Points added successfully",
	})
}

// GetTierInfo gets information about loyalty tiers
// @Summary Get tier information
// @Description Get information about all loyalty tiers
// @Tags loyalty
// @Produce json
// @Success 200 {array} models.TierInfo
// @Router /loyalty/tiers [get]
func (h *LoyaltyHandler) GetTierInfo(c *gin.Context) {
	tiers := []models.TierInfo{
		models.TierBronze.GetTierInfo(),
		models.TierSilver.GetTierInfo(),
		models.TierGold.GetTierInfo(),
		models.TierPlatinum.GetTierInfo(),
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    tiers,
	})
}