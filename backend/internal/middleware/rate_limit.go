package middleware

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// RateLimiter represents a rate limiter
type RateLimiter struct {
	requests map[string][]time.Time
	mutex    sync.RWMutex
	limit    int
	window   time.Duration
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	rl := &RateLimiter{
		requests: make(map[string][]time.Time),
		limit:    limit,
		window:   window,
	}

	// Cleanup old requests periodically
	go rl.cleanup()

	return rl
}

// IsAllowed checks if a request is allowed for the given key
func (rl *RateLimiter) IsAllowed(key string) bool {
	rl.mutex.Lock()
	defer rl.mutex.Unlock()

	now := time.Now()
	cutoff := now.Add(-rl.window)

	// Clean old requests for this key
	if requests, exists := rl.requests[key]; exists {
		var validRequests []time.Time
		for _, req := range requests {
			if req.After(cutoff) {
				validRequests = append(validRequests, req)
			}
		}
		rl.requests[key] = validRequests
	}

	// Check if under limit
	if len(rl.requests[key]) < rl.limit {
		rl.requests[key] = append(rl.requests[key], now)
		return true
	}

	return false
}

// cleanup removes old requests periodically
func (rl *RateLimiter) cleanup() {
	ticker := time.NewTicker(rl.window)
	defer ticker.Stop()

	for range ticker.C {
		rl.mutex.Lock()
		now := time.Now()
		cutoff := now.Add(-rl.window * 2) // Keep some buffer

		for key, requests := range rl.requests {
			var validRequests []time.Time
			for _, req := range requests {
				if req.After(cutoff) {
					validRequests = append(validRequests, req)
				}
			}
			if len(validRequests) == 0 {
				delete(rl.requests, key)
			} else {
				rl.requests[key] = validRequests
			}
		}
		rl.mutex.Unlock()
	}
}

// Global rate limiter instance
var globalRateLimiter *RateLimiter

// RateLimit middleware limits requests per minute
func RateLimit(requestsPerMinute int) gin.HandlerFunc {
	if globalRateLimiter == nil {
		globalRateLimiter = NewRateLimiter(requestsPerMinute, time.Minute)
	}

	return func(c *gin.Context) {
		// Get client IP
		clientIP := c.ClientIP()

		// Check if request is allowed
		if !globalRateLimiter.IsAllowed(clientIP) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"success": false,
				"error":   "Rate limit exceeded. Please try again later.",
				"code":    "RATE_LIMIT_EXCEEDED",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// UserRateLimit middleware limits requests per user per minute
func UserRateLimit(requestsPerMinute int) gin.HandlerFunc {
	rateLimiter := NewRateLimiter(requestsPerMinute, time.Minute)

	return func(c *gin.Context) {
		// Get user ID if authenticated, otherwise use IP
		var key string
		if userID, exists := GetUserIDFromContext(c); exists {
			key = "user:" + userID
		} else {
			key = "ip:" + c.ClientIP()
		}

		// Check if request is allowed
		if !rateLimiter.IsAllowed(key) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"success": false,
				"error":   "Rate limit exceeded. Please try again later.",
				"code":    "RATE_LIMIT_EXCEEDED",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// APIRateLimit middleware with different limits for different endpoints
func APIRateLimit() gin.HandlerFunc {
	// Different rate limits for different types of endpoints
	authLimiter := NewRateLimiter(10, time.Minute)    // 10 requests per minute for auth
	generalLimiter := NewRateLimiter(100, time.Minute) // 100 requests per minute for general API

	return func(c *gin.Context) {
		var rateLimiter *RateLimiter
		key := c.ClientIP()

		// Determine which rate limiter to use based on the endpoint
		path := c.Request.URL.Path
		if strings.Contains(path, "/auth/") {
			rateLimiter = authLimiter
			key = "auth:" + key
		} else {
			rateLimiter = generalLimiter
			key = "api:" + key
		}

		// Check if request is allowed
		if !rateLimiter.IsAllowed(key) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"success": false,
				"error":   "Rate limit exceeded. Please try again later.",
				"code":    "RATE_LIMIT_EXCEEDED",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
