package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"
)

// HomepageHandler handles homepage-related requests
type HomepageHandler struct {
	homepageService *services.HomepageService
}

// NewHomepageHandler creates a new homepage handler
func NewHomepageHandler(homepageService *services.HomepageService) *HomepageHandler {
	return &HomepageHandler{
		homepageService: homepageService,
	}
}

// GetHomepageData returns complete homepage data
// @Summary Get homepage data
// @Description Get all sections and data for homepage
// @Tags homepage
// @Produce json
// @Success 200 {object} models.HomepageResponse
// @Router /homepage [get]
func (h *HomepageHandler) GetHomepageData(c *gin.Context) {
	// Get user ID if authenticated
	var userID *primitive.ObjectID
	if uid, exists := c.Get("userID"); exists {
		id := uid.(primitive.ObjectID)
		userID = &id
	}

	// Get session ID from header or guest session
	var sessionID *string
	if sid := c.GetHeader("X-Guest-Session-ID"); sid != "" {
		sessionID = &sid
	}

	data, err := h.homepageService.GetHomepageData(c.Request.Context(), userID, sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    data,
	})
}

// TrackProductView tracks when a user views a product
// @Summary Track product view
// @Description Track product view for recently viewed section
// @Tags homepage
// @Accept json
// @Produce json
// @Param productId path string true "Product ID"
// @Success 200 {object} map[string]interface{}
// @Router /homepage/track/{productId} [post]
func (h *HomepageHandler) TrackProductView(c *gin.Context) {
	productIDStr := c.Param("productId")
	productID, err := primitive.ObjectIDFromHex(productIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	// Get user ID if authenticated
	var userID *primitive.ObjectID
	if uid, exists := c.Get("userID"); exists {
		id := uid.(primitive.ObjectID)
		userID = &id
	}

	// Get session ID from header
	var sessionID *string
	if sid := c.GetHeader("X-Guest-Session-ID"); sid != "" {
		sessionID = &sid
	}

	err = h.homepageService.TrackProductView(c.Request.Context(), userID, sessionID, productID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Product view tracked",
	})
}

// GetRecentlyViewed returns recently viewed products
// @Summary Get recently viewed products
// @Description Get user's recently viewed products
// @Tags homepage
// @Produce json
// @Param limit query int false "Limit" default(10)
// @Success 200 {array} models.Product
// @Router /homepage/recently-viewed [get]
func (h *HomepageHandler) GetRecentlyViewed(c *gin.Context) {
	// Get user ID if authenticated
	var userID *primitive.ObjectID
	if uid, exists := c.Get("userID"); exists {
		id := uid.(primitive.ObjectID)
		userID = &id
	}

	// Get session ID from header
	var sessionID *string
	if sid := c.GetHeader("X-Guest-Session-ID"); sid != "" {
		sessionID = &sid
	}

	limit := 10
	if l, ok := c.GetQuery("limit"); ok {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	products, err := h.homepageService.GetRecentlyViewed(c.Request.Context(), userID, sessionID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}

// Deal of Day Handlers

type CreateDealRequest struct {
	ProductID       string    `json:"productId" binding:"required"`
	DiscountPercent int       `json:"discountPercent" binding:"required,min=1,max=90"`
	Stock           int       `json:"stock" binding:"required,min=1"`
	StartTime       time.Time `json:"startTime" binding:"required"`
	EndTime         time.Time `json:"endTime" binding:"required"`
}

// CreateDealOfDay creates a new deal of the day
// @Summary Create deal of day
// @Description Create a new deal of the day (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateDealRequest true "Deal request"
// @Success 200 {object} map[string]interface{}
// @Router /admin/homepage/deal-of-day [post]
func (h *HomepageHandler) CreateDealOfDay(c *gin.Context) {
	var req CreateDealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	productID, err := primitive.ObjectIDFromHex(req.ProductID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	deal := &models.DealOfDay{
		ProductID:       productID,
		DiscountPercent: req.DiscountPercent,
		Stock:           req.Stock,
		StartTime:       req.StartTime,
		EndTime:         req.EndTime,
	}

	err = h.homepageService.CreateDealOfDay(c.Request.Context(), deal)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Deal of day created successfully",
		"data":    deal,
	})
}

// GetActiveDealOfDay returns the current active deal
// @Summary Get active deal of day
// @Description Get currently active deal of the day
// @Tags homepage
// @Produce json
// @Success 200 {object} models.DealOfDay
// @Router /homepage/deal-of-day [get]
func (h *HomepageHandler) GetActiveDealOfDay(c *gin.Context) {
	deal, err := h.homepageService.GetActiveDealOfDay(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if deal == nil {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    nil,
			"message": "No active deal",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    deal,
	})
}

// Flash Sale Handlers

type CreateFlashSaleRequest struct {
	Title       string   `json:"title" binding:"required"`
	Description string   `json:"description"`
	BannerImage string   `json:"bannerImage"`
	ProductIDs  []string `json:"productIds" binding:"required,min=1"`
	StartTime   time.Time `json:"startTime" binding:"required"`
	EndTime     time.Time `json:"endTime" binding:"required"`
	Discount    int      `json:"discount" binding:"required,min=1,max=90"`
}

// CreateFlashSale creates a new flash sale
// @Summary Create flash sale
// @Description Create a new flash sale (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateFlashSaleRequest true "Flash sale request"
// @Success 200 {object} map[string]interface{}
// @Router /admin/homepage/flash-sale [post]
func (h *HomepageHandler) CreateFlashSale(c *gin.Context) {
	var req CreateFlashSaleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Convert product IDs
	var productIDs []primitive.ObjectID
	for _, idStr := range req.ProductIDs {
		id, err := primitive.ObjectIDFromHex(idStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID: " + idStr})
			return
		}
		productIDs = append(productIDs, id)
	}

	sale := &models.FlashSale{
		Title:       req.Title,
		Description: req.Description,
		BannerImage: req.BannerImage,
		ProductIDs:  productIDs,
		StartTime:   req.StartTime,
		EndTime:     req.EndTime,
		Discount:    req.Discount,
	}

	err := h.homepageService.CreateFlashSale(c.Request.Context(), sale)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Flash sale created successfully",
		"data":    sale,
	})
}

// GetActiveFlashSales returns all active flash sales
// @Summary Get active flash sales
// @Description Get all currently active flash sales
// @Tags homepage
// @Produce json
// @Success 200 {array} models.FlashSale
// @Router /homepage/flash-sales [get]
func (h *HomepageHandler) GetActiveFlashSales(c *gin.Context) {
	sales, err := h.homepageService.GetActiveFlashSales(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    sales,
	})
}

// GetAllFlashSales returns all flash sales for admin
// @Summary Get all flash sales
// @Description Get all flash sales (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.FlashSale
// @Router /admin/homepage/flash-sales [get]
func (h *HomepageHandler) GetAllFlashSales(c *gin.Context) {
	sales, err := h.homepageService.GetAllFlashSales(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    sales,
	})
}

// Brand Handlers

type CreateBrandRequest struct {
	Name        string `json:"name" binding:"required"`
	Logo        string `json:"logo" binding:"required"`
	Description string `json:"description"`
	Priority    int    `json:"priority"`
}

// CreateBrand creates a new brand
// @Summary Create brand
// @Description Create a new brand (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateBrandRequest true "Brand request"
// @Success 200 {object} map[string]interface{}
// @Router /admin/homepage/brands [post]
func (h *HomepageHandler) CreateBrand(c *gin.Context) {
	var req CreateBrandRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	brand := &models.Brand{
		Name:        req.Name,
		Logo:        req.Logo,
		Description: req.Description,
		Priority:    req.Priority,
	}

	err := h.homepageService.CreateBrand(c.Request.Context(), brand)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Brand created successfully",
		"data":    brand,
	})
}

// GetActiveBrands returns all active brands
// @Summary Get active brands
// @Description Get all active brands
// @Tags homepage
// @Produce json
// @Success 200 {array} models.Brand
// @Router /homepage/brands [get]
func (h *HomepageHandler) GetActiveBrands(c *gin.Context) {
	brands, err := h.homepageService.GetActiveBrands(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    brands,
	})
}

// GetAllBrands returns all brands for admin
// @Summary Get all brands
// @Description Get all brands (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.Brand
// @Router /admin/homepage/brands [get]
func (h *HomepageHandler) GetAllBrands(c *gin.Context) {
	brands, err := h.homepageService.GetAllBrands(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    brands,
	})
}

// Homepage Configuration Handlers

// GetHomepageConfig returns the homepage configuration
// @Summary Get homepage config
// @Description Get homepage configuration (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Produce json
// @Success 200 {object} models.HomepageConfig
// @Router /admin/homepage/config [get]
func (h *HomepageHandler) GetHomepageConfig(c *gin.Context) {
	config, err := h.homepageService.GetHomepageConfig(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    config,
	})
}

// UpdateHomepageConfig updates the homepage configuration
// @Summary Update homepage config
// @Description Update homepage configuration (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body models.HomepageConfig true "Homepage config"
// @Success 200 {object} map[string]interface{}
// @Router /admin/homepage/config [put]
func (h *HomepageHandler) UpdateHomepageConfig(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var config models.HomepageConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.homepageService.UpdateHomepageConfig(c.Request.Context(), &config, userID.(primitive.ObjectID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Homepage configuration updated successfully",
		"data":    config,
	})
}
