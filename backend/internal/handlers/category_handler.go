package handlers

import (
    "net/http"
    "thyne-jewels-backend/internal/services"
    "github.com/gin-gonic/gin"
)

type CategoryHandler struct { categoryService services.CategoryService }

func NewCategoryHandler(categoryService services.CategoryService) *CategoryHandler {
    return &CategoryHandler{ categoryService: categoryService }
}

// CreateCategory creates a new category (admin only)
// @Summary Create category
// @Description Create a new product category (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body object true "Category creation data"
// @Success 201 {object} map[string]interface{} "Category created successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 403 {object} map[string]interface{} "Admin access required"
// @Router /admin/categories [post]
func (h *CategoryHandler) CreateCategory(c *gin.Context) {
    var req struct {
		Name        string   `json:"name" binding:"required"`
		Description string   `json:"description"`
		Subcategories []string `json:"subcategories"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

    created, err := h.categoryService.CreateCategory(c.Request.Context(), req.Name, req.Description)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "Failed to create category", "code": "CREATE_FAILED"})
        return
    }
    c.JSON(http.StatusCreated, gin.H{"success": true, "data": created, "message": "Category created successfully"})
}

// UpdateCategory updates an existing category (admin only)
func (h *CategoryHandler) UpdateCategory(c *gin.Context) {
	categoryID := c.Param("id")
	if categoryID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Category ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req struct {
		Name        string   `json:"name" binding:"required"`
		Description string   `json:"description"`
		Subcategories []string `json:"subcategories"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

    updated, err := h.categoryService.UpdateCategory(c.Request.Context(), categoryID, req.Name, req.Description)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "Failed to update category", "code": "UPDATE_FAILED"})
        return
    }
    c.JSON(http.StatusOK, gin.H{"success": true, "data": updated, "message": "Category updated successfully"})
}

// DeleteCategory deletes a category (admin only)
func (h *CategoryHandler) DeleteCategory(c *gin.Context) {
	categoryID := c.Param("id")
	if categoryID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Category ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

    if err := h.categoryService.DeleteCategory(c.Request.Context(), categoryID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "Failed to delete category", "code": "DELETE_FAILED"})
        return
    }
    c.JSON(http.StatusOK, gin.H{"success": true, "message": "Category deleted successfully"})
}

// GetAllCategories gets all categories with subcategories (admin only)
func (h *CategoryHandler) GetAllCategories(c *gin.Context) {
    categories, err := h.categoryService.GetAllCategories(c.Request.Context())
    if err != nil {
        // Log the actual error server-side for debugging
        // Note: using Gin's logger
        c.Error(err)
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error":   err.Error(),
            "code":    "FETCH_FAILED",
        })
        return
    }
    c.JSON(http.StatusOK, gin.H{"success": true, "data": categories})
}
