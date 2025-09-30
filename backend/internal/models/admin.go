package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UserStatistics represents user statistics for admin dashboard
type UserStatistics struct {
	TotalUsers          int64                    `json:"totalUsers"`
	ActiveUsers         int64                    `json:"activeUsers"`
	NewUsersToday       int64                    `json:"newUsersToday"`
	NewUsersThisMonth   int64                    `json:"newUsersThisMonth"`
	UserGrowthRate      float64                  `json:"userGrowthRate"`
	UsersByTier         map[string]int64         `json:"usersByTier"`
	UserRegistrations   []DailyRegistration      `json:"userRegistrations"`
	AverageOrderValue   float64                  `json:"averageOrderValue"`
	TopSpendingUsers    []TopUser                `json:"topSpendingUsers"`
}

// ProductStatistics represents product statistics for admin dashboard
type ProductStatistics struct {
	TotalProducts       int64                    `json:"totalProducts"`
	ProductsInStock     int64                    `json:"productsInStock"`
	ProductsOutOfStock  int64                    `json:"productsOutOfStock"`
	FeaturedProducts    int64                    `json:"featuredProducts"`
	NewProductsToday    int64                    `json:"newProductsToday"`
	TopSellingProducts  []TopProduct             `json:"topSellingProducts"`
	CategoryDistribution map[string]int64        `json:"categoryDistribution"`
	LowStockProducts    []LowStockProduct        `json:"lowStockProducts"`
	AverageRating       float64                  `json:"averageRating"`
	TotalReviews        int64                    `json:"totalReviews"`
}

// OrderStatistics represents order statistics for admin dashboard
type OrderStatistics struct {
	TotalOrders         int64                    `json:"totalOrders"`
	PendingOrders       int64                    `json:"pendingOrders"`
	CompletedOrders     int64                    `json:"completedOrders"`
	CancelledOrders     int64                    `json:"cancelledOrders"`
	TodaysOrders        int64                    `json:"todaysOrders"`
	TodaysRevenue       float64                  `json:"todaysRevenue"`
	MonthlyRevenue      float64                  `json:"monthlyRevenue"`
	AverageOrderValue   float64                  `json:"averageOrderValue"`
	OrderGrowthRate     float64                  `json:"orderGrowthRate"`
	RevenueGrowthRate   float64                  `json:"revenueGrowthRate"`
	OrdersByStatus      map[string]int64         `json:"ordersByStatus"`
	RevenueByMonth      []MonthlyRevenue         `json:"revenueByMonth"`
	TopPaymentMethods   []PaymentMethodStats     `json:"topPaymentMethods"`
}

// LoyaltyStatistics represents loyalty program statistics
type LoyaltyStatistics struct {
	TotalMembers        int64                    `json:"totalMembers"`
	ActiveMembers       int64                    `json:"activeMembers"`
	TotalPointsIssued   int64                    `json:"totalPointsIssued"`
	TotalPointsRedeemed int64                    `json:"totalPointsRedeemed"`
	MembersByTier       map[string]int64         `json:"membersByTier"`
	AveragePointsBalance int                     `json:"averagePointsBalance"`
	PointsIssuedToday   int64                    `json:"pointsIssuedToday"`
	TopLoyaltyMembers   []TopLoyaltyMember       `json:"topLoyaltyMembers"`
	EngagementRate      float64                  `json:"engagementRate"`
}

// NotificationStatistics represents notification statistics
type NotificationStatistics struct {
	TotalSent           int64                    `json:"totalSent"`
	TotalDelivered      int64                    `json:"totalDelivered"`
	TotalOpened         int64                    `json:"totalOpened"`
	TotalClicked        int64                    `json:"totalClicked"`
	DeliveryRate        float64                  `json:"deliveryRate"`
	OpenRate            float64                  `json:"openRate"`
	ClickRate           float64                  `json:"clickRate"`
	NotificationsByType map[string]int64         `json:"notificationsByType"`
	CampaignPerformance []CampaignStats          `json:"campaignPerformance"`
}

// DailyRegistration represents daily user registrations
type DailyRegistration struct {
	Date  string `json:"date"`
	Count int64  `json:"count"`
}

// TopUser represents top spending user
type TopUser struct {
	UserID      primitive.ObjectID `json:"userId"`
	Name        string             `json:"name"`
	Email       string             `json:"email"`
	TotalSpent  float64            `json:"totalSpent"`
	OrderCount  int64              `json:"orderCount"`
	LoyaltyTier string             `json:"loyaltyTier"`
}

// TopProduct represents top selling product
type TopProduct struct {
	ProductID   primitive.ObjectID `json:"productId"`
	Name        string             `json:"name"`
	Category    string             `json:"category"`
	Price       float64            `json:"price"`
	SalesCount  int64              `json:"salesCount"`
	Revenue     float64            `json:"revenue"`
	Rating      float64            `json:"rating"`
}

// LowStockProduct represents product with low stock
type LowStockProduct struct {
	ProductID     primitive.ObjectID `json:"productId"`
	Name          string             `json:"name"`
	SKU           string             `json:"sku"`
	Category      string             `json:"category"`
	CurrentStock  int                `json:"currentStock"`
	MinimumStock  int                `json:"minimumStock"`
	Price         float64            `json:"price"`
}

// MonthlyRevenue represents monthly revenue data
type MonthlyRevenue struct {
	Month   string  `json:"month"`
	Revenue float64 `json:"revenue"`
	Orders  int64   `json:"orders"`
}

// PaymentMethodStats represents payment method statistics
type PaymentMethodStats struct {
	Method      string  `json:"method"`
	Count       int64   `json:"count"`
	Percentage  float64 `json:"percentage"`
	TotalAmount float64 `json:"totalAmount"`
}

// TopLoyaltyMember represents top loyalty program member
type TopLoyaltyMember struct {
	UserID         primitive.ObjectID `json:"userId"`
	Name           string             `json:"name"`
	Email          string             `json:"email"`
	TotalPoints    int                `json:"totalPoints"`
	CurrentPoints  int                `json:"currentPoints"`
	Tier           string             `json:"tier"`
	TotalSpent     float64            `json:"totalSpent"`
	JoinedAt       time.Time          `json:"joinedAt"`
}

// CampaignStats represents campaign performance statistics
type CampaignStats struct {
	CampaignID   primitive.ObjectID `json:"campaignId"`
	Name         string             `json:"name"`
	Type         string             `json:"type"`
	Sent         int64              `json:"sent"`
	Delivered    int64              `json:"delivered"`
	Opened       int64              `json:"opened"`
	Clicked      int64              `json:"clicked"`
	DeliveryRate float64            `json:"deliveryRate"`
	OpenRate     float64            `json:"openRate"`
	ClickRate    float64            `json:"clickRate"`
	CreatedAt    time.Time          `json:"createdAt"`
}

// BusinessConfig represents business configuration settings
type BusinessConfig struct {
	ID              primitive.ObjectID    `json:"id" bson:"_id,omitempty"`
	CompanyName     string                `json:"companyName" bson:"companyName"`
	CompanyEmail    string                `json:"companyEmail" bson:"companyEmail"`
	CompanyPhone    string                `json:"companyPhone" bson:"companyPhone"`
	CompanyAddress  string                `json:"companyAddress" bson:"companyAddress"`
	BusinessHours   string                `json:"businessHours" bson:"businessHours"`
	SupportEmail    string                `json:"supportEmail" bson:"supportEmail"`
	SupportPhone    string                `json:"supportPhone" bson:"supportPhone"`
	SocialLinks     map[string]string     `json:"socialLinks" bson:"socialLinks"`
	ShippingRates   map[string]float64    `json:"shippingRates" bson:"shippingRates"`
	TaxRates        map[string]float64    `json:"taxRates" bson:"taxRates"`
	CurrencyCode    string                `json:"currencyCode" bson:"currencyCode"`
	CurrencySymbol  string                `json:"currencySymbol" bson:"currencySymbol"`
	MaintenanceMode bool                  `json:"maintenanceMode" bson:"maintenanceMode"`
	CreatedAt       time.Time             `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time             `json:"updatedAt" bson:"updatedAt"`
}

// AuditLog represents system audit log entry
type AuditLog struct {
	ID          primitive.ObjectID     `json:"id" bson:"_id,omitempty"`
	UserID      *primitive.ObjectID    `json:"userId,omitempty" bson:"userId,omitempty"`
	Action      string                 `json:"action" bson:"action"`
	Resource    string                 `json:"resource" bson:"resource"`
	ResourceID  string                 `json:"resourceId" bson:"resourceId"`
	Description string                 `json:"description" bson:"description"`
	IPAddress   string                 `json:"ipAddress" bson:"ipAddress"`
	UserAgent   string                 `json:"userAgent" bson:"userAgent"`
	Metadata    map[string]interface{} `json:"metadata" bson:"metadata"`
	Timestamp   time.Time              `json:"timestamp" bson:"timestamp"`
}

// SystemMetrics represents system performance metrics
type SystemMetrics struct {
	ID               primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CPUUsage         float64            `json:"cpuUsage" bson:"cpuUsage"`
	MemoryUsage      float64            `json:"memoryUsage" bson:"memoryUsage"`
	DiskUsage        float64            `json:"diskUsage" bson:"diskUsage"`
	ActiveConnections int64             `json:"activeConnections" bson:"activeConnections"`
	ResponseTime     float64            `json:"responseTime" bson:"responseTime"`
	ErrorRate        float64            `json:"errorRate" bson:"errorRate"`
	ThroughputRPS    float64            `json:"throughputRps" bson:"throughputRps"`
	DatabaseQueries  int64              `json:"databaseQueries" bson:"databaseQueries"`
	CacheHitRate     float64            `json:"cacheHitRate" bson:"cacheHitRate"`
	Timestamp        time.Time          `json:"timestamp" bson:"timestamp"`
}

// AdminRole represents admin role configuration
type AdminRole struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name        string             `json:"name" bson:"name"`
	Description string             `json:"description" bson:"description"`
	Permissions []Permission       `json:"permissions" bson:"permissions"`
	IsActive    bool               `json:"isActive" bson:"isActive"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// Permission represents a specific permission
type Permission struct {
	Resource string   `json:"resource" bson:"resource"` // "products", "orders", "users", etc.
	Actions  []string `json:"actions" bson:"actions"`   // "create", "read", "update", "delete"
}

// AdminUser represents an admin user
type AdminUser struct {
	ID          primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	UserID      primitive.ObjectID   `json:"userId" bson:"userId"`
	RoleIDs     []primitive.ObjectID `json:"roleIds" bson:"roleIds"`
	Permissions []Permission         `json:"permissions" bson:"permissions"`
	IsActive    bool                 `json:"isActive" bson:"isActive"`
	CreatedBy   primitive.ObjectID   `json:"createdBy" bson:"createdBy"`
	CreatedAt   time.Time            `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time            `json:"updatedAt" bson:"updatedAt"`
}

// BackupConfig represents backup configuration
type BackupConfig struct {
	ID              primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	IsEnabled       bool               `json:"isEnabled" bson:"isEnabled"`
	Schedule        string             `json:"schedule" bson:"schedule"` // Cron expression
	RetentionDays   int                `json:"retentionDays" bson:"retentionDays"`
	BackupLocation  string             `json:"backupLocation" bson:"backupLocation"`
	IncludeUploads  bool               `json:"includeUploads" bson:"includeUploads"`
	EncryptBackups  bool               `json:"encryptBackups" bson:"encryptBackups"`
	NotifyOnFailure bool               `json:"notifyOnFailure" bson:"notifyOnFailure"`
	CreatedAt       time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// BackupRecord represents a backup record
type BackupRecord struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Type        string             `json:"type" bson:"type"` // "manual", "scheduled"
	Status      string             `json:"status" bson:"status"` // "in_progress", "completed", "failed"
	StartTime   time.Time          `json:"startTime" bson:"startTime"`
	EndTime     *time.Time         `json:"endTime,omitempty" bson:"endTime,omitempty"`
	Size        int64              `json:"size" bson:"size"`
	Location    string             `json:"location" bson:"location"`
	Checksum    string             `json:"checksum" bson:"checksum"`
	ErrorMsg    string             `json:"errorMsg,omitempty" bson:"errorMsg,omitempty"`
	CreatedBy   *primitive.ObjectID `json:"createdBy,omitempty" bson:"createdBy,omitempty"`
}

// FeatureFlag represents feature flag configuration
type FeatureFlag struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name        string             `json:"name" bson:"name"`
	Description string             `json:"description" bson:"description"`
	IsEnabled   bool               `json:"isEnabled" bson:"isEnabled"`
	Environment string             `json:"environment" bson:"environment"` // "development", "staging", "production"
	Conditions  map[string]interface{} `json:"conditions" bson:"conditions"`
	CreatedBy   primitive.ObjectID `json:"createdBy" bson:"createdBy"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// AdminNotification represents notifications for admin users
type AdminNotification struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Title       string             `json:"title" bson:"title"`
	Message     string             `json:"message" bson:"message"`
	Type        string             `json:"type" bson:"type"` // "info", "warning", "error", "success"
	Priority    string             `json:"priority" bson:"priority"` // "low", "medium", "high", "critical"
	IsRead      bool               `json:"isRead" bson:"isRead"`
	ActionURL   string             `json:"actionUrl,omitempty" bson:"actionUrl,omitempty"`
	Metadata    map[string]interface{} `json:"metadata" bson:"metadata"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	ReadAt      *time.Time         `json:"readAt,omitempty" bson:"readAt,omitempty"`
}

// Constants for admin operations
const (
	// Audit actions
	AuditActionCreate = "create"
	AuditActionRead   = "read"
	AuditActionUpdate = "update"
	AuditActionDelete = "delete"
	AuditActionLogin  = "login"
	AuditActionLogout = "logout"

	// Resources
	ResourceUser         = "user"
	ResourceProduct      = "product"
	ResourceOrder        = "order"
	ResourceVoucher      = "voucher"
	ResourceNotification = "notification"
	ResourceStorefront   = "storefront"
	ResourceLoyalty      = "loyalty"

	// Admin notification types
	NotificationTypeInfo     = "info"
	NotificationTypeWarning  = "warning"
	NotificationTypeError    = "error"
	NotificationTypeSuccess  = "success"

	// Admin notification priorities
	PriorityLow      = "low"
	PriorityMedium   = "medium"
	PriorityHigh     = "high"
	PriorityCritical = "critical"

	// Backup statuses
	BackupStatusInProgress = "in_progress"
	BackupStatusCompleted  = "completed"
	BackupStatusFailed     = "failed"

	// Permission actions
	PermissionCreate = "create"
	PermissionRead   = "read"
	PermissionUpdate = "update"
	PermissionDelete = "delete"
	PermissionManage = "manage"
)

// GetDefaultBusinessConfig returns default business configuration
func GetDefaultBusinessConfig() *BusinessConfig {
	return &BusinessConfig{
		CompanyName:     "Thyne Jewels",
		CompanyEmail:    "info@thynejewels.com",
		CompanyPhone:    "+91-22-12345678",
		CompanyAddress:  "123 Jewelry Street, Mumbai, Maharashtra 400001, India",
		BusinessHours:   "Mon-Sat: 10:00 AM - 8:00 PM, Sun: 12:00 PM - 6:00 PM",
		SupportEmail:    "support@thynejewels.com",
		SupportPhone:    "+91-22-87654321",
		SocialLinks: map[string]string{
			"facebook":  "https://facebook.com/thynejewels",
			"instagram": "https://instagram.com/thynejewels",
			"twitter":   "https://twitter.com/thynejewels",
			"youtube":   "https://youtube.com/thynejewels",
		},
		ShippingRates: map[string]float64{
			"standard": 99.0,
			"express":  199.0,
			"premium":  299.0,
		},
		TaxRates: map[string]float64{
			"gst": 18.0,
		},
		CurrencyCode:    "INR",
		CurrencySymbol:  "₹",
		MaintenanceMode: false,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}
}

// DashboardStats represents dashboard statistics
type DashboardStats struct {
	TotalUsers         int64   `json:"totalUsers"`
	NewUsers           int64   `json:"newUsers"`
	TotalOrders        int64   `json:"totalOrders"`
	PendingOrders      int64   `json:"pendingOrders"`
	TotalRevenue       float64 `json:"totalRevenue"`
	MonthlyRevenue     float64 `json:"monthlyRevenue"`
	TotalProducts      int64   `json:"totalProducts"`
	LowStockProducts   int64   `json:"lowStockProducts"`
	PendingReviews     int64   `json:"pendingReviews"`
}

// AdminActivity represents recent admin activity
type AdminActivity struct {
	Type        string    `json:"type"`
	Description string    `json:"description"`
	Timestamp   time.Time `json:"timestamp"`
	EntityID    string    `json:"entityId"`
}

// ProductSales represents product sales data
type ProductSales struct {
	ProductID   primitive.ObjectID `json:"productId"`
	ProductName string             `json:"productName"`
	ImageUrl    []string           `json:"imageUrl"`
	TotalSold   int64              `json:"totalSold"`
	TotalValue  float64            `json:"totalValue"`
}

// UserGrowthData represents user growth over time
type UserGrowthData struct {
	Date  string `json:"_id" bson:"_id"`
	Count int64  `json:"count" bson:"count"`
}

// RevenueGrowthData represents revenue growth over time
type RevenueGrowthData struct {
	Date    string  `json:"_id" bson:"_id"`
	Revenue float64 `json:"revenue" bson:"revenue"`
}

// SystemHealth represents system health metrics
type SystemHealth struct {
	DatabaseStatus        string `json:"databaseStatus"`
	ActiveUsers          int64  `json:"activeUsers"`
	PendingNotifications int64  `json:"pendingNotifications"`
	ErrorRate            float64 `json:"errorRate"`
	SystemUptime         string  `json:"systemUptime"`
}

// GetDefaultAdminRoles returns default admin roles
func GetDefaultAdminRoles() []AdminRole {
	return []AdminRole{
		{
			Name:        "Super Admin",
			Description: "Full access to all features and settings",
			Permissions: []Permission{
				{Resource: "*", Actions: []string{"*"}},
			},
			IsActive:  true,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
		{
			Name:        "Admin",
			Description: "Access to most features with some restrictions",
			Permissions: []Permission{
				{Resource: "users", Actions: []string{"read", "update"}},
				{Resource: "products", Actions: []string{"create", "read", "update", "delete"}},
				{Resource: "orders", Actions: []string{"read", "update"}},
				{Resource: "vouchers", Actions: []string{"create", "read", "update", "delete"}},
				{Resource: "notifications", Actions: []string{"create", "read", "update"}},
				{Resource: "storefront", Actions: []string{"read", "update"}},
				{Resource: "loyalty", Actions: []string{"read", "update"}},
			},
			IsActive:  true,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
		{
			Name:        "Manager",
			Description: "Limited access for operational management",
			Permissions: []Permission{
				{Resource: "users", Actions: []string{"read"}},
				{Resource: "products", Actions: []string{"read", "update"}},
				{Resource: "orders", Actions: []string{"read", "update"}},
				{Resource: "vouchers", Actions: []string{"read"}},
				{Resource: "notifications", Actions: []string{"read"}},
				{Resource: "storefront", Actions: []string{"read"}},
				{Resource: "loyalty", Actions: []string{"read"}},
			},
			IsActive:  true,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
		{
			Name:        "Support",
			Description: "Customer support access",
			Permissions: []Permission{
				{Resource: "users", Actions: []string{"read"}},
				{Resource: "orders", Actions: []string{"read", "update"}},
				{Resource: "notifications", Actions: []string{"read"}},
				{Resource: "loyalty", Actions: []string{"read"}},
			},
			IsActive:  true,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
	}
}