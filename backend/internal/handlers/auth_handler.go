package handlers

import (
	"net/http"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService services.AuthService
	userService services.UserService
}

func NewAuthHandler(authService services.AuthService, userService services.UserService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		userService: userService,
	}
}

// Register handles user registration
// @Summary Register a new user
// @Description Register a new user with email, name, phone, and password
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body models.CreateUserRequest true "User registration data"
// @Success 201 {object} map[string]interface{} "User registered successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 409 {object} map[string]interface{} "User already exists"
// @Router /auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req models.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request data",
			"code":    "INVALID_INPUT",
		})
		return
	}

	// Additional required field validation
	if req.Name == "" || req.Email == "" || req.Phone == "" || req.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "All fields are required",
			"code":    "VALIDATION_ERROR",
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

	// Register user
	response, err := h.authService.Register(&req)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "REGISTRATION_FAILED",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    response,
		"message": "User registered successfully",
	})
}

// Login handles user login
// @Summary Login user
// @Description Login user with email and password
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body models.LoginRequest true "Login credentials"
// @Success 200 {object} map[string]interface{} "Login successful"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Invalid credentials"
// @Router /auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
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

	// Login user
	response, err := h.authService.Login(&req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "LOGIN_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
		"message": "Login successful",
	})
}

// Logout handles user logout
// @Summary Logout user
// @Description Logout the authenticated user
// @Tags Authentication
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "Logout successful"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /auth/logout [post]
func (h *AuthHandler) Logout(c *gin.Context) {
	// In a stateless JWT system, logout is handled client-side by removing the token
	// However, you could implement a token blacklist here for additional security
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Logout successful",
	})
}

// RefreshToken handles token refresh
// @Summary Refresh token
// @Description Refresh the access token using refresh token
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body object true "Refresh token request"
// @Success 200 {object} map[string]interface{} "Token refreshed successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 401 {object} map[string]interface{} "Invalid refresh token"
// @Router /auth/refresh [post]
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refreshToken" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Refresh token is required",
			"code":    "INVALID_INPUT",
		})
		return
	}

	// Refresh token
	response, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "INVALID_REFRESH_TOKEN",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
		"message": "Token refreshed successfully",
	})
}

// ForgotPassword handles forgot password request
// @Summary Forgot password
// @Description Send password reset email to user
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body models.ForgotPasswordRequest true "Forgot password request"
// @Success 200 {object} map[string]interface{} "Password reset email sent successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data"
// @Failure 500 {object} map[string]interface{} "Failed to send email"
// @Router /auth/forgot-password [post]
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	var req models.ForgotPasswordRequest
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

	// Send reset email
	err := h.authService.ForgotPassword(req.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to send reset email",
			"code":    "EMAIL_SEND_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Password reset email sent successfully",
	})
}

// ResetPassword handles password reset
// @Summary Reset password
// @Description Reset user password using reset token
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body models.ResetPasswordRequest true "Reset password request"
// @Success 200 {object} map[string]interface{} "Password reset successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request data or token"
// @Router /auth/reset-password [post]
func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req models.ResetPasswordRequest
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

	// Reset password
	err := h.authService.ResetPassword(&req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
			"code":    "PASSWORD_RESET_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Password reset successfully",
	})
}
