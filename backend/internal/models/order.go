package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"gopkg.in/validator.v2"
)

// OrderStatus represents the status of an order
type OrderStatus string

const (
	OrderStatusPending       OrderStatus = "pending"
	OrderStatusConfirmed     OrderStatus = "confirmed"
	OrderStatusProcessing    OrderStatus = "processing"
	OrderStatusShipped       OrderStatus = "shipped"
	OrderStatusOutForDelivery OrderStatus = "out_for_delivery"
	OrderStatusDelivered     OrderStatus = "delivered"
	OrderStatusCancelled     OrderStatus = "cancelled"
	OrderStatusReturned      OrderStatus = "returned"
)

// PaymentStatus represents the payment status
type PaymentStatus string

const (
	PaymentStatusPending   PaymentStatus = "pending"
	PaymentStatusPaid      PaymentStatus = "paid"
	PaymentStatusFailed    PaymentStatus = "failed"
	PaymentStatusRefunded  PaymentStatus = "refunded"
	PaymentStatusCancelled PaymentStatus = "cancelled"
)

// PaymentMethod represents the payment method
type PaymentMethod string

const (
	PaymentMethodRazorpay PaymentMethod = "razorpay"
	PaymentMethodUPI      PaymentMethod = "upi"
	PaymentMethodWallet   PaymentMethod = "wallet"
	PaymentMethodCOD      PaymentMethod = "cod"
)

// Order represents an order in the system
type Order struct {
	ID                 primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	OrderNumber        string            `json:"orderNumber" bson:"orderNumber" validate:"required"`
	UserID             primitive.ObjectID `json:"userId,omitempty" bson:"userId,omitempty"`
	GuestSessionID     string            `json:"guestSessionId,omitempty" bson:"guestSessionId,omitempty"`
	Items              []OrderItem       `json:"items" bson:"items" validate:"required,min=1"`
	ShippingAddress    Address           `json:"shippingAddress" bson:"shippingAddress" validate:"required"`
	PaymentMethod      PaymentMethod     `json:"paymentMethod" bson:"paymentMethod" validate:"required"`
	PaymentStatus      PaymentStatus     `json:"paymentStatus" bson:"paymentStatus"`
	RazorpayOrderID    *string           `json:"razorpayOrderId,omitempty" bson:"razorpayOrderId,omitempty"`
	RazorpayPaymentID  *string           `json:"razorpayPaymentId,omitempty" bson:"razorpayPaymentId,omitempty"`
	Status             OrderStatus       `json:"status" bson:"status"`
	Subtotal           float64           `json:"subtotal" bson:"subtotal" validate:"required,min=0"`
	Tax                float64           `json:"tax" bson:"tax" validate:"required,min=0"`
	Shipping           float64           `json:"shipping" bson:"shipping" validate:"required,min=0"`
	Discount           float64           `json:"discount" bson:"discount" validate:"min=0"`
	Total              float64           `json:"total" bson:"total" validate:"required,min=0"`
	TrackingNumber     *string           `json:"trackingNumber,omitempty" bson:"trackingNumber,omitempty"`
	CreatedAt          time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt          time.Time         `json:"updatedAt" bson:"updatedAt"`
	DeliveredAt        *time.Time        `json:"deliveredAt,omitempty" bson:"deliveredAt,omitempty"`
	ProcessedAt        *time.Time        `json:"processedAt,omitempty" bson:"processedAt,omitempty"`
	ShippedAt          *time.Time        `json:"shippedAt,omitempty" bson:"shippedAt,omitempty"`
	CancellationReason *string           `json:"cancellationReason,omitempty" bson:"cancellationReason,omitempty"`
	ReturnReason       *string           `json:"returnReason,omitempty" bson:"returnReason,omitempty"`
	RefundStatus       *string           `json:"refundStatus,omitempty" bson:"refundStatus,omitempty"`
	RefundAmount       *float64          `json:"refundAmount,omitempty" bson:"refundAmount,omitempty"`
	RefundedAt         *time.Time        `json:"refundedAt,omitempty" bson:"refundedAt,omitempty"`
}

// OrderItem represents an item in an order
type OrderItem struct {
	ProductID primitive.ObjectID `json:"productId" bson:"productId" validate:"required"`
	Quantity  int               `json:"quantity" bson:"quantity" validate:"required,min=1"`
	Price     float64           `json:"price" bson:"price" validate:"required,min=0"`
	Name      string            `json:"name" bson:"name" validate:"required"`
	Image     string            `json:"image" bson:"image"`
}

// CreateOrderRequest represents the request to create an order
type CreateOrderRequest struct {
	Items           []OrderItem   `json:"items" validate:"required,min=1"`
	ShippingAddress Address       `json:"shippingAddress" validate:"required"`
	PaymentMethod   PaymentMethod `json:"paymentMethod" validate:"required"`
	CouponCode      *string       `json:"couponCode,omitempty"`
}

// UpdateOrderStatusRequest represents the request to update order status
type UpdateOrderStatusRequest struct {
	Status          OrderStatus   `json:"status" validate:"required"`
	TrackingNumber  *string       `json:"trackingNumber,omitempty"`
	PaymentStatus   *PaymentStatus `json:"paymentStatus,omitempty"`
	RazorpayOrderID *string       `json:"razorpayOrderId,omitempty"`
	RazorpayPaymentID *string     `json:"razorpayPaymentId,omitempty"`
}

// OrderListResponse represents the response for order listing
type OrderListResponse struct {
	Orders     []Order `json:"orders"`
	Total      int64   `json:"total"`
	Page       int     `json:"page"`
	Limit      int     `json:"limit"`
	TotalPages int     `json:"totalPages"`
}

// OrderFilter represents filters for order search
type OrderFilter struct {
	UserID        *primitive.ObjectID `json:"userId,omitempty"`
	GuestSessionID *string            `json:"guestSessionId,omitempty"`
	Status        *OrderStatus        `json:"status,omitempty"`
	PaymentStatus *PaymentStatus      `json:"paymentStatus,omitempty"`
	PaymentMethod *PaymentMethod      `json:"paymentMethod,omitempty"`
	DateFrom      *time.Time          `json:"dateFrom,omitempty"`
	DateTo        *time.Time          `json:"dateTo,omitempty"`
	OrderNumber   *string             `json:"orderNumber,omitempty"`
	Page          int                 `json:"page,omitempty"`
	Limit         int                 `json:"limit,omitempty"`
}

// Validate validates the order struct
func (o *Order) Validate() error {
	return validator.Validate(o)
}

// Validate validates the order item struct
func (oi *OrderItem) Validate() error {
	return validator.Validate(oi)
}

// Validate validates the create order request
func (r *CreateOrderRequest) Validate() error {
	return validator.Validate(r)
}

// Validate validates the update order status request
func (r *UpdateOrderStatusRequest) Validate() error {
	return validator.Validate(r)
}

// IsCancellable checks if the order can be cancelled
func (o *Order) IsCancellable() bool {
	return o.Status == OrderStatusPending || 
		   o.Status == OrderStatusConfirmed || 
		   o.Status == OrderStatusProcessing
}

// IsRefundable checks if the order can be refunded
func (o *Order) IsRefundable() bool {
	return o.Status == OrderStatusDelivered && 
		   o.PaymentStatus == PaymentStatusPaid
}

// CanBeDelivered checks if the order can be marked as delivered
func (o *Order) CanBeDelivered() bool {
	return o.Status == OrderStatusOutForDelivery
}

// CanBeShipped checks if the order can be shipped
func (o *Order) CanBeShipped() bool {
	return o.Status == OrderStatusConfirmed || 
		   o.Status == OrderStatusProcessing
}

// GetDisplayStatus returns a human-readable status
func (o *Order) GetDisplayStatus() string {
	switch o.Status {
	case OrderStatusPending:
		return "Pending"
	case OrderStatusConfirmed:
		return "Confirmed"
	case OrderStatusProcessing:
		return "Processing"
	case OrderStatusShipped:
		return "Shipped"
	case OrderStatusOutForDelivery:
		return "Out for Delivery"
	case OrderStatusDelivered:
		return "Delivered"
	case OrderStatusCancelled:
		return "Cancelled"
	case OrderStatusReturned:
		return "Returned"
	default:
		return "Unknown"
	}
}

// GetDisplayPaymentStatus returns a human-readable payment status
func (o *Order) GetDisplayPaymentStatus() string {
	switch o.PaymentStatus {
	case PaymentStatusPending:
		return "Pending"
	case PaymentStatusPaid:
		return "Paid"
	case PaymentStatusFailed:
		return "Failed"
	case PaymentStatusRefunded:
		return "Refunded"
	case PaymentStatusCancelled:
		return "Cancelled"
	default:
		return "Unknown"
	}
}

// GetDisplayPaymentMethod returns a human-readable payment method
func (o *Order) GetDisplayPaymentMethod() string {
	switch o.PaymentMethod {
	case PaymentMethodRazorpay:
		return "Credit/Debit Card"
	case PaymentMethodUPI:
		return "UPI Payment"
	case PaymentMethodWallet:
		return "Digital Wallet"
	case PaymentMethodCOD:
		return "Cash on Delivery"
	default:
		return "Unknown"
	}
}

// CalculateItemTotal calculates the total for all items in the order
func (o *Order) CalculateItemTotal() float64 {
	total := 0.0
	for _, item := range o.Items {
		total += item.Price * float64(item.Quantity)
	}
	return total
}

// UpdateStatus updates the order status and sets appropriate timestamps
func (o *Order) UpdateStatus(status OrderStatus) {
	o.Status = status
	o.UpdatedAt = time.Now()
	
	now := time.Now()
	switch status {
	case OrderStatusProcessing:
		if o.ProcessedAt == nil {
			o.ProcessedAt = &now
		}
	case OrderStatusShipped:
		if o.ShippedAt == nil {
			o.ShippedAt = &now
		}
	case OrderStatusDelivered:
		if o.DeliveredAt == nil {
			o.DeliveredAt = &now
		}
	}
}

// MarkAsPaid marks the order as paid with payment details
func (o *Order) MarkAsPaid(paymentID, razorpayOrderID, razorpayPaymentID string) {
	o.PaymentStatus = PaymentStatusPaid
	o.RazorpayPaymentID = &paymentID
	o.RazorpayOrderID = &razorpayOrderID
	o.RazorpayPaymentID = &razorpayPaymentID
	o.UpdatedAt = time.Now()
}

// MarkAsFailed marks the order payment as failed
func (o *Order) MarkAsFailed() {
	o.PaymentStatus = PaymentStatusFailed
	o.UpdatedAt = time.Now()
}

// Cancel cancels the order
func (o *Order) Cancel(reason string) {
	o.Status = OrderStatusCancelled
	o.PaymentStatus = PaymentStatusCancelled
	o.CancellationReason = &reason
	o.UpdatedAt = time.Now()
}

// Refund refunds the order
func (o *Order) Refund(reason string) {
	o.PaymentStatus = PaymentStatusRefunded
	o.Status = OrderStatusReturned
	o.ReturnReason = &reason
	o.RefundAmount = &o.Total
	now := time.Now()
	o.RefundedAt = &now
	o.UpdatedAt = now
}
