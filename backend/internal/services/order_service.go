package services

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
)

type OrderService interface {
	CreateOrder(userID string, guestSessionID string, req *models.CreateOrderRequest) (*models.Order, error)
	GetOrders(userID string, guestSessionID string, page, limit int) ([]models.Order, int64, error)
    // Admin: list all orders
    GetAllOrders(page, limit int, status *models.OrderStatus) ([]models.Order, int64, error)
	GetOrder(orderID string) (*models.Order, error)
	CancelOrder(orderID string, reason string) error
	TrackOrder(orderID string) (*models.Order, error)
	ReturnOrder(orderID string, reason string) error
	RefundOrder(orderID string, reason string) error
	UpdateOrderStatus(orderID string, status models.OrderStatus, trackingNumber *string) error
	CompleteOrder(orderID string) error
}

type orderService struct {
	orderRepo         repository.OrderRepository
	productRepo       repository.ProductRepository
	cartRepo          repository.CartRepository
	loyaltyService    *LoyaltyService
	notificationService *NotificationService
}

func NewOrderService(orderRepo repository.OrderRepository, productRepo repository.ProductRepository, cartRepo repository.CartRepository) OrderService {
	return &orderService{
		orderRepo:   orderRepo,
		productRepo: productRepo,
		cartRepo:    cartRepo,
	}
}

func (s *orderService) SetLoyaltyService(loyaltyService *LoyaltyService) {
	s.loyaltyService = loyaltyService
}

func (s *orderService) SetNotificationService(notificationService *NotificationService) {
	s.notificationService = notificationService
}

func (s *orderService) CreateOrder(userID string, guestSessionID string, req *models.CreateOrderRequest) (*models.Order, error) {
	ctx := context.Background()

	// Generate unique order number
	orderNumber := generateOrderNumber()

	// Create order object
	order := &models.Order{
		OrderNumber:     orderNumber,
		Items:           req.Items,
		ShippingAddress: req.ShippingAddress,
		PaymentMethod:   req.PaymentMethod,
		PaymentStatus:   models.PaymentStatusPending,
		Status:          models.OrderStatusPending,
		Subtotal:        0,
		Tax:             0,
		Shipping:        0,
		Discount:        0,
		Total:           0,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	// Set user ID or guest session ID
	if userID != "" {
		userObjID, err := primitive.ObjectIDFromHex(userID)
		if err != nil {
			return nil, errors.New("invalid user ID")
		}
		order.UserID = userObjID
	} else if guestSessionID != "" {
		order.GuestSessionID = guestSessionID
	} else {
		return nil, errors.New("either user ID or guest session ID is required")
	}

	// Calculate totals
	total := 0.0
	for _, item := range req.Items {
		total += item.Price * float64(item.Quantity)
	}

	order.Subtotal = total
	order.Tax = total * 0.18 // 18% GST
	order.Shipping = 0 // Free shipping for now
	order.Total = order.Subtotal + order.Tax + order.Shipping

	// Save to database
	err := s.orderRepo.Create(ctx, order)
	if err != nil {
		return nil, fmt.Errorf("failed to create order: %w", err)
	}

	// Send order placed notification if user is authenticated and notification service is available
	if !order.UserID.IsZero() && s.notificationService != nil {
		go func() {
			if err := s.notificationService.SendOrderPlacedNotification(ctx, order.UserID, order.ID.Hex()); err != nil {
				fmt.Printf("Failed to send order placed notification for order %s: %v\n", order.ID.Hex(), err)
			}
		}()
	}

	return order, nil
}

func (s *orderService) GetOrders(userID string, guestSessionID string, page, limit int) ([]models.Order, int64, error) {
	ctx := context.Background()

	if userID != "" {
		userObjID, err := primitive.ObjectIDFromHex(userID)
		if err != nil {
			return nil, 0, errors.New("invalid user ID")
		}
		return s.orderRepo.GetByUserID(ctx, userObjID, page, limit)
	} else if guestSessionID != "" {
		return s.orderRepo.GetByGuestSessionID(ctx, guestSessionID, page, limit)
	}

	return nil, 0, errors.New("either user ID or guest session ID is required")
}

// GetAllOrders returns all orders for admin with optional status filter
func (s *orderService) GetAllOrders(page, limit int, status *models.OrderStatus) ([]models.Order, int64, error) {
    ctx := context.Background()
    return s.orderRepo.GetAll(ctx, page, limit, status)
}

func (s *orderService) GetOrder(orderID string) (*models.Order, error) {
	ctx := context.Background()
	
	objID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return nil, errors.New("invalid order ID")
	}

	return s.orderRepo.GetByID(ctx, objID)
}

func (s *orderService) CancelOrder(orderID string, reason string) error {
	ctx := context.Background()
	
	objID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return errors.New("invalid order ID")
	}

	order, err := s.orderRepo.GetByID(ctx, objID)
	if err != nil {
		return err
	}

	if !order.IsCancellable() {
		return errors.New("order cannot be cancelled")
	}

	order.Cancel(reason)
    err = s.orderRepo.Update(ctx, order)
	if err != nil {
		return err
	}

	// Send order cancelled notification if user is authenticated and notification service is available
	if !order.UserID.IsZero() && s.notificationService != nil {
		go func() {
			if err := s.notificationService.SendOrderCancelledNotification(ctx, order.UserID, order.ID.Hex()); err != nil {
				fmt.Printf("Failed to send order cancelled notification for order %s: %v\n", order.ID.Hex(), err)
			}
		}()
	}

	return nil
}

func (s *orderService) TrackOrder(orderID string) (*models.Order, error) {
	return s.GetOrder(orderID)
}

func (s *orderService) ReturnOrder(orderID string, reason string) error {
	ctx := context.Background()
	
	objID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return errors.New("invalid order ID")
	}

	order, err := s.orderRepo.GetByID(ctx, objID)
	if err != nil {
		return err
	}

	if order.Status != models.OrderStatusDelivered {
		return errors.New("only delivered orders can be returned")
	}

	order.Status = models.OrderStatusReturned
	order.ReturnReason = &reason
	order.UpdatedAt = time.Now()
	
	return s.orderRepo.Update(ctx, order)
}

func (s *orderService) RefundOrder(orderID string, reason string) error {
	ctx := context.Background()
	
	objID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return errors.New("invalid order ID")
	}

	order, err := s.orderRepo.GetByID(ctx, objID)
	if err != nil {
		return err
	}

	if !order.IsRefundable() {
		return errors.New("order is not refundable")
	}

	order.Refund(reason)
	return s.orderRepo.Update(ctx, order)
}

func (s *orderService) UpdateOrderStatus(orderID string, status models.OrderStatus, trackingNumber *string) error {
	ctx := context.Background()
	
	objID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return errors.New("invalid order ID")
	}

	order, err := s.orderRepo.GetByID(ctx, objID)
	if err != nil {
		return err
	}

	order.UpdateStatus(status)
	if trackingNumber != nil {
		order.TrackingNumber = trackingNumber
	}

    err = s.orderRepo.Update(ctx, order)
	if err != nil {
		return err
	}

	// Send appropriate notification based on status change if user is authenticated and notification service is available
	if !order.UserID.IsZero() && s.notificationService != nil {
		go func() {
			var notificationErr error
			switch status {
			case models.OrderStatusShipped:
				trackingNum := ""
				if order.TrackingNumber != nil {
					trackingNum = *order.TrackingNumber
				}
				notificationErr = s.notificationService.SendOrderShippedNotification(ctx, order.UserID, order.ID.Hex(), trackingNum)
			case models.OrderStatusDelivered:
				notificationErr = s.notificationService.SendOrderDeliveredNotification(ctx, order.UserID, order.ID.Hex())
			}
			
			if notificationErr != nil {
				fmt.Printf("Failed to send order status notification for order %s: %v\n", order.ID.Hex(), notificationErr)
			}
		}()
	}

	return nil
}

func (s *orderService) CompleteOrder(orderID string) error {
	ctx := context.Background()
	
	objID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return errors.New("invalid order ID")
	}

	order, err := s.orderRepo.GetByID(ctx, objID)
	if err != nil {
		return err
	}

	// Update order status to completed/paid
	order.UpdateStatus(models.OrderStatusConfirmed)
	order.PaymentStatus = models.PaymentStatusPaid
	
	if err := s.orderRepo.Update(ctx, order); err != nil {
		return err
	}

	// Award loyalty points if user is authenticated and loyalty service is available
	if !order.UserID.IsZero() && s.loyaltyService != nil {
		err := s.loyaltyService.AddPointsFromPurchase(ctx, order.UserID, order.Total, order.ID)
		if err != nil {
			// Log error but don't fail the order completion
			fmt.Printf("Failed to award loyalty points for order %s: %v\n", order.ID.Hex(), err)
		}
	}

	return nil
}

func generateOrderNumber() string {
	// Generate order number: TJ + timestamp + random
	timestamp := time.Now().Unix()
	random := rand.Intn(1000)
	return fmt.Sprintf("TJ%d%03d", timestamp, random)
}
