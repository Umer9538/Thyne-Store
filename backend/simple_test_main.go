package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"thyne-jewels-backend/internal/config"
	"thyne-jewels-backend/internal/handlers"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Mock repository for testing
type mockUserRepository struct {
	users map[string]*models.User
}

func newMockUserRepository() *mockUserRepository {
	return &mockUserRepository{
		users: make(map[string]*models.User),
	}
}

func (m *mockUserRepository) Create(ctx context.Context, user *models.User) error {
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()
	user.IsActive = true
	user.IsVerified = false
	user.IsAdmin = false
	m.users[user.Email] = user
	return nil
}

func (m *mockUserRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.User, error) {
	for _, user := range m.users {
		if user.ID == id {
			return user, nil
		}
	}
	return nil, fmt.Errorf("user not found")
}

func (m *mockUserRepository) GetByEmail(ctx context.Context, email string) (*models.User, error) {
	user, exists := m.users[email]
	if !exists {
		return nil, fmt.Errorf("user not found")
	}
	return user, nil
}

func (m *mockUserRepository) GetByPhone(ctx context.Context, phone string) (*models.User, error) {
	for _, user := range m.users {
		if user.Phone == phone {
			return user, nil
		}
	}
	return nil, fmt.Errorf("user not found")
}

func (m *mockUserRepository) Update(ctx context.Context, user *models.User) error {
	m.users[user.Email] = user
	return nil
}

func (m *mockUserRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	for email, user := range m.users {
		if user.ID == id {
			delete(m.users, email)
			return nil
		}
	}
	return fmt.Errorf("user not found")
}

func (m *mockUserRepository) UpdatePassword(ctx context.Context, id primitive.ObjectID, hashedPassword string) error {
	for _, user := range m.users {
		if user.ID == id {
			user.Password = hashedPassword
			user.UpdatedAt = time.Now()
			return nil
		}
	}
	return fmt.Errorf("user not found")
}

func (m *mockUserRepository) UpdateProfile(ctx context.Context, id primitive.ObjectID, updates *models.UpdateProfileRequest) error {
	for _, user := range m.users {
		if user.ID == id {
			if updates.Name != "" {
				user.Name = updates.Name
			}
			if updates.Phone != "" {
				user.Phone = updates.Phone
			}
			if updates.ProfileImage != "" {
				user.ProfileImage = updates.ProfileImage
			}
			if updates.Addresses != nil {
				user.Addresses = updates.Addresses
			}
			user.UpdatedAt = time.Now()
			return nil
		}
	}
	return fmt.Errorf("user not found")
}

func (m *mockUserRepository) AddAddress(ctx context.Context, userID primitive.ObjectID, address models.Address) error {
	for _, user := range m.users {
		if user.ID == userID {
			user.Addresses = append(user.Addresses, address)
			user.UpdatedAt = time.Now()
			return nil
		}
	}
	return fmt.Errorf("user not found")
}

func (m *mockUserRepository) UpdateAddress(ctx context.Context, userID primitive.ObjectID, addressID string, address models.Address) error {
	for _, user := range m.users {
		if user.ID == userID {
			for i, addr := range user.Addresses {
				if addr.ID == addressID {
					user.Addresses[i] = address
					user.UpdatedAt = time.Now()
					return nil
				}
			}
		}
	}
	return fmt.Errorf("address not found")
}

func (m *mockUserRepository) DeleteAddress(ctx context.Context, userID primitive.ObjectID, addressID string) error {
	for _, user := range m.users {
		if user.ID == userID {
			for i, addr := range user.Addresses {
				if addr.ID == addressID {
					user.Addresses = append(user.Addresses[:i], user.Addresses[i+1:]...)
					user.UpdatedAt = time.Now()
					return nil
				}
			}
		}
	}
	return fmt.Errorf("address not found")
}

func (m *mockUserRepository) SetDefaultAddress(ctx context.Context, userID primitive.ObjectID, addressID string) error {
	for _, user := range m.users {
		if user.ID == userID {
			// Set all addresses to not default
			for i := range user.Addresses {
				user.Addresses[i].IsDefault = false
			}
			// Set the specified address as default
			for i := range user.Addresses {
				if user.Addresses[i].ID == addressID {
					user.Addresses[i].IsDefault = true
					user.UpdatedAt = time.Now()
					return nil
				}
			}
		}
	}
	return fmt.Errorf("address not found")
}

func (m *mockUserRepository) GetAll(ctx context.Context, page, limit int) ([]models.User, int64, error) {
	users := make([]models.User, 0, len(m.users))
	for _, user := range m.users {
		users = append(users, *user)
	}
	return users, int64(len(users)), nil
}

func (m *mockUserRepository) Search(ctx context.Context, query string, page, limit int) ([]models.User, int64, error) {
	users := make([]models.User, 0)
	for _, user := range m.users {
		if user.Name == query || user.Email == query || user.Phone == query {
			users = append(users, *user)
		}
	}
	return users, int64(len(users)), nil
}

func TestAuthenticationEndpoints(t *testing.T) {
	fmt.Println("🧪 Testing Authentication Endpoints")
	fmt.Println(strings.Repeat("=", 50))

	// Setup
	gin.SetMode(gin.TestMode)
	router := gin.New()

	// Create mock repository and services
	mockRepo := newMockUserRepository()
	jwtConfig := config.JWTConfig{
		Secret: "test-secret-key-for-testing-purposes-only",
	}
	authService := services.NewAuthService(mockRepo, jwtConfig, 12)
	userService := services.NewUserService(mockRepo)
	authHandler := handlers.NewAuthHandler(authService, userService)

	// Setup routes
	api := router.Group("/api/v1")
	auth := api.Group("/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/forgot-password", authHandler.ForgotPassword)
	}

	// Test 1: Registration
	fmt.Println("\n1️⃣ Testing User Registration")
	fmt.Println(strings.Repeat("-", 30))

	registerData := map[string]interface{}{
		"name":     "Test User",
		"email":    "test@example.com",
		"phone":    "+1234567890",
		"password": "testpass123",
	}

	registerJSON, _ := json.Marshal(registerData)
	registerReq := httptest.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(registerJSON))
	registerReq.Header.Set("Content-Type", "application/json")
	registerRecorder := httptest.NewRecorder()

	router.ServeHTTP(registerRecorder, registerReq)

	fmt.Printf("   Status Code: %d\n", registerRecorder.Code)
	if registerRecorder.Code == http.StatusCreated {
		fmt.Println("   ✅ Registration successful!")
		var response map[string]interface{}
		json.Unmarshal(registerRecorder.Body.Bytes(), &response)
		if data, ok := response["data"].(map[string]interface{}); ok {
			if user, ok := data["user"].(map[string]interface{}); ok {
				fmt.Printf("   User: %s\n", user["name"])
				fmt.Printf("   Email: %s\n", user["email"])
				fmt.Printf("   IsAdmin: %t\n", user["isAdmin"])
			}
		}
	} else {
		fmt.Printf("   ❌ Registration failed: %s\n", registerRecorder.Body.String())
	}

	// Test 2: Login
	fmt.Println("\n2️⃣ Testing User Login")
	fmt.Println(strings.Repeat("-", 30))

	loginData := map[string]interface{}{
		"email":    "test@example.com",
		"password": "testpass123",
	}

	loginJSON, _ := json.Marshal(loginData)
	loginReq := httptest.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(loginJSON))
	loginReq.Header.Set("Content-Type", "application/json")
	loginRecorder := httptest.NewRecorder()

	router.ServeHTTP(loginRecorder, loginReq)

	fmt.Printf("   Status Code: %d\n", loginRecorder.Code)
	if loginRecorder.Code == http.StatusOK {
		fmt.Println("   ✅ Login successful!")
		var response map[string]interface{}
		json.Unmarshal(loginRecorder.Body.Bytes(), &response)
		if data, ok := response["data"].(map[string]interface{}); ok {
			if user, ok := data["user"].(map[string]interface{}); ok {
				fmt.Printf("   User: %s\n", user["name"])
				fmt.Printf("   Email: %s\n", user["email"])
			}
			if token, ok := data["accessToken"].(string); ok {
				fmt.Printf("   Access Token: %s...\n", token[:20])
			}
		}
	} else {
		fmt.Printf("   ❌ Login failed: %s\n", loginRecorder.Body.String())
	}

	// Test 3: Forgot Password
	fmt.Println("\n3️⃣ Testing Forgot Password")
	fmt.Println(strings.Repeat("-", 30))

	forgotData := map[string]interface{}{
		"email": "test@example.com",
	}

	forgotJSON, _ := json.Marshal(forgotData)
	forgotReq := httptest.NewRequest("POST", "/api/v1/auth/forgot-password", bytes.NewBuffer(forgotJSON))
	forgotReq.Header.Set("Content-Type", "application/json")
	forgotRecorder := httptest.NewRecorder()

	router.ServeHTTP(forgotRecorder, forgotReq)

	fmt.Printf("   Status Code: %d\n", forgotRecorder.Code)
	if forgotRecorder.Code == http.StatusOK {
		fmt.Println("   ✅ Forgot password successful!")
	} else {
		fmt.Printf("   ❌ Forgot password failed: %s\n", forgotRecorder.Body.String())
	}

	// Test 4: Duplicate Email Registration
	fmt.Println("\n4️⃣ Testing Duplicate Email Validation")
	fmt.Println(strings.Repeat("-", 30))

	duplicateData := map[string]interface{}{
		"name":     "Another User",
		"email":    "test@example.com", // Same email
		"phone":    "+9876543210",
		"password": "password123",
	}

	duplicateJSON, _ := json.Marshal(duplicateData)
	duplicateReq := httptest.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(duplicateJSON))
	duplicateReq.Header.Set("Content-Type", "application/json")
	duplicateRecorder := httptest.NewRecorder()

	router.ServeHTTP(duplicateRecorder, duplicateReq)

	fmt.Printf("   Status Code: %d\n", duplicateRecorder.Code)
	if duplicateRecorder.Code == http.StatusConflict {
		fmt.Println("   ✅ Duplicate email validation working!")
	} else {
		fmt.Printf("   ❌ Duplicate email validation failed: %s\n", duplicateRecorder.Body.String())
	}

	fmt.Println("\n🎉 Authentication Endpoints Test Completed!")
	fmt.Println(strings.Repeat("=", 50))
}

func main() {
	// Run the test
	TestAuthenticationEndpoints(&testing.T{})
}
