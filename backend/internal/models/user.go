package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"github.com/go-playground/validator/v10"
)

// User represents a registered user in the system
type User struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
    Name         string             `json:"name" bson:"name" validate:"required,min=2,max=100"`
    Email        string             `json:"email" bson:"email" validate:"required,email,min=5,max=100"`
    Phone        string             `json:"phone" bson:"phone" validate:"required,min=10,max=15"`
    Password     string             `json:"-" bson:"password" validate:"required,min=6"`
    ProfileImage string             `json:"profileImage,omitempty" bson:"profileImage"`
    Addresses    []Address          `json:"addresses" bson:"addresses"`
    IsActive     bool               `json:"isActive" bson:"isActive"`
    IsVerified   bool               `json:"isVerified" bson:"isVerified"`
    IsAdmin      bool               `json:"isAdmin" bson:"isAdmin"`
    CreatedAt    time.Time          `json:"createdAt" bson:"createdAt"`
    UpdatedAt    time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// Address represents a user's address
type Address struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId"`
	Street    string             `json:"street" bson:"street" validate:"required,min=5,max=200"`
	City      string             `json:"city" bson:"city" validate:"required,min=2,max=100"`
	State     string             `json:"state" bson:"state" validate:"required,min=2,max=100"`
	ZipCode   string             `json:"zipCode" bson:"zipCode" validate:"required,min=3,max=10"`
	Country   string             `json:"country" bson:"country" validate:"required,min=2,max=100"`
	IsDefault bool               `json:"isDefault" bson:"isDefault"`
	CreatedAt time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// CreateUserRequest represents the request to create a new user
type CreateUserRequest struct {
    Name     string `json:"name" validate:"required,min=2,max=100"`
    Email    string `json:"email" validate:"required,email,min=5,max=100"`
    Phone    string `json:"phone" validate:"required,min=10,max=15"`
    Password string `json:"password" validate:"required,min=6"`
}

// LoginRequest represents the login request
type LoginRequest struct {
    Email    string `json:"email" validate:"min=5,max=100"`
    Password string `json:"password"`
}

// LoginResponse represents the login response
type LoginResponse struct {
	User         *User  `json:"user"`
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
	ExpiresIn    int64  `json:"expiresIn"`
}

// UpdateProfileRequest represents the request to update user profile
type UpdateProfileRequest struct {
	Name         string    `json:"name,omitempty" validate:"min=2,max=100"`
	Phone        string    `json:"phone,omitempty" validate:"min=10,max=15"`
	ProfileImage string    `json:"profileImage,omitempty"`
	Addresses    []Address `json:"addresses,omitempty"`
}

// AddAddressRequest represents the request to add a new address
type AddAddressRequest struct {
	Street    string `json:"street" validate:"required,min=5,max=200"`
	City      string `json:"city" validate:"required,min=2,max=100"`
	State     string `json:"state" validate:"required,min=2,max=100"`
	ZipCode   string `json:"zipCode" validate:"required,min=3,max=10"`
	Country   string `json:"country" validate:"required,min=2,max=100"`
	IsDefault bool   `json:"isDefault"`
}

// ForgotPasswordRequest represents the forgot password request
type ForgotPasswordRequest struct {
    Email string `json:"email" validate:"required,email,min=5,max=100"`
}

// ResetPasswordRequest represents the reset password request
type ResetPasswordRequest struct {
	Token       string `json:"token"`
	NewPassword string `json:"newPassword" validate:"min=6"`
}

// ChangePasswordRequest represents the change password request
type ChangePasswordRequest struct {
	CurrentPassword string `json:"currentPassword"`
	NewPassword     string `json:"newPassword" validate:"min=6"`
}

// Validate validates the user struct
func (u *User) Validate() error {
	validate := validator.New()
	return validate.Struct(u)
}

// Validate validates the create user request
func (r *CreateUserRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the login request
func (r *LoginRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the update profile request
func (r *UpdateProfileRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the add address request
func (r *AddAddressRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the forgot password request
func (r *ForgotPasswordRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the reset password request
func (r *ResetPasswordRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// Validate validates the change password request
func (r *ChangePasswordRequest) Validate() error {
	validate := validator.New()
	return validate.Struct(r)
}

// GetDefaultAddress returns the default address or the first address
func (u *User) GetDefaultAddress() *Address {
	for _, addr := range u.Addresses {
		if addr.IsDefault {
			return &addr
		}
	}
	if len(u.Addresses) > 0 {
		return &u.Addresses[0]
	}
	return nil
}

// SetDefaultAddress sets the specified address as default and unsets others
func (u *User) SetDefaultAddress(addressID primitive.ObjectID) {
	for i := range u.Addresses {
		u.Addresses[i].IsDefault = (u.Addresses[i].ID == addressID)
	}
}
