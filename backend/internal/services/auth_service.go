package services

import (
	"context"
	"errors"
	"time"

	"thyne-jewels-backend/internal/config"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"github.com/golang-jwt/jwt/v5"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"golang.org/x/crypto/bcrypt"
)

type AuthService interface {
	Register(req *models.CreateUserRequest) (*models.LoginResponse, error)
	Login(req *models.LoginRequest) (*models.LoginResponse, error)
	ValidateToken(tokenString string) (*models.User, error)
	RefreshToken(refreshToken string) (*models.LoginResponse, error)
	ForgotPassword(email string) error
	ResetPassword(req *models.ResetPasswordRequest) error
	ChangePassword(userID primitive.ObjectID, req *models.ChangePasswordRequest) error
	GenerateTokenPair(user *models.User) (string, string, int64, error)
	HashPassword(password string) (string, error)
	VerifyPassword(hashedPassword, password string) error
}

type authService struct {
	userRepo   repository.UserRepository
	jwtConfig  config.JWTConfig
	bcryptCost int
}

func NewAuthService(userRepo repository.UserRepository, jwtConfig config.JWTConfig, bcryptCost int) AuthService {
	return &authService{
		userRepo:   userRepo,
		jwtConfig:  jwtConfig,
		bcryptCost: bcryptCost,
	}
}

func (s *authService) Register(req *models.CreateUserRequest) (*models.LoginResponse, error) {
	// Check if email already exists
    existingUser, _ := s.userRepo.GetByEmail(context.Background(), req.Email)
	if existingUser != nil {
		return nil, errors.New("email already exists")
	}

	// Check if phone already exists
    existingUser, _ = s.userRepo.GetByPhone(context.Background(), req.Phone)
	if existingUser != nil {
		return nil, errors.New("phone number already exists")
	}

	// Hash password
	hashedPassword, err := s.HashPassword(req.Password)
	if err != nil {
		return nil, err
	}

	// Create user
	user := &models.User{
		ID:       primitive.NewObjectID(),
		Name:     req.Name,
		Email:    req.Email,
		Phone:    req.Phone,
		Password: hashedPassword,
	}

    if err := s.userRepo.Create(context.Background(), user); err != nil {
		return nil, err
	}

	// Generate tokens
	accessToken, refreshToken, expiresIn, err := s.GenerateTokenPair(user)
	if err != nil {
		return nil, err
	}

	return &models.LoginResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
	}, nil
}

func (s *authService) Login(req *models.LoginRequest) (*models.LoginResponse, error) {
	// Get user by email
	user, err := s.userRepo.GetByEmail(nil, req.Email)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	// Verify password
	if err := s.VerifyPassword(user.Password, req.Password); err != nil {
		return nil, errors.New("invalid credentials")
	}

	// Check if user is active
	if !user.IsActive {
		return nil, errors.New("account is deactivated")
	}

	// Generate tokens
	accessToken, refreshToken, expiresIn, err := s.GenerateTokenPair(user)
	if err != nil {
		return nil, err
	}

	return &models.LoginResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
	}, nil
}

func (s *authService) ValidateToken(tokenString string) (*models.User, error) {
	// Parse and validate token
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(s.jwtConfig.Secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		// Extract user ID from claims
		userIDStr, ok := claims["user_id"].(string)
		if !ok {
			return nil, errors.New("invalid token claims")
		}

		userID, err := primitive.ObjectIDFromHex(userIDStr)
		if err != nil {
			return nil, err
		}

		// Get user from database
		user, err := s.userRepo.GetByID(nil, userID)
		if err != nil {
			return nil, errors.New("user not found")
		}

		// Check if user is still active
		if !user.IsActive {
			return nil, errors.New("user account is deactivated")
		}

		return user, nil
	}

	return nil, errors.New("invalid token")
}

func (s *authService) RefreshToken(refreshToken string) (*models.LoginResponse, error) {
	// Parse and validate refresh token
	token, err := jwt.Parse(refreshToken, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(s.jwtConfig.Secret), nil
	})

	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		// Check if it's a refresh token
		tokenType, ok := claims["type"].(string)
		if !ok || tokenType != "refresh" {
			return nil, errors.New("invalid token type")
		}

		// Extract user ID from claims
		userIDStr, ok := claims["user_id"].(string)
		if !ok {
			return nil, errors.New("invalid token claims")
		}

		userID, err := primitive.ObjectIDFromHex(userIDStr)
		if err != nil {
			return nil, err
		}

		// Get user from database
		user, err := s.userRepo.GetByID(nil, userID)
		if err != nil {
			return nil, errors.New("user not found")
		}

		// Check if user is still active
		if !user.IsActive {
			return nil, errors.New("user account is deactivated")
		}

		// Generate new tokens
		accessToken, refreshToken, expiresIn, err := s.GenerateTokenPair(user)
		if err != nil {
			return nil, err
		}

		return &models.LoginResponse{
			User:         user,
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
			ExpiresIn:    expiresIn,
		}, nil
	}

	return nil, errors.New("invalid refresh token")
}

func (s *authService) ForgotPassword(email string) error {
	// Check if user exists
	user, err := s.userRepo.GetByEmail(nil, email)
	if err != nil {
		// Don't reveal if email exists or not for security
		return nil
	}

	// Generate reset token (in a real app, this would be stored in database with expiration)
	// For now, we'll just return success
	_ = user // Use the user variable to avoid unused variable warning

	// TODO: Send reset email with token
	// This would typically involve:
	// 1. Generate a secure reset token
	// 2. Store it in database with expiration
	// 3. Send email with reset link

	return nil
}

func (s *authService) ResetPassword(req *models.ResetPasswordRequest) error {
	// In a real app, you would:
	// 1. Validate the reset token
	// 2. Check if it's not expired
	// 3. Get the user associated with the token
	// 4. Update the password

	// For now, we'll return an error as this requires proper token management
	return errors.New("password reset not implemented - requires email service integration")
}

func (s *authService) ChangePassword(userID primitive.ObjectID, req *models.ChangePasswordRequest) error {
	// Get user
	user, err := s.userRepo.GetByID(nil, userID)
	if err != nil {
		return errors.New("user not found")
	}

	// Verify current password
	if err := s.VerifyPassword(user.Password, req.CurrentPassword); err != nil {
		return errors.New("current password is incorrect")
	}

	// Hash new password
	hashedPassword, err := s.HashPassword(req.NewPassword)
	if err != nil {
		return err
	}

	// Update password
	return s.userRepo.UpdatePassword(nil, userID, hashedPassword)
}

func (s *authService) GenerateTokenPair(user *models.User) (string, string, int64, error) {
	// Access token
	accessClaims := jwt.MapClaims{
		"user_id": user.ID.Hex(),
		"email":   user.Email,
		"name":    user.Name,
		"is_admin": user.IsAdmin,
		"type":    "access",
		"exp":     time.Now().Add(time.Hour * 24).Unix(), // 24 hours
		"iat":     time.Now().Unix(),
	}

	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenString, err := accessToken.SignedString([]byte(s.jwtConfig.Secret))
	if err != nil {
		return "", "", 0, err
	}

	// Refresh token
	refreshClaims := jwt.MapClaims{
		"user_id": user.ID.Hex(),
		"type":    "refresh",
		"exp":     time.Now().Add(time.Hour * 24 * 7).Unix(), // 7 days
		"iat":     time.Now().Unix(),
	}

	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenString, err := refreshToken.SignedString([]byte(s.jwtConfig.Secret))
	if err != nil {
		return "", "", 0, err
	}

	expiresIn := int64(24 * 60 * 60) // 24 hours in seconds

	return accessTokenString, refreshTokenString, expiresIn, nil
}

func (s *authService) HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), s.bcryptCost)
	return string(bytes), err
}

func (s *authService) VerifyPassword(hashedPassword, password string) error {
	return bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
}
