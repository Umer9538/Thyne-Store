package models

import (
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"gopkg.in/validator.v2"
)

// GuestSession represents a guest user session
type GuestSession struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	SessionID    string            `json:"sessionId" bson:"sessionId" validate:"required"`
	Email        *string           `json:"email,omitempty" bson:"email,omitempty"`
	Phone        *string           `json:"phone,omitempty" bson:"phone,omitempty"`
	Name         *string           `json:"name,omitempty" bson:"name,omitempty"`
	CartItems    []CartItem        `json:"cartItems" bson:"cartItems"`
	CreatedAt    time.Time         `json:"createdAt" bson:"createdAt"`
	LastActivity time.Time         `json:"lastActivity" bson:"lastActivity"`
	ExpiresAt    time.Time         `json:"expiresAt" bson:"expiresAt"`
}

// CreateGuestSessionRequest represents the request to create a guest session
type CreateGuestSessionRequest struct {
	Email *string `json:"email,omitempty" validate:"omitempty,email"`
	Phone *string `json:"phone,omitempty" validate:"omitempty,min=10,max=15"`
	Name  *string `json:"name,omitempty" validate:"omitempty,min=2,max=100"`
}

// UpdateGuestSessionRequest represents the request to update guest session
type UpdateGuestSessionRequest struct {
	Email *string `json:"email,omitempty" validate:"omitempty,email"`
	Phone *string `json:"phone,omitempty" validate:"omitempty,min=10,max=15"`
	Name  *string `json:"name,omitempty" validate:"omitempty,min=2,max=100"`
}

// GuestSessionResponse represents the response for guest session operations
type GuestSessionResponse struct {
	SessionID    string    `json:"sessionId"`
	Email        *string   `json:"email,omitempty"`
	Phone        *string   `json:"phone,omitempty"`
	Name         *string   `json:"name,omitempty"`
	HasContactInfo bool    `json:"hasContactInfo"`
	HasName      bool      `json:"hasName"`
	DisplayName  string    `json:"displayName"`
	CreatedAt    time.Time `json:"createdAt"`
	LastActivity time.Time `json:"lastActivity"`
	ExpiresAt    time.Time `json:"expiresAt"`
	IsExpired    bool      `json:"isExpired"`
}

// Validate validates the guest session struct
func (gs *GuestSession) Validate() error {
	return validator.Validate(gs)
}

// Validate validates the create guest session request
func (r *CreateGuestSessionRequest) Validate() error {
	return validator.Validate(r)
}

// Validate validates the update guest session request
func (r *UpdateGuestSessionRequest) Validate() error {
	return validator.Validate(r)
}

// IsExpired checks if the guest session is expired
func (gs *GuestSession) IsExpired() bool {
	return time.Now().After(gs.ExpiresAt)
}

// HasContactInfo checks if the guest session has contact information
func (gs *GuestSession) HasContactInfo() bool {
	return gs.Email != nil || gs.Phone != nil
}

// HasName checks if the guest session has a name
func (gs *GuestSession) HasName() bool {
	return gs.Name != nil && *gs.Name != ""
}

// GetDisplayName returns a display name for the guest user
func (gs *GuestSession) GetDisplayName() string {
	if gs.HasName() {
		return *gs.Name
	}
	if gs.Email != nil {
		return (*gs.Email)[:len(*gs.Email)-len((*gs.Email)[strings.LastIndex(*gs.Email, "@"):])]
	}
	if gs.Phone != nil {
		phone := *gs.Phone
		if len(phone) > 4 {
			return "Guest (" + phone[:4] + "...)"
		}
		return "Guest (" + phone + ")"
	}
	return "Guest User"
}

// UpdateActivity updates the last activity timestamp
func (gs *GuestSession) UpdateActivity() {
	gs.LastActivity = time.Now()
}

// ExtendExpiry extends the session expiry by the default duration
func (gs *GuestSession) ExtendExpiry(duration time.Duration) {
	gs.ExpiresAt = time.Now().Add(duration)
}

// AddToCart adds an item to the guest's cart
func (gs *GuestSession) AddToCart(productID primitive.ObjectID, quantity int) {
	for i, item := range gs.CartItems {
		if item.ProductID == productID {
			gs.CartItems[i].Quantity += quantity
			gs.UpdateActivity()
			return
		}
	}
	gs.CartItems = append(gs.CartItems, CartItem{
		ProductID: productID,
		Quantity:  quantity,
		AddedAt:   time.Now(),
	})
	gs.UpdateActivity()
}

// UpdateCartItem updates the quantity of an item in the guest's cart
func (gs *GuestSession) UpdateCartItem(productID primitive.ObjectID, quantity int) {
	for i, item := range gs.CartItems {
		if item.ProductID == productID {
			if quantity <= 0 {
				gs.RemoveFromCart(productID)
			} else {
				gs.CartItems[i].Quantity = quantity
				gs.UpdateActivity()
			}
			return
		}
	}
}

// RemoveFromCart removes an item from the guest's cart
func (gs *GuestSession) RemoveFromCart(productID primitive.ObjectID) {
	for i, item := range gs.CartItems {
		if item.ProductID == productID {
			gs.CartItems = append(gs.CartItems[:i], gs.CartItems[i+1:]...)
			gs.UpdateActivity()
			return
		}
	}
}

// GetCartItemCount returns the total number of items in the guest's cart
func (gs *GuestSession) GetCartItemCount() int {
	count := 0
	for _, item := range gs.CartItems {
		count += item.Quantity
	}
	return count
}

// ClearCart removes all items from the guest's cart
func (gs *GuestSession) ClearCart() {
	gs.CartItems = []CartItem{}
	gs.UpdateActivity()
}

// ToResponse converts GuestSession to GuestSessionResponse
func (gs *GuestSession) ToResponse() GuestSessionResponse {
	return GuestSessionResponse{
		SessionID:      gs.SessionID,
		Email:          gs.Email,
		Phone:          gs.Phone,
		Name:           gs.Name,
		HasContactInfo: gs.HasContactInfo(),
		HasName:        gs.HasName(),
		DisplayName:    gs.GetDisplayName(),
		CreatedAt:      gs.CreatedAt,
		LastActivity:   gs.LastActivity,
		ExpiresAt:      gs.ExpiresAt,
		IsExpired:      gs.IsExpired(),
	}
}

// ConvertToUser converts guest session to user registration data
func (gs *GuestSession) ConvertToUser(name, email, phone, password string) CreateUserRequest {
	// Use guest data if available, otherwise use provided data
	finalName := name
	if gs.Name != nil && *gs.Name != "" {
		finalName = *gs.Name
	}
	
	finalEmail := email
	if gs.Email != nil && *gs.Email != "" {
		finalEmail = *gs.Email
	}
	
	finalPhone := phone
	if gs.Phone != nil && *gs.Phone != "" {
		finalPhone = *gs.Phone
	}

	return CreateUserRequest{
		Name:     finalName,
		Email:    finalEmail,
		Phone:    finalPhone,
		Password: password,
	}
}

// NewGuestSession creates a new guest session with default values
func NewGuestSession() *GuestSession {
	now := time.Now()
	sessionID := generateSessionID()
	
	return &GuestSession{
		SessionID:    sessionID,
		CartItems:    []CartItem{},
		CreatedAt:    now,
		LastActivity: now,
		ExpiresAt:    now.Add(30 * 24 * time.Hour), // 30 days
	}
}

// generateSessionID generates a unique session ID
func generateSessionID() string {
	return "guest_" + time.Now().Format("20060102150405") + "_" + primitive.NewObjectID().Hex()[:8]
}
