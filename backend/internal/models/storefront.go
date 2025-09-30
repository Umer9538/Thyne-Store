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