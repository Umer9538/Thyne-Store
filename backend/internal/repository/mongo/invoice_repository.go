package mongo

import (
	"context"
	"errors"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type invoiceRepository struct {
	collection *mongo.Collection
}

// NewInvoiceRepository creates a new invoice repository
func NewInvoiceRepository(db *mongo.Database) repository.InvoiceRepository {
	return &invoiceRepository{
		collection: db.Collection("invoices"),
	}
}

// Create creates a new invoice
func (r *invoiceRepository) Create(ctx context.Context, invoice *models.Invoice) error {
	invoice.CreatedAt = time.Now()
	invoice.UpdatedAt = time.Now()

	result, err := r.collection.InsertOne(ctx, invoice)
	if err != nil {
		return fmt.Errorf("failed to create invoice: %w", err)
	}

	invoice.ID = result.InsertedID.(primitive.ObjectID)
	return nil
}

// GetByID retrieves an invoice by ID
func (r *invoiceRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Invoice, error) {
	var invoice models.Invoice
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&invoice)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, fmt.Errorf("invoice not found")
		}
		return nil, fmt.Errorf("failed to get invoice: %w", err)
	}
	return &invoice, nil
}

// GetByOrderID retrieves an invoice by order ID
func (r *invoiceRepository) GetByOrderID(ctx context.Context, orderID primitive.ObjectID) (*models.Invoice, error) {
	var invoice models.Invoice
	err := r.collection.FindOne(ctx, bson.M{"orderId": orderID}).Decode(&invoice)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, fmt.Errorf("invoice not found for order")
		}
		return nil, fmt.Errorf("failed to get invoice: %w", err)
	}
	return &invoice, nil
}

// GetByInvoiceNumber retrieves an invoice by invoice number
func (r *invoiceRepository) GetByInvoiceNumber(ctx context.Context, invoiceNumber string) (*models.Invoice, error) {
	var invoice models.Invoice
	err := r.collection.FindOne(ctx, bson.M{"invoiceNumber": invoiceNumber}).Decode(&invoice)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, fmt.Errorf("invoice not found")
		}
		return nil, fmt.Errorf("failed to get invoice: %w", err)
	}
	return &invoice, nil
}

// GetByUserID retrieves invoices by user ID
func (r *invoiceRepository) GetByUserID(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]models.Invoice, int64, error) {
	filter := bson.M{"userId": userID}
	return r.findWithPagination(ctx, filter, page, limit)
}

// GetByGuestSessionID retrieves invoices by guest session ID
func (r *invoiceRepository) GetByGuestSessionID(ctx context.Context, guestSessionID string, page, limit int) ([]models.Invoice, int64, error) {
	filter := bson.M{"guestSessionId": guestSessionID}
	return r.findWithPagination(ctx, filter, page, limit)
}

// List retrieves invoices with filters
func (r *invoiceRepository) List(ctx context.Context, filter *models.InvoiceFilter) ([]models.Invoice, int64, error) {
	mongoFilter := bson.M{}

	if filter.UserID != nil {
		mongoFilter["userId"] = *filter.UserID
	}

	if filter.GuestSessionID != nil {
		mongoFilter["guestSessionId"] = *filter.GuestSessionID
	}

	if filter.OrderID != nil {
		mongoFilter["orderId"] = *filter.OrderID
	}

	if filter.Status != nil {
		mongoFilter["status"] = *filter.Status
	}

	if filter.InvoiceNumber != nil {
		mongoFilter["invoiceNumber"] = *filter.InvoiceNumber
	}

	if filter.DateFrom != nil || filter.DateTo != nil {
		dateFilter := bson.M{}
		if filter.DateFrom != nil {
			dateFilter["$gte"] = *filter.DateFrom
		}
		if filter.DateTo != nil {
			dateFilter["$lte"] = *filter.DateTo
		}
		mongoFilter["invoiceDate"] = dateFilter
	}

	page := filter.Page
	if page < 1 {
		page = 1
	}

	limit := filter.Limit
	if limit < 1 {
		limit = 20
	}

	return r.findWithPagination(ctx, mongoFilter, page, limit)
}

// Update updates an invoice
func (r *invoiceRepository) Update(ctx context.Context, invoice *models.Invoice) error {
	invoice.UpdatedAt = time.Now()

	filter := bson.M{"_id": invoice.ID}
	update := bson.M{"$set": invoice}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to update invoice: %w", err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("invoice not found")
	}

	return nil
}

// Delete deletes an invoice
func (r *invoiceRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	result, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete invoice: %w", err)
	}

	if result.DeletedCount == 0 {
		return fmt.Errorf("invoice not found")
	}

	return nil
}

// MarkAsDownloaded marks an invoice as downloaded
func (r *invoiceRepository) MarkAsDownloaded(ctx context.Context, id primitive.ObjectID) error {
	now := time.Now()
	filter := bson.M{"_id": id}
	update := bson.M{
		"$set": bson.M{
			"isDownloaded":  true,
			"downloadedAt":  now,
			"updatedAt":     now,
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to mark invoice as downloaded: %w", err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("invoice not found")
	}

	return nil
}

// Helper function for pagination
func (r *invoiceRepository) findWithPagination(ctx context.Context, filter bson.M, page, limit int) ([]models.Invoice, int64, error) {
	// Count total documents
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count invoices: %w", err)
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find with pagination
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetSkip(int64(skip)).
		SetLimit(int64(limit))

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to find invoices: %w", err)
	}
	defer cursor.Close(ctx)

	var invoices []models.Invoice
	if err = cursor.All(ctx, &invoices); err != nil {
		return nil, 0, fmt.Errorf("failed to decode invoices: %w", err)
	}

	if invoices == nil {
		invoices = []models.Invoice{}
	}

	return invoices, total, nil
}
