package models

import (
    "fmt"
    "time"

    "go.mongodb.org/mongo-driver/bson/primitive"
    v10 "github.com/go-playground/validator/v10"
)

// StoneConfig represents a stone with shape and available colors
type StoneConfig struct {
	Name                string             `json:"name" bson:"name"`                                         // e.g., "Center Stone", "Accent Stone A"
	Shape               string             `json:"shape" bson:"shape"`                                       // e.g., "Oval", "Round"
	AvailableColors     []string           `json:"availableColors" bson:"availableColors"`                   // e.g., ["Red", "Blue", "Clear"]
	Count               *int               `json:"count,omitempty" bson:"count,omitempty"`                   // Number of stones (for accent stones)
	ColorPriceModifiers map[string]float64 `json:"colorPriceModifiers,omitempty" bson:"colorPriceModifiers,omitempty"` // Price modifier per color
}

// ProductCustomization represents customer's customization choices for an order
type ProductCustomization struct {
	Metal          string            `json:"metal,omitempty" bson:"metal,omitempty"`                   // Selected metal e.g., "14K Gold"
	PlatingColor   string            `json:"platingColor,omitempty" bson:"platingColor,omitempty"`     // Selected plating e.g., "Rose Gold"
	StoneColors    map[string]string `json:"stoneColors,omitempty" bson:"stoneColors,omitempty"`       // Stone name -> selected color
	RingSize       string            `json:"ringSize,omitempty" bson:"ringSize,omitempty"`             // Selected ring size
	Engraving      string            `json:"engraving,omitempty" bson:"engraving,omitempty"`           // Engraving text (up to maxEngravingChars)
	PriceModifier  float64           `json:"priceModifier" bson:"priceModifier"`                       // Total price adjustment from customizations
	SummaryLines   []string          `json:"summaryLines,omitempty" bson:"summaryLines,omitempty"`     // Human-readable summary
}

// GetSummaryLines generates human-readable summary of customization
func (pc *ProductCustomization) GetSummaryLines() []string {
	var lines []string
	if pc.Metal != "" {
		lines = append(lines, "Metal: "+pc.Metal)
	}
	if pc.PlatingColor != "" {
		lines = append(lines, "Plating: "+pc.PlatingColor)
	}
	for stoneName, color := range pc.StoneColors {
		lines = append(lines, stoneName+": "+color)
	}
	if pc.RingSize != "" {
		lines = append(lines, "Ring Size: "+pc.RingSize)
	}
	if pc.Engraving != "" {
		lines = append(lines, "Engraving: \""+pc.Engraving+"\"")
	}
	return lines
}

// StockType represents whether product is stocked or made-to-order
type StockType string

const (
	StockTypeStocked     StockType = "stocked"      // Regular inventory with limited quantity
	StockTypeMadeToOrder StockType = "made_to_order" // Custom/on-demand, always available
)

// Product represents a jewelry product
type Product struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name           string            `json:"name" bson:"name" validate:"required,min=2,max=200"`
	Description    string            `json:"description" bson:"description" validate:"required,min=10,max=2000"`
	Price          float64           `json:"price" bson:"price" validate:"required,min=0"`
	OriginalPrice  *float64          `json:"originalPrice,omitempty" bson:"originalPrice,omitempty"`
	Images         []string          `json:"images" bson:"images" validate:"required,min=1"`
	Videos         []string          `json:"videos,omitempty" bson:"videos,omitempty"`
	Category       string            `json:"category" bson:"category" validate:"required"`
	Subcategory    string            `json:"subcategory" bson:"subcategory" validate:"required"`
	MetalType      string            `json:"metalType" bson:"metalType" validate:"required"`
	StoneType      *string           `json:"stoneType,omitempty" bson:"stoneType,omitempty"`
	Weight         *float64          `json:"weight,omitempty" bson:"weight,omitempty"`
	Size           *string           `json:"size,omitempty" bson:"size,omitempty"`
	StockType      StockType         `json:"stockType" bson:"stockType"`                            // "stocked" or "made_to_order"
	StockQuantity  int               `json:"stockQuantity" bson:"stockQuantity" validate:"min=0"`
	Rating         float64           `json:"rating" bson:"rating" validate:"min=0,max=5"`
	ReviewCount    int               `json:"reviewCount" bson:"reviewCount" validate:"min=0"`
	Tags           []string          `json:"tags" bson:"tags"`
	Gender         []string          `json:"gender" bson:"gender"` // ["all", "women", "men", "kids", "inclusive"]
	IsAvailable    bool              `json:"isAvailable" bson:"isAvailable"`
	IsFeatured     bool              `json:"isFeatured" bson:"isFeatured"`
	// Customization options (legacy - kept for compatibility)
	AvailableColors       []string `json:"availableColors,omitempty" bson:"availableColors,omitempty"`
	AvailablePolishTypes  []string `json:"availablePolishTypes,omitempty" bson:"availablePolishTypes,omitempty"`
	AvailableStoneColors  []string `json:"availableStoneColors,omitempty" bson:"availableStoneColors,omitempty"`
	AvailableGemstones    []string `json:"availableGemstones,omitempty" bson:"availableGemstones,omitempty"`
	// Enhanced customization options (Diamondere style)
	AvailableMetals         []string           `json:"availableMetals,omitempty" bson:"availableMetals,omitempty"`                 // e.g., ["14K Gold", "18K Gold", "925 Silver"]
	AvailablePlatingColors  []string           `json:"availablePlatingColors,omitempty" bson:"availablePlatingColors,omitempty"`   // e.g., ["White Gold", "Rose Gold"]
	Stones                  []StoneConfig      `json:"stones,omitempty" bson:"stones,omitempty"`                                   // Multiple stones with shape + colors
	AvailableSizes          []string           `json:"availableSizes,omitempty" bson:"availableSizes,omitempty"`                   // Ring sizes
	EngravingEnabled        bool               `json:"engravingEnabled" bson:"engravingEnabled"`
	MaxEngravingChars       int                `json:"maxEngravingChars" bson:"maxEngravingChars"`
	EngravingPrice          float64            `json:"engravingPrice" bson:"engravingPrice"`                                       // Price for engraving service
	MinThickness            *float64           `json:"minThickness,omitempty" bson:"minThickness,omitempty"`
	MaxThickness            *float64           `json:"maxThickness,omitempty" bson:"maxThickness,omitempty"`
	// Price modifiers for customization options
	MetalPriceModifiers     map[string]float64 `json:"metalPriceModifiers,omitempty" bson:"metalPriceModifiers,omitempty"`         // Metal -> price modifier
	PlatingPriceModifiers   map[string]float64 `json:"platingPriceModifiers,omitempty" bson:"platingPriceModifiers,omitempty"`     // Plating color -> price modifier
	CreatedAt      time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt      time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// Review represents a product review
type Review struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId" validate:"required"`
	UserName  string            `json:"userName" bson:"userName" validate:"required,min=2,max=100"`
	ProductID primitive.ObjectID `json:"productId" bson:"productId" validate:"required"`
	Rating    float64           `json:"rating" bson:"rating" validate:"required,min=1,max=5"`
	Comment   string            `json:"comment" bson:"comment" validate:"required,min=10,max=1000"`
	Images    []string          `json:"images" bson:"images"`
	IsVerified bool             `json:"isVerified" bson:"isVerified"`
	CreatedAt time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// CreateProductRequest represents the request to create a new product
type CreateProductRequest struct {
	Name          string    `json:"name" validate:"required,min=2,max=200"`
	Description   string    `json:"description" validate:"required,min=10,max=2000"`
	Price         float64   `json:"price" validate:"required,min=0"`
	OriginalPrice *float64  `json:"originalPrice,omitempty"`
	Images        []string  `json:"images" validate:"required,min=1"`
	Videos        []string  `json:"videos,omitempty"`
	Category      string    `json:"category" validate:"required"`
	Subcategory   string    `json:"subcategory" validate:"required"`
	MetalType     string    `json:"metalType" validate:"required"`
	StoneType     *string   `json:"stoneType,omitempty"`
	Weight        *float64  `json:"weight,omitempty"`
	Size          *string   `json:"size,omitempty"`
	StockType     StockType `json:"stockType"`                              // "stocked" or "made_to_order"
	StockQuantity int       `json:"stockQuantity" validate:"min=0"`
	Tags          []string  `json:"tags"`
	Gender        []string  `json:"gender"`
	IsAvailable   bool      `json:"isAvailable"`
	IsFeatured    bool      `json:"isFeatured"`
	// Customization options (legacy)
	AvailableColors       []string `json:"availableColors,omitempty"`
	AvailablePolishTypes  []string `json:"availablePolishTypes,omitempty"`
	AvailableStoneColors  []string `json:"availableStoneColors,omitempty"`
	AvailableGemstones    []string `json:"availableGemstones,omitempty"`
	// Enhanced customization options
	AvailableMetals         []string           `json:"availableMetals,omitempty"`
	AvailablePlatingColors  []string           `json:"availablePlatingColors,omitempty"`
	Stones                  []StoneConfig      `json:"stones,omitempty"`
	AvailableSizes          []string           `json:"availableSizes,omitempty"`
	EngravingEnabled        bool               `json:"engravingEnabled"`
	MaxEngravingChars       int                `json:"maxEngravingChars"`
	EngravingPrice          float64            `json:"engravingPrice"`
	MinThickness            *float64           `json:"minThickness,omitempty"`
	MaxThickness            *float64           `json:"maxThickness,omitempty"`
	// Price modifiers
	MetalPriceModifiers     map[string]float64 `json:"metalPriceModifiers,omitempty"`
	PlatingPriceModifiers   map[string]float64 `json:"platingPriceModifiers,omitempty"`
}

// UpdateProductRequest represents the request to update a product
type UpdateProductRequest struct {
	Name          *string    `json:"name,omitempty" validate:"omitempty,min=2,max=200"`
	Description   *string    `json:"description,omitempty" validate:"omitempty,min=10,max=2000"`
	Price         *float64   `json:"price,omitempty" validate:"omitempty,min=0"`
	OriginalPrice *float64   `json:"originalPrice,omitempty"`
	Images        []string   `json:"images,omitempty" validate:"omitempty,min=1"`
	Videos        []string   `json:"videos,omitempty"`
	Category      *string    `json:"category,omitempty"`
	Subcategory   *string    `json:"subcategory,omitempty"`
	MetalType     *string    `json:"metalType,omitempty"`
	StoneType     *string    `json:"stoneType,omitempty"`
	Weight        *float64   `json:"weight,omitempty"`
	Size          *string    `json:"size,omitempty"`
	StockType     *StockType `json:"stockType,omitempty"`                         // "stocked" or "made_to_order"
	StockQuantity *int       `json:"stockQuantity,omitempty" validate:"omitempty,min=0"`
	Tags          []string  `json:"tags,omitempty"`
	Gender        []string  `json:"gender,omitempty"`
	IsAvailable   *bool     `json:"isAvailable,omitempty"`
	IsFeatured    *bool     `json:"isFeatured,omitempty"`
	// Customization options (legacy)
	AvailableColors       []string `json:"availableColors,omitempty"`
	AvailablePolishTypes  []string `json:"availablePolishTypes,omitempty"`
	AvailableStoneColors  []string `json:"availableStoneColors,omitempty"`
	AvailableGemstones    []string `json:"availableGemstones,omitempty"`
	// Enhanced customization options
	AvailableMetals         []string           `json:"availableMetals,omitempty"`
	AvailablePlatingColors  []string           `json:"availablePlatingColors,omitempty"`
	Stones                  []StoneConfig      `json:"stones,omitempty"`
	AvailableSizes          []string           `json:"availableSizes,omitempty"`
	EngravingEnabled        *bool              `json:"engravingEnabled,omitempty"`
	MaxEngravingChars       *int               `json:"maxEngravingChars,omitempty"`
	EngravingPrice          *float64           `json:"engravingPrice,omitempty"`
	MinThickness            *float64           `json:"minThickness,omitempty"`
	MaxThickness            *float64           `json:"maxThickness,omitempty"`
	// Price modifiers
	MetalPriceModifiers     map[string]float64 `json:"metalPriceModifiers,omitempty"`
	PlatingPriceModifiers   map[string]float64 `json:"platingPriceModifiers,omitempty"`
}

// CreateReviewRequest represents the request to create a product review
type CreateReviewRequest struct {
	ProductID primitive.ObjectID `json:"productId" validate:"required"`
	Rating    float64           `json:"rating" validate:"required,min=1,max=5"`
	Comment   string            `json:"comment" validate:"required,min=10,max=1000"`
	Images    []string          `json:"images"`
}

// UpdateReviewRequest represents the request to update a review
type UpdateReviewRequest struct {
	Rating  *float64 `json:"rating,omitempty" validate:"omitempty,min=1,max=5"`
	Comment *string  `json:"comment,omitempty" validate:"omitempty,min=10,max=1000"`
	Images  []string `json:"images,omitempty"`
}

// ProductFilter represents filters for product search
type ProductFilter struct {
	Category   string   `json:"category,omitempty"`
	Subcategory string   `json:"subcategory,omitempty"`
	MetalType  []string `json:"metalType,omitempty"`
	StoneType  []string `json:"stoneType,omitempty"`
	Gender     []string `json:"gender,omitempty"` // filter by gender: women, men, kids, inclusive
	MinPrice   *float64 `json:"minPrice,omitempty"`
	MaxPrice   *float64 `json:"maxPrice,omitempty"`
	MinRating  *float64 `json:"minRating,omitempty"`
	InStock    *bool    `json:"inStock,omitempty"`
	IsFeatured *bool    `json:"isFeatured,omitempty"`
	Tags       []string `json:"tags,omitempty"`
	Search     string   `json:"search,omitempty"`
	SortBy     string   `json:"sortBy,omitempty"` // price_low, price_high, rating, newest, popularity
	Page       int      `json:"page,omitempty"`
	Limit      int      `json:"limit,omitempty"`
}

// ProductListResponse represents the response for product listing
type ProductListResponse struct {
	Products   []Product `json:"products"`
	Total      int64     `json:"total"`
	Page       int       `json:"page"`
	Limit      int       `json:"limit"`
	TotalPages int       `json:"totalPages"`
}

// Category represents a product category
type Category struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name          string            `json:"name" bson:"name" validate:"required,min=2,max=100"`
	Slug          string            `json:"slug" bson:"slug" validate:"required,min=2,max=100"`
	Description   string            `json:"description" bson:"description"`
	Subcategories []string          `json:"subcategories" bson:"subcategories"`
	Image         string            `json:"image" bson:"image"`
	Gender        []string          `json:"gender" bson:"gender"` // ["all", "women", "men", "kids", "inclusive"]
	IsActive      bool              `json:"isActive" bson:"isActive"`
	SortOrder     int               `json:"sortOrder" bson:"sortOrder"`
	CreatedAt     time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt     time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// WishlistItem represents an item in user's wishlist
type WishlistItem struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId"`
	ProductID primitive.ObjectID `json:"productId" bson:"productId"`
	CreatedAt time.Time         `json:"createdAt" bson:"createdAt"`
}

// Wishlist represents a user's complete wishlist
type Wishlist struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId"`
	Items     []WishlistItem     `json:"items" bson:"items"`
	CreatedAt time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// Validate validates the product struct
func (p *Product) Validate() error {
    return v10.New().Struct(p)
}

// Validate validates the review struct
func (r *Review) Validate() error {
    return v10.New().Struct(r)
}

// Validate validates the create product request
func (r *CreateProductRequest) Validate() error {
    return v10.New().Struct(r)
}

// Validate validates the update product request
func (r *UpdateProductRequest) Validate() error {
    return v10.New().Struct(r)
}

// Validate validates the create review request
func (r *CreateReviewRequest) Validate() error {
    return v10.New().Struct(r)
}

// Validate validates the update review request
func (r *UpdateReviewRequest) Validate() error {
    return v10.New().Struct(r)
}

// Validate validates the category struct
func (c *Category) Validate() error {
    return v10.New().Struct(c)
}

// BulkCreateError represents an error that occurred during bulk product creation
type BulkCreateError struct {
	Index   int    `json:"index"`
	Product CreateProductRequest `json:"product"`
	Error   string `json:"error"`
}

// CalculateDiscount calculates the discount percentage
func (p *Product) CalculateDiscount() float64 {
	if p.OriginalPrice != nil && *p.OriginalPrice > p.Price {
		return ((*p.OriginalPrice - p.Price) / *p.OriginalPrice) * 100
	}
	return 0
}

// IsInStock checks if the product is in stock
// Made-to-order products are always considered in stock
func (p *Product) IsInStock() bool {
	if p.StockType == StockTypeMadeToOrder {
		return p.IsAvailable // Made-to-order products are always available if enabled
	}
	return p.IsAvailable && p.StockQuantity > 0
}

// UpdateRating updates the product rating based on reviews
func (p *Product) UpdateRating(rating float64, reviewCount int) {
	p.Rating = rating
	p.ReviewCount = reviewCount
}

// AddToStock adds quantity to stock
func (p *Product) AddToStock(quantity int) {
	p.StockQuantity += quantity
}

// RemoveFromStock removes quantity from stock
func (p *Product) RemoveFromStock(quantity int) bool {
	if p.StockQuantity >= quantity {
		p.StockQuantity -= quantity
		return true
	}
	return false
}

// ValidateCustomization validates a ProductCustomization against the product's available options
func (p *Product) ValidateCustomization(customization *ProductCustomization) error {
	if customization == nil {
		return nil
	}

	// Validate metal selection
	if customization.Metal != "" && len(p.AvailableMetals) > 0 {
		found := false
		for _, m := range p.AvailableMetals {
			if m == customization.Metal {
				found = true
				break
			}
		}
		if !found {
			return fmt.Errorf("invalid metal selection: %s", customization.Metal)
		}
	}

	// Validate plating color selection
	if customization.PlatingColor != "" && len(p.AvailablePlatingColors) > 0 {
		found := false
		for _, pc := range p.AvailablePlatingColors {
			if pc == customization.PlatingColor {
				found = true
				break
			}
		}
		if !found {
			return fmt.Errorf("invalid plating color selection: %s", customization.PlatingColor)
		}
	}

	// Validate stone color selections
	for stoneName, colorSelected := range customization.StoneColors {
		found := false
		for _, stone := range p.Stones {
			if stone.Name == stoneName {
				for _, availColor := range stone.AvailableColors {
					if availColor == colorSelected {
						found = true
						break
					}
				}
				break
			}
		}
		if !found {
			return fmt.Errorf("invalid stone color selection for %s: %s", stoneName, colorSelected)
		}
	}

	// Validate ring size selection
	if customization.RingSize != "" && len(p.AvailableSizes) > 0 {
		found := false
		for _, s := range p.AvailableSizes {
			if s == customization.RingSize {
				found = true
				break
			}
		}
		if !found {
			return fmt.Errorf("invalid ring size selection: %s", customization.RingSize)
		}
	}

	// Validate engraving
	if customization.Engraving != "" {
		if !p.EngravingEnabled {
			return fmt.Errorf("engraving is not available for this product")
		}
		if len(customization.Engraving) > p.MaxEngravingChars {
			return fmt.Errorf("engraving text exceeds maximum length of %d characters", p.MaxEngravingChars)
		}
	}

	return nil
}

// CalculateCustomizationPrice calculates the total price modifier for a customization
func (p *Product) CalculateCustomizationPrice(customization *ProductCustomization) float64 {
	if customization == nil {
		return 0
	}

	var total float64

	// Add metal price modifier
	if customization.Metal != "" && p.MetalPriceModifiers != nil {
		if modifier, ok := p.MetalPriceModifiers[customization.Metal]; ok {
			total += modifier
		}
	}

	// Add plating price modifier
	if customization.PlatingColor != "" && p.PlatingPriceModifiers != nil {
		if modifier, ok := p.PlatingPriceModifiers[customization.PlatingColor]; ok {
			total += modifier
		}
	}

	// Add stone color price modifiers
	for stoneName, colorSelected := range customization.StoneColors {
		for _, stone := range p.Stones {
			if stone.Name == stoneName && stone.ColorPriceModifiers != nil {
				if modifier, ok := stone.ColorPriceModifiers[colorSelected]; ok {
					total += modifier
				}
				break
			}
		}
	}

	// Add engraving price
	if customization.Engraving != "" && p.EngravingEnabled {
		total += p.EngravingPrice
	}

	return total
}

// GetCustomizedPrice returns the base price plus customization price modifier
func (p *Product) GetCustomizedPrice(customization *ProductCustomization) float64 {
	return p.Price + p.CalculateCustomizationPrice(customization)
}
