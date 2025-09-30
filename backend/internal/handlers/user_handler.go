package handlers

import (
	"net/http"
	"strconv"

	"thyne-jewels-backend/internal/middleware"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type UserHandler struct {
	userService services.UserService
	authService services.AuthService
}

func NewUserHandler(userService services.UserService, authService services.AuthService) *UserHandler {
	return &UserHandler{
		userService: userService,
		authService: authService,
	}
}

// GetProfile gets the current user's profile
// @Summary Get user profile
// @Description Get the authenticated user's profile information
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "Profile retrieved successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 404 {object} map[string]interface{} "User not found"
// @Router /users/profile [get]
func (h *UserHandler) GetProfile(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	user, err := h.userService.GetProfile(objectID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "User not found",
			"code":    "NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
	})
}

// UpdateProfile updates the current user's profile
// @Summary Update user profile
// @Description Update the authenticated user's profile information
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.UpdateProfileRequest true "Profile update data"
// @Success 200 {object} map[string]interface{} "Profile updated successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /users/profile [put]
func (h *UserHandler) UpdateProfile(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.UpdateProfileRequest
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

	user, err := h.userService.UpdateProfile(objectID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "UPDATE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
		"message": "Profile updated successfully",
	})
}

// AddAddress adds a new address to the user's profile
// @Summary Add address
// @Description Add a new address to the user's profile
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.AddAddressRequest true "Address data"
// @Success 201 {object} map[string]interface{} "Address added successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /users/addresses [post]
func (h *UserHandler) AddAddress(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.AddAddressRequest
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

	err = h.userService.AddAddress(objectID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "ADD_ADDRESS_FAILED",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Address added successfully",
	})
}

// UpdateAddress updates an existing address
// @Summary Update address
// @Description Update an existing address in the user's profile
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Address ID"
// @Param request body models.AddAddressRequest true "Address update data"
// @Success 200 {object} map[string]interface{} "Address updated successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /users/addresses/{id} [put]
func (h *UserHandler) UpdateAddress(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	addressID := c.Param("id")
	if addressID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Address ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.AddAddressRequest
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

	err = h.userService.UpdateAddress(objectID, addressID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "UPDATE_ADDRESS_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Address updated successfully",
	})
}

// DeleteAddress deletes an address
// @Summary Delete address
// @Description Delete an address from the user's profile
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Address ID"
// @Success 200 {object} map[string]interface{} "Address deleted successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 404 {object} map[string]interface{} "Address not found"
// @Router /users/addresses/{id} [delete]
func (h *UserHandler) DeleteAddress(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	addressID := c.Param("id")
	if addressID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Address ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err = h.userService.DeleteAddress(objectID, addressID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "DELETE_ADDRESS_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Address deleted successfully",
	})
}

// ChangePassword changes the user's password
// @Summary Change password
// @Description Change the authenticated user's password
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.ChangePasswordRequest true "Password change data"
// @Success 200 {object} map[string]interface{} "Password changed successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /users/change-password [post]
func (h *UserHandler) ChangePassword(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req models.ChangePasswordRequest
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

	err = h.authService.ChangePassword(objectID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "CHANGE_PASSWORD_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Password changed successfully",
	})
}

// GetWishlist gets the user's wishlist
// @Summary Get wishlist
// @Description Get the authenticated user's wishlist
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(20)
// @Success 200 {object} map[string]interface{} "Wishlist retrieved successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /users/wishlist [get]
func (h *UserHandler) GetWishlist(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	products, total, err := h.userService.GetWishlistItems(objectID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch wishlist",
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

// AddToWishlist adds a product to wishlist
// @Summary Add to wishlist
// @Description Add a product to the user's wishlist
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body object true "Add to wishlist request"
// @Success 200 {object} map[string]interface{} "Product added to wishlist successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /users/wishlist [post]
func (h *UserHandler) AddToWishlist(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	var req struct {
		ProductID string `json:"productId" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	productObjectID, err := primitive.ObjectIDFromHex(req.ProductID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid product ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err = h.userService.AddToWishlist(objectID, productObjectID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "WISHLIST_ADD_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Product added to wishlist successfully",
	})
}

// RemoveFromWishlist removes a product from wishlist
// @Summary Remove from wishlist
// @Description Remove a product from the user's wishlist
// @Tags Users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param productId path string true "Product ID to remove"
// @Success 200 {object} map[string]interface{} "Product removed from wishlist successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /users/wishlist/{productId} [delete]
func (h *UserHandler) RemoveFromWishlist(c *gin.Context) {
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "User not authenticated",
			"code":    "UNAUTHORIZED",
		})
		return
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	productID := c.Param("productId")
	if productID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Product ID is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	productObjectID, err := primitive.ObjectIDFromHex(productID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid product ID",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err = h.userService.RemoveFromWishlist(objectID, productObjectID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "WISHLIST_REMOVE_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Product removed from wishlist successfully",
	})
}

// Admin endpoints

// GetAllUsers gets all users (admin only)
// @Summary Get all users
// @Description Get all users in the system (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(20)
// @Success 200 {object} map[string]interface{} "Users retrieved successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 403 {object} map[string]interface{} "Admin access required"
// @Router /admin/users [get]
func (h *UserHandler) GetAllUsers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	users, total, err := h.userService.GetAllUsers(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to fetch users",
			"code":    "FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"users": users,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"totalPages": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// SearchUsers searches users (admin only)
// @Summary Search users
// @Description Search users by query string (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param q query string true "Search query"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(20)
// @Success 200 {object} map[string]interface{} "Users found successfully"
// @Failure 400 {object} map[string]interface{} "Search query is required"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 403 {object} map[string]interface{} "Admin access required"
// @Router /admin/users/search [get]
func (h *UserHandler) SearchUsers(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Search query is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	users, total, err := h.userService.SearchUsers(query, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to search users",
			"code":    "SEARCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"users": users,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"totalPages": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// GetUserByID gets a single user by ID (admin only)
// @Summary Get user by ID
// @Description Get a specific user by ID (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID"
// @Success 200 {object} map[string]interface{} "User retrieved successfully"
// @Failure 400 {object} map[string]interface{} "Invalid user ID"
// @Failure 404 {object} map[string]interface{} "User not found"
// @Router /admin/users/{id} [get]
func (h *UserHandler) GetUserByID(c *gin.Context) {
    id := c.Param("id")
    objectID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error":   "Invalid user ID",
            "code":    "INVALID_INPUT",
        })
        return
    }

    user, err := h.userService.GetProfile(objectID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "success": false,
            "error":   "User not found",
            "code":    "NOT_FOUND",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data":    user,
    })
}

// ActivateUser activates a user (admin only)
// @Summary Activate user
// @Description Activate a user account (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID"
// @Success 200 {object} map[string]interface{} "User activated successfully"
// @Failure 400 {object} map[string]interface{} "Invalid user ID"
// @Failure 500 {object} map[string]interface{} "Failed to activate user"
// @Router /admin/users/{id}/activate [post]
func (h *UserHandler) ActivateUser(c *gin.Context) {
    id := c.Param("id")
    objectID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error":   "Invalid user ID",
            "code":    "INVALID_INPUT",
        })
        return
    }

    if err := h.userService.ActivateUser(objectID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error":   "Failed to activate user",
            "code":    "ACTIVATE_FAILED",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "message": "User activated successfully",
    })
}

// DeactivateUser deactivates a user (admin only)
// @Summary Deactivate user
// @Description Deactivate a user account (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID"
// @Success 200 {object} map[string]interface{} "User deactivated successfully"
// @Failure 400 {object} map[string]interface{} "Invalid user ID"
// @Failure 500 {object} map[string]interface{} "Failed to deactivate user"
// @Router /admin/users/{id}/deactivate [post]
func (h *UserHandler) DeactivateUser(c *gin.Context) {
    id := c.Param("id")
    objectID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error":   "Invalid user ID",
            "code":    "INVALID_INPUT",
        })
        return
    }

    if err := h.userService.DeactivateUser(objectID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error":   "Failed to deactivate user",
            "code":    "DEACTIVATE_FAILED",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "message": "User deactivated successfully",
    })
}

// MakeUserAdmin grants admin privileges to a user (admin only)
// @Summary Grant admin
// @Description Grant admin privileges to a user (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID"
// @Success 200 {object} map[string]interface{} "User promoted to admin successfully"
// @Failure 400 {object} map[string]interface{} "Invalid user ID"
// @Failure 500 {object} map[string]interface{} "Failed to promote user"
// @Router /admin/users/{id}/make-admin [post]
func (h *UserHandler) MakeUserAdmin(c *gin.Context) {
    id := c.Param("id")
    objectID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error":   "Invalid user ID",
            "code":    "INVALID_INPUT",
        })
        return
    }

    if err := h.userService.MakeAdmin(objectID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error":   "Failed to promote user to admin",
            "code":    "PROMOTE_FAILED",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "message": "User promoted to admin successfully",
    })
}

// RemoveUserAdmin revokes admin privileges from a user (admin only)
// @Summary Revoke admin
// @Description Revoke admin privileges from a user (Admin only)
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID"
// @Success 200 {object} map[string]interface{} "Admin privileges revoked successfully"
// @Failure 400 {object} map[string]interface{} "Invalid user ID"
// @Failure 500 {object} map[string]interface{} "Failed to revoke admin"
// @Router /admin/users/{id}/remove-admin [post]
func (h *UserHandler) RemoveUserAdmin(c *gin.Context) {
    id := c.Param("id")
    objectID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error":   "Invalid user ID",
            "code":    "INVALID_INPUT",
        })
        return
    }

    if err := h.userService.RemoveAdmin(objectID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error":   "Failed to revoke admin privileges",
            "code":    "REVOKE_FAILED",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "message": "Admin privileges revoked successfully",
    })
}
