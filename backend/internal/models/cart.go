package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"github.com/go-playground/validator/v10"
)

// Cart represents a shopping cart
type Cart struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID         primitive.ObjectID `json:"userId,omitempty" bson:"userId,omitempty"`
	GuestSessionID string            `json:"guestSessionId,omitempty" bson:"guestSessionId,omitempty"`
	Items          []CartItem        `json:"items" bson:"items"`
	CouponCode     *string           `json:"couponCode,omitempty" bson:"couponCode,omitempty"`
	Discount       float64           `json:"discount" bson:"discount"`
	CreatedAt      time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt      time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// CartItem represents an item in the cart
type CartItem struct {
	ProductID primitive.ObjectID `json:"productId" bson:"productId" validate:"required"`
	Quantity  int               `json:"quantity" bson:"quantity" validate:"required,min=1"`
	AddedAt   time.Time         `json:"addedAt" bson:"addedAt"`
}

// AddToCartRequest represents the request to add item to cart
type AddToCartRequest struct {
	ProductID primitive.ObjectID `json:"productId" validate:"required"`
	Quantity  int               `json:"quantity" validate:"required,min=1,max=10"`
}

// UpdateCartItemRequest represents the request to update cart item quantity
type UpdateCartItemRequest struct {
	ProductID primitive.ObjectID `json:"productId" validate:"required"`
	Quantity  int               `json:"quantity" validate:"required,min=1,max=10"`
}

// RemoveFromCartRequest represents the request to remove item from cart
type RemoveFromCartRequest struct {
	ProductID primitive.ObjectID `json:"productId" validate:"required"`
}

// ApplyCouponRequest represents the request to apply coupon code
type ApplyCouponRequest struct {
	CouponCode string `json:"couponCode" validate:"required,min=3,max=20"`
}

// Coupon represents a discount coupon
type Coupon struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Code        string            `json:"code" bson:"code" validate:"required,min=3,max=20"`
	Name        string            `json:"name" bson:"name" validate:"required,min=2,max=100"`
	Description string            `json:"description" bson:"description"`
	Type        string            `json:"type" bson:"type" validate:"required"` // percentage, fixed
	Value       float64           `json:"value" bson:"value" validate:"required,min=0"`
	MinAmount   *float64          `json:"minAmount,omitempty" bson:"minAmount,omitempty"`
	MaxDiscount *float64          `json:"maxDiscount,omitempty" bson:"maxDiscount,omitempty"`
	UsageLimit  *int              `json:"usageLimit,omitempty" bson:"usageLimit,omitempty"`
	UsedCount   int               `json:"usedCount" bson:"usedCount"`
	IsActive    bool              `json:"isActive" bson:"isActive"`
	ValidFrom   time.Time         `json:"validFrom" bson:"validFrom"`
	ValidUntil  time.Time         `json:"validUntil" bson:"validUntil"`
	CreatedAt   time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// CreateCouponRequest represents the request to create a coupon
type CreateCouponRequest struct {
	Code        string    `json:"code" validate:"required,min=3,max=20"`
	Name        string    `json:"name" validate:"required,min=2,max=100"`
	Description string    `json:"description"`
	Type        string    `json:"type" validate:"required,oneof=percentage fixed"`
	Value       float64   `json:"value" validate:"required,min=0"`
	MinAmount   *float64  `json:"minAmount,omitempty"`
	MaxDiscount *float64  `json:"maxDiscount,omitempty"`
	UsageLimit  *int      `json:"usageLimit,omitempty"`
	ValidFrom   time.Time `json:"validFrom" validate:"required"`
	ValidUntil  time.Time `json:"validUntil" validate:"required"`
}

// CartSummary represents the cart summary for checkout
type CartSummary struct {
	Subtotal    float64 `json:"subtotal"`
	Tax         float64 `json:"tax"`
	Shipping    float64 `json:"shipping"`
	Discount    float64 `json:"discount"`
	Total       float64 `json:"total"`
	ItemCount   int     `json:"itemCount"`
	CouponCode  *string `json:"couponCode,omitempty"`
}

// Validate validates the cart item struct
func (ci *CartItem) Validate() error {
	validate := validator.New()
	return validate.Struct(ci)
}

// Validate validates the add to cart request
func (r *AddToCartRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the update cart item request
func (r *UpdateCartItemRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the remove from cart request
func (r *RemoveFromCartRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the apply coupon request
func (r *ApplyCouponRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the coupon struct
func (c *Coupon) Validate() error {
	validate := validator.New()
	return validate.Struct(c)
}

// Validate validates the create coupon request
func (r *CreateCouponRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// IsValid checks if the coupon is valid for use
func (c *Coupon) IsValid() bool {
	now := time.Now()
	return c.IsActive && 
		   now.After(c.ValidFrom) && 
		   now.Before(c.ValidUntil) &&
		   (c.UsageLimit == nil || c.UsedCount < *c.UsageLimit)
}

// CanApply checks if the coupon can be applied to the given amount
func (c *Coupon) CanApply(amount float64) bool {
	if !c.IsValid() {
		return false
	}
	if c.MinAmount != nil && amount < *c.MinAmount {
		return false
	}
	return true
}

// CalculateDiscount calculates the discount amount for the given cart total
func (c *Coupon) CalculateDiscount(cartTotal float64) float64 {
	if !c.CanApply(cartTotal) {
		return 0
	}

	var discount float64
	switch c.Type {
	case "percentage":
		discount = (cartTotal * c.Value) / 100
	case "fixed":
		discount = c.Value
	}

	// Apply max discount limit if specified
	if c.MaxDiscount != nil && discount > *c.MaxDiscount {
		discount = *c.MaxDiscount
	}

	// Don't allow discount to exceed cart total
	if discount > cartTotal {
		discount = cartTotal
	}

	return discount
}

// IncrementUsage increments the usage count of the coupon
func (c *Coupon) IncrementUsage() {
	c.UsedCount++
}

// GetItemCount returns the total number of items in the cart
func (c *Cart) GetItemCount() int {
	count := 0
	for _, item := range c.Items {
		count += item.Quantity
	}
	return count
}

// GetSubtotal calculates the subtotal of all items in the cart
func (c *Cart) GetSubtotal() float64 {
	// This would need to fetch product prices from the database
	// For now, returning 0 - this should be calculated in the service layer
	return 0
}

// ClearItems removes all items from the cart
func (c *Cart) ClearItems() {
	c.Items = []CartItem{}
	c.CouponCode = nil
	c.Discount = 0
}

// AddItem adds or updates an item in the cart
func (c *Cart) AddItem(productID primitive.ObjectID, quantity int) {
	for i, item := range c.Items {
		if item.ProductID == productID {
			c.Items[i].Quantity += quantity
			return
		}
	}
	c.Items = append(c.Items, CartItem{
		ProductID: productID,
		Quantity:  quantity,
		AddedAt:   time.Now(),
	})
}

// UpdateItemQuantity updates the quantity of an item in the cart
func (c *Cart) UpdateItemQuantity(productID primitive.ObjectID, quantity int) {
	for i, item := range c.Items {
		if item.ProductID == productID {
			if quantity <= 0 {
				c.RemoveItem(productID)
			} else {
				c.Items[i].Quantity = quantity
			}
			return
		}
	}
}

// RemoveItem removes an item from the cart
func (c *Cart) RemoveItem(productID primitive.ObjectID) {
	for i, item := range c.Items {
		if item.ProductID == productID {
			c.Items = append(c.Items[:i], c.Items[i+1:]...)
			return
		}
	}
}

// ApplyCoupon applies a coupon to the cart
func (c *Cart) ApplyCoupon(coupon *Coupon) {
	c.CouponCode = &coupon.Code
	c.Discount = coupon.CalculateDiscount(c.GetSubtotal())
}

// RemoveCoupon removes the applied coupon from the cart
func (c *Cart) RemoveCoupon() {
	c.CouponCode = nil
	c.Discount = 0
}
