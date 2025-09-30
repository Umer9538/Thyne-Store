package services

import (
	"errors"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type GuestSessionService interface {
	CreateSession() (*models.GuestSession, error)
	GetSession(sessionID string) (*models.GuestSession, error)
	UpdateSession(sessionID string, req *models.UpdateGuestSessionRequest) (*models.GuestSession, error)
	DeleteSession(sessionID string) error
	ExtendSession(sessionID string) error
	AddToCart(sessionID string, productID primitive.ObjectID, quantity int) error
	UpdateCartItem(sessionID string, productID primitive.ObjectID, quantity int) error
	RemoveFromCart(sessionID string, productID primitive.ObjectID) error
	ClearCart(sessionID string) error
}

type guestSessionService struct {
	guestRepo repository.GuestSessionRepository
	cartRepo  repository.CartRepository
}

func NewGuestSessionService(guestRepo repository.GuestSessionRepository, cartRepo repository.CartRepository) GuestSessionService {
	return &guestSessionService{
		guestRepo: guestRepo,
		cartRepo:  cartRepo,
	}
}

func (s *guestSessionService) CreateSession() (*models.GuestSession, error) {
	session := models.NewGuestSession()
	
	if err := s.guestRepo.Create(nil, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *guestSessionService) GetSession(sessionID string) (*models.GuestSession, error) {
	session, err := s.guestRepo.GetBySessionID(nil, sessionID)
	if err != nil {
		return nil, err
	}

	if session.IsExpired() {
		// Delete expired session
		s.guestRepo.DeleteBySessionID(nil, sessionID)
		return nil, errors.New("session expired")
	}

	// Update last activity
	session.UpdateActivity()
	s.guestRepo.Update(nil, session)

	return session, nil
}

func (s *guestSessionService) UpdateSession(sessionID string, req *models.UpdateGuestSessionRequest) (*models.GuestSession, error) {
	session, err := s.GetSession(sessionID)
	if err != nil {
		return nil, err
	}

	// Update fields
	if req.Email != nil {
		session.Email = req.Email
	}
	if req.Phone != nil {
		session.Phone = req.Phone
	}
	if req.Name != nil {
		session.Name = req.Name
	}

	session.UpdateActivity()

	if err := s.guestRepo.Update(nil, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *guestSessionService) DeleteSession(sessionID string) error {
	return s.guestRepo.DeleteBySessionID(nil, sessionID)
}

func (s *guestSessionService) ExtendSession(sessionID string) error {
	session, err := s.GetSession(sessionID)
	if err != nil {
		return err
	}

	session.ExtendExpiry(30 * 24 * time.Hour) // Extend by 30 days
	return s.guestRepo.Update(nil, session)
}

func (s *guestSessionService) AddToCart(sessionID string, productID primitive.ObjectID, quantity int) error {
	session, err := s.GetSession(sessionID)
	if err != nil {
		return err
	}

	session.AddToCart(productID, quantity)
	session.UpdateActivity()

	return s.guestRepo.Update(nil, session)
}

func (s *guestSessionService) UpdateCartItem(sessionID string, productID primitive.ObjectID, quantity int) error {
	session, err := s.GetSession(sessionID)
	if err != nil {
		return err
	}

	session.UpdateCartItem(productID, quantity)
	session.UpdateActivity()

	return s.guestRepo.Update(nil, session)
}

func (s *guestSessionService) RemoveFromCart(sessionID string, productID primitive.ObjectID) error {
	session, err := s.GetSession(sessionID)
	if err != nil {
		return err
	}

	session.RemoveFromCart(productID)
	session.UpdateActivity()

	return s.guestRepo.Update(nil, session)
}

func (s *guestSessionService) ClearCart(sessionID string) error {
	session, err := s.GetSession(sessionID)
	if err != nil {
		return err
	}

	session.ClearCart()
	session.UpdateActivity()

	return s.guestRepo.Update(nil, session)
}
