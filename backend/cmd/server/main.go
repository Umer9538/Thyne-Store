package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"thyne-jewels-backend/internal/config"
	"thyne-jewels-backend/internal/database"
	"thyne-jewels-backend/internal/handlers"
	"thyne-jewels-backend/internal/middleware"
    "thyne-jewels-backend/internal/repository"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	_ "thyne-jewels-backend/docs" // This will be generated
)

// @title Thyne Jewels API
// @version 1.0
// @description API documentation for Thyne Jewels e-commerce platform
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@swagger.io

// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html

// @host localhost:8080
// @BasePath /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.

func main() {
	// Load configuration
	cfg := config.Load()

	// Set Gin mode
	gin.SetMode(cfg.Server.Mode)

	// Initialize database
	db, err := database.Connect(cfg.Database.URI, cfg.Database.Name)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer func() {
		if err := database.Disconnect(); err != nil {
			log.Printf("Error disconnecting from database: %v", err)
		}
	}()

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
    productRepo := repository.NewProductRepository(db)
    categoryRepo := repository.NewCategoryRepository(db)
    // storefrontRepo := mongo.NewStorefrontRepository(db)
	cartRepo := repository.NewCartRepository(db)
	orderRepo := repository.NewOrderRepository(db)
	guestRepo := repository.NewGuestSessionRepository(db)
	reviewRepo := repository.NewReviewRepository(db)
	couponRepo := repository.NewCouponRepository(db)
	wishlistRepo := repository.NewWishlistRepository(db)
    // loyaltyRepo := mongo.NewLoyaltyRepository(db)
    // notificationRepo := mongo.NewNotificationRepository(db)

	// Initialize services
	authService := services.NewAuthService(userRepo, cfg.JWT, 12) // bcrypt cost 12
	userService := services.NewUserService(userRepo)
	userService.SetWishlistRepository(wishlistRepo)
	productService := services.NewProductService(productRepo, reviewRepo)
	cartService := services.NewCartService(cartRepo, productRepo, couponRepo)
    var loyaltyService *services.LoyaltyService
	orderService := services.NewOrderService(orderRepo, productRepo, cartRepo)
	
	// Initialize notification service (without Firebase credentials for now)
    // notifications disabled for build-only profile
	
	// Set loyalty service on order service for purchase points integration
	if orderServiceImpl, ok := orderService.(interface{ SetLoyaltyService(*services.LoyaltyService) }); ok {
		orderServiceImpl.SetLoyaltyService(loyaltyService)
	}
	
    // Set notification service on other services (wishlist disabled in build-only profile)
	
    guestService := services.NewGuestSessionService(guestRepo, cartRepo)
	reviewService := services.NewReviewService(reviewRepo, productRepo, userRepo)
	paymentService := services.NewPaymentService(orderRepo, cfg.Razorpay)

    // Initialize handlers
	authHandler := handlers.NewAuthHandler(authService, userService)
	userHandler := handlers.NewUserHandler(userService, authService)
	productHandler := handlers.NewProductHandler(productService)
	cartHandler := handlers.NewCartHandler(cartService, authService)
	orderHandler := handlers.NewOrderHandler(orderService, paymentService, authService)
	guestHandler := handlers.NewGuestHandler(guestService)
	reviewHandler := handlers.NewReviewHandler(reviewService, authService)
    categoryService := services.NewCategoryService(categoryRepo)
    categoryHandler := handlers.NewCategoryHandler(categoryService)
    adminHandler := handlers.NewAdminHandler(userService, productService, orderService)
    
    // Initialize notification handler if service is available
    // var notificationHandler *handlers.NotificationHandler

	// Initialize Gin router
	router := gin.New()

	// Add middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	
	// CORS configuration
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowOrigins = cfg.Security.CORSAllowedOrigins
	corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	corsConfig.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"}
	corsConfig.AllowCredentials = true
	router.Use(cors.New(corsConfig))

	// Rate limiting middleware
	router.Use(middleware.RateLimit(cfg.Security.RateLimitPerMinute))

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now(),
			"version":   "1.0.0",
		})
	})

	// Swagger documentation endpoint
	router.GET("/docs", func(c *gin.Context) {
		c.Redirect(http.StatusMovedPermanently, "/docs/index.html")
	})
	router.GET("/docs/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

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

        // Product routes
		products := api.Group("/products")
		{
			products.GET("", productHandler.GetProducts)
			products.GET("/:id", productHandler.GetProduct)
			products.GET("/categories", productHandler.GetCategories)
			products.GET("/featured", productHandler.GetFeaturedProducts)
			products.GET("/search", productHandler.SearchProducts)
			products.GET("/:id/reviews", productHandler.GetProductReviews)
		}

        // Storefront routes disabled in build-only profile

		// Cart routes
		cart := api.Group("/cart")
		cart.Use(middleware.OptionalAuth(authService))
		{
			cart.GET("", cartHandler.GetCart)
			cart.POST("/add", cartHandler.AddToCart)
			cart.PUT("/update", cartHandler.UpdateCartItem)
			cart.DELETE("/remove/:productId", cartHandler.RemoveFromCart)
			cart.POST("/coupon", cartHandler.ApplyCoupon)
			cart.DELETE("/coupon", cartHandler.RemoveCoupon)
			cart.DELETE("/clear", cartHandler.ClearCart)
		}

		// Order routes
		orders := api.Group("/orders")
		orders.Use(middleware.OptionalAuth(authService))
		{
			orders.POST("", orderHandler.CreateOrder)
			orders.GET("", orderHandler.GetOrders)
			orders.GET("/:id", orderHandler.GetOrder)
			orders.DELETE("/:id", orderHandler.CancelOrder)
			orders.POST("/:id/return", orderHandler.ReturnOrder)
			orders.POST("/:id/refund", orderHandler.RefundOrder)
			orders.GET("/:id/track", orderHandler.TrackOrder)
		}

		// Review routes
		reviews := api.Group("/reviews")
		reviews.Use(middleware.AuthRequired(authService))
		{
			reviews.POST("", reviewHandler.CreateReview)
			reviews.PUT("/:id", reviewHandler.UpdateReview)
			reviews.DELETE("/:id", reviewHandler.DeleteReview)
		}

		// Guest routes
		guest := api.Group("/guest")
		{
			guest.POST("/session", guestHandler.CreateSession)
			guest.GET("/session/:id", guestHandler.GetSession)
			guest.PUT("/session/:id", guestHandler.UpdateSession)
			guest.DELETE("/session/:id", guestHandler.DeleteSession)
		}

		// Payment routes
		payment := api.Group("/payment")
		payment.Use(middleware.OptionalAuth(authService))
		{
			payment.POST("/create-order", orderHandler.CreatePaymentOrder)
			payment.POST("/verify", orderHandler.VerifyPayment)
			payment.POST("/webhook", orderHandler.HandleWebhook)
		}

        // Loyalty routes disabled in build-only profile

        // Notification routes disabled in build-only profile

        // Admin routes
		admin := api.Group("/admin")
		admin.Use(middleware.AuthRequired(authService))
		admin.Use(middleware.AdminRequired(authService))
		{
			// Dashboard
			admin.GET("/dashboard/stats", adminHandler.GetDashboardStats)
			admin.GET("/dashboard/activities", adminHandler.GetRecentActivities)
			admin.GET("/dashboard/users", adminHandler.GetUserStatistics)
			admin.GET("/dashboard/products", adminHandler.GetProductStatistics)

			// Product management
			admin.POST("/products", productHandler.CreateProduct)
			admin.PUT("/products/:id", productHandler.UpdateProduct)
			admin.DELETE("/products/:id", productHandler.DeleteProduct)
			admin.PUT("/products/:id/stock", productHandler.UpdateProductStock)

			// Category management
			admin.GET("/categories", categoryHandler.GetAllCategories)
			admin.POST("/categories", categoryHandler.CreateCategory)
			admin.PUT("/categories/:id", categoryHandler.UpdateCategory)
			admin.DELETE("/categories/:id", categoryHandler.DeleteCategory)

			// Order management
			admin.GET("/orders", adminHandler.GetAllOrders)
			admin.GET("/orders/:id", adminHandler.GetOrderDetails)
			admin.PUT("/orders/:id/status", adminHandler.UpdateOrderStatus)
			admin.GET("/orders/analytics", adminHandler.GetOrderAnalytics)

			// User management
			admin.GET("/users", userHandler.GetAllUsers)
			admin.GET("/users/search", userHandler.SearchUsers)
			admin.GET("/users/:id", userHandler.GetUserByID)
			admin.POST("/users/:id/activate", userHandler.ActivateUser)
			admin.POST("/users/:id/deactivate", userHandler.DeactivateUser)
			admin.POST("/users/:id/make-admin", userHandler.MakeUserAdmin)
			admin.POST("/users/:id/remove-admin", userHandler.RemoveUserAdmin)

			// System
			admin.GET("/system/health", adminHandler.GetSystemHealth)
			admin.GET("/audit-logs", adminHandler.GetAuditLogs)
			admin.POST("/export/orders", adminHandler.ExportOrders)
			
            // Storefront admin disabled in build-only profile
            
            // Admin notification endpoints disabled in build-only profile
			
			// Placeholder endpoints for future implementation
			admin.GET("/config/business", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "Business config not implemented"})
			})
			admin.PUT("/config/business", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "Business config update not implemented"})
			})
		}
	}

	// Start server
	server := &http.Server{
		Addr:    fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port),
		Handler: router,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on %s:%s", cfg.Server.Host, cfg.Server.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Start background jobs
	if cartService != nil {
		go startBackgroundJobs(cartService)
	}

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	// Give outstanding requests 30 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	log.Println("Server exited")
}

// startBackgroundJobs starts background tasks for the application
func startBackgroundJobs(cartService services.CartService) {
	ticker := time.NewTicker(24 * time.Hour) // Run once per day
	defer ticker.Stop()

	// Run immediately on startup
	if cartServiceImpl, ok := cartService.(interface{ ProcessAbandonedCarts() error }); ok {
		if err := cartServiceImpl.ProcessAbandonedCarts(); err != nil {
			log.Printf("Error processing abandoned carts: %v", err)
		}
	}

	// Run on schedule
	for range ticker.C {
		if cartServiceImpl, ok := cartService.(interface{ ProcessAbandonedCarts() error }); ok {
			if err := cartServiceImpl.ProcessAbandonedCarts(); err != nil {
				log.Printf("Error processing abandoned carts: %v", err)
			}
		}
	}
}
