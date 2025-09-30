package handlers

import (
	"net/http"
	"strconv"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

type ProductHandler struct {
	productService services.ProductService
}

func NewProductHandler(productService services.ProductService) *ProductHandler {
	return &ProductHandler{
		productService: productService,
	}
}

// GetProducts gets all products with filtering and pagination
// @Summary Get products
// @Description Get all products with filtering, pagination, and sorting options
// @Tags Products
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(20)
// @Param category query string false "Product category"
// @Param subcategory query string false "Product subcategory"
// @Param search query string false "Search term"
// @Param sortBy query string false "Sort by field" default(popularity)
// @Param minPrice query number false "Minimum price"
// @Param maxPrice query number false "Maximum price"
// @Param inStock query boolean false "Filter by stock availability"
// @Success 200 {object} map[string]interface{} "Products retrieved successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /products [get]
func (h *ProductHandler) GetProducts(c *gin.Context) {
	// Parse query parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	category := c.Query("category")
	subcategory := c.Query("subcategory")
	search := c.Query("search")
	sortBy := c.DefaultQuery("sortBy", "popularity")

	// Build filter
	filter := models.ProductFilter{
		Page:        page,
		Limit:       limit,
		Category:    category,
		Subcategory: subcategory,
		Search:      search,
		SortBy:      sortBy,
	}

	// Parse price filters
	if minPriceStr := c.Query("minPrice"); minPriceStr != "" {
		if minPrice, err := strconv.ParseFloat(minPriceStr, 64); err == nil {
			filter.MinPrice = &minPrice
		}
	}
	if maxPriceStr := c.Query("maxPrice"); maxPriceStr != "" {
		if maxPrice, err := strconv.ParseFloat(maxPriceStr, 64); err == nil {
			filter.MaxPrice = &maxPrice
		}
	}

	// Parse other filters
	if inStockStr := c.Query("inStock"); inStockStr != "" {
		if inStock, err := strconv.ParseBool(inStockStr); err == nil {
			filter.InStock = &inStock
		}
	}

	// Get products
	products, total, err := h.productService.GetProducts(filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch products",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"products": products,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"totalPages": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// GetProduct gets a single product by ID
// @Summary Get product by ID
// @Description Get a single product by its ID
// @Tags Products
// @Accept json
// @Produce json
// @Param id path string true "Product ID"
// @Success 200 {object} map[string]interface{} "Product retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid product ID"
// @Failure 404 {object} map[string]interface{} "Product not found"
// @Router /products/{id} [get]
func (h *ProductHandler) GetProduct(c *gin.Context) {
	productID := c.Param("id")
	if productID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Product ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	product, err := h.productService.GetProduct(productID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Product not found",
			"code":    "NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    product,
	})
}

// GetCategories gets all product categories
// @Summary Get categories
// @Description Get all product categories
// @Tags Products
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{} "Categories retrieved successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /products/categories [get]
func (h *ProductHandler) GetCategories(c *gin.Context) {
	categories, err := h.productService.GetCategories()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch categories",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    categories,
	})
}

// GetFeaturedProducts gets featured products
// @Summary Get featured products
// @Description Get all featured products
// @Tags Products
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{} "Featured products retrieved successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /products/featured [get]
func (h *ProductHandler) GetFeaturedProducts(c *gin.Context) {
	products, err := h.productService.GetFeaturedProducts()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch featured products",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}

// SearchProducts searches products
// @Summary Search products
// @Description Search products by query string
// @Tags Products
// @Accept json
// @Produce json
// @Param q query string true "Search query"
// @Success 200 {object} map[string]interface{} "Products found successfully"
// @Failure 400 {object} map[string]interface{} "Search query is required"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /products/search [get]
func (h *ProductHandler) SearchProducts(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Search query is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	products, err := h.productService.SearchProducts(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to search products",
			"code":    "SEARCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}

// GetProductReviews gets reviews for a product
// @Summary Get product reviews
// @Description Get reviews for a specific product
// @Tags Products
// @Accept json
// @Produce json
// @Param id path string true "Product ID"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(10)
// @Success 200 {object} map[string]interface{} "Reviews retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid product ID"
// @Router /products/{id}/reviews [get]
func (h *ProductHandler) GetProductReviews(c *gin.Context) {
	productID := c.Param("id")
	if productID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Product ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	// TODO: Implement get product reviews
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    []interface{}{},
		"message": "Product reviews feature coming soon",
	})
}

// Admin endpoints

// CreateProduct creates a new product (admin only)
func (h *ProductHandler) CreateProduct(c *gin.Context) {
	var req models.CreateProductRequest
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

	product, err := h.productService.CreateProduct(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to create product",
			"code":    "CREATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    product,
		"message": "Product created successfully",
	})
}

// UpdateProduct updates an existing product (admin only)
func (h *ProductHandler) UpdateProduct(c *gin.Context) {
	productID := c.Param("id")
	if productID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Product ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.UpdateProductRequest
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

	product, err := h.productService.UpdateProduct(c.Request.Context(), productID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to update product",
			"code":    "UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    product,
		"message": "Product updated successfully",
	})
}

// DeleteProduct deletes a product (admin only)
func (h *ProductHandler) DeleteProduct(c *gin.Context) {
	productID := c.Param("id")
	if productID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Product ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.productService.DeleteProduct(c.Request.Context(), productID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to delete product",
			"code":    "DELETE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Product deleted successfully",
	})
}

// UpdateProductStock updates product stock (admin only)
func (h *ProductHandler) UpdateProductStock(c *gin.Context) {
	productID := c.Param("id")
	if productID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Product ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req struct {
		Quantity int    `json:"quantity" binding:"required"`
		Reason   string `json:"reason"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.productService.UpdateProductStock(c.Request.Context(), productID, req.Quantity, req.Reason)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to update stock",
			"code":    "STOCK_UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Stock updated successfully",
	})
}
