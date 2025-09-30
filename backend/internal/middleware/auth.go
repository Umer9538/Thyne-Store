package middleware

import (
	"net/http"
	"strings"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

// AuthRequired middleware requires authentication
func AuthRequired(authService services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := extractToken(c)
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Authorization token required",
				"code":    "UNAUTHORIZED",
			})
			c.Abort()
			return
		}

		user, err := authService.ValidateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Invalid or expired token",
				"code":    "UNAUTHORIZED",
			})
			c.Abort()
			return
		}

		// Set user in context
		c.Set("user", user)
		c.Set("userID", user.ID.Hex())
		c.Next()
	}
}

// OptionalAuth middleware allows optional authentication
func OptionalAuth(authService services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := extractToken(c)
		if token != "" {
			user, err := authService.ValidateToken(token)
			if err == nil {
				// Set user in context if token is valid
				c.Set("user", user)
				c.Set("userID", user.ID.Hex())
			}
		}

		// Continue regardless of authentication status
		c.Next()
	}
}

// extractToken extracts the JWT token from the Authorization header
func extractToken(c *gin.Context) string {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		return ""
	}

	// Check if the header starts with "Bearer "
	if !strings.HasPrefix(authHeader, "Bearer ") {
		return ""
	}

	// Extract the token part
	return strings.TrimPrefix(authHeader, "Bearer ")
}

// RequireGuestSession middleware requires a valid guest session
func RequireGuestSession(guestService services.GuestSessionService) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.GetHeader("X-Guest-Session-ID")
		if sessionID == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Guest session ID required",
				"code":    "GUEST_SESSION_REQUIRED",
			})
			c.Abort()
			return
		}

		session, err := guestService.GetSession(sessionID)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Invalid guest session",
				"code":    "INVALID_GUEST_SESSION",
			})
			c.Abort()
			return
		}

		if session.IsExpired() {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Guest session expired",
				"code":    "GUEST_SESSION_EXPIRED",
			})
			c.Abort()
			return
		}

		// Set session in context
		c.Set("guestSession", session)
		c.Set("guestSessionID", session.SessionID)
		c.Next()
	}
}

// OptionalGuestSession middleware allows optional guest session
func OptionalGuestSession(guestService services.GuestSessionService) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.GetHeader("X-Guest-Session-ID")
		if sessionID != "" {
			session, err := guestService.GetSession(sessionID)
			if err == nil && !session.IsExpired() {
				// Set session in context if valid
				c.Set("guestSession", session)
				c.Set("guestSessionID", session.SessionID)
			}
		}

		// Continue regardless of guest session status
		c.Next()
	}
}

// AdminRequired middleware requires admin privileges
func AdminRequired(authService services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userInterface, exists := c.Get("user")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Authentication required",
				"code":    "UNAUTHORIZED",
			})
			c.Abort()
			return
		}

		user := userInterface.(*models.User)
		if !user.IsAdmin {
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"error":   "Admin privileges required",
				"code":    "FORBIDDEN",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// GetUserFromContext extracts user from context
func GetUserFromContext(c *gin.Context) (*models.User, bool) {
	userInterface, exists := c.Get("user")
	if !exists {
		return nil, false
	}

	user, ok := userInterface.(*models.User)
	return user, ok
}

// GetUserIDFromContext extracts user ID from context
func GetUserIDFromContext(c *gin.Context) (string, bool) {
	userIDInterface, exists := c.Get("userID")
	if !exists {
		return "", false
	}

	userID, ok := userIDInterface.(string)
	return userID, ok
}

// GetGuestSessionFromContext extracts guest session from context
func GetGuestSessionFromContext(c *gin.Context) (*models.GuestSession, bool) {
	sessionInterface, exists := c.Get("guestSession")
	if !exists {
		return nil, false
	}

	session, ok := sessionInterface.(*models.GuestSession)
	return session, ok
}

// GetGuestSessionIDFromContext extracts guest session ID from context
func GetGuestSessionIDFromContext(c *gin.Context) (string, bool) {
	sessionIDInterface, exists := c.Get("guestSessionID")
	if !exists {
		return "", false
	}

	sessionID, ok := sessionIDInterface.(string)
	return sessionID, ok
}
