package models

import (
	"time"

	"github.com/go-playground/validator/v10"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CustomOrderStatus represents the status of a custom AI jewelry order
type CustomOrderStatus string

const (
	CustomOrderStatusPendingContact CustomOrderStatus = "pending_contact"
	CustomOrderStatusContacted      CustomOrderStatus = "contacted"
	CustomOrderStatusConfirmed      CustomOrderStatus = "confirmed"
	CustomOrderStatusProcessing     CustomOrderStatus = "processing"
	CustomOrderStatusShipped        CustomOrderStatus = "shipped"
	CustomOrderStatusDelivered      CustomOrderStatus = "delivered"
	CustomOrderStatusCancelled      CustomOrderStatus = "cancelled"
)

// CustomOrder represents a custom AI-generated jewelry order
type CustomOrder struct {
	ID              primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	OrderNumber     string             `json:"orderNumber" bson:"orderNumber"`
	UserID          primitive.ObjectID `json:"userId,omitempty" bson:"userId,omitempty"`
	GuestSessionID  string             `json:"guestSessionId,omitempty" bson:"guestSessionId,omitempty"`
	CustomerInfo    CustomerInfo       `json:"customerInfo" bson:"customerInfo" validate:"required"`
	DesignInfo      DesignInfo         `json:"designInfo" bson:"designInfo" validate:"required"`
	PriceInfo       PriceInfo          `json:"priceInfo" bson:"priceInfo"`
	Status          CustomOrderStatus  `json:"status" bson:"status"`
	AdminNotes      string             `json:"adminNotes,omitempty" bson:"adminNotes,omitempty"`
	ContactedAt     *time.Time         `json:"contactedAt,omitempty" bson:"contactedAt,omitempty"`
	ContactedBy     string             `json:"contactedBy,omitempty" bson:"contactedBy,omitempty"`
	ConfirmedAt     *time.Time         `json:"confirmedAt,omitempty" bson:"confirmedAt,omitempty"`
	ProcessingAt    *time.Time         `json:"processingAt,omitempty" bson:"processingAt,omitempty"`
	ShippedAt       *time.Time         `json:"shippedAt,omitempty" bson:"shippedAt,omitempty"`
	DeliveredAt     *time.Time         `json:"deliveredAt,omitempty" bson:"deliveredAt,omitempty"`
	CancelledAt     *time.Time         `json:"cancelledAt,omitempty" bson:"cancelledAt,omitempty"`
	CancelReason    string             `json:"cancelReason,omitempty" bson:"cancelReason,omitempty"`
	TrackingNumber  string             `json:"trackingNumber,omitempty" bson:"trackingNumber,omitempty"`
	CreatedAt       time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// CustomerInfo represents customer contact information
type CustomerInfo struct {
	Name  string `json:"name" bson:"name" validate:"required"`
	Phone string `json:"phone" bson:"phone" validate:"required"`
	Email string `json:"email" bson:"email" validate:"required,email"`
	Notes string `json:"notes,omitempty" bson:"notes,omitempty"`
}

// DesignInfo represents the AI-generated design information
type DesignInfo struct {
	Prompt      string   `json:"prompt" bson:"prompt" validate:"required"`
	ImageURL    string   `json:"imageUrl" bson:"imageUrl" validate:"required"`
	JewelryType string   `json:"jewelryType,omitempty" bson:"jewelryType,omitempty"`
	Metal       string   `json:"metal,omitempty" bson:"metal,omitempty"`
	Style       string   `json:"style,omitempty" bson:"style,omitempty"`
	Stones      []string `json:"stones,omitempty" bson:"stones,omitempty"`
}

// PriceInfo represents pricing information
type PriceInfo struct {
	EstimatedPrice float64 `json:"estimatedPrice" bson:"estimatedPrice"`
	FinalPrice     float64 `json:"finalPrice,omitempty" bson:"finalPrice,omitempty"`
	Currency       string  `json:"currency" bson:"currency"`
}

// CreateCustomOrderRequest represents the request to create a custom order
type CreateCustomOrderRequest struct {
	CustomerInfo CustomerInfo `json:"customerInfo" validate:"required"`
	DesignInfo   DesignInfo   `json:"designInfo" validate:"required"`
	PriceInfo    PriceInfo    `json:"priceInfo"`
}

// UpdateCustomOrderStatusRequest represents the request to update custom order status
type UpdateCustomOrderStatusRequest struct {
	Status         CustomOrderStatus `json:"status" validate:"required"`
	AdminNotes     string            `json:"adminNotes,omitempty"`
	FinalPrice     float64           `json:"finalPrice,omitempty"`
	TrackingNumber string            `json:"trackingNumber,omitempty"`
	CancelReason   string            `json:"cancelReason,omitempty"`
}

// MarkContactedRequest represents the request to mark an order as contacted
type MarkContactedRequest struct {
	ContactedBy string `json:"contactedBy" validate:"required"`
	AdminNotes  string `json:"adminNotes,omitempty"`
}

// ConfirmOrderRequest represents the request to confirm an order
type ConfirmOrderRequest struct {
	FinalPrice float64 `json:"finalPrice" validate:"required,min=0"`
	AdminNotes string  `json:"adminNotes,omitempty"`
}

// CustomOrderListResponse represents the response for custom order listing
type CustomOrderListResponse struct {
	Orders     []CustomOrder `json:"orders"`
	Total      int64         `json:"total"`
	Page       int           `json:"page"`
	Limit      int           `json:"limit"`
	TotalPages int           `json:"totalPages"`
}

// CustomOrderFilter represents filters for custom order search
type CustomOrderFilter struct {
	Status   *CustomOrderStatus  `json:"status,omitempty"`
	UserID   *primitive.ObjectID `json:"userId,omitempty"`
	DateFrom *time.Time          `json:"dateFrom,omitempty"`
	DateTo   *time.Time          `json:"dateTo,omitempty"`
	Page     int                 `json:"page,omitempty"`
	Limit    int                 `json:"limit,omitempty"`
}

// Validate validates the custom order struct
func (o *CustomOrder) Validate() error {
	validate := validator.New()
	return validate.Struct(o)
}

// Validate validates the create custom order request
func (r *CreateCustomOrderRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the update custom order status request
func (r *UpdateCustomOrderStatusRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// GetDisplayStatus returns a human-readable status
func (o *CustomOrder) GetDisplayStatus() string {
	switch o.Status {
	case CustomOrderStatusPendingContact:
		return "Pending Contact"
	case CustomOrderStatusContacted:
		return "Contacted"
	case CustomOrderStatusConfirmed:
		return "Confirmed"
	case CustomOrderStatusProcessing:
		return "Processing"
	case CustomOrderStatusShipped:
		return "Shipped"
	case CustomOrderStatusDelivered:
		return "Delivered"
	case CustomOrderStatusCancelled:
		return "Cancelled"
	default:
		return "Unknown"
	}
}

// MarkAsContacted marks the order as contacted
func (o *CustomOrder) MarkAsContacted(contactedBy string) {
	o.Status = CustomOrderStatusContacted
	now := time.Now()
	o.ContactedAt = &now
	o.ContactedBy = contactedBy
	o.UpdatedAt = now
}

// Confirm confirms the order with final price
func (o *CustomOrder) Confirm(finalPrice float64) {
	o.Status = CustomOrderStatusConfirmed
	o.PriceInfo.FinalPrice = finalPrice
	now := time.Now()
	o.ConfirmedAt = &now
	o.UpdatedAt = now
}

// StartProcessing starts processing the order
func (o *CustomOrder) StartProcessing() {
	o.Status = CustomOrderStatusProcessing
	now := time.Now()
	o.ProcessingAt = &now
	o.UpdatedAt = now
}

// Ship marks the order as shipped
func (o *CustomOrder) Ship(trackingNumber string) {
	o.Status = CustomOrderStatusShipped
	o.TrackingNumber = trackingNumber
	now := time.Now()
	o.ShippedAt = &now
	o.UpdatedAt = now
}

// MarkDelivered marks the order as delivered
func (o *CustomOrder) MarkDelivered() {
	o.Status = CustomOrderStatusDelivered
	now := time.Now()
	o.DeliveredAt = &now
	o.UpdatedAt = now
}

// Cancel cancels the order
func (o *CustomOrder) Cancel(reason string) {
	o.Status = CustomOrderStatusCancelled
	o.CancelReason = reason
	now := time.Now()
	o.CancelledAt = &now
	o.UpdatedAt = now
}
