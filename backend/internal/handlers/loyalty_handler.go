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

// GetCreditHistory gets user's credit transaction history
// @Summary Get credit history
// @Description Get user's loyalty credit transaction history
// @Tags loyalty
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {array} models.PointTransaction
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/credits/history [get]
func (h *LoyaltyHandler) GetCreditHistory(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	transactions, err := h.loyaltyService.GetCreditHistory(c.Request.Context(), userID.(primitive.ObjectID), limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    transactions,
	})
}

// GetRedemptionOptions gets all available redemption options
// @Summary Get redemption options
// @Description Get all available credit redemption options
// @Tags loyalty
// @Produce json
// @Success 200 {array} models.RedemptionOption
// @Router /loyalty/redemption-options [get]
func (h *LoyaltyHandler) GetRedemptionOptions(c *gin.Context) {
	options := h.loyaltyService.GetRedemptionOptions(c.Request.Context())

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    options,
	})
}

// RedeemCreditsRequest represents a credit redemption request
type RedeemCreditsRequest struct {
	RedemptionID string `json:"redemptionId" binding:"required"`
}

// RedeemCredits redeems credits for a discount or voucher
// @Summary Redeem credits
// @Description Redeem loyalty credits for a discount or voucher
// @Tags loyalty
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body RedeemCreditsRequest true "Credit redemption request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /loyalty/redeem [post]
func (h *LoyaltyHandler) RedeemCredits(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, map[string]interface{}{"error": "User not authenticated"})
		return
	}

	var req RedeemCreditsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	voucherCode, err := h.loyaltyService.RedeemCredits(c.Request.Context(), userID.(primitive.ObjectID), req.RedemptionID)
	if err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success":     true,
		"voucherCode": voucherCode,
		"message":     "Credits redeemed successfully",
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
	BaseCreditsPerDollar float64 `json:"baseCreditsPerDollar" binding:"required,min=0"`
	DailyLoginBonus      int     `json:"dailyLoginBonus" binding:"required,min=0"`
	StreakBonusCredits   int     `json:"streakBonusCredits" binding:"required,min=0"`
	StreakBonusDays      int     `json:"streakBonusDays" binding:"required,min=1"`
	WelcomeBonus         int     `json:"welcomeBonus" binding:"required,min=0"`
	CreditsToMoneyRatio  float64 `json:"creditsToMoneyRatio" binding:"required,min=0"`
}

// UpdateLoyaltyConfig updates loyalty program configuration (Admin only)
// @Summary Update loyalty configuration
// @Description Update loyalty program configuration (Admin only)
// @Tags admin-loyalty
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body UpdateLoyaltyConfigRequest true "Loyalty config update request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /admin/loyalty/config [put]
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
		BaseCreditsPerDollar: req.BaseCreditsPerDollar,
		DailyLoginBonus:      req.DailyLoginBonus,
		StreakBonusCredits:   req.StreakBonusCredits,
		StreakBonusDays:      req.StreakBonusDays,
		WelcomeBonus:         req.WelcomeBonus,
		CreditsToMoneyRatio:  req.CreditsToMoneyRatio,
	}

	err := h.loyaltyService.UpdateLoyaltyConfig(c.Request.Context(), config)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Loyalty configuration updated successfully",
		"data":    config,
	})
}

// AddCreditsRequest represents an add credits request (for admin use)
type AddCreditsRequest struct {
	UserID      primitive.ObjectID     `json:"userId" binding:"required"`
	Credits     int                    `json:"credits" binding:"required"`
	Description string                 `json:"description" binding:"required"`
	Type        models.TransactionType `json:"type" binding:"required"`
}

// AddCredits adds credits to a user's account (Admin only)
// @Summary Add credits to user
// @Description Add loyalty credits to a user's account (Admin only)
// @Tags admin-loyalty
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body AddCreditsRequest true "Add credits request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /admin/loyalty/credits/add [post]
func (h *LoyaltyHandler) AddCredits(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	var req AddCreditsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, map[string]interface{}{"error": err.Error()})
		return
	}

	err := h.loyaltyService.AddCredits(c.Request.Context(), req.UserID, req.Credits, req.Description, req.Type, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Credits added successfully",
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

// GetLoyaltyStatistics gets loyalty program statistics (Admin only)
// @Summary Get loyalty statistics
// @Description Get overall loyalty program statistics (Admin only)
// @Tags admin-loyalty
// @Security BearerAuth
// @Produce json
// @Success 200 {object} models.LoyaltyStatistics
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /admin/loyalty/statistics [get]
func (h *LoyaltyHandler) GetLoyaltyStatistics(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	stats, err := h.loyaltyService.GetLoyaltyStatistics(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    stats,
	})
}

// GetTopLoyaltyMembers gets top loyalty members (Admin only)
// @Summary Get top loyalty members
// @Description Get top loyalty program members by total credits (Admin only)
// @Tags admin-loyalty
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limit" default(10)
// @Success 200 {array} models.TopLoyaltyMember
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /admin/loyalty/top-members [get]
func (h *LoyaltyHandler) GetTopLoyaltyMembers(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	members, err := h.loyaltyService.GetTopLoyaltyMembers(c.Request.Context(), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    members,
	})
}

// ExportLoyaltyData exports loyalty data (Admin only)
// @Summary Export loyalty data
// @Description Export loyalty program data in specified format (Admin only)
// @Tags admin-loyalty
// @Security BearerAuth
// @Produce json
// @Param format query string true "Export format (csv, xlsx)"
// @Param startDate query string false "Start date (YYYY-MM-DD)"
// @Param endDate query string false "End date (YYYY-MM-DD)"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 403 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /admin/loyalty/export [get]
func (h *LoyaltyHandler) ExportLoyaltyData(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, map[string]interface{}{"error": "Admin access required"})
		return
	}

	format := c.Query("format")
	if format == "" {
		format = "csv"
	}

	var startDate, endDate time.Time
	var err error

	startDateStr := c.Query("startDate")
	if startDateStr != "" {
		startDate, err = time.Parse("2006-01-02", startDateStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid start date format"})
			return
		}
	}

	endDateStr := c.Query("endDate")
	if endDateStr != "" {
		endDate, err = time.Parse("2006-01-02", endDateStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid end date format"})
			return
		}
	} else {
		endDate = time.Now()
	}

	filename, err := h.loyaltyService.ExportLoyaltyData(c.Request.Context(), format, startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"success":  true,
		"filename": filename,
		"format":   format,
	})
}