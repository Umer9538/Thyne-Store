package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"thyne-jewels-backend/internal/config"
	"thyne-jewels-backend/internal/database"
	"thyne-jewels-backend/internal/handlers"
	"thyne-jewels-backend/internal/middleware"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

func main() {
	fmt.Println("🚀 Starting Test Server for Authentication Verification")
	fmt.Println(strings.Repeat("=", 60))

	// Create test configuration
	cfg := &config.Config{
		Server: config.ServerConfig{
			Port: "8080",
			Host: "localhost",
		},
		Database: config.DatabaseConfig{
			URI:      "mongodb://localhost:27017",
			Name:     "thyne_jewels_test",
			Username: "",
			Password: "",
		},
		JWT: config.JWTConfig{
			Secret: "test-secret-key-for-testing-purposes-only",
		},
	}

	// Initialize Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(gin.Logger(), gin.Recovery())

	// Add CORS middleware
	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Guest-Session-ID")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		
		c.Next()
	})

	// Initialize database (mock for testing)
	db := &database.MockDatabase{}

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	productRepo := repository.NewProductRepository(db)
	cartRepo := repository.NewCartRepository(db)
	orderRepo := repository.NewOrderRepository(db)
	guestRepo := repository.NewGuestSessionRepository(db)
	reviewRepo := repository.NewReviewRepository(db)
	couponRepo := repository.NewCouponRepository(db)

	// Initialize services
	authService := services.NewAuthService(userRepo, cfg.JWT, 12)
	userService := services.NewUserService(userRepo)
	productService := services.NewProductService(productRepo, reviewRepo)
	cartService := services.NewCartService(cartRepo, productRepo, couponRepo)
	orderService := services.NewOrderService(orderRepo, productRepo, cartRepo)
	guestService := services.NewGuestSessionService(guestRepo, cartRepo)
	paymentService := services.NewPaymentService(cfg.Payment)
	reviewService := services.NewReviewService(reviewRepo)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService, userService)
	userHandler := handlers.NewUserHandler(userService)
	productHandler := handlers.NewProductHandler(productService)
	cartHandler := handlers.NewCartHandler(cartService, authService, guestService)
	orderHandler := handlers.NewOrderHandler(orderService, paymentService, authService, guestService)
	guestHandler := handlers.NewGuestHandler(guestService)
	reviewHandler := handlers.NewReviewHandler(reviewService, authService)

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "thyne-jewels-backend",
			"version": "1.0.0",
		})
	})

	// API routes
	api := router.Group("/api/v1")
	{
		// Authentication routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/logout", middleware.AuthRequired(authService), authHandler.Logout)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/forgot-password", authHandler.ForgotPassword)
			auth.POST("/reset-password", authHandler.ResetPassword)
		}

		// User routes
		users := api.Group("/users")
		users.Use(middleware.AuthRequired(authService))
		{
			users.GET("/profile", userHandler.GetProfile)
			users.PUT("/profile", userHandler.UpdateProfile)
			users.POST("/addresses", userHandler.AddAddress)
			users.PUT("/addresses/:id", userHandler.UpdateAddress)
			users.DELETE("/addresses/:id", userHandler.DeleteAddress)
			users.POST("/change-password", userHandler.ChangePassword)
			users.GET("/wishlist", userHandler.GetWishlist)
			users.POST("/wishlist", userHandler.AddToWishlist)
			users.DELETE("/wishlist/:productId", userHandler.RemoveFromWishlist)
		}

		// Guest routes
		guest := api.Group("/guest")
		{
			guest.POST("/session", guestHandler.CreateSession)
			guest.GET("/session/:id", guestHandler.GetSession)
			guest.PUT("/session/:id", guestHandler.UpdateSession)
			guest.DELETE("/session/:id", guestHandler.DeleteSession)
		}
	}

	// Start server
	fmt.Printf("🌐 Starting server on http://%s:%s\n", cfg.Server.Host, cfg.Server.Port)
	fmt.Println("📋 Available endpoints:")
	fmt.Println("   GET  /health")
	fmt.Println("   POST /api/v1/auth/register")
	fmt.Println("   POST /api/v1/auth/login")
	fmt.Println("   POST /api/v1/auth/logout")
	fmt.Println("   POST /api/v1/auth/forgot-password")
	fmt.Println("   POST /api/v1/auth/reset-password")
	fmt.Println("   GET  /api/v1/users/profile")
	fmt.Println("   PUT  /api/v1/users/profile")
	fmt.Println("   POST /api/v1/users/change-password")
	fmt.Println(strings.Repeat("=", 60))

	// Run server
	if err := router.Run(":" + cfg.Server.Port); err != nil {
		fmt.Printf("❌ Failed to start server: %v\n", err)
	}
}


