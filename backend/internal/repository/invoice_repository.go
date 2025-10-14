package repository

import (
	"context"
	"thyne-jewels-backend/internal/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// InvoiceRepository defines the interface for invoice data operations
type InvoiceRepository interface {
	Create(ctx context.Context, invoice *models.Invoice) error
	GetByID(ctx context.Context, id primitive.ObjectID) (*models.Invoice, error)
	GetByOrderID(ctx context.Context, orderID primitive.ObjectID) (*models.Invoice, error)
	GetByInvoiceNumber(ctx context.Context, invoiceNumber string) (*models.Invoice, error)
	GetByUserID(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Invoice, int64, error)
	GetByGuestSessionID(ctx context.Context, guestSessionID string, page, limit int) ([]models.Invoice, int64, error)
	List(ctx context.Context, filter *models.InvoiceFilter) ([]models.Invoice, int64, error)
	Update(ctx context.Context, invoice *models.Invoice) error
	Delete(ctx context.Context, id primitive.ObjectID) error
	MarkAsDownloaded(ctx context.Context, id primitive.ObjectID) error
}
