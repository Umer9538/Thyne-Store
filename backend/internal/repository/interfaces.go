package repository

import (
	"context"
	"time"

	"thyne-jewels-backend/internal/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UserRepository defines basic user data access methods
type UserRepository interface {
	Create(ctx context.Context, user *models.User) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.User, error)
	GetByEmail(ctx context.Context, email string) (*models.User, error)
	GetByPhone(ctx context.Context, phone string) (*models.User, error)
	Update(ctx context.Context, user *models.User) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	UpdatePassword(ctx context.Context, id primitive.ObjectID, hashedPassword string) error
	UpdateProfile(ctx context.Context, id primitive.ObjectID, updates *models.UpdateProfileRequest) error
	AddAddress(ctx context.Context, userID primitive.ObjectID, address models.Address) error
	UpdateAddress(ctx context.Context, userID primitive.ObjectID, addressID primitive.ObjectID, address models.Address) error
	DeleteAddress(ctx context.Context, userID primitive.ObjectID, addressID primitive.ObjectID) error
	SetDefaultAddress(ctx context.Context, userID primitive.ObjectID, addressID primitive.ObjectID) error
	GetAll(ctx context.Context, page, limit int) ([]models.User, int64, error)
	Search(ctx context.Context, query string, page, limit int) ([]models.User, int64, error)
}

// ProductRepository defines basic product data access methods
type ProductRepository interface {
	Create(ctx context.Context, product *models.Product) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Product, error)
	GetAll(ctx context.Context, filter models.ProductFilter) ([]models.Product, int64, error)
	Update(ctx context.Context, product *models.Product) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	GetFeatured(ctx context.Context) ([]models.Product, error)
	GetCategories(ctx context.Context) ([]string, error)
	Search(ctx context.Context, query string) ([]models.Product, error)
}

// OrderRepository defines basic order data access methods
type OrderRepository interface {
	Create(ctx context.Context, order *models.Order) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Order, error)
	GetByOrderNumber(ctx context.Context, orderNumber string) (*models.Order, error)
	GetByUserID(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Order, int64, error)
	GetByGuestSessionID(ctx context.Context, sessionID string, page, limit int) ([]models.Order, int64, error)
    // GetAll lists orders for admin with optional status filter and pagination
    GetAll(ctx context.Context, page, limit int, status *models.OrderStatus) ([]models.Order, int64, error)
	Update(ctx context.Context, order *models.Order) error
	UpdateStatus(ctx context.Context, id primitive.ObjectID, status models.OrderStatus) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	ExportOrders(ctx context.Context, format string, startDate, endDate time.Time, filters map[string]interface{}) (string, error)
}

// ReviewRepository defines basic review data access methods
type ReviewRepository interface {
	Create(ctx context.Context, review *models.Review) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Review, error)
	GetByProductID(ctx context.Context, productID primitive.ObjectID, page, limit int) ([]models.Review, int64, error)
	GetByUserID(ctx context.Context, userID primitive.ObjectID) ([]models.Review, error)
	Update(ctx context.Context, review *models.Review) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	GetAverageRating(ctx context.Context, productID primitive.ObjectID) (float64, int64, error)
}

// CartRepository defines basic cart data access methods
type CartRepository interface {
	Create(ctx context.Context, cart *models.Cart) error
	GetByUserID(ctx context.Context, userID primitive.ObjectID) (*models.Cart, error)
	GetByGuestSessionID(ctx context.Context, sessionID string) (*models.Cart, error)
	Update(ctx context.Context, cart *models.Cart) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	ClearByUserID(ctx context.Context, userID primitive.ObjectID) error
	ClearByGuestSessionID(ctx context.Context, sessionID string) error
	GetAbandonedCarts(ctx context.Context, cutoffTime time.Time) ([]models.Cart, error)
}

// CouponRepository defines basic coupon data access methods
type CouponRepository interface {
	Create(ctx context.Context, coupon *models.Coupon) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Coupon, error)
	GetByCode(ctx context.Context, code string) (*models.Coupon, error)
	GetAll(ctx context.Context) ([]models.Coupon, error)
	Update(ctx context.Context, coupon *models.Coupon) error
	Delete(ctx context.Context, id primitive.ObjectID) error
}

// GuestSessionRepository defines basic guest session data access methods
type GuestSessionRepository interface {
	Create(ctx context.Context, session *models.GuestSession) error
	GetBySessionID(ctx context.Context, sessionID string) (*models.GuestSession, error)
	Update(ctx context.Context, session *models.GuestSession) error
	DeleteBySessionID(ctx context.Context, sessionID string) error
	DeleteExpired(ctx context.Context) error
}

// LoyaltyRepository defines loyalty program data access methods
type LoyaltyRepository interface {
	CreateProgram(ctx context.Context, program *models.LoyaltyProgram) error
	GetProgramByUserID(ctx context.Context, userID primitive.ObjectID) (*models.LoyaltyProgram, error)
	UpdateProgram(ctx context.Context, program *models.LoyaltyProgram) error
	AddTransaction(ctx context.Context, transaction *models.PointTransaction) error
	GetTransactionHistory(ctx context.Context, userID primitive.ObjectID, limit, offset int) ([]models.PointTransaction, error)
	GetConfig(ctx context.Context) (*models.LoyaltyConfig, error)
	UpdateConfig(ctx context.Context, config *models.LoyaltyConfig) error
	GetLoyaltyStatistics(ctx context.Context) (*models.LoyaltyStatistics, error)
	ExportLoyaltyData(ctx context.Context, format string, startDate, endDate time.Time) (string, error)
	GetTopLoyaltyMembers(ctx context.Context, limit int) ([]models.TopLoyaltyMember, error)
}

// NotificationRepository defines notification data access methods
type NotificationRepository interface {
	Create(ctx context.Context, notification *models.Notification) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Notification, error)
	Update(ctx context.Context, notification *models.Notification) error
	GetUserNotifications(ctx context.Context, userID primitive.ObjectID, limit, offset int, unreadOnly bool) ([]models.Notification, error)
	MarkAsRead(ctx context.Context, notificationID, userID primitive.ObjectID) error
	MarkAllAsRead(ctx context.Context, userID primitive.ObjectID) error
	GetUnreadCount(ctx context.Context, userID primitive.ObjectID) (int64, error)
	CreateFCMToken(ctx context.Context, token *models.FCMToken) error
	GetActiveFCMTokens(ctx context.Context, userID *primitive.ObjectID) ([]models.FCMToken, error)
	GetAllActiveFCMTokens(ctx context.Context) ([]models.FCMToken, error)
	UpdateFCMToken(ctx context.Context, token *models.FCMToken) error
	DeactivateFCMToken(ctx context.Context, tokenValue string) error
	CreateCampaign(ctx context.Context, campaign *models.NotificationCampaign) error
	GetCampaignByID(ctx context.Context, id primitive.ObjectID) (*models.NotificationCampaign, error)
	UpdateCampaign(ctx context.Context, campaign *models.NotificationCampaign) error
	GetCampaigns(ctx context.Context, page, limit int) ([]models.NotificationCampaign, int64, error)
	GetUserPreferences(ctx context.Context, userID primitive.ObjectID) (*models.NotificationPreference, error)
	CreateUserPreferences(ctx context.Context, preferences *models.NotificationPreference) error
	UpdateUserPreferences(ctx context.Context, preferences *models.NotificationPreference) error
	GetNotificationStatistics(ctx context.Context) (*models.NotificationAnalytics, error)
	CreateTemplate(ctx context.Context, template *models.NotificationTemplate) error
	GetTemplateByType(ctx context.Context, templateType models.NotificationType) (*models.NotificationTemplate, error)
}

// CategoryRepository defines category data access methods
type CategoryRepository interface {
	Create(ctx context.Context, category *models.Category) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Category, error)
	GetBySlug(ctx context.Context, slug string) (*models.Category, error)
	Update(ctx context.Context, category *models.Category) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	List(ctx context.Context, page, limit int) ([]models.Category, int64, error)
	GetActive(ctx context.Context) ([]models.Category, error)
	GetHierarchy(ctx context.Context) ([]models.Category, error)
	GetByParentID(ctx context.Context, parentID primitive.ObjectID) ([]models.Category, error)
}

// AddressRepository defines address data access methods
type AddressRepository interface {
	Create(ctx context.Context, address *models.Address) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Address, error)
	Update(ctx context.Context, address *models.Address) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	GetUserAddresses(ctx context.Context, userID primitive.ObjectID) ([]models.Address, error)
	SetDefault(ctx context.Context, userID, addressID primitive.ObjectID) error
	GetDefault(ctx context.Context, userID primitive.ObjectID) (*models.Address, error)
}

// AdminRepository defines admin-specific data access methods
type AdminRepository interface {
	GetDashboardStats(ctx context.Context) (*models.DashboardStats, error)
	GetRecentActivity(ctx context.Context, limit int) ([]models.AdminActivity, error)
	GetTopSellingProducts(ctx context.Context, limit int) ([]models.ProductSales, error)
	GetUserGrowth(ctx context.Context, days int) ([]models.UserGrowthData, error)
	GetRevenueGrowth(ctx context.Context, days int) ([]models.RevenueGrowthData, error)
	GetSystemHealth(ctx context.Context) (*models.SystemHealth, error)
	BulkUpdateProductStatus(ctx context.Context, productIDs []primitive.ObjectID, isActive bool) error
	BulkUpdateUserStatus(ctx context.Context, userIDs []primitive.ObjectID, isActive bool) error
	GetLoyaltyStatistics(ctx context.Context) (*models.LoyaltyStatistics, error)
	GetNotificationStatistics(ctx context.Context) (*models.NotificationStatistics, error)
}

// VoucherRepository defines voucher and rewards data access methods
type VoucherRepository interface {
	Create(ctx context.Context, voucher *models.Voucher) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Voucher, error)
	GetByCode(ctx context.Context, code string) (*models.Voucher, error)
	Update(ctx context.Context, voucher *models.Voucher) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	GetAvailable(ctx context.Context) ([]models.Voucher, error)
	GetRedemptionCount(ctx context.Context, voucherID primitive.ObjectID) (int, error)
	GetUserRedemptionCount(ctx context.Context, userID, voucherID primitive.ObjectID) (int, error)
	CreateUserVoucher(ctx context.Context, userVoucher *models.UserVoucher) error
	GetUserVouchers(ctx context.Context, userID primitive.ObjectID, onlyUnused bool) ([]models.UserVoucher, error)
	GetUserVoucherByCode(ctx context.Context, userID primitive.ObjectID, code string) (*models.UserVoucher, error)
	UpdateUserVoucher(ctx context.Context, userVoucher *models.UserVoucher) error
	CreateReward(ctx context.Context, reward *models.Reward) error
	GetRewardByID(ctx context.Context, id primitive.ObjectID) (*models.Reward, error)
	UpdateReward(ctx context.Context, reward *models.Reward) error
	GetUserRewards(ctx context.Context, userID primitive.ObjectID, status string) ([]models.Reward, error)
	GetAnalytics(ctx context.Context, startDate, endDate time.Time) (*models.VoucherAnalytics, error)
}

// PDFRepository defines PDF and tracking data access methods
type PDFRepository interface {
	Create(ctx context.Context, pdf *models.PDFDocument) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.PDFDocument, error)
	GetByOrderID(ctx context.Context, orderID primitive.ObjectID, pdfType string) (*models.PDFDocument, error)
	Update(ctx context.Context, pdf *models.PDFDocument) error
	GetByUserID(ctx context.Context, userID primitive.ObjectID, pdfType string) ([]models.PDFDocument, error)
	GetOrderTracking(ctx context.Context, orderID primitive.ObjectID) (*models.OrderTracking, error)
	CreateOrderTracking(ctx context.Context, tracking *models.OrderTracking) error
	UpdateOrderTracking(ctx context.Context, tracking *models.OrderTracking) error
	CreateWarranty(ctx context.Context, warranty *models.WarrantyInfo) error
	GetWarrantyByID(ctx context.Context, id primitive.ObjectID) (*models.WarrantyInfo, error)
	UpdateWarranty(ctx context.Context, warranty *models.WarrantyInfo) error
	GetTemplate(ctx context.Context, templateType string) (*models.PDFTemplate, error)
	CreateTemplate(ctx context.Context, template *models.PDFTemplate) error
	UpdateTemplate(ctx context.Context, template *models.PDFTemplate) error
}

// SearchRepository defines search data access methods
type SearchRepository interface {
	GetPopularSearches(ctx context.Context, category string, limit int) ([]models.PopularSearch, error)
	GetTrendingSearches(ctx context.Context, period string, limit int) ([]models.TrendingSearch, error)
	UpdatePopularSearch(ctx context.Context, query, category string) error
	RecordSearchAnalytics(ctx context.Context, analytics *models.SearchAnalytics) error
	GetSearchAnalytics(ctx context.Context, startDate, endDate time.Time) ([]models.SearchAnalytics, error)
	CreateSynonym(ctx context.Context, synonym *models.SearchSynonym) error
	GetSynonyms(ctx context.Context, term string) ([]string, error)
	UpdateSearchConfig(ctx context.Context, config *models.SearchConfig) error
	GetSearchConfig(ctx context.Context) (*models.SearchConfig, error)
	GetPersonalization(ctx context.Context, userID primitive.ObjectID) (*models.SearchPersonalization, error)
	UpdatePersonalization(ctx context.Context, personalization *models.SearchPersonalization) error
	RecordProductClick(ctx context.Context, query string, productID primitive.ObjectID, userID *primitive.ObjectID) error
	GetCategorySuggestions(ctx context.Context, query string, limit int) ([]models.CategorySuggestion, error)
	GetCategoryFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error)
	GetBrandFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error)
	GetMetalTypeFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error)
	GetGemstoneTypeFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error)
	GetPriceRangeFacets(ctx context.Context, baseMatch interface{}) ([]models.PriceRange, error)
	GetPurityFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error)
	GetTagFacets(ctx context.Context, baseMatch interface{}) ([]models.FacetItem, error)
	CacheResults(ctx context.Context, cache *models.SearchCache) error
	GetCachedResults(ctx context.Context, queryHash string) (*models.SearchCache, error)
	UpdateCacheHit(ctx context.Context, queryHash string) error
}

// StorefrontRepository defines storefront configuration data access methods
type StorefrontRepository interface {
	GetConfig(ctx context.Context) (*models.StorefrontConfig, error)
	CreateConfig(ctx context.Context, config *models.StorefrontConfig) error
	UpdateConfig(ctx context.Context, config *models.StorefrontConfig) error
	GetConfigHistory(ctx context.Context, limit int) ([]models.StorefrontConfig, error)
	GetConfigByVersion(ctx context.Context, version int) (*models.StorefrontConfig, error)
	CreatePopupBanner(ctx context.Context, banner *models.PopupBanner) error
	GetActivePopupBanners(ctx context.Context) ([]models.PopupBanner, error)
	UpdateMenuConfig(ctx context.Context, menuConfig *models.MenuConfig) error
	GetMenuConfig(ctx context.Context) (*models.MenuConfig, error)
	UpdateSEOConfig(ctx context.Context, seoConfig *models.SEOConfig) error
	GetSEOConfig(ctx context.Context) (*models.SEOConfig, error)
	RecordBannerClick(ctx context.Context, bannerID string) error
	RecordSectionView(ctx context.Context, sectionName string) error
	RecordFeatureUsage(ctx context.Context, feature string) error
	GetAnalytics(ctx context.Context, startDate, endDate time.Time) ([]models.StorefrontAnalytics, error)
	GetBusinessConfig(ctx context.Context) (*models.BusinessConfig, error)
	UpdateBusinessConfig(ctx context.Context, config *models.BusinessConfig) error
}

// WishlistRepository defines wishlist data access methods
type WishlistRepository interface {
	Create(ctx context.Context, wishlist *models.Wishlist) error
	GetByUserID(ctx context.Context, userID primitive.ObjectID) (*models.Wishlist, error)
	AddItem(ctx context.Context, userID, productID primitive.ObjectID) error
	RemoveItem(ctx context.Context, userID, productID primitive.ObjectID) error
	IsInWishlist(ctx context.Context, userID, productID primitive.ObjectID) (bool, error)
	GetWishlistItems(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Product, int64, error)
	GetWishlistItemsByProduct(ctx context.Context, productID primitive.ObjectID) ([]models.WishlistItem, error)
	ClearWishlist(ctx context.Context, userID primitive.ObjectID) error
}
