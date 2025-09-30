package services

import (
	"context"
	"errors"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type UserService interface {
	GetProfile(userID primitive.ObjectID) (*models.User, error)
	UpdateProfile(userID primitive.ObjectID, req *models.UpdateProfileRequest) (*models.User, error)
	AddAddress(userID primitive.ObjectID, req *models.AddAddressRequest) error
    UpdateAddress(userID primitive.ObjectID, addressID string, req *models.AddAddressRequest) error
    DeleteAddress(userID primitive.ObjectID, addressID string) error
    SetDefaultAddress(userID primitive.ObjectID, addressID string) error
	GetAllUsers(page, limit int) ([]models.User, int64, error)
	SearchUsers(query string, page, limit int) ([]models.User, int64, error)
	DeactivateUser(userID primitive.ObjectID) error
	ActivateUser(userID primitive.ObjectID) error
	MakeAdmin(userID primitive.ObjectID) error
	RemoveAdmin(userID primitive.ObjectID) error
	// Wishlist methods
	GetWishlistItems(userID primitive.ObjectID, page, limit int) ([]models.Product, int64, error)
	AddToWishlist(userID, productID primitive.ObjectID) error
	RemoveFromWishlist(userID, productID primitive.ObjectID) error
	IsInWishlist(userID, productID primitive.ObjectID) (bool, error)
	SetWishlistRepository(wishlistRepo repository.WishlistRepository)
}

type userService struct {
	userRepo      repository.UserRepository
	wishlistRepo  repository.WishlistRepository
}

func NewUserService(userRepo repository.UserRepository) UserService {
	return &userService{
		userRepo: userRepo,
	}
}

func (s *userService) SetWishlistRepository(wishlistRepo repository.WishlistRepository) {
	s.wishlistRepo = wishlistRepo
}

func (s *userService) GetProfile(userID primitive.ObjectID) (*models.User, error) {
    return s.userRepo.GetByID(context.Background(), userID)
}

func (s *userService) UpdateProfile(userID primitive.ObjectID, req *models.UpdateProfileRequest) (*models.User, error) {
	// Get current user
    user, err := s.userRepo.GetByID(context.Background(), userID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	// Update fields
	if req.Name != "" {
		user.Name = req.Name
	}
	if req.Phone != "" {
		// Check if phone is already taken by another user
        existingUser, _ := s.userRepo.GetByPhone(context.Background(), req.Phone)
		if existingUser != nil && existingUser.ID != userID {
			return nil, errors.New("phone number already exists")
		}
		user.Phone = req.Phone
	}
	if req.ProfileImage != "" {
		user.ProfileImage = req.ProfileImage
	}
	if req.Addresses != nil {
		user.Addresses = req.Addresses
	}

	// Save changes
    if err := s.userRepo.Update(context.Background(), user); err != nil {
		return nil, err
	}

	return user, nil
}

func (s *userService) AddAddress(userID primitive.ObjectID, req *models.AddAddressRequest) error {
	// Create address
	address := models.Address{
		ID:        primitive.NewObjectID(),
		Street:    req.Street,
		City:      req.City,
		State:     req.State,
		ZipCode:   req.ZipCode,
		Country:   req.Country,
		IsDefault: req.IsDefault,
	}

	// If this is set as default, unset other defaults first
	if req.IsDefault {
    user, err := s.userRepo.GetByID(context.Background(), userID)
		if err != nil {
			return errors.New("user not found")
		}

		// Unset all existing defaults
		for i := range user.Addresses {
			user.Addresses[i].IsDefault = false
		}
		user.Addresses = append(user.Addresses, address)
		user.UpdatedAt = time.Now()

        return s.userRepo.Update(context.Background(), user)
	}

    return s.userRepo.AddAddress(context.Background(), userID, address)
}

func (s *userService) UpdateAddress(userID primitive.ObjectID, addressID string, req *models.AddAddressRequest) error {
    addrID, err := primitive.ObjectIDFromHex(addressID)
    if err != nil {
        return errors.New("invalid address ID")
    }
	// Create updated address
	address := models.Address{
        ID:        addrID,
		Street:    req.Street,
		City:      req.City,
		State:     req.State,
		ZipCode:   req.ZipCode,
		Country:   req.Country,
		IsDefault: req.IsDefault,
	}

	// If this is set as default, unset other defaults first
    if req.IsDefault {
        return s.userRepo.SetDefaultAddress(nil, userID, addrID)
	}

    return s.userRepo.UpdateAddress(nil, userID, addrID, address)
}

func (s *userService) DeleteAddress(userID primitive.ObjectID, addressID string) error {
    addrID, err := primitive.ObjectIDFromHex(addressID)
    if err != nil {
        return errors.New("invalid address ID")
    }
    return s.userRepo.DeleteAddress(nil, userID, addrID)
}

func (s *userService) SetDefaultAddress(userID primitive.ObjectID, addressID string) error {
    addrID, err := primitive.ObjectIDFromHex(addressID)
    if err != nil {
        return errors.New("invalid address ID")
    }
    return s.userRepo.SetDefaultAddress(nil, userID, addrID)
}

func (s *userService) GetAllUsers(page, limit int) ([]models.User, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	return s.userRepo.GetAll(nil, page, limit)
}

func (s *userService) SearchUsers(query string, page, limit int) ([]models.User, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	return s.userRepo.Search(nil, query, page, limit)
}

func (s *userService) DeactivateUser(userID primitive.ObjectID) error {
	user, err := s.userRepo.GetByID(nil, userID)
	if err != nil {
		return errors.New("user not found")
	}

	user.IsActive = false
	user.UpdatedAt = time.Now()

	return s.userRepo.Update(nil, user)
}

func (s *userService) ActivateUser(userID primitive.ObjectID) error {
	user, err := s.userRepo.GetByID(nil, userID)
	if err != nil {
		return errors.New("user not found")
	}

	user.IsActive = true
	user.UpdatedAt = time.Now()

	return s.userRepo.Update(nil, user)
}

func (s *userService) MakeAdmin(userID primitive.ObjectID) error {
	user, err := s.userRepo.GetByID(nil, userID)
	if err != nil {
		return errors.New("user not found")
	}

	user.IsAdmin = true
	user.UpdatedAt = time.Now()

	return s.userRepo.Update(nil, user)
}

func (s *userService) RemoveAdmin(userID primitive.ObjectID) error {
	user, err := s.userRepo.GetByID(nil, userID)
	if err != nil {
		return errors.New("user not found")
	}

	user.IsAdmin = false
	user.UpdatedAt = time.Now()

	return s.userRepo.Update(nil, user)
}

// Wishlist methods
func (s *userService) GetWishlistItems(userID primitive.ObjectID, page, limit int) ([]models.Product, int64, error) {
	if s.wishlistRepo == nil {
		return nil, 0, errors.New("wishlist repository not initialized")
	}
	return s.wishlistRepo.GetWishlistItems(context.Background(), userID, page, limit)
}

func (s *userService) AddToWishlist(userID, productID primitive.ObjectID) error {
	if s.wishlistRepo == nil {
		return errors.New("wishlist repository not initialized")
	}
	return s.wishlistRepo.AddItem(context.Background(), userID, productID)
}

func (s *userService) RemoveFromWishlist(userID, productID primitive.ObjectID) error {
	if s.wishlistRepo == nil {
		return errors.New("wishlist repository not initialized")
	}
	return s.wishlistRepo.RemoveItem(context.Background(), userID, productID)
}

func (s *userService) IsInWishlist(userID, productID primitive.ObjectID) (bool, error) {
	if s.wishlistRepo == nil {
		return false, errors.New("wishlist repository not initialized")
	}
	return s.wishlistRepo.IsInWishlist(context.Background(), userID, productID)
}
