package services

import (
	"context"
	"encoding/csv"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// InvoiceService defines the interface for invoice business logic
type InvoiceService interface {
	GenerateInvoice(ctx context.Context, orderID string) (*models.Invoice, error)
	GetInvoice(ctx context.Context, invoiceID string) (*models.Invoice, error)
	GetInvoiceByOrderID(ctx context.Context, orderID string) (*models.Invoice, error)
	GetInvoicesByUser(ctx context.Context, userID string, page, limit int) ([]models.Invoice, int64, error)
	GetInvoicesByGuestSession(ctx context.Context, guestSessionID string, page, limit int) ([]models.Invoice, int64, error)
	ListInvoices(ctx context.Context, filter *models.InvoiceFilter) ([]models.Invoice, int64, error)
	MarkAsDownloaded(ctx context.Context, invoiceID string) error
	GenerateCSVData(ctx context.Context, invoices []models.Invoice) ([]byte, error)
	DeleteInvoice(ctx context.Context, invoiceID string) error
}

type invoiceService struct {
	invoiceRepo repository.InvoiceRepository
	orderRepo   repository.OrderRepository
	userRepo    repository.UserRepository
}

// NewInvoiceService creates a new invoice service
func NewInvoiceService(invoiceRepo repository.InvoiceRepository, orderRepo repository.OrderRepository, userRepo repository.UserRepository) InvoiceService {
	return &invoiceService{
		invoiceRepo: invoiceRepo,
		orderRepo:   orderRepo,
		userRepo:    userRepo,
	}
}

// GenerateInvoice generates an invoice for an order
func (s *invoiceService) GenerateInvoice(ctx context.Context, orderID string) (*models.Invoice, error) {
	// Convert order ID to ObjectID
	orderObjID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return nil, fmt.Errorf("invalid order ID: %w", err)
	}

	// Check if invoice already exists for this order
	existingInvoice, err := s.invoiceRepo.GetByOrderID(ctx, orderObjID)
	if err == nil && existingInvoice != nil {
		return existingInvoice, nil
	}

	// Get order details
	order, err := s.orderRepo.GetByID(ctx, orderObjID)
	if err != nil {
		return nil, fmt.Errorf("failed to get order: %w", err)
	}

	// Generate invoice number
	invoiceNumber := s.generateInvoiceNumber(order)

	// Create invoice
	invoice := &models.Invoice{
		InvoiceNumber:  invoiceNumber,
		OrderID:        orderObjID,
		UserID:         order.UserID,
		GuestSessionID: order.GuestSessionID,
		InvoiceDate:    time.Now(),
		Status:         s.getInvoiceStatusFromOrder(order),
		Subtotal:       order.Subtotal,
		Tax:            order.Tax,
		Shipping:       order.Shipping,
		Discount:       order.Discount,
		Total:          order.Total,
		Currency:       "INR", // You can make this configurable
		IsDownloaded:   false,
	}

	// Save invoice to database
	err = s.invoiceRepo.Create(ctx, invoice)
	if err != nil {
		return nil, fmt.Errorf("failed to create invoice: %w", err)
	}

	return invoice, nil
}

// GetInvoice retrieves an invoice by ID
func (s *invoiceService) GetInvoice(ctx context.Context, invoiceID string) (*models.Invoice, error) {
	objID, err := primitive.ObjectIDFromHex(invoiceID)
	if err != nil {
		return nil, fmt.Errorf("invalid invoice ID: %w", err)
	}

	return s.invoiceRepo.GetByID(ctx, objID)
}

// GetInvoiceByOrderID retrieves an invoice by order ID
func (s *invoiceService) GetInvoiceByOrderID(ctx context.Context, orderID string) (*models.Invoice, error) {
	objID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return nil, fmt.Errorf("invalid order ID: %w", err)
	}

	return s.invoiceRepo.GetByOrderID(ctx, objID)
}

// GetInvoicesByUser retrieves invoices for a user
func (s *invoiceService) GetInvoicesByUser(ctx context.Context, userID string, page, limit int) ([]models.Invoice, int64, error) {
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, 0, fmt.Errorf("invalid user ID: %w", err)
	}

	return s.invoiceRepo.GetByUserID(ctx, objID, page, limit)
}

// GetInvoicesByGuestSession retrieves invoices for a guest session
func (s *invoiceService) GetInvoicesByGuestSession(ctx context.Context, guestSessionID string, page, limit int) ([]models.Invoice, int64, error) {
	return s.invoiceRepo.GetByGuestSessionID(ctx, guestSessionID, page, limit)
}

// ListInvoices retrieves invoices with filters
func (s *invoiceService) ListInvoices(ctx context.Context, filter *models.InvoiceFilter) ([]models.Invoice, int64, error) {
	return s.invoiceRepo.List(ctx, filter)
}

// MarkAsDownloaded marks an invoice as downloaded
func (s *invoiceService) MarkAsDownloaded(ctx context.Context, invoiceID string) error {
	objID, err := primitive.ObjectIDFromHex(invoiceID)
	if err != nil {
		return fmt.Errorf("invalid invoice ID: %w", err)
	}

	return s.invoiceRepo.MarkAsDownloaded(ctx, objID)
}

// GenerateCSVData generates CSV data for invoices
func (s *invoiceService) GenerateCSVData(ctx context.Context, invoices []models.Invoice) ([]byte, error) {
	var buffer [][]string

	// Header
	header := []string{
		"Invoice Number",
		"Order ID",
		"Invoice Date",
		"Status",
		"Subtotal",
		"Tax",
		"Shipping",
		"Discount",
		"Total",
		"Currency",
		"Downloaded",
	}
	buffer = append(buffer, header)

	// Data rows
	for _, invoice := range invoices {
		row := []string{
			invoice.InvoiceNumber,
			invoice.OrderID.Hex(),
			invoice.InvoiceDate.Format("2006-01-02 15:04:05"),
			string(invoice.Status),
			fmt.Sprintf("%.2f", invoice.Subtotal),
			fmt.Sprintf("%.2f", invoice.Tax),
			fmt.Sprintf("%.2f", invoice.Shipping),
			fmt.Sprintf("%.2f", invoice.Discount),
			fmt.Sprintf("%.2f", invoice.Total),
			invoice.Currency,
			fmt.Sprintf("%t", invoice.IsDownloaded),
		}
		buffer = append(buffer, row)
	}

	// Convert to CSV bytes
	var csvData []byte
	csvWriter := csv.NewWriter(&csvBuffer{data: &csvData})

	for _, row := range buffer {
		if err := csvWriter.Write(row); err != nil {
			return nil, fmt.Errorf("failed to write CSV row: %w", err)
		}
	}

	csvWriter.Flush()
	if err := csvWriter.Error(); err != nil {
		return nil, fmt.Errorf("failed to flush CSV writer: %w", err)
	}

	return csvData, nil
}

// DeleteInvoice deletes an invoice
func (s *invoiceService) DeleteInvoice(ctx context.Context, invoiceID string) error {
	objID, err := primitive.ObjectIDFromHex(invoiceID)
	if err != nil {
		return fmt.Errorf("invalid invoice ID: %w", err)
	}

	return s.invoiceRepo.Delete(ctx, objID)
}

// Helper functions

// generateInvoiceNumber generates a unique invoice number
func (s *invoiceService) generateInvoiceNumber(order *models.Order) string {
	// Format: INV-YYYYMMDD-ORDERNUM
	date := time.Now().Format("20060102")
	return fmt.Sprintf("INV-%s-%s", date, order.OrderNumber)
}

// getInvoiceStatusFromOrder determines invoice status from order
func (s *invoiceService) getInvoiceStatusFromOrder(order *models.Order) models.InvoiceStatus {
	switch order.PaymentStatus {
	case models.PaymentStatusPaid:
		return models.InvoiceStatusPaid
	case models.PaymentStatusRefunded:
		return models.InvoiceStatusRefunded
	case models.PaymentStatusCancelled:
		return models.InvoiceStatusCancelled
	case models.PaymentStatusPending:
		return models.InvoiceStatusIssued
	default:
		return models.InvoiceStatusDraft
	}
}

// csvBuffer is a helper type to write CSV to bytes
type csvBuffer struct {
	data *[]byte
}

func (b *csvBuffer) Write(p []byte) (n int, err error) {
	*b.data = append(*b.data, p...)
	return len(p), nil
}
