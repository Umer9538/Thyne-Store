package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
)

// StorefrontDataHandler handles storefront data requests
type StorefrontDataHandler struct{
	repo *repository.StorefrontDataRepository
}

// NewStorefrontDataHandler creates a new storefront data handler
func NewStorefrontDataHandler(repo *repository.StorefrontDataRepository) *StorefrontDataHandler {
	return &StorefrontDataHandler{
		repo: repo,
	}
}

// ==================== Public Endpoints (Active Only) ====================

// GetOccasions returns shop by occasion data (public endpoint - only active)
func (h *StorefrontDataHandler) GetOccasions(c *gin.Context) {
	occasions, err := h.repo.GetActiveOccasions(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch occasions",
		})
		return
	}

	// Convert to response format
	var occasionsResponse []models.OccasionResponse
	for _, occasion := range occasions {
		occasionsResponse = append(occasionsResponse, models.OccasionResponse{
			ID:          occasion.ID.Hex(),
			Name:        occasion.Name,
			Icon:        occasion.Icon,
			Description: occasion.Description,
			ItemCount:   occasion.ItemCount,
			Tags:        occasion.Tags,
			Priority:    occasion.Priority,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    occasionsResponse,
	})
}

// GetBudgetRanges returns shop by budget data (public endpoint - only active)
func (h *StorefrontDataHandler) GetBudgetRanges(c *gin.Context) {
	budgetRanges, err := h.repo.GetActiveBudgetRanges(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch budget ranges",
		})
		return
	}

	// Convert to response format
	var budgetRangesResponse []models.BudgetRangeResponse
	for _, budgetRange := range budgetRanges {
		budgetRangesResponse = append(budgetRangesResponse, models.BudgetRangeResponse{
			ID:        budgetRange.ID.Hex(),
			Label:     budgetRange.Label,
			MinPrice:  budgetRange.MinPrice,
			MaxPrice:  budgetRange.MaxPrice,
			ItemCount: budgetRange.ItemCount,
			IsPopular: budgetRange.IsPopular,
			Priority:  budgetRange.Priority,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    budgetRangesResponse,
	})
}

// GetCollections returns curated collections (public endpoint - only active)
func (h *StorefrontDataHandler) GetCollections(c *gin.Context) {
	collections, err := h.repo.GetActiveCollections(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch collections",
		})
		return
	}

	// Convert to response format
	var collectionsResponse []models.CollectionResponse
	for _, collection := range collections {
		collectionsResponse = append(collectionsResponse, models.CollectionResponse{
			ID:          collection.ID.Hex(),
			Title:       collection.Title,
			Subtitle:    collection.Subtitle,
			Description: collection.Description,
			ImageURLs:   collection.ImageURLs,
			ItemCount:   collection.ItemCount,
			Tags:        collection.Tags,
			IsFeatured:  collection.IsFeatured,
			Priority:    collection.Priority,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    collectionsResponse,
	})
}

// GetCollectionProducts returns products in a specific collection
func (h *StorefrontDataHandler) GetCollectionProducts(c *gin.Context) {
	collectionID := c.Param("id")
	if collectionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Collection ID is required",
		})
		return
	}

	products, err := h.repo.GetCollectionProducts(c.Request.Context(), collectionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch collection products",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}

// ==================== Admin Endpoints - Occasions ====================

// GetAllOccasions returns all occasions (admin only)
func (h *StorefrontDataHandler) GetAllOccasions(c *gin.Context) {
	occasions, err := h.repo.GetAllOccasions(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch occasions",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    occasions,
	})
}

// CreateOccasion creates a new occasion (admin only)
func (h *StorefrontDataHandler) CreateOccasion(c *gin.Context) {
	var occasion models.Occasion
	if err := c.ShouldBindJSON(&occasion); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	if err := h.repo.CreateOccasion(c.Request.Context(), &occasion); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create occasion",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Occasion created successfully",
		"data":    occasion,
	})
}

// UpdateOccasion updates an existing occasion (admin only)
func (h *StorefrontDataHandler) UpdateOccasion(c *gin.Context) {
	id := c.Param("id")

	var occasion models.Occasion
	if err := c.ShouldBindJSON(&occasion); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	if err := h.repo.UpdateOccasion(c.Request.Context(), id, &occasion); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update occasion",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Occasion updated successfully",
	})
}

// DeleteOccasion deletes an occasion (admin only)
func (h *StorefrontDataHandler) DeleteOccasion(c *gin.Context) {
	id := c.Param("id")

	if err := h.repo.DeleteOccasion(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to delete occasion",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Occasion deleted successfully",
	})
}

// ==================== Admin Endpoints - Budget Ranges ====================

// GetAllBudgetRanges returns all budget ranges (admin only)
func (h *StorefrontDataHandler) GetAllBudgetRanges(c *gin.Context) {
	budgetRanges, err := h.repo.GetAllBudgetRanges(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch budget ranges",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    budgetRanges,
	})
}

// CreateBudgetRange creates a new budget range (admin only)
func (h *StorefrontDataHandler) CreateBudgetRange(c *gin.Context) {
	var budgetRange models.BudgetRange
	if err := c.ShouldBindJSON(&budgetRange); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	if err := h.repo.CreateBudgetRange(c.Request.Context(), &budgetRange); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create budget range",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Budget range created successfully",
		"data":    budgetRange,
	})
}

// UpdateBudgetRange updates an existing budget range (admin only)
func (h *StorefrontDataHandler) UpdateBudgetRange(c *gin.Context) {
	id := c.Param("id")

	var budgetRange models.BudgetRange
	if err := c.ShouldBindJSON(&budgetRange); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	if err := h.repo.UpdateBudgetRange(c.Request.Context(), id, &budgetRange); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update budget range",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Budget range updated successfully",
	})
}

// DeleteBudgetRange deletes a budget range (admin only)
func (h *StorefrontDataHandler) DeleteBudgetRange(c *gin.Context) {
	id := c.Param("id")

	if err := h.repo.DeleteBudgetRange(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to delete budget range",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Budget range deleted successfully",
	})
}

// ==================== Admin Endpoints - Collections ====================

// GetAllCollections returns all collections (admin only)
func (h *StorefrontDataHandler) GetAllCollections(c *gin.Context) {
	collections, err := h.repo.GetAllCollections(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch collections",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    collections,
	})
}

// CreateCollection creates a new collection (admin only)
func (h *StorefrontDataHandler) CreateCollection(c *gin.Context) {
	var collection models.Collection
	if err := c.ShouldBindJSON(&collection); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	if err := h.repo.CreateCollection(c.Request.Context(), &collection); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create collection",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Collection created successfully",
		"data":    collection,
	})
}

// UpdateCollection updates an existing collection (admin only)
func (h *StorefrontDataHandler) UpdateCollection(c *gin.Context) {
	id := c.Param("id")

	var collection models.Collection
	if err := c.ShouldBindJSON(&collection); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	if err := h.repo.UpdateCollection(c.Request.Context(), id, &collection); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update collection",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Collection updated successfully",
	})
}

// DeleteCollection deletes a collection (admin only)
func (h *StorefrontDataHandler) DeleteCollection(c *gin.Context) {
	id := c.Param("id")

	if err := h.repo.DeleteCollection(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to delete collection",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Collection deleted successfully",
	})
}

// ==================== Store Settings ====================

// GetStoreSettings returns the store settings (public endpoint for cart calculations)
func (h *StorefrontDataHandler) GetStoreSettings(c *gin.Context) {
	settings, err := h.repo.GetStoreSettings(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to fetch store settings",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    settings.ToResponse(),
	})
}

// UpdateStoreSettings updates the store settings (admin only)
func (h *StorefrontDataHandler) UpdateStoreSettings(c *gin.Context) {
	var settings models.StoreSettings
	if err := c.ShouldBindJSON(&settings); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	if err := h.repo.UpdateStoreSettings(c.Request.Context(), &settings); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update store settings",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Store settings updated successfully",
	})
}
