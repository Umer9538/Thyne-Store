package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// StorefrontConfig represents the dynamic configuration of the storefront
type StorefrontConfig struct {
	ID                  primitive.ObjectID    `json:"id" bson:"_id,omitempty"`
	HomePage            HomePageConfig        `json:"homePage" bson:"homePage"`
	CategoryVisibility  []CategoryVisibility  `json:"categoryVisibility" bson:"categoryVisibility"`
	PromotionalBanners  PromotionalBanners    `json:"promotionalBanners" bson:"promotionalBanners"`
	ThemeConfig         ThemeConfig           `json:"themeConfig" bson:"themeConfig"`
	FeatureFlags        FeatureFlags          `json:"featureFlags" bson:"featureFlags"`
	LastUpdated         time.Time             `json:"lastUpdated" bson:"lastUpdated"`
	UpdatedBy           primitive.ObjectID    `json:"updatedBy" bson:"updatedBy"`
	Version             int                   `json:"version" bson:"version"`
}

// HomePageConfig represents homepage layout configuration
type HomePageConfig struct {
	HeroBanners          []HeroBanner      `json:"heroBanners" bson:"heroBanners"`
	Carousels            []CarouselSection `json:"carousels" bson:"carousels"`
	FeaturedProductIDs   []primitive.ObjectID `json:"featuredProductIds" bson:"featuredProductIds"`
	FeaturedCategoryIDs  []primitive.ObjectID `json:"featuredCategoryIds" bson:"featuredCategoryIds"`
	ShowNewArrivals      bool              `json:"showNewArrivals" bson:"showNewArrivals"`
	ShowBestSellers      bool              `json:"showBestSellers" bson:"showBestSellers"`
	ShowRecommended      bool              `json:"showRecommended" bson:"showRecommended"`
	ShowDeals            bool              `json:"showDeals" bson:"showDeals"`
	WelcomeMessage       *string           `json:"welcomeMessage,omitempty" bson:"welcomeMessage,omitempty"`
	AnnouncementBar      *string           `json:"announcementBar,omitempty" bson:"announcementBar,omitempty"`
}

// HeroBanner represents a hero banner on the homepage
type HeroBanner struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	ImageURL  string             `json:"imageUrl" bson:"imageUrl"`
	Title     *string            `json:"title,omitempty" bson:"title,omitempty"`
	Subtitle  *string            `json:"subtitle,omitempty" bson:"subtitle,omitempty"`
	CTAText   *string            `json:"ctaText,omitempty" bson:"ctaText,omitempty"`
	CTALink   *string            `json:"ctaLink,omitempty" bson:"ctaLink,omitempty"`
	Order     int                `json:"order" bson:"order"`
	IsActive  bool               `json:"isActive" bson:"isActive"`
	StartDate *time.Time         `json:"startDate,omitempty" bson:"startDate,omitempty"`
	EndDate   *time.Time         `json:"endDate,omitempty" bson:"endDate,omitempty"`
	CreatedAt time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// IsCurrentlyActive checks if banner is currently active
func (h *HeroBanner) IsCurrentlyActive() bool {
	if !h.IsActive {
		return false
	}

	now := time.Now()
	if h.StartDate != nil && now.Before(*h.StartDate) {
		return false
	}
	if h.EndDate != nil && now.After(*h.EndDate) {
		return false
	}

	return true
}

// CarouselSection represents a carousel section on the homepage
type CarouselSection struct {
	ID        primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	Title     string               `json:"title" bson:"title"`
	Type      CarouselType         `json:"type" bson:"type"`
	ItemIDs   []primitive.ObjectID `json:"itemIds" bson:"itemIds"`
	Order     int                  `json:"order" bson:"order"`
	IsVisible bool                 `json:"isVisible" bson:"isVisible"`
}

// CarouselType represents different types of carousels
type CarouselType string

const (
	CarouselProducts   CarouselType = "products"
	CarouselCategories CarouselType = "categories"
	CarouselBrands     CarouselType = "brands"
	CarouselCustom     CarouselType = "custom"
)

// CategoryVisibility represents visibility and ordering of categories
type CategoryVisibility struct {
	CategoryID string `json:"categoryId" bson:"categoryId"`
	IsVisible  bool   `json:"isVisible" bson:"isVisible"`
	Order      int    `json:"order" bson:"order"`
}

// PromotionalBanners represents promotional banner configuration
type PromotionalBanners struct {
	TopBanner      *string  `json:"topBanner,omitempty" bson:"topBanner,omitempty"`
	BottomBanner   *string  `json:"bottomBanner,omitempty" bson:"bottomBanner,omitempty"`
	PopupBanners   []string `json:"popupBanners" bson:"popupBanners"`
	ShowTopBanner  bool     `json:"showTopBanner" bson:"showTopBanner"`
	ShowBottomBanner bool   `json:"showBottomBanner" bson:"showBottomBanner"`
	ShowPopups     bool     `json:"showPopups" bson:"showPopups"`
}

// ThemeConfig represents theme customization
type ThemeConfig struct {
	PrimaryColor   string `json:"primaryColor" bson:"primaryColor"`
	SecondaryColor string `json:"secondaryColor" bson:"secondaryColor"`
	AccentColor    string `json:"accentColor" bson:"accentColor"`
	FontFamily     string `json:"fontFamily" bson:"fontFamily"`
	IsDarkMode     bool   `json:"isDarkMode" bson:"isDarkMode"`
}

// FeatureFlags represents toggleable features
type FeatureFlags struct {
	EnableLoyaltyProgram bool `json:"enableLoyaltyProgram" bson:"enableLoyaltyProgram"`
	EnableWishlist       bool `json:"enableWishlist" bson:"enableWishlist"`
	EnableReviews        bool `json:"enableReviews" bson:"enableReviews"`
	EnableChat           bool `json:"enableChat" bson:"enableChat"`
	EnableAR             bool `json:"enableAR" bson:"enableAR"`
	EnableSocialLogin    bool `json:"enableSocialLogin" bson:"enableSocialLogin"`
	EnableGuestCheckout  bool `json:"enableGuestCheckout" bson:"enableGuestCheckout"`
	EnableReferrals      bool `json:"enableReferrals" bson:"enableReferrals"`
}

// Default storefront configuration
func DefaultStorefrontConfig() *StorefrontConfig {
	return &StorefrontConfig{
		HomePage: HomePageConfig{
			HeroBanners:         []HeroBanner{},
			Carousels:          []CarouselSection{},
			FeaturedProductIDs: []primitive.ObjectID{},
			FeaturedCategoryIDs: []primitive.ObjectID{},
			ShowNewArrivals:    true,
			ShowBestSellers:    true,
			ShowRecommended:    true,
			ShowDeals:          true,
		},
		CategoryVisibility: []CategoryVisibility{
			{CategoryID: "rings", IsVisible: true, Order: 1},
			{CategoryID: "necklaces", IsVisible: true, Order: 2},
			{CategoryID: "bracelets", IsVisible: true, Order: 3},
			{CategoryID: "earrings", IsVisible: true, Order: 4},
		},
		PromotionalBanners: PromotionalBanners{
			PopupBanners:     []string{},
			ShowTopBanner:    false,
			ShowBottomBanner: false,
			ShowPopups:       false,
		},
		ThemeConfig: ThemeConfig{
			PrimaryColor:   "#FFD700",
			SecondaryColor: "#E5B7B7",
			AccentColor:    "#B76E79",
			FontFamily:     "Poppins",
			IsDarkMode:     false,
		},
		FeatureFlags: FeatureFlags{
			EnableLoyaltyProgram: true,
			EnableWishlist:       true,
			EnableReviews:        true,
			EnableChat:           false,
			EnableAR:             false,
			EnableSocialLogin:    false,
			EnableGuestCheckout:  true,
			EnableReferrals:      false,
		},
		LastUpdated: time.Now(),
		Version:     1,
	}
}

// PopupBanner represents a popup promotional banner
type PopupBanner struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Title       string             `json:"title" bson:"title"`
	Content     string             `json:"content" bson:"content"`
	ImageURL    *string            `json:"imageUrl,omitempty" bson:"imageUrl,omitempty"`
	CTAText     *string            `json:"ctaText,omitempty" bson:"ctaText,omitempty"`
	CTALink     *string            `json:"ctaLink,omitempty" bson:"ctaLink,omitempty"`
	TriggerType PopupTriggerType   `json:"triggerType" bson:"triggerType"`
	TriggerDelay int               `json:"triggerDelay" bson:"triggerDelay"` // seconds
	IsActive    bool               `json:"isActive" bson:"isActive"`
	StartDate   *time.Time         `json:"startDate,omitempty" bson:"startDate,omitempty"`
	EndDate     *time.Time         `json:"endDate,omitempty" bson:"endDate,omitempty"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// PopupTriggerType represents when to show popup
type PopupTriggerType string

const (
	PopupOnEntry    PopupTriggerType = "on_entry"
	PopupOnExit     PopupTriggerType = "on_exit"
	PopupOnScroll   PopupTriggerType = "on_scroll"
	PopupOnTime     PopupTriggerType = "on_time"
)

// MenuConfig represents navigation menu configuration
type MenuConfig struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	MenuItems    []MenuItem         `json:"menuItems" bson:"menuItems"`
	ShowSearch   bool               `json:"showSearch" bson:"showSearch"`
	ShowCart     bool               `json:"showCart" bson:"showCart"`
	ShowWishlist bool               `json:"showWishlist" bson:"showWishlist"`
	ShowProfile  bool               `json:"showProfile" bson:"showProfile"`
	UpdatedAt    time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// MenuItem represents a navigation menu item
type MenuItem struct {
	ID       string     `json:"id" bson:"id"`
	Label    string     `json:"label" bson:"label"`
	URL      string     `json:"url" bson:"url"`
	Icon     *string    `json:"icon,omitempty" bson:"icon,omitempty"`
	Order    int        `json:"order" bson:"order"`
	IsActive bool       `json:"isActive" bson:"isActive"`
	Children []MenuItem `json:"children,omitempty" bson:"children,omitempty"`
}

// SEOConfig represents SEO configuration
type SEOConfig struct {
	ID               primitive.ObjectID    `json:"id" bson:"_id,omitempty"`
	SiteName         string                `json:"siteName" bson:"siteName"`
	SiteDescription  string                `json:"siteDescription" bson:"siteDescription"`
	SiteKeywords     []string              `json:"siteKeywords" bson:"siteKeywords"`
	OGImage          *string               `json:"ogImage,omitempty" bson:"ogImage,omitempty"`
	TwitterHandle    *string               `json:"twitterHandle,omitempty" bson:"twitterHandle,omitempty"`
	GoogleAnalyticsID *string              `json:"googleAnalyticsId,omitempty" bson:"googleAnalyticsId,omitempty"`
	FacebookPixelID  *string               `json:"facebookPixelId,omitempty" bson:"facebookPixelId,omitempty"`
	PageConfigs      map[string]PageSEO    `json:"pageConfigs" bson:"pageConfigs"`
	UpdatedAt        time.Time             `json:"updatedAt" bson:"updatedAt"`
}

// PageSEO represents SEO configuration for a specific page
type PageSEO struct {
	Title       string   `json:"title" bson:"title"`
	Description string   `json:"description" bson:"description"`
	Keywords    []string `json:"keywords" bson:"keywords"`
	OGImage     *string  `json:"ogImage,omitempty" bson:"ogImage,omitempty"`
}

// StorefrontAnalytics represents analytics for storefront configuration
type StorefrontAnalytics struct {
	ID                primitive.ObjectID             `json:"id" bson:"_id,omitempty"`
	Date              time.Time                      `json:"date" bson:"date"`
	BannerClicks      map[string]int                 `json:"bannerClicks" bson:"bannerClicks"`
	SectionViews      map[string]int                 `json:"sectionViews" bson:"sectionViews"`
	FeatureUsage      map[string]int                 `json:"featureUsage" bson:"featureUsage"`
	PopupInteractions map[string]PopupInteractionStats `json:"popupInteractions" bson:"popupInteractions"`
	CreatedAt         time.Time                      `json:"createdAt" bson:"createdAt"`
}

// PopupInteractionStats represents popup interaction statistics
type PopupInteractionStats struct {
	Shown   int `json:"shown" bson:"shown"`
	Clicked int `json:"clicked" bson:"clicked"`
	Closed  int `json:"closed" bson:"closed"`
}

// Occasion represents shopping occasions (engagement, wedding, etc.)
type Occasion struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name        string             `json:"name" bson:"name"`
	Icon        string             `json:"icon" bson:"icon"` // Emoji or icon name
	Description string             `json:"description" bson:"description"`
	ItemCount   int                `json:"itemCount" bson:"itemCount"`
	Tags        []string           `json:"tags" bson:"tags"` // Product tags for this occasion
	IsActive    bool               `json:"isActive" bson:"isActive"`
	Priority    int                `json:"priority" bson:"priority"` // Display order
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// BudgetRange represents price range categories
type BudgetRange struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Label       string             `json:"label" bson:"label"`       // "₹0k-10k"
	MinPrice    float64            `json:"minPrice" bson:"minPrice"` // 0
	MaxPrice    float64            `json:"maxPrice" bson:"maxPrice"` // 10000
	ItemCount   int                `json:"itemCount" bson:"itemCount"`
	IsPopular   bool               `json:"isPopular" bson:"isPopular"`
	Priority    int                `json:"priority" bson:"priority"` // Display order
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// Collection represents curated product collections
type Collection struct {
	ID          primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	Title       string               `json:"title" bson:"title"`
	Subtitle    string               `json:"subtitle" bson:"subtitle"`
	Description string               `json:"description" bson:"description"`
	ImageURLs   []string             `json:"imageUrls" bson:"imageUrls"` // Collection preview images
	ProductIDs  []primitive.ObjectID `json:"productIds" bson:"productIds"`
	ItemCount   int                  `json:"itemCount" bson:"itemCount"`
	Tags        []string             `json:"tags" bson:"tags"`
	IsActive    bool                 `json:"isActive" bson:"isActive"`
	IsFeatured  bool                 `json:"isFeatured" bson:"isFeatured"`
	Priority    int                  `json:"priority" bson:"priority"`
	CreatedAt   time.Time            `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time            `json:"updatedAt" bson:"updatedAt"`
}

// OccasionResponse for API
type OccasionResponse struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Icon        string   `json:"icon"`
	Description string   `json:"description"`
	ItemCount   int      `json:"itemCount"`
	Tags        []string `json:"tags"`
	Priority    int      `json:"priority"`
}

// BudgetRangeResponse for API
type BudgetRangeResponse struct {
	ID        string  `json:"id"`
	Label     string  `json:"label"`
	MinPrice  float64 `json:"minPrice"`
	MaxPrice  float64 `json:"maxPrice"`
	ItemCount int     `json:"itemCount"`
	IsPopular bool    `json:"isPopular"`
	Priority  int     `json:"priority"`
}

// CollectionResponse for API
type CollectionResponse struct {
	ID          string   `json:"id"`
	Title       string   `json:"title"`
	Subtitle    string   `json:"subtitle"`
	Description string   `json:"description"`
	ImageURLs   []string `json:"imageUrls"`
	ItemCount   int      `json:"itemCount"`
	Tags        []string `json:"tags"`
	IsFeatured  bool     `json:"isFeatured"`
	Priority    int      `json:"priority"`
}

// ToResponse converts Occasion to OccasionResponse
func (o *Occasion) ToResponse() OccasionResponse {
	return OccasionResponse{
		ID:          o.ID.Hex(),
		Name:        o.Name,
		Icon:        o.Icon,
		Description: o.Description,
		ItemCount:   o.ItemCount,
		Tags:        o.Tags,
		Priority:    o.Priority,
	}
}

// ToResponse converts BudgetRange to BudgetRangeResponse
func (b *BudgetRange) ToResponse() BudgetRangeResponse {
	return BudgetRangeResponse{
		ID:        b.ID.Hex(),
		Label:     b.Label,
		MinPrice:  b.MinPrice,
		MaxPrice:  b.MaxPrice,
		ItemCount: b.ItemCount,
		IsPopular: b.IsPopular,
		Priority:  b.Priority,
	}
}

// ToResponse converts Collection to CollectionResponse
func (c *Collection) ToResponse() CollectionResponse {
	return CollectionResponse{
		ID:          c.ID.Hex(),
		Title:       c.Title,
		Subtitle:    c.Subtitle,
		Description: c.Description,
		ImageURLs:   c.ImageURLs,
		ItemCount:   c.ItemCount,
		Tags:        c.Tags,
		IsFeatured:  c.IsFeatured,
		Priority:    c.Priority,
	}
}

// MetalSubtype represents a specific purity/karat level
type MetalSubtype struct {
	Name            string   `json:"name" bson:"name"`                                   // e.g., "9K", "14K", "925 Sterling Silver"
	Code            string   `json:"code,omitempty" bson:"code,omitempty"`               // Internal code
	PriceMultiplier *float64 `json:"priceMultiplier,omitempty" bson:"priceMultiplier,omitempty"` // Price adjustment factor
}

// MetalOption represents a metal type with its variants (karats/purity)
type MetalOption struct {
	ID           string         `json:"id,omitempty" bson:"id,omitempty"`
	Type         string         `json:"type" bson:"type"`                 // Gold, Silver, Platinum
	Subtypes     []MetalSubtype `json:"subtypes" bson:"subtypes"`         // Detailed purity variants
	Variants     []string       `json:"variants" bson:"variants"`         // Legacy support - 9K, 14K, 22K for Gold
	InternalCode string         `json:"internalCode,omitempty" bson:"internalCode,omitempty"`
	IsActive     bool           `json:"isActive" bson:"isActive"`
	SortOrder    int            `json:"sortOrder" bson:"sortOrder"`
}

// PlatingColor represents plating color options
type PlatingColor struct {
	ID        string `json:"id,omitempty" bson:"id,omitempty"`
	Name      string `json:"name" bson:"name"`                             // Yellow Gold, Rose Gold, etc.
	HexColor  string `json:"hexColor,omitempty" bson:"hexColor,omitempty"` // For UI display
	Code      string `json:"code,omitempty" bson:"code,omitempty"`         // Internal code
	IsActive  bool   `json:"isActive" bson:"isActive"`
	SortOrder int    `json:"sortOrder" bson:"sortOrder"`
}

// SizeValue represents an individual size option
type SizeValue struct {
	Name         string   `json:"name" bson:"name"`                               // Display name (e.g., "US 6")
	Value        string   `json:"value" bson:"value"`                             // Value for storage
	MmEquivalent *float64 `json:"mmEquivalent,omitempty" bson:"mmEquivalent,omitempty"` // Millimeter equivalent
	Code         string   `json:"code,omitempty" bson:"code,omitempty"`           // Internal code
}

// SizeOption represents size options for a jewelry category
type SizeOption struct {
	ID       string      `json:"id,omitempty" bson:"id,omitempty"`
	Category string      `json:"category" bson:"category"` // Ring, Chain, Bracelet, Bangle
	Sizes    []SizeValue `json:"sizes" bson:"sizes"`
	IsActive bool        `json:"isActive" bson:"isActive"`
}

// StoneType represents a type of stone available
type StoneType struct {
	ID              string   `json:"id,omitempty" bson:"id,omitempty"`
	Name            string   `json:"name" bson:"name"`                               // Diamond, Moissanite, CZ, etc.
	Category        string   `json:"category" bson:"category"`                       // Precious, Semi-Precious, Lab-Grown, Artificial
	AvailableCuts   []string `json:"availableCuts" bson:"availableCuts"`             // Round, Oval, Princess, etc.
	AvailableColors []string `json:"availableColors" bson:"availableColors"`         // Color options
	Code            string   `json:"code,omitempty" bson:"code,omitempty"`           // Internal code
	IsActive        bool     `json:"isActive" bson:"isActive"`
	SortOrder       int      `json:"sortOrder" bson:"sortOrder"`
}

// StoreSettings represents configurable store settings (GST, shipping, etc.)
type StoreSettings struct {
	ID                    primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	// Tax Settings
	GSTRate               float64            `json:"gstRate" bson:"gstRate"`                           // GST percentage (e.g., 18 for 18%)
	GSTNumber             string             `json:"gstNumber" bson:"gstNumber"`                       // Store GST number
	EnableGST             bool               `json:"enableGst" bson:"enableGst"`                       // Enable/disable GST
	// Shipping Settings
	FreeShippingThreshold float64            `json:"freeShippingThreshold" bson:"freeShippingThreshold"` // Minimum order for free shipping
	ShippingCost          float64            `json:"shippingCost" bson:"shippingCost"`                   // Standard shipping cost
	EnableFreeShipping    bool               `json:"enableFreeShipping" bson:"enableFreeShipping"`       // Enable free shipping above threshold
	// COD Settings
	EnableCOD             bool               `json:"enableCod" bson:"enableCod"`                         // Enable Cash on Delivery
	CODCharge             float64            `json:"codCharge" bson:"codCharge"`                         // Extra charge for COD
	CODMaxAmount          float64            `json:"codMaxAmount" bson:"codMaxAmount"`                   // Maximum order value for COD
	// Store Info
	StoreName             string             `json:"storeName" bson:"storeName"`
	StoreEmail            string             `json:"storeEmail" bson:"storeEmail"`
	StorePhone            string             `json:"storePhone" bson:"storePhone"`
	StoreAddress          string             `json:"storeAddress" bson:"storeAddress"`
	Currency              string             `json:"currency" bson:"currency"`                           // INR, USD, etc.
	CurrencySymbol        string             `json:"currencySymbol" bson:"currencySymbol"`               // ₹, $, etc.
	// Order ID Settings
	OrderIdPrefix         string             `json:"orderIdPrefix" bson:"orderIdPrefix"`                 // Prefix for order numbers (e.g., TJ, ORD)
	OrderIdCounter        int64              `json:"orderIdCounter" bson:"orderIdCounter"`               // Current counter for order numbers
	// Product Customization Options (Admin Editable)
	MetalOptions          []MetalOption      `json:"metalOptions" bson:"metalOptions"`                   // Available metal types with variants
	PlatingColors         []PlatingColor     `json:"platingColors" bson:"platingColors"`                 // Plating color options
	SizeOptions           []SizeOption       `json:"sizeOptions" bson:"sizeOptions"`                     // Size options by category
	StoneTypes            []StoneType        `json:"stoneTypes" bson:"stoneTypes"`                       // Available stone types
	MaxEngravingChars     int                `json:"maxEngravingChars" bson:"maxEngravingChars"`         // Default max engraving characters
	// Metadata
	UpdatedAt             time.Time          `json:"updatedAt" bson:"updatedAt"`
	UpdatedBy             primitive.ObjectID `json:"updatedBy" bson:"updatedBy"`
}

// StoreSettingsResponse for API
type StoreSettingsResponse struct {
	ID                    string         `json:"id"`
	GSTRate               float64        `json:"gstRate"`
	GSTNumber             string         `json:"gstNumber"`
	EnableGST             bool           `json:"enableGst"`
	FreeShippingThreshold float64        `json:"freeShippingThreshold"`
	ShippingCost          float64        `json:"shippingCost"`
	EnableFreeShipping    bool           `json:"enableFreeShipping"`
	EnableCOD             bool           `json:"enableCod"`
	CODCharge             float64        `json:"codCharge"`
	CODMaxAmount          float64        `json:"codMaxAmount"`
	StoreName             string         `json:"storeName"`
	StoreEmail            string         `json:"storeEmail"`
	StorePhone            string         `json:"storePhone"`
	StoreAddress          string         `json:"storeAddress"`
	Currency              string         `json:"currency"`
	CurrencySymbol        string         `json:"currencySymbol"`
	OrderIdPrefix         string         `json:"orderIdPrefix"`
	OrderIdCounter        int64          `json:"orderIdCounter"`
	MetalOptions          []MetalOption  `json:"metalOptions"`
	PlatingColors         []PlatingColor `json:"platingColors"`
	SizeOptions           []SizeOption   `json:"sizeOptions"`
	StoneTypes            []StoneType    `json:"stoneTypes"`
	MaxEngravingChars     int            `json:"maxEngravingChars"`
	UpdatedAt             string         `json:"updatedAt"`
}

// ToResponse converts StoreSettings to StoreSettingsResponse
func (s *StoreSettings) ToResponse() StoreSettingsResponse {
	return StoreSettingsResponse{
		ID:                    s.ID.Hex(),
		GSTRate:               s.GSTRate,
		GSTNumber:             s.GSTNumber,
		EnableGST:             s.EnableGST,
		FreeShippingThreshold: s.FreeShippingThreshold,
		ShippingCost:          s.ShippingCost,
		EnableFreeShipping:    s.EnableFreeShipping,
		EnableCOD:             s.EnableCOD,
		CODCharge:             s.CODCharge,
		CODMaxAmount:          s.CODMaxAmount,
		StoreName:             s.StoreName,
		StoreEmail:            s.StoreEmail,
		StorePhone:            s.StorePhone,
		StoreAddress:          s.StoreAddress,
		Currency:              s.Currency,
		CurrencySymbol:        s.CurrencySymbol,
		OrderIdPrefix:         s.OrderIdPrefix,
		OrderIdCounter:        s.OrderIdCounter,
		MetalOptions:          s.MetalOptions,
		PlatingColors:         s.PlatingColors,
		SizeOptions:           s.SizeOptions,
		StoneTypes:            s.StoneTypes,
		MaxEngravingChars:     s.MaxEngravingChars,
		UpdatedAt:             s.UpdatedAt.Format(time.RFC3339),
	}
}

// DefaultStoreSettings returns default store settings
func DefaultStoreSettings() *StoreSettings {
	return &StoreSettings{
		GSTRate:               18.0,
		GSTNumber:             "",
		EnableGST:             true,
		FreeShippingThreshold: 1000.0,
		ShippingCost:          99.0,
		EnableFreeShipping:    true,
		EnableCOD:             true,
		CODCharge:             0.0,
		CODMaxAmount:          50000.0,
		StoreName:             "Thyne Jewels",
		StoreEmail:            "support@thynejewels.com",
		StorePhone:            "+91 9876543210",
		StoreAddress:          "Mumbai, India",
		Currency:              "INR",
		CurrencySymbol:        "₹",
		OrderIdPrefix:         "TJ",
		OrderIdCounter:        1000,
		MetalOptions: []MetalOption{
			{
				Type:     "Gold",
				Variants: []string{"9K", "14K", "18K", "22K"},
				Subtypes: []MetalSubtype{
					{Name: "9K", Code: "G9K"},
					{Name: "14K", Code: "G14K"},
					{Name: "18K", Code: "G18K"},
					{Name: "22K", Code: "G22K"},
				},
				IsActive: true,
			},
			{
				Type:     "Silver",
				Variants: []string{"925 Sterling Silver"},
				Subtypes: []MetalSubtype{
					{Name: "925 Sterling Silver", Code: "S925"},
				},
				IsActive: true,
			},
			{
				Type:     "Platinum",
				Variants: []string{"950 Platinum"},
				Subtypes: []MetalSubtype{
					{Name: "950 Platinum", Code: "PT950"},
				},
				IsActive: true,
			},
		},
		PlatingColors: []PlatingColor{
			{Name: "Yellow Gold", HexColor: "#FFD700", IsActive: true},
			{Name: "Rose Gold", HexColor: "#B76E79", IsActive: true},
			{Name: "White Gold", HexColor: "#E8E8E8", IsActive: true},
			{Name: "Rhodium", HexColor: "#C0C0C0", IsActive: true},
			{Name: "Antique", HexColor: "#8B7355", IsActive: true},
			{Name: "Black Gold", HexColor: "#1C1C1C", IsActive: true},
		},
		SizeOptions: []SizeOption{
			{
				Category: "Ring",
				Sizes: []SizeValue{
					{Name: "US 4", Value: "4", MmEquivalent: floatPtr(14.9)},
					{Name: "US 5", Value: "5", MmEquivalent: floatPtr(15.7)},
					{Name: "US 6", Value: "6", MmEquivalent: floatPtr(16.5)},
					{Name: "US 7", Value: "7", MmEquivalent: floatPtr(17.3)},
					{Name: "US 8", Value: "8", MmEquivalent: floatPtr(18.1)},
					{Name: "US 9", Value: "9", MmEquivalent: floatPtr(18.9)},
					{Name: "US 10", Value: "10", MmEquivalent: floatPtr(19.8)},
					{Name: "US 11", Value: "11", MmEquivalent: floatPtr(20.6)},
					{Name: "US 12", Value: "12", MmEquivalent: floatPtr(21.4)},
				},
				IsActive: true,
			},
			{
				Category: "Chain",
				Sizes: []SizeValue{
					{Name: "16 inch", Value: "16", MmEquivalent: floatPtr(406)},
					{Name: "18 inch", Value: "18", MmEquivalent: floatPtr(457)},
					{Name: "20 inch", Value: "20", MmEquivalent: floatPtr(508)},
					{Name: "22 inch", Value: "22", MmEquivalent: floatPtr(559)},
					{Name: "24 inch", Value: "24", MmEquivalent: floatPtr(610)},
				},
				IsActive: true,
			},
			{
				Category: "Bracelet",
				Sizes: []SizeValue{
					{Name: "6 inch", Value: "6", MmEquivalent: floatPtr(152)},
					{Name: "6.5 inch", Value: "6.5", MmEquivalent: floatPtr(165)},
					{Name: "7 inch", Value: "7", MmEquivalent: floatPtr(178)},
					{Name: "7.5 inch", Value: "7.5", MmEquivalent: floatPtr(190)},
					{Name: "8 inch", Value: "8", MmEquivalent: floatPtr(203)},
				},
				IsActive: true,
			},
			{
				Category: "Bangle",
				Sizes: []SizeValue{
					{Name: "2.2", Value: "2.2", MmEquivalent: floatPtr(56)},
					{Name: "2.4", Value: "2.4", MmEquivalent: floatPtr(61)},
					{Name: "2.6", Value: "2.6", MmEquivalent: floatPtr(66)},
					{Name: "2.8", Value: "2.8", MmEquivalent: floatPtr(71)},
					{Name: "2.10", Value: "2.10", MmEquivalent: floatPtr(76)},
				},
				IsActive: true,
			},
		},
		StoneTypes: []StoneType{
			// Precious
			{Name: "Diamond", Category: "Precious", AvailableCuts: []string{"Round", "Oval", "Princess", "Cushion", "Emerald", "Pear", "Marquise", "Heart", "Radiant", "Asscher"}, AvailableColors: []string{"D (Colorless)", "E", "F", "G", "H", "I", "J", "K", "Fancy Yellow", "Fancy Pink", "Fancy Blue"}, IsActive: true},
			{Name: "Ruby", Category: "Precious", AvailableCuts: []string{"Round", "Oval", "Cushion", "Pear", "Heart"}, AvailableColors: []string{"Pigeon Blood Red", "Deep Red", "Pinkish Red", "Purplish Red"}, IsActive: true},
			{Name: "Emerald", Category: "Precious", AvailableCuts: []string{"Emerald", "Oval", "Round", "Pear", "Cushion"}, AvailableColors: []string{"Deep Green", "Vivid Green", "Medium Green", "Light Green"}, IsActive: true},
			{Name: "Sapphire", Category: "Precious", AvailableCuts: []string{"Round", "Oval", "Cushion", "Pear", "Princess"}, AvailableColors: []string{"Blue", "Yellow", "Pink", "White", "Padparadscha"}, IsActive: true},
			// Lab-Grown
			{Name: "Moissanite", Category: "Lab-Grown", AvailableCuts: []string{"Round", "Oval", "Cushion", "Pear", "Princess", "Emerald", "Radiant"}, AvailableColors: []string{"DEF (Colorless)", "GHI (Near Colorless)", "Champagne", "Green", "Blue"}, IsActive: true},
			{Name: "Lab Diamond", Category: "Lab-Grown", AvailableCuts: []string{"Round", "Oval", "Princess", "Cushion", "Emerald", "Pear", "Marquise"}, AvailableColors: []string{"D", "E", "F", "G", "H", "Fancy Yellow", "Fancy Pink"}, IsActive: true},
			// Semi-Precious
			{Name: "Amethyst", Category: "Semi-Precious", AvailableCuts: []string{"Round", "Oval", "Cushion", "Pear", "Heart"}, AvailableColors: []string{"Deep Purple", "Medium Purple", "Light Purple", "Rose de France"}, IsActive: true},
			{Name: "Blue Topaz", Category: "Semi-Precious", AvailableCuts: []string{"Round", "Oval", "Cushion", "Pear", "Heart"}, AvailableColors: []string{"Sky Blue", "Swiss Blue", "London Blue"}, IsActive: true},
			{Name: "Citrine", Category: "Semi-Precious", AvailableCuts: []string{"Round", "Oval", "Cushion", "Pear"}, AvailableColors: []string{"Golden Yellow", "Orange", "Madeira"}, IsActive: true},
			{Name: "Peridot", Category: "Semi-Precious", AvailableCuts: []string{"Round", "Oval", "Cushion", "Pear"}, AvailableColors: []string{"Lime Green", "Olive Green", "Yellow Green"}, IsActive: true},
			{Name: "Garnet", Category: "Semi-Precious", AvailableCuts: []string{"Round", "Oval", "Cushion", "Pear"}, AvailableColors: []string{"Deep Red", "Orange", "Green (Tsavorite)", "Purple (Rhodolite)"}, IsActive: true},
			// Artificial
			{Name: "Cubic Zirconia (CZ)", Category: "Artificial", AvailableCuts: []string{"Round", "Oval", "Princess", "Cushion", "Emerald", "Pear", "Heart"}, AvailableColors: []string{"Clear", "Pink", "Blue", "Green", "Yellow", "Purple", "Champagne"}, IsActive: true},
			{Name: "AAA Crystal", Category: "Artificial", AvailableCuts: []string{"Round", "Oval", "Princess"}, AvailableColors: []string{"Clear", "Aurora Borealis", "Various"}, IsActive: true},
		},
		MaxEngravingChars: 15,
		UpdatedAt:         time.Now(),
	}
}

// Helper function for float pointers
func floatPtr(f float64) *float64 {
	return &f
}