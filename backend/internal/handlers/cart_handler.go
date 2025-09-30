package handlers

import (
	"net/http"

	"thyne-jewels-backend/internal/middleware"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

type CartHandler struct {
	cartService services.CartService
	authService services.AuthService
}

func NewCartHandler(cartService services.CartService, authService services.AuthService) *CartHandler {
	return &CartHandler{
		cartService: cartService,
		authService: authService,
	}
}

// GetCart gets the user's cart
// @Summary Get cart
// @Description Get the user's shopping cart (authenticated or guest)
// @Tags Cart
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Success 200 {object} map[string]interface{} "Cart retrieved successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /cart [get]
func (h *CartHandler) GetCart(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	cart, err := h.cartService.GetCart(userID, guestSessionID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Cart not found",
			"code":    "NOT_FOUND",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    cart,
	})
}

// AddToCart adds an item to the cart
// @Summary Add item to cart
// @Description Add a product to the shopping cart
// @Tags Cart
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body object true "Add to cart request"
// @Success 200 {object} map[string]interface{} "Item added to cart successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /cart/add [post]
func (h *CartHandler) AddToCart(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	var req struct {
		ProductID string `json:"productId" binding:"required"`
		Quantity  int    `json:"quantity" binding:"required,min=1"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.cartService.AddToCart(userID, guestSessionID, req.ProductID, req.Quantity)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "ADD_TO_CART_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Item added to cart successfully",
	})
}

// UpdateCartItem updates cart item quantity
// @Summary Update cart item
// @Description Update quantity of an item in the cart
// @Tags Cart
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body object true "Update cart item request"
// @Success 200 {object} map[string]interface{} "Cart item updated successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /cart/update [put]
func (h *CartHandler) UpdateCartItem(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	var req struct {
		ProductID string `json:"productId" binding:"required"`
		Quantity  int    `json:"quantity" binding:"required,min=0"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.cartService.UpdateCartItem(userID, guestSessionID, req.ProductID, req.Quantity)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "UPDATE_CART_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Cart updated successfully",
	})
}

// RemoveFromCart removes an item from the cart
// @Summary Remove item from cart
// @Description Remove a product from the shopping cart
// @Tags Cart
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param productId path string true "Product ID to remove"
// @Success 200 {object} map[string]interface{} "Item removed from cart successfully"
// @Failure 400 {object} map[string]interface{} "Invalid product ID"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /cart/remove/{productId} [delete]
func (h *CartHandler) RemoveFromCart(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")
	productID := c.Param("productId")

	err := h.cartService.RemoveFromCart(userID, guestSessionID, productID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "REMOVE_FROM_CART_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Item removed from cart successfully",
	})
}

// ApplyCoupon applies a coupon code to the cart
// @Summary Apply coupon
// @Description Apply a coupon code to the cart
// @Tags Cart
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Param request body object true "Apply coupon request"
// @Success 200 {object} map[string]interface{} "Coupon applied successfully"
// @Failure 400 {object} map[string]interface{} "Invalid coupon code"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /cart/coupon [post]
func (h *CartHandler) ApplyCoupon(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	var req struct {
		CouponCode string `json:"couponCode" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	err := h.cartService.ApplyCoupon(userID, guestSessionID, req.CouponCode)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "COUPON_APPLICATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Coupon applied successfully",
	})
}

// RemoveCoupon removes the applied coupon from the cart
// @Summary Remove coupon
// @Description Remove applied coupon from the cart
// @Tags Cart
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Success 200 {object} map[string]interface{} "Coupon removed successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /cart/coupon [delete]
func (h *CartHandler) RemoveCoupon(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	err := h.cartService.RemoveCoupon(userID, guestSessionID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "COUPON_REMOVAL_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Coupon removed successfully",
	})
}

// ClearCart clears all items from the cart
// @Summary Clear cart
// @Description Remove all items from the shopping cart
// @Tags Cart
// @Accept json
// @Produce json
// @Param X-Guest-Session-ID header string false "Guest session ID for guest users"
// @Success 200 {object} map[string]interface{} "Cart cleared successfully"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /cart/clear [delete]
func (h *CartHandler) ClearCart(c *gin.Context) {
	userID, _ := middleware.GetUserIDFromContext(c)
	guestSessionID := c.GetHeader("X-Guest-Session-ID")

	err := h.cartService.ClearCart(userID, guestSessionID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "CLEAR_CART_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Cart cleared successfully",
	})
}
