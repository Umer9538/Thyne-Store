package services

import (
	"context"
	"errors"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CustomOrderService defines the interface for custom order operations
type CustomOrderService interface {
	CreateOrder(ctx context.Context, userIDStr string, guestSessionID string, req *models.CreateCustomOrderRequest) (*models.CustomOrder, error)
	GetOrder(ctx context.Context, id string) (*models.CustomOrder, error)
	GetOrderByNumber(ctx context.Context, orderNumber string) (*models.CustomOrder, error)
	GetUserOrders(ctx context.Context, userIDStr string, page, limit int) ([]models.CustomOrder, int64, error)
	GetAllOrders(ctx context.Context, filter models.CustomOrderFilter) ([]models.CustomOrder, int64, error)
	GetOrdersByStatus(ctx context.Context, status models.CustomOrderStatus, page, limit int) ([]models.CustomOrder, int64, error)
	MarkAsContacted(ctx context.Context, id string, contactedBy, adminNotes string) (*models.CustomOrder, error)
	ConfirmOrder(ctx context.Context, id string, finalPrice float64, adminNotes string) (*models.CustomOrder, error)
	UpdateStatus(ctx context.Context, id string, req *models.UpdateCustomOrderStatusRequest) (*models.CustomOrder, error)
	CancelOrder(ctx context.Context, id string, reason string) (*models.CustomOrder, error)
	GetStatistics(ctx context.Context) (map[string]interface{}, error)
}

type customOrderService struct {
	repo repository.CustomOrderRepository
}

// NewCustomOrderService creates a new custom order service
func NewCustomOrderService(repo repository.CustomOrderRepository) CustomOrderService {
	return &customOrderService{repo: repo}
}

// CreateOrder creates a new custom order
func (s *customOrderService) CreateOrder(ctx context.Context, userIDStr string, guestSessionID string, req *models.CreateCustomOrderRequest) (*models.CustomOrder, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}

	order := &models.CustomOrder{
		CustomerInfo: req.CustomerInfo,
		DesignInfo:   req.DesignInfo,
		PriceInfo:    req.PriceInfo,
		Status:       models.CustomOrderStatusPendingContact,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if userIDStr != "" {
		userID, err := primitive.ObjectIDFromHex(userIDStr)
		if err == nil {
			order.UserID = userID
		}
	}
	if guestSessionID != "" {
		order.GuestSessionID = guestSessionID
	}

	if order.PriceInfo.Currency == "" {
		order.PriceInfo.Currency = "INR"
	}

	if err := s.repo.Create(ctx, order); err != nil {
		return nil, err
	}

	return order, nil
}

// GetOrder retrieves a custom order by ID
func (s *customOrderService) GetOrder(ctx context.Context, id string) (*models.CustomOrder, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, errors.New("invalid order ID")
	}

	return s.repo.GetByID(ctx, objectID)
}

// GetOrderByNumber retrieves a custom order by order number
func (s *customOrderService) GetOrderByNumber(ctx context.Context, orderNumber string) (*models.CustomOrder, error) {
	return s.repo.GetByOrderNumber(ctx, orderNumber)
}

// GetUserOrders retrieves orders for a specific user
func (s *customOrderService) GetUserOrders(ctx context.Context, userIDStr string, page, limit int) ([]models.CustomOrder, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		return nil, 0, errors.New("invalid user ID")
	}

	return s.repo.GetByUserID(ctx, userID, page, limit)
}

// GetAllOrders retrieves all orders with filters (admin)
func (s *customOrderService) GetAllOrders(ctx context.Context, filter models.CustomOrderFilter) ([]models.CustomOrder, int64, error) {
	if filter.Page < 1 {
		filter.Page = 1
	}
	if filter.Limit < 1 || filter.Limit > 100 {
		filter.Limit = 20
	}

	return s.repo.GetAll(ctx, filter)
}

// GetOrdersByStatus retrieves orders by status
func (s *customOrderService) GetOrdersByStatus(ctx context.Context, status models.CustomOrderStatus, page, limit int) ([]models.CustomOrder, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	return s.repo.GetByStatus(ctx, status, page, limit)
}

// MarkAsContacted marks an order as contacted by the team
func (s *customOrderService) MarkAsContacted(ctx context.Context, id string, contactedBy, adminNotes string) (*models.CustomOrder, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, errors.New("invalid order ID")
	}

	order, err := s.repo.GetByID(ctx, objectID)
	if err != nil {
		return nil, err
	}

	if order.Status != models.CustomOrderStatusPendingContact {
		return nil, errors.New("order has already been contacted or processed")
	}

	order.MarkAsContacted(contactedBy)
	if adminNotes != "" {
		order.AdminNotes = adminNotes
	}

	if err := s.repo.Update(ctx, order); err != nil {
		return nil, err
	}

	return order, nil
}

// ConfirmOrder confirms the order with a final price
func (s *customOrderService) ConfirmOrder(ctx context.Context, id string, finalPrice float64, adminNotes string) (*models.CustomOrder, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, errors.New("invalid order ID")
	}

	order, err := s.repo.GetByID(ctx, objectID)
	if err != nil {
		return nil, err
	}

	if order.Status != models.CustomOrderStatusContacted {
		return nil, errors.New("order must be in 'contacted' status to confirm")
	}

	if finalPrice <= 0 {
		return nil, errors.New("final price must be greater than 0")
	}

	order.Confirm(finalPrice)
	if adminNotes != "" {
		order.AdminNotes = adminNotes
	}

	if err := s.repo.Update(ctx, order); err != nil {
		return nil, err
	}

	return order, nil
}

// UpdateStatus updates the order status
func (s *customOrderService) UpdateStatus(ctx context.Context, id string, req *models.UpdateCustomOrderStatusRequest) (*models.CustomOrder, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, errors.New("invalid order ID")
	}

	order, err := s.repo.GetByID(ctx, objectID)
	if err != nil {
		return nil, err
	}

	// Validate status transitions
	if err := validateStatusTransition(order.Status, req.Status); err != nil {
		return nil, err
	}

	// Update based on new status
	now := time.Now()
	switch req.Status {
	case models.CustomOrderStatusContacted:
		order.Status = req.Status
		order.ContactedAt = &now
	case models.CustomOrderStatusConfirmed:
		order.Status = req.Status
		order.ConfirmedAt = &now
		if req.FinalPrice > 0 {
			order.PriceInfo.FinalPrice = req.FinalPrice
		}
	case models.CustomOrderStatusProcessing:
		order.Status = req.Status
		order.ProcessingAt = &now
	case models.CustomOrderStatusShipped:
		order.Status = req.Status
		order.ShippedAt = &now
		if req.TrackingNumber != "" {
			order.TrackingNumber = req.TrackingNumber
		}
	case models.CustomOrderStatusDelivered:
		order.Status = req.Status
		order.DeliveredAt = &now
	case models.CustomOrderStatusCancelled:
		order.Status = req.Status
		order.CancelledAt = &now
		if req.CancelReason != "" {
			order.CancelReason = req.CancelReason
		}
	default:
		order.Status = req.Status
	}

	if req.AdminNotes != "" {
		order.AdminNotes = req.AdminNotes
	}
	order.UpdatedAt = now

	if err := s.repo.Update(ctx, order); err != nil {
		return nil, err
	}

	return order, nil
}

// CancelOrder cancels an order
func (s *customOrderService) CancelOrder(ctx context.Context, id string, reason string) (*models.CustomOrder, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, errors.New("invalid order ID")
	}

	order, err := s.repo.GetByID(ctx, objectID)
	if err != nil {
		return nil, err
	}

	// Check if order can be cancelled
	if order.Status == models.CustomOrderStatusDelivered || order.Status == models.CustomOrderStatusCancelled {
		return nil, errors.New("order cannot be cancelled in its current status")
	}

	order.Cancel(reason)

	if err := s.repo.Update(ctx, order); err != nil {
		return nil, err
	}

	return order, nil
}

// GetStatistics retrieves custom order statistics
func (s *customOrderService) GetStatistics(ctx context.Context) (map[string]interface{}, error) {
	return s.repo.GetStatistics(ctx)
}

// validateStatusTransition validates if a status transition is allowed
func validateStatusTransition(current, new models.CustomOrderStatus) error {
	validTransitions := map[models.CustomOrderStatus][]models.CustomOrderStatus{
		models.CustomOrderStatusPendingContact: {
			models.CustomOrderStatusContacted,
			models.CustomOrderStatusCancelled,
		},
		models.CustomOrderStatusContacted: {
			models.CustomOrderStatusConfirmed,
			models.CustomOrderStatusCancelled,
		},
		models.CustomOrderStatusConfirmed: {
			models.CustomOrderStatusProcessing,
			models.CustomOrderStatusCancelled,
		},
		models.CustomOrderStatusProcessing: {
			models.CustomOrderStatusShipped,
			models.CustomOrderStatusCancelled,
		},
		models.CustomOrderStatusShipped: {
			models.CustomOrderStatusDelivered,
		},
		models.CustomOrderStatusDelivered: {},
		models.CustomOrderStatusCancelled: {},
	}

	allowed, ok := validTransitions[current]
	if !ok {
		return errors.New("invalid current status")
	}

	for _, s := range allowed {
		if s == new {
			return nil
		}
	}

	return errors.New("invalid status transition")
}
