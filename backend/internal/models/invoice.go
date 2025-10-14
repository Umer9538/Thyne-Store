package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Invoice represents an invoice generated for an order
type Invoice struct {
	ID              primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	InvoiceNumber   string            `json:"invoiceNumber" bson:"invoiceNumber" validate:"required"`
	OrderID         primitive.ObjectID `json:"orderId" bson:"orderId" validate:"required"`
	UserID          primitive.ObjectID `json:"userId" bson:"userId"`
	GuestSessionID  string            `json:"guestSessionId,omitempty" bson:"guestSessionId,omitempty"`
	InvoiceDate     time.Time         `json:"invoiceDate" bson:"invoiceDate"`
	DueDate         *time.Time        `json:"dueDate,omitempty" bson:"dueDate,omitempty"`
	Status          InvoiceStatus     `json:"status" bson:"status"`
	Subtotal        float64           `json:"subtotal" bson:"subtotal"`
	Tax             float64           `json:"tax" bson:"tax"`
	Shipping        float64           `json:"shipping" bson:"shipping"`
	Discount        float64           `json:"discount" bson:"discount"`
	Total           float64           `json:"total" bson:"total"`
	Currency        string            `json:"currency" bson:"currency"`
	Notes           string            `json:"notes,omitempty" bson:"notes,omitempty"`
	PDFUrl          string            `json:"pdfUrl,omitempty" bson:"pdfUrl,omitempty"`
	IsDownloaded    bool              `json:"isDownloaded" bson:"isDownloaded"`
	DownloadedAt    *time.Time        `json:"downloadedAt,omitempty" bson:"downloadedAt,omitempty"`
	CreatedAt       time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// InvoiceStatus represents the status of an invoice
type InvoiceStatus string

const (
	InvoiceStatusDraft     InvoiceStatus = "draft"
	InvoiceStatusIssued    InvoiceStatus = "issued"
	InvoiceStatusPaid      InvoiceStatus = "paid"
	InvoiceStatusOverdue   InvoiceStatus = "overdue"
	InvoiceStatusCancelled InvoiceStatus = "cancelled"
	InvoiceStatusRefunded  InvoiceStatus = "refunded"
)

// InvoiceListResponse represents the response for invoice listing
type InvoiceListResponse struct {
	Invoices   []Invoice `json:"invoices"`
	Total      int64     `json:"total"`
	Page       int       `json:"page"`
	Limit      int       `json:"limit"`
	TotalPages int       `json:"totalPages"`
}

// InvoiceFilter represents filters for invoice search
type InvoiceFilter struct {
	UserID         *primitive.ObjectID `json:"userId,omitempty"`
	GuestSessionID *string             `json:"guestSessionId,omitempty"`
	OrderID        *primitive.ObjectID `json:"orderId,omitempty"`
	Status         *InvoiceStatus      `json:"status,omitempty"`
	DateFrom       *time.Time          `json:"dateFrom,omitempty"`
	DateTo         *time.Time          `json:"dateTo,omitempty"`
	InvoiceNumber  *string             `json:"invoiceNumber,omitempty"`
	Page           int                 `json:"page,omitempty"`
	Limit          int                 `json:"limit,omitempty"`
}

// CreateInvoiceRequest represents the request to create an invoice
type CreateInvoiceRequest struct {
	OrderID string `json:"orderId" validate:"required"`
	Notes   string `json:"notes,omitempty"`
}

// GenerateInvoiceResponse represents the response after generating an invoice
type GenerateInvoiceResponse struct {
	Invoice       Invoice `json:"invoice"`
	DownloadUrl   string  `json:"downloadUrl"`
	Message       string  `json:"message"`
}

// GetDisplayStatus returns a human-readable status
func (i *Invoice) GetDisplayStatus() string {
	switch i.Status {
	case InvoiceStatusDraft:
		return "Draft"
	case InvoiceStatusIssued:
		return "Issued"
	case InvoiceStatusPaid:
		return "Paid"
	case InvoiceStatusOverdue:
		return "Overdue"
	case InvoiceStatusCancelled:
		return "Cancelled"
	case InvoiceStatusRefunded:
		return "Refunded"
	default:
		return "Unknown"
	}
}

// MarkAsDownloaded marks the invoice as downloaded
func (i *Invoice) MarkAsDownloaded() {
	i.IsDownloaded = true
	now := time.Now()
	i.DownloadedAt = &now
	i.UpdatedAt = now
}

// UpdateStatus updates the invoice status
func (i *Invoice) UpdateStatus(status InvoiceStatus) {
	i.Status = status
	i.UpdatedAt = time.Now()
}
