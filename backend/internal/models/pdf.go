package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PDFDocument represents a generated PDF document
type PDFDocument struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Type         string             `json:"type" bson:"type"` // "invoice", "receipt", "warranty"
	OrderID      primitive.ObjectID `json:"orderId" bson:"orderId"`
	UserID       primitive.ObjectID `json:"userId" bson:"userId"`
	FileURL      string             `json:"fileUrl" bson:"fileUrl"`
	Filename     string             `json:"filename" bson:"filename"`
	Size         int64              `json:"size" bson:"size"`
	GeneratedAt  time.Time          `json:"generatedAt" bson:"generatedAt"`
	ExpiresAt    *time.Time         `json:"expiresAt,omitempty" bson:"expiresAt,omitempty"`
	DownloadedAt *time.Time         `json:"downloadedAt,omitempty" bson:"downloadedAt,omitempty"`
	IsActive     bool               `json:"isActive" bson:"isActive"`
}

// InvoiceData represents data structure for invoice generation
type InvoiceData struct {
	Order           Order           `json:"order"`
	User            User            `json:"user"`
	Company         CompanyInfo     `json:"company"`
	TaxDetails      TaxDetails      `json:"taxDetails"`
	PaymentDetails  PaymentInfo     `json:"paymentDetails"`
	ShippingDetails ShippingInfo    `json:"shippingDetails"`
	Items           []InvoiceItem   `json:"items"`
	Totals          InvoiceTotals   `json:"totals"`
	Notes           string          `json:"notes"`
	QRCode          string          `json:"qrCode"`
}

// InvoiceItem represents an item in the invoice
type InvoiceItem struct {
	ProductID    primitive.ObjectID `json:"productId"`
	ProductName  string             `json:"productName"`
	SKU          string             `json:"sku"`
	Quantity     int                `json:"quantity"`
	UnitPrice    float64            `json:"unitPrice"`
	TotalPrice   float64            `json:"totalPrice"`
	TaxRate      float64            `json:"taxRate"`
	TaxAmount    float64            `json:"taxAmount"`
	Description  string             `json:"description"`
	MetalType    string             `json:"metalType,omitempty"`
	GemstoneType string             `json:"gemstoneType,omitempty"`
	Weight       float64            `json:"weight,omitempty"`
	Purity       string             `json:"purity,omitempty"`
}

// InvoiceTotals represents totals for the invoice
type InvoiceTotals struct {
	Subtotal     float64 `json:"subtotal"`
	TaxAmount    float64 `json:"taxAmount"`
	ShippingCost float64 `json:"shippingCost"`
	Discount     float64 `json:"discount"`
	VoucherValue float64 `json:"voucherValue"`
	Total        float64 `json:"total"`
}

// CompanyInfo represents company information for invoices
type CompanyInfo struct {
	Name           string `json:"name"`
	Address        string `json:"address"`
	City           string `json:"city"`
	State          string `json:"state"`
	PostalCode     string `json:"postalCode"`
	Country        string `json:"country"`
	Phone          string `json:"phone"`
	Email          string `json:"email"`
	Website        string `json:"website"`
	TaxID          string `json:"taxId"`
	RegistrationNo string `json:"registrationNo"`
	LogoURL        string `json:"logoUrl"`
}

// TaxDetails represents tax calculation details
type TaxDetails struct {
	TaxType     string  `json:"taxType"` // "GST", "VAT", "Sales Tax"
	TaxRate     float64 `json:"taxRate"`
	TaxID       string  `json:"taxId"`
	TaxAddress  string  `json:"taxAddress"`
	CGST        float64 `json:"cgst,omitempty"`
	SGST        float64 `json:"sgst,omitempty"`
	IGST        float64 `json:"igst,omitempty"`
	HSNCode     string  `json:"hsnCode,omitempty"`
}

// PaymentInfo represents payment information for invoice
type PaymentInfo struct {
	Method          string    `json:"method"`
	TransactionID   string    `json:"transactionId"`
	PaymentDate     time.Time `json:"paymentDate"`
	PaymentStatus   string    `json:"paymentStatus"`
	Gateway         string    `json:"gateway"`
	GatewayFee      float64   `json:"gatewayFee"`
	CurrencyCode    string    `json:"currencyCode"`
	ExchangeRate    float64   `json:"exchangeRate,omitempty"`
}

// ShippingInfo represents shipping information for invoice
type ShippingInfo struct {
	Method       string    `json:"method"`
	TrackingID   string    `json:"trackingId"`
	Carrier      string    `json:"carrier"`
	EstimatedDate time.Time `json:"estimatedDate"`
	ActualDate   *time.Time `json:"actualDate,omitempty"`
	ShippingCost float64   `json:"shippingCost"`
	Insurance    float64   `json:"insurance"`
	Address      Address   `json:"address"`
}

// OrderTracking represents order tracking information
type OrderTracking struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	OrderID       primitive.ObjectID `json:"orderId" bson:"orderId"`
	TrackingID    string             `json:"trackingId" bson:"trackingId"`
	Carrier       string             `json:"carrier" bson:"carrier"`
	Service       string             `json:"service" bson:"service"`
	Status        string             `json:"status" bson:"status"`
	CurrentLocation string           `json:"currentLocation" bson:"currentLocation"`
	EstimatedDelivery time.Time      `json:"estimatedDelivery" bson:"estimatedDelivery"`
	ActualDelivery  *time.Time       `json:"actualDelivery,omitempty" bson:"actualDelivery,omitempty"`
	Events          []TrackingEvent  `json:"events" bson:"events"`
	CreatedAt       time.Time        `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time        `json:"updatedAt" bson:"updatedAt"`
}

// TrackingEvent represents a tracking event
type TrackingEvent struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Status      string             `json:"status" bson:"status"`
	Description string             `json:"description" bson:"description"`
	Location    string             `json:"location" bson:"location"`
	Timestamp   time.Time          `json:"timestamp" bson:"timestamp"`
	IsDelivered bool               `json:"isDelivered" bson:"isDelivered"`
	IsMilestone bool               `json:"isMilestone" bson:"isMilestone"`
	SignedBy    string             `json:"signedBy,omitempty" bson:"signedBy,omitempty"`
	Notes       string             `json:"notes,omitempty" bson:"notes,omitempty"`
}

// WarrantyInfo represents warranty information for jewelry
type WarrantyInfo struct {
	ID               primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	OrderID          primitive.ObjectID `json:"orderId" bson:"orderId"`
	ProductID        primitive.ObjectID `json:"productId" bson:"productId"`
	UserID           primitive.ObjectID `json:"userId" bson:"userId"`
	WarrantyNumber   string             `json:"warrantyNumber" bson:"warrantyNumber"`
	WarrantyType     string             `json:"warrantyType" bson:"warrantyType"` // "manufacturing", "extended", "lifetime"
	PurchaseDate     time.Time          `json:"purchaseDate" bson:"purchaseDate"`
	WarrantyStart    time.Time          `json:"warrantyStart" bson:"warrantyStart"`
	WarrantyEnd      time.Time          `json:"warrantyEnd" bson:"warrantyEnd"`
	CoverageDetails  []CoverageDetail   `json:"coverageDetails" bson:"coverageDetails"`
	CertificateURL   string             `json:"certificateUrl" bson:"certificateUrl"`
	Terms            []string           `json:"terms" bson:"terms"`
	Exclusions       []string           `json:"exclusions" bson:"exclusions"`
	IsActive         bool               `json:"isActive" bson:"isActive"`
	CreatedAt        time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt        time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// CoverageDetail represents what is covered under warranty
type CoverageDetail struct {
	Type        string `json:"type" bson:"type"` // "repair", "replacement", "cleaning", "resizing"
	Description string `json:"description" bson:"description"`
	MaxClaims   int    `json:"maxClaims" bson:"maxClaims"`
	UsedClaims  int    `json:"usedClaims" bson:"usedClaims"`
}

// WarrantyClaim represents a warranty claim
type WarrantyClaim struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	WarrantyID     primitive.ObjectID `json:"warrantyId" bson:"warrantyId"`
	ClaimNumber    string             `json:"claimNumber" bson:"claimNumber"`
	ClaimType      string             `json:"claimType" bson:"claimType"`
	Description    string             `json:"description" bson:"description"`
	Status         string             `json:"status" bson:"status"` // "submitted", "approved", "rejected", "completed"
	SubmittedAt    time.Time          `json:"submittedAt" bson:"submittedAt"`
	ProcessedAt    *time.Time         `json:"processedAt,omitempty" bson:"processedAt,omitempty"`
	CompletedAt    *time.Time         `json:"completedAt,omitempty" bson:"completedAt,omitempty"`
	RepairCost     float64            `json:"repairCost" bson:"repairCost"`
	Photos         []string           `json:"photos" bson:"photos"`
	AdminNotes     string             `json:"adminNotes" bson:"adminNotes"`
	UserNotes      string             `json:"userNotes" bson:"userNotes"`
	ResolutionType string             `json:"resolutionType" bson:"resolutionType"` // "repair", "replace", "refund"
}

// Certificate represents a jewelry certificate
type Certificate struct {
	ID              primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	OrderID         primitive.ObjectID `json:"orderId" bson:"orderId"`
	ProductID       primitive.ObjectID `json:"productId" bson:"productId"`
	CertificateType string             `json:"certificateType" bson:"certificateType"` // "authenticity", "appraisal", "grading"
	CertificateNo   string             `json:"certificateNo" bson:"certificateNo"`
	IssuingAuthority string            `json:"issuingAuthority" bson:"issuingAuthority"`
	IssueDate       time.Time          `json:"issueDate" bson:"issueDate"`
	ExpiryDate      *time.Time         `json:"expiryDate,omitempty" bson:"expiryDate,omitempty"`
	GradingDetails  GradingDetails     `json:"gradingDetails" bson:"gradingDetails"`
	CertificateURL  string             `json:"certificateUrl" bson:"certificateUrl"`
	QRCode          string             `json:"qrCode" bson:"qrCode"`
	IsVerified      bool               `json:"isVerified" bson:"isVerified"`
	CreatedAt       time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt       time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// GradingDetails represents jewelry grading information
type GradingDetails struct {
	MetalType     string             `json:"metalType" bson:"metalType"`
	MetalPurity   string             `json:"metalPurity" bson:"metalPurity"`
	Weight        float64            `json:"weight" bson:"weight"`
	Dimensions    string             `json:"dimensions" bson:"dimensions"`
	Gemstones     []GemstoneGrading  `json:"gemstones" bson:"gemstones"`
	Craftsmanship string             `json:"craftsmanship" bson:"craftsmanship"`
	Condition     string             `json:"condition" bson:"condition"`
	AppraisedValue float64           `json:"appraisedValue" bson:"appraisedValue"`
	InsuranceValue float64           `json:"insuranceValue" bson:"insuranceValue"`
}

// GemstoneGrading represents individual gemstone grading
type GemstoneGrading struct {
	Type        string  `json:"type" bson:"type"`
	Cut         string  `json:"cut" bson:"cut"`
	Color       string  `json:"color" bson:"color"`
	Clarity     string  `json:"clarity" bson:"clarity"`
	Carat       float64 `json:"carat" bson:"carat"`
	Origin      string  `json:"origin" bson:"origin"`
	Treatment   string  `json:"treatment" bson:"treatment"`
	Shape       string  `json:"shape" bson:"shape"`
	Measurements string `json:"measurements" bson:"measurements"`
}

// PDFTemplate represents a PDF template configuration
type PDFTemplate struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Type        string             `json:"type" bson:"type"` // "invoice", "receipt", "warranty", "certificate"
	Name        string             `json:"name" bson:"name"`
	Version     string             `json:"version" bson:"version"`
	Template    string             `json:"template" bson:"template"` // HTML template
	Styles      string             `json:"styles" bson:"styles"`     // CSS styles
	IsActive    bool               `json:"isActive" bson:"isActive"`
	IsDefault   bool               `json:"isDefault" bson:"isDefault"`
	CreatedBy   primitive.ObjectID `json:"createdBy" bson:"createdBy"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// EmailTemplate represents email template for PDF attachments
type EmailTemplate struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Type        string             `json:"type" bson:"type"` // "invoice_email", "warranty_email"
	Subject     string             `json:"subject" bson:"subject"`
	HTMLBody    string             `json:"htmlBody" bson:"htmlBody"`
	TextBody    string             `json:"textBody" bson:"textBody"`
	Variables   []string           `json:"variables" bson:"variables"`
	IsActive    bool               `json:"isActive" bson:"isActive"`
	CreatedBy   primitive.ObjectID `json:"createdBy" bson:"createdBy"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}