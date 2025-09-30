package services

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
)

type CartService interface {
	GetCart(userID string, guestSessionID string) (*models.Cart, error)
	AddToCart(userID string, guestSessionID string, productID string, quantity int) error
	UpdateCartItem(userID string, guestSessionID string, productID string, quantity int) error
	RemoveFromCart(userID string, guestSessionID string, productID string) error
	ApplyCoupon(userID string, guestSessionID string, couponCode string) error
	RemoveCoupon(userID string, guestSessionID string) error
	ClearCart(userID string, guestSessionID string) error
	ProcessAbandonedCarts() error
}

type cartService struct {
	cartRepo           repository.CartRepository
	productRepo        repository.ProductRepository
	couponRepo         repository.CouponRepository
	notificationService *NotificationService
}

func NewCartService(cartRepo repository.CartRepository, productRepo repository.ProductRepository, couponRepo repository.CouponRepository) CartService {
	return &cartService{
		cartRepo:    cartRepo,
		productRepo: productRepo,
		couponRepo:  couponRepo,
	}
}

func (s *cartService) SetNotificationService(notificationService *NotificationService) {
	s.notificationService = notificationService
}

func (s *cartService) GetCart(userID string, guestSessionID string) (*models.Cart, error) {
	ctx := context.Background()
	
	if userID != "" {
		userObjID, err := primitive.ObjectIDFromHex(userID)
		if err != nil {
			return nil, errors.New("invalid user ID")
		}
		return s.cartRepo.GetByUserID(ctx, userObjID)
	} else if guestSessionID != "" {
		return s.cartRepo.GetByGuestSessionID(ctx, guestSessionID)
	}
	
	return nil, errors.New("either user ID or guest session ID is required")
}

func (s *cartService) AddToCart(userID string, guestSessionID string, productID string, quantity int) error {
	// Placeholder implementation
	return nil
}

func (s *cartService) UpdateCartItem(userID string, guestSessionID string, productID string, quantity int) error {
	// Placeholder implementation
	return nil
}

func (s *cartService) RemoveFromCart(userID string, guestSessionID string, productID string) error {
	// Placeholder implementation
	return nil
}

func (s *cartService) ApplyCoupon(userID string, guestSessionID string, couponCode string) error {
	// Placeholder implementation
	return nil
}

func (s *cartService) RemoveCoupon(userID string, guestSessionID string) error {
	// Placeholder implementation
	return nil
}

func (s *cartService) ClearCart(userID string, guestSessionID string) error {
	ctx := context.Background()
	
	if userID != "" {
		userObjID, err := primitive.ObjectIDFromHex(userID)
		if err != nil {
			return errors.New("invalid user ID")
		}
		return s.cartRepo.ClearByUserID(ctx, userObjID)
	} else if guestSessionID != "" {
		return s.cartRepo.ClearByGuestSessionID(ctx, guestSessionID)
	}
	
	return errors.New("either user ID or guest session ID is required")
}

// ProcessAbandonedCarts identifies and sends notifications for abandoned carts
func (s *cartService) ProcessAbandonedCarts() error {
	ctx := context.Background()
	
	// Find carts that haven't been updated in the last 24 hours and have items
	cutoffTime := time.Now().Add(-24 * time.Hour)
	abandonedCarts, err := s.cartRepo.GetAbandonedCarts(ctx, cutoffTime)
	if err != nil {
		return err
	}
	
	// Send notifications for abandoned carts (only for authenticated users)
	if s.notificationService != nil {
		for _, cart := range abandonedCarts {
            if !cart.UserID.IsZero() {
                itemCount := cart.GetItemCount()
                totalAmount := cart.GetSubtotal()
                
                if itemCount > 0 && totalAmount > 0 {
                    userID := cart.UserID
                    go func(userID primitive.ObjectID, count int, amount float64) {
                        if s.notificationService != nil {
                            _ = s.notificationService.SendAbandonedCartNotification(ctx, userID, count, amount)
                        }
                    }(userID, itemCount, totalAmount)
                }
            }
		}
	}
	
	return nil
}
