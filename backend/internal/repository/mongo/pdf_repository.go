package mongo

import (
	"context"
	"fmt"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type pdfRepository struct {
	pdfCollection      *mongo.Collection
	trackingCollection *mongo.Collection
	warrantyCollection *mongo.Collection
	templateCollection *mongo.Collection
}

// NewPDFRepository creates a new PDF repository
func NewPDFRepository(db *mongo.Database) repository.PDFRepository {
	return &pdfRepository{
		pdfCollection:      db.Collection("pdf_documents"),
		trackingCollection: db.Collection("order_tracking"),
		warrantyCollection: db.Collection("warranties"),
		templateCollection: db.Collection("pdf_templates"),
	}
}

func (r *pdfRepository) Create(ctx context.Context, pdf *models.PDFDocument) error {
	pdf.ID = primitive.NewObjectID()
	pdf.GeneratedAt = time.Now()

	_, err := r.pdfCollection.InsertOne(ctx, pdf)
	if err != nil {
		return fmt.Errorf("failed to create PDF document: %w", err)
	}

	return nil
}

func (r *pdfRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.PDFDocument, error) {
	var pdf models.PDFDocument
	err := r.pdfCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&pdf)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("PDF document not found")
		}
		return nil, fmt.Errorf("failed to get PDF document: %w", err)
	}
	return &pdf, nil
}

func (r *pdfRepository) GetByOrderID(ctx context.Context, orderID primitive.ObjectID, pdfType string) (*models.PDFDocument, error) {
	filter := bson.M{"orderId": orderID}
	if pdfType != "" {
		filter["type"] = pdfType
	}

	var pdf models.PDFDocument
	err := r.pdfCollection.FindOne(ctx, filter).Decode(&pdf)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("PDF document not found")
		}
		return nil, fmt.Errorf("failed to get PDF document by order: %w", err)
	}
	return &pdf, nil
}

func (r *pdfRepository) Update(ctx context.Context, pdf *models.PDFDocument) error {
	_, err := r.pdfCollection.UpdateOne(
		ctx,
		bson.M{"_id": pdf.ID},
		bson.M{"$set": pdf},
	)
	if err != nil {
		return fmt.Errorf("failed to update PDF document: %w", err)
	}

	return nil
}

func (r *pdfRepository) GetByUserID(ctx context.Context, userID primitive.ObjectID, pdfType string) ([]models.PDFDocument, error) {
	filter := bson.M{"userId": userID, "isActive": true}
	if pdfType != "" {
		filter["type"] = pdfType
	}

	opts := options.Find().SetSort(bson.M{"generatedAt": -1})

	cursor, err := r.pdfCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find PDF documents: %w", err)
	}
	defer cursor.Close(ctx)

	var pdfs []models.PDFDocument
	if err = cursor.All(ctx, &pdfs); err != nil {
		return nil, fmt.Errorf("failed to decode PDF documents: %w", err)
	}

	return pdfs, nil
}

func (r *pdfRepository) GetOrderTracking(ctx context.Context, orderID primitive.ObjectID) (*models.OrderTracking, error) {
	var tracking models.OrderTracking
	err := r.trackingCollection.FindOne(ctx, bson.M{"orderId": orderID}).Decode(&tracking)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("order tracking not found")
		}
		return nil, fmt.Errorf("failed to get order tracking: %w", err)
	}
	return &tracking, nil
}

func (r *pdfRepository) CreateOrderTracking(ctx context.Context, tracking *models.OrderTracking) error {
	tracking.ID = primitive.NewObjectID()
	tracking.CreatedAt = time.Now()
	tracking.UpdatedAt = time.Now()

	_, err := r.trackingCollection.InsertOne(ctx, tracking)
	if err != nil {
		return fmt.Errorf("failed to create order tracking: %w", err)
	}

	return nil
}

func (r *pdfRepository) UpdateOrderTracking(ctx context.Context, tracking *models.OrderTracking) error {
	tracking.UpdatedAt = time.Now()

	_, err := r.trackingCollection.UpdateOne(
		ctx,
		bson.M{"_id": tracking.ID},
		bson.M{"$set": tracking},
	)
	if err != nil {
		return fmt.Errorf("failed to update order tracking: %w", err)
	}

	return nil
}

func (r *pdfRepository) CreateWarranty(ctx context.Context, warranty *models.WarrantyInfo) error {
	warranty.ID = primitive.NewObjectID()
	warranty.CreatedAt = time.Now()
	warranty.UpdatedAt = time.Now()

	_, err := r.warrantyCollection.InsertOne(ctx, warranty)
	if err != nil {
		return fmt.Errorf("failed to create warranty: %w", err)
	}

	return nil
}

func (r *pdfRepository) GetWarrantyByID(ctx context.Context, id primitive.ObjectID) (*models.WarrantyInfo, error) {
	var warranty models.WarrantyInfo
	err := r.warrantyCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&warranty)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("warranty not found")
		}
		return nil, fmt.Errorf("failed to get warranty: %w", err)
	}
	return &warranty, nil
}

func (r *pdfRepository) UpdateWarranty(ctx context.Context, warranty *models.WarrantyInfo) error {
	warranty.UpdatedAt = time.Now()

	_, err := r.warrantyCollection.UpdateOne(
		ctx,
		bson.M{"_id": warranty.ID},
		bson.M{"$set": warranty},
	)
	if err != nil {
		return fmt.Errorf("failed to update warranty: %w", err)
	}

	return nil
}

func (r *pdfRepository) GetTemplate(ctx context.Context, templateType string) (*models.PDFTemplate, error) {
	filter := bson.M{
		"type":      templateType,
		"isActive":  true,
		"isDefault": true,
	}

	var template models.PDFTemplate
	err := r.templateCollection.FindOne(ctx, filter).Decode(&template)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("PDF template not found")
		}
		return nil, fmt.Errorf("failed to get PDF template: %w", err)
	}
	return &template, nil
}

func (r *pdfRepository) CreateTemplate(ctx context.Context, template *models.PDFTemplate) error {
	template.ID = primitive.NewObjectID()
	template.CreatedAt = time.Now()
	template.UpdatedAt = time.Now()

	_, err := r.templateCollection.InsertOne(ctx, template)
	if err != nil {
		return fmt.Errorf("failed to create PDF template: %w", err)
	}

	return nil
}

func (r *pdfRepository) UpdateTemplate(ctx context.Context, template *models.PDFTemplate) error {
	template.UpdatedAt = time.Now()

	_, err := r.templateCollection.UpdateOne(
		ctx,
		bson.M{"_id": template.ID},
		bson.M{"$set": template},
	)
	if err != nil {
		return fmt.Errorf("failed to update PDF template: %w", err)
	}

	return nil
}