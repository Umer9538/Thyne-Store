package models

import (
    "time"

    "go.mongodb.org/mongo-driver/bson/primitive"
    v10 "github.com/go-playground/validator/v10"
)

// Product represents a jewelry product
type Product struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name           string            `json:"name" bson:"name" validate:"required,min=2,max=200"`
	Description    string            `json:"description" bson:"description" validate:"required,min=10,max=2000"`
	Price          float64           `json:"price" bson:"price" validate:"required,min=0"`
	OriginalPrice  *float64          `json:"originalPrice,omitempty" bson:"originalPrice,omitempty"`
	Images         []string          `json:"images" bson:"images" validate:"required,min=1"`
	Category       string            `json:"category" bson:"category" validate:"required"`
	Subcategory    string            `json:"subcategory" bson:"subcategory" validate:"required"`
	MetalType      string            `json:"metalType" bson:"metalType" validate:"required"`
	StoneType      *string           `json:"stoneType,omitempty" bson:"stoneType,omitempty"`
	Weight         *float64          `json:"weight,omitempty" bson:"weight,omitempty"`
	Size           *string           `json:"size,omitempty" bson:"size,omitempty"`
	StockQuantity  int               `json:"stockQuantity" bson:"stockQuantity" validate:"required,min=0"`
	Rating         float64           `json:"rating" bson:"rating" validate:"min=0,max=5"`
	ReviewCount    int               `json:"reviewCount" bson:"reviewCount" validate:"min=0"`
	Tags           []string          `json:"tags" bson:"tags"`
	IsAvailable    bool              `json:"isAvailable" bson:"isAvailable"`
	IsFeatured     bool              `json:"isFeatured" bson:"isFeatured"`
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
	Category      string    `json:"category" validate:"required"`
	Subcategory   string    `json:"subcategory" validate:"required"`
	MetalType     string    `json:"metalType" validate:"required"`
	StoneType     *string   `json:"stoneType,omitempty"`
	Weight        *float64  `json:"weight,omitempty"`
	Size          *string   `json:"size,omitempty"`
	StockQuantity int       `json:"stockQuantity" validate:"required,min=0"`
	Tags          []string  `json:"tags"`
	IsAvailable   bool      `json:"isAvailable"`
	IsFeatured    bool      `json:"isFeatured"`
}

// UpdateProductRequest represents the request to update a product
type UpdateProductRequest struct {
	Name          *string   `json:"name,omitempty" validate:"omitempty,min=2,max=200"`
	Description   *string   `json:"description,omitempty" validate:"omitempty,min=10,max=2000"`
	Price         *float64  `json:"price,omitempty" validate:"omitempty,min=0"`
	OriginalPrice *float64  `json:"originalPrice,omitempty"`
	Images        []string  `json:"images,omitempty" validate:"omitempty,min=1"`
	Category      *string   `json:"category,omitempty"`
	Subcategory   *string   `json:"subcategory,omitempty"`
	MetalType     *string   `json:"metalType,omitempty"`
	StoneType     *string   `json:"stoneType,omitempty"`
	Weight        *float64  `json:"weight,omitempty"`
	Size          *string   `json:"size,omitempty"`
	StockQuantity *int      `json:"stockQuantity,omitempty" validate:"omitempty,min=0"`
	Tags          []string  `json:"tags,omitempty"`
	IsAvailable   *bool     `json:"isAvailable,omitempty"`
	IsFeatured    *bool     `json:"isFeatured,omitempty"`
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
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name        string            `json:"name" bson:"name" validate:"required,min=2,max=100"`
	Slug        string            `json:"slug" bson:"slug" validate:"required,min=2,max=100"`
	Description string            `json:"description" bson:"description"`
	Image       string            `json:"image" bson:"image"`
	IsActive    bool              `json:"isActive" bson:"isActive"`
	SortOrder   int               `json:"sortOrder" bson:"sortOrder"`
	CreatedAt   time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time         `json:"updatedAt" bson:"updatedAt"`
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

// CalculateDiscount calculates the discount percentage
func (p *Product) CalculateDiscount() float64 {
	if p.OriginalPrice != nil && *p.OriginalPrice > p.Price {
		return ((*p.OriginalPrice - p.Price) / *p.OriginalPrice) * 100
	}
	return 0
}

// IsInStock checks if the product is in stock
func (p *Product) IsInStock() bool {
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
