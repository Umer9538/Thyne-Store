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

// GetActiveDealOfDay returns the current active deal with product details
// @Summary Get active deal of day
// @Description Get currently active deal of the day with full product details
// @Tags homepage
// @Produce json
// @Success 200 {object} models.DealOfDayWithProduct
// @Router /homepage/deal-of-day [get]
func (h *HomepageHandler) GetActiveDealOfDay(c *gin.Context) {
	deal, err := h.homepageService.GetActiveDealOfDayWithProduct(c.Request.Context())
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

// GetActiveFlashSales returns all active flash sales with full product details
// @Summary Get active flash sales
// @Description Get all currently active flash sales with products and discounted prices
// @Tags homepage
// @Produce json
// @Success 200 {array} models.FlashSaleWithProducts
// @Router /homepage/flash-sales [get]
func (h *HomepageHandler) GetActiveFlashSales(c *gin.Context) {
	sales, err := h.homepageService.GetActiveFlashSalesWithProducts(c.Request.Context())
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

// UpdateFlashSaleRequest defines the request body for updating a flash sale
type UpdateFlashSaleRequest struct {
	Title       string    `json:"title"`
	Description string    `json:"description"`
	BannerImage string    `json:"bannerImage"`
	ProductIDs  []string  `json:"productIds"`
	StartTime   time.Time `json:"startTime"`
	EndTime     time.Time `json:"endTime"`
	Discount    int       `json:"discount"`
	IsActive    *bool     `json:"isActive"`
}

// UpdateFlashSale updates an existing flash sale
// @Summary Update flash sale
// @Description Update an existing flash sale (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Flash Sale ID"
// @Param request body UpdateFlashSaleRequest true "Flash sale update request"
// @Success 200 {object} map[string]interface{}
// @Router /admin/homepage/flash-sale/{id} [put]
func (h *HomepageHandler) UpdateFlashSale(c *gin.Context) {
	saleID := c.Param("id")
	if saleID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Flash sale ID is required"})
		return
	}

	var req UpdateFlashSaleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Convert sale ID to ObjectID
	objectID, err := primitive.ObjectIDFromHex(saleID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid flash sale ID"})
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
		ID:          objectID,
		Title:       req.Title,
		Description: req.Description,
		BannerImage: req.BannerImage,
		ProductIDs:  productIDs,
		StartTime:   req.StartTime,
		EndTime:     req.EndTime,
		Discount:    req.Discount,
	}

	if req.IsActive != nil {
		sale.IsActive = *req.IsActive
	}

	err = h.homepageService.UpdateFlashSale(c.Request.Context(), sale)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Flash sale updated successfully",
		"data":    sale,
	})
}

// DeleteFlashSale deletes a flash sale
// @Summary Delete flash sale
// @Description Delete an existing flash sale (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Param id path string true "Flash Sale ID"
// @Success 200 {object} map[string]interface{}
// @Router /admin/homepage/flash-sale/{id} [delete]
func (h *HomepageHandler) DeleteFlashSale(c *gin.Context) {
	saleID := c.Param("id")
	if saleID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Flash sale ID is required"})
		return
	}

	err := h.homepageService.DeleteFlashSale(c.Request.Context(), saleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Flash sale deleted successfully",
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

// Homepage Layout Handlers

// GetHomepageLayout returns the homepage layout configuration
// @Summary Get homepage layout
// @Description Get homepage section ordering configuration (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Produce json
// @Success 200 {object} models.HomepageLayout
// @Router /admin/homepage/layout [get]
func (h *HomepageHandler) GetHomepageLayout(c *gin.Context) {
	layout, err := h.homepageService.GetHomepageLayout(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    layout,
	})
}

// UpdateHomepageLayout updates the homepage layout configuration
// @Summary Update homepage layout
// @Description Update homepage section ordering (Admin only)
// @Tags admin-homepage
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body models.HomepageLayout true "Homepage layout"
// @Success 200 {object} map[string]interface{}
// @Router /admin/homepage/layout [put]
func (h *HomepageHandler) UpdateHomepageLayout(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var layout models.HomepageLayout
	if err := c.ShouldBindJSON(&layout); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.homepageService.UpdateHomepageLayout(c.Request.Context(), &layout, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Homepage layout updated successfully",
		"data":    layout,
	})
}

// ==================== 360° Showcase Handlers ====================

// GetActiveShowcases returns all active 360° showcases for public display
func (h *HomepageHandler) GetActiveShowcases(c *gin.Context) {
	showcases, err := h.homepageService.GetActiveShowcases(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    showcases,
	})
}

// GetAllShowcases returns all 360° showcases for admin
func (h *HomepageHandler) GetAllShowcases(c *gin.Context) {
	showcases, err := h.homepageService.GetAllShowcases(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    showcases,
	})
}

// CreateShowcase creates a new 360° showcase
func (h *HomepageHandler) CreateShowcase(c *gin.Context) {
	var req struct {
		ProductID    string   `json:"productId" binding:"required"`
		Title        string   `json:"title" binding:"required"`
		Description  string   `json:"description"`
		Images360    []string `json:"images360" binding:"required,min=4"`
		VideoURL     string   `json:"videoUrl"`
		ThumbnailURL string   `json:"thumbnailUrl"`
		Priority     int      `json:"priority"`
		IsActive     bool     `json:"isActive"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request: " + err.Error(),
		})
		return
	}

	productID, err := primitive.ObjectIDFromHex(req.ProductID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid product ID",
		})
		return
	}

	showcase := &models.Showcase360{
		ProductID:    productID,
		Title:        req.Title,
		Description:  req.Description,
		Images360:    req.Images360,
		VideoURL:     req.VideoURL,
		ThumbnailURL: req.ThumbnailURL,
		Priority:     req.Priority,
		IsActive:     req.IsActive,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	err = h.homepageService.CreateShowcase(c.Request.Context(), showcase)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "360° Showcase created successfully",
		"data":    showcase,
	})
}

// UpdateShowcase updates an existing 360° showcase
func (h *HomepageHandler) UpdateShowcase(c *gin.Context) {
	showcaseID := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(showcaseID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid showcase ID",
		})
		return
	}

	var req struct {
		ProductID    string   `json:"productId"`
		Title        string   `json:"title"`
		Description  string   `json:"description"`
		Images360    []string `json:"images360"`
		VideoURL     string   `json:"videoUrl"`
		ThumbnailURL string   `json:"thumbnailUrl"`
		Priority     *int     `json:"priority"`
		IsActive     *bool    `json:"isActive"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request: " + err.Error(),
		})
		return
	}

	showcase := &models.Showcase360{
		ID:           objID,
		Title:        req.Title,
		Description:  req.Description,
		Images360:    req.Images360,
		VideoURL:     req.VideoURL,
		ThumbnailURL: req.ThumbnailURL,
		UpdatedAt:    time.Now(),
	}

	if req.ProductID != "" {
		productID, err := primitive.ObjectIDFromHex(req.ProductID)
		if err == nil {
			showcase.ProductID = productID
		}
	}

	if req.Priority != nil {
		showcase.Priority = *req.Priority
	}

	if req.IsActive != nil {
		showcase.IsActive = *req.IsActive
	}

	err = h.homepageService.UpdateShowcase(c.Request.Context(), showcase)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "360° Showcase updated successfully",
		"data":    showcase,
	})
}

// DeleteShowcase deletes a 360° showcase
func (h *HomepageHandler) DeleteShowcase(c *gin.Context) {
	showcaseID := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(showcaseID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid showcase ID",
		})
		return
	}

	err = h.homepageService.DeleteShowcase(c.Request.Context(), objID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "360° Showcase deleted successfully",
	})
}

// ==================== Bundle Deals Handlers ====================

// GetActiveBundleDeals returns all active bundle deals for public display
func (h *HomepageHandler) GetActiveBundleDeals(c *gin.Context) {
	bundles, err := h.homepageService.GetActiveBundleDeals(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    bundles,
	})
}

// GetAllBundleDeals returns all bundle deals for admin
func (h *HomepageHandler) GetAllBundleDeals(c *gin.Context) {
	bundles, err := h.homepageService.GetActiveBundleDeals(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    bundles,
	})
}

// CreateBundleDeal creates a new bundle deal
func (h *HomepageHandler) CreateBundleDeal(c *gin.Context) {
	var req struct {
		Title       string `json:"title" binding:"required"`
		Description string `json:"description"`
		Items       []struct {
			ProductID string `json:"productId" binding:"required"`
			Quantity  int    `json:"quantity" binding:"required,min=1"`
		} `json:"items" binding:"required,min=1"`
		BundlePrice float64    `json:"bundlePrice" binding:"required"`
		Stock       int        `json:"stock" binding:"required,min=1"`
		StartTime   *time.Time `json:"startTime"`
		EndTime     *time.Time `json:"endTime"`
		BannerImage string     `json:"bannerImage"`
		Priority    int        `json:"priority"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request: " + err.Error(),
		})
		return
	}

	// Convert items
	var items []models.BundleItem
	for _, item := range req.Items {
		productID, err := primitive.ObjectIDFromHex(item.ProductID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid product ID: " + item.ProductID,
			})
			return
		}
		items = append(items, models.BundleItem{
			ProductID: productID,
			Quantity:  item.Quantity,
		})
	}

	bundle := &models.BundleDeal{
		Title:       req.Title,
		Description: req.Description,
		Items:       items,
		BundlePrice: req.BundlePrice,
		Stock:       req.Stock,
		StartTime:   req.StartTime,
		EndTime:     req.EndTime,
		BannerImage: req.BannerImage,
		Priority:    req.Priority,
		IsActive:    true,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	err := h.homepageService.CreateBundleDeal(c.Request.Context(), bundle)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Bundle Deal created successfully",
		"data":    bundle,
	})
}

// UpdateBundleDeal updates an existing bundle deal
func (h *HomepageHandler) UpdateBundleDeal(c *gin.Context) {
	bundleID := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(bundleID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid bundle ID",
		})
		return
	}

	var req struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		Items       []struct {
			ProductID string `json:"productId"`
			Quantity  int    `json:"quantity"`
		} `json:"items"`
		BundlePrice float64    `json:"bundlePrice"`
		Stock       int        `json:"stock"`
		StartTime   *time.Time `json:"startTime"`
		EndTime     *time.Time `json:"endTime"`
		BannerImage string     `json:"bannerImage"`
		Priority    *int       `json:"priority"`
		IsActive    *bool      `json:"isActive"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request: " + err.Error(),
		})
		return
	}

	bundle := &models.BundleDeal{
		ID:          objID,
		Title:       req.Title,
		Description: req.Description,
		BundlePrice: req.BundlePrice,
		Stock:       req.Stock,
		BannerImage: req.BannerImage,
		UpdatedAt:   time.Now(),
	}

	// Convert items if provided
	if len(req.Items) > 0 {
		var items []models.BundleItem
		for _, item := range req.Items {
			productID, err := primitive.ObjectIDFromHex(item.ProductID)
			if err != nil {
				continue
			}
			items = append(items, models.BundleItem{
				ProductID: productID,
				Quantity:  item.Quantity,
			})
		}
		bundle.Items = items
	}

	if req.StartTime != nil {
		bundle.StartTime = req.StartTime
	}
	if req.EndTime != nil {
		bundle.EndTime = req.EndTime
	}
	if req.Priority != nil {
		bundle.Priority = *req.Priority
	}
	if req.IsActive != nil {
		bundle.IsActive = *req.IsActive
	}

	err = h.homepageService.UpdateBundleDeal(c.Request.Context(), bundle)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Bundle Deal updated successfully",
		"data":    bundle,
	})
}

// DeleteBundleDeal deletes a bundle deal
func (h *HomepageHandler) DeleteBundleDeal(c *gin.Context) {
	bundleID := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(bundleID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid bundle ID",
		})
		return
	}

	err = h.homepageService.DeleteBundleDeal(c.Request.Context(), objID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Bundle Deal deleted successfully",
	})
}
