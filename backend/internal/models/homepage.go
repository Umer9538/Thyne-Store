package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SectionType represents the type of homepage section
type SectionType string

const (
	SectionBannerCarousel SectionType = "banner_carousel"
	SectionCategories     SectionType = "categories"
	SectionDealOfDay      SectionType = "deal_of_day"
	SectionFlashSale      SectionType = "flash_sale"
	SectionBestSellers    SectionType = "best_sellers"
	SectionFeatured       SectionType = "featured"
	SectionNewArrivals    SectionType = "new_arrivals"
	SectionSpecialOffers  SectionType = "special_offers"
	SectionBrands         SectionType = "brands"
	SectionRecentlyViewed SectionType = "recently_viewed"
	SectionUpcomingEvents SectionType = "upcoming_events"
	SectionCustomBanner   SectionType = "custom_banner"
	SectionShowcase360    SectionType = "showcase_360"
	SectionBundleDeals    SectionType = "bundle_deals"
)

// HomepageSection represents a configurable section on the homepage
type HomepageSection struct {
	ID          primitive.ObjectID     `json:"id" bson:"_id,omitempty"`
	Type        SectionType            `json:"type" bson:"type"`
	Title       string                 `json:"title" bson:"title"`
	Subtitle    string                 `json:"subtitle" bson:"subtitle"`
	Priority    int                    `json:"priority" bson:"priority"` // Lower number = higher priority
	IsActive    bool                   `json:"isActive" bson:"isActive"`
	Config      map[string]interface{} `json:"config" bson:"config"` // Section-specific configuration
	StartDate   *time.Time             `json:"startDate" bson:"startDate"`
	EndDate     *time.Time             `json:"endDate" bson:"endDate"`
	CreatedBy   primitive.ObjectID     `json:"createdBy" bson:"createdBy"`
	CreatedAt   time.Time              `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time              `json:"updatedAt" bson:"updatedAt"`
}

// HomepageConfig represents the complete homepage configuration
type HomepageConfig struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Sections  []HomepageSection  `json:"sections" bson:"sections"`
	UpdatedBy primitive.ObjectID `json:"updatedBy" bson:"updatedBy"`
	UpdatedAt time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// SectionLayoutItem represents the order and visibility of a section
type SectionLayoutItem struct {
	SectionType SectionType `json:"sectionType" bson:"sectionType"`
	Order       int         `json:"order" bson:"order"`           // Display order (0 = first, 1 = second, etc.)
	IsVisible   bool        `json:"isVisible" bson:"isVisible"`   // Whether section is visible
	Title       string      `json:"title,omitempty" bson:"title,omitempty"` // Optional custom title override
}

// HomepageLayout represents the display order configuration for homepage sections
type HomepageLayout struct {
	ID        primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	Layout    []SectionLayoutItem `json:"layout" bson:"layout"`
	UpdatedBy primitive.ObjectID  `json:"updatedBy" bson:"updatedBy"`
	UpdatedAt time.Time           `json:"updatedAt" bson:"updatedAt"`
	CreatedAt time.Time           `json:"createdAt" bson:"createdAt"`
}

// DealOfDay represents a time-limited special deal
type DealOfDay struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	ProductID    primitive.ObjectID `json:"productId" bson:"productId"`
	OriginalPrice float64           `json:"originalPrice" bson:"originalPrice"`
	DealPrice    float64            `json:"dealPrice" bson:"dealPrice"`
	DiscountPercent int             `json:"discountPercent" bson:"discountPercent"`
	StartTime    time.Time          `json:"startTime" bson:"startTime"`
	EndTime      time.Time          `json:"endTime" bson:"endTime"`
	Stock        int                `json:"stock" bson:"stock"`
	SoldCount    int                `json:"soldCount" bson:"soldCount"`
	IsActive     bool               `json:"isActive" bson:"isActive"`
	CreatedAt    time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt    time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// FlashSale represents a time-limited sale event
type FlashSale struct {
	ID          primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	Title       string               `json:"title" bson:"title"`
	Description string               `json:"description" bson:"description"`
	BannerImage string               `json:"bannerImage" bson:"bannerImage"`
	ProductIDs  []primitive.ObjectID `json:"productIds" bson:"productIds"`
	StartTime   time.Time            `json:"startTime" bson:"startTime"`
	EndTime     time.Time            `json:"endTime" bson:"endTime"`
	Discount    int                  `json:"discount" bson:"discount"` // Percentage
	IsActive    bool                 `json:"isActive" bson:"isActive"`
	CreatedAt   time.Time            `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time            `json:"updatedAt" bson:"updatedAt"`
}

// Brand represents a jewelry brand
type Brand struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name        string             `json:"name" bson:"name"`
	Logo        string             `json:"logo" bson:"logo"`
	Description string             `json:"description" bson:"description"`
	IsActive    bool               `json:"isActive" bson:"isActive"`
	Priority    int                `json:"priority" bson:"priority"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// RecentlyViewed tracks products viewed by users
type RecentlyViewed struct {
	ID         primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	UserID     *primitive.ObjectID  `json:"userId" bson:"userId"`
	SessionID  *string              `json:"sessionId" bson:"sessionId"` // For guest users
	ProductIDs []primitive.ObjectID `json:"productIds" bson:"productIds"`
	UpdatedAt  time.Time            `json:"updatedAt" bson:"updatedAt"`
}

// Showcase360 represents an interactive 360° product showcase
type Showcase360 struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	ProductID   primitive.ObjectID `json:"productId" bson:"productId"`
	Title       string             `json:"title" bson:"title"`
	Description string             `json:"description" bson:"description"`
	Images360   []string           `json:"images360" bson:"images360"`     // Array of images for 360° rotation
	VideoURL    string             `json:"videoUrl" bson:"videoUrl"`       // Video loop of jewelry being worn
	ThumbnailURL string            `json:"thumbnailUrl" bson:"thumbnailUrl"` // Thumbnail for the showcase
	Priority    int                `json:"priority" bson:"priority"`       // Display order
	IsActive    bool               `json:"isActive" bson:"isActive"`
	StartTime   *time.Time         `json:"startTime" bson:"startTime"`
	EndTime     *time.Time         `json:"endTime" bson:"endTime"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// BundleItem represents a product in a bundle
type BundleItem struct {
	ProductID primitive.ObjectID `json:"productId" bson:"productId"`
	Quantity  int                `json:"quantity" bson:"quantity"`
}

// BundleDeal represents a bundle of products sold together at a discount
type BundleDeal struct {
	ID              primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Title           string             `json:"title" bson:"title"`
	Description     string             `json:"description" bson:"description"`
	BannerImage     string             `json:"bannerImage" bson:"bannerImage"`
	Items           []BundleItem       `json:"items" bson:"items"`
	OriginalPrice   float64            `json:"originalPrice" bson:"originalPrice"`
	BundlePrice     float64            `json:"bundlePrice" bson:"bundlePrice"`
	DiscountPercent int                `json:"discountPercent" bson:"discountPercent"`
	Category        string             `json:"category" bson:"category"` // e.g., "Bridal", "Complete Look", "Gift Set"
	Priority        int                `json:"priority" bson:"priority"`
	IsActive        bool               `json:"isActive" bson:"isActive"`
	StartTime       *time.Time         `json:"startTime" bson:"startTime"`
	EndTime         *time.Time         `json:"endTime" bson:"endTime"`
	Stock           int                `json:"stock" bson:"stock"`
	SoldCount       int                `json:"soldCount" bson:"soldCount"`
	CreatedAt       time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// HomepageResponse represents the complete homepage data response
type HomepageResponse struct {
	Layout           []SectionLayoutItem `json:"layout,omitempty"`        // Section ordering configuration
	Sections         []HomepageSection   `json:"sections"`
	DealOfDay        *DealOfDay          `json:"dealOfDay,omitempty"`
	ActiveFlashSales []FlashSale         `json:"activeFlashSales,omitempty"`
	Brands           []Brand             `json:"brands,omitempty"`
	RecentlyViewed   []Product           `json:"recentlyViewed,omitempty"`
	Showcases360     []Showcase360       `json:"showcases360,omitempty"`
	BundleDeals      []BundleDeal        `json:"bundleDeals,omitempty"`
}

// Helper methods

// IsCurrentlyActive checks if a section is currently active based on dates
func (s *HomepageSection) IsCurrentlyActive() bool {
	if !s.IsActive {
		return false
	}

	now := time.Now()

	if s.StartDate != nil && now.Before(*s.StartDate) {
		return false
	}

	if s.EndDate != nil && now.After(*s.EndDate) {
		return false
	}

	return true
}

// IsLive checks if deal of day is currently live
func (d *DealOfDay) IsLive() bool {
	if !d.IsActive {
		return false
	}

	now := time.Now()
	return now.After(d.StartTime) && now.Before(d.EndTime) && d.Stock > d.SoldCount
}

// TimeRemaining returns the time remaining for the deal
func (d *DealOfDay) TimeRemaining() time.Duration {
	return time.Until(d.EndTime)
}

// IsLive checks if flash sale is currently live
func (f *FlashSale) IsLive() bool {
	if !f.IsActive {
		return false
	}

	now := time.Now()
	return now.After(f.StartTime) && now.Before(f.EndTime)
}

// TimeRemaining returns the time remaining for the flash sale
func (f *FlashSale) TimeRemaining() time.Duration {
	return time.Until(f.EndTime)
}

// IsLive checks if showcase is currently active
func (s *Showcase360) IsLive() bool {
	if !s.IsActive {
		return false
	}

	now := time.Now()

	if s.StartTime != nil && now.Before(*s.StartTime) {
		return false
	}

	if s.EndTime != nil && now.After(*s.EndTime) {
		return false
	}

	return true
}

// IsLive checks if bundle deal is currently active
func (b *BundleDeal) IsLive() bool {
	if !b.IsActive {
		return false
	}

	now := time.Now()

	if b.StartTime != nil && now.Before(*b.StartTime) {
		return false
	}

	if b.EndTime != nil && now.After(*b.EndTime) {
		return false
	}

	return b.Stock > b.SoldCount
}

// CalculateSavings returns the amount saved
func (b *BundleDeal) CalculateSavings() float64 {
	return b.OriginalPrice - b.BundlePrice
}
