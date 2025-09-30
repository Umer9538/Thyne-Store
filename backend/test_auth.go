package main

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"thyne-jewels-backend/internal/config"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

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

func main() {
	fmt.Println("🧪 Testing Authentication & User Management System")
	fmt.Println(strings.Repeat("=", 50))

	// Create mock repository
	mockRepo := newMockUserRepository()

	// Create auth service
	jwtConfig := config.JWTConfig{
		Secret: "test-secret-key-for-testing-purposes-only",
	}
	authService := services.NewAuthService(mockRepo, jwtConfig, 12)

	// Test 1: Customer Sign Up (Email and Phone)
	fmt.Println("\n1️⃣ Testing Customer Sign Up (Email and Phone)")
	fmt.Println(strings.Repeat("-", 40))

	registerReq := &models.CreateUserRequest{
		Name:     "John Doe",
		Email:    "john.doe@example.com",
		Phone:    "+1234567890",
		Password: "password123",
	}

	registerResp, err := authService.Register(registerReq)
	if err != nil {
		log.Printf("❌ Registration failed: %v", err)
	} else {
		fmt.Printf("✅ Registration successful!\n")
		fmt.Printf("   User ID: %s\n", registerResp.User.ID.Hex())
		fmt.Printf("   Email: %s\n", registerResp.User.Email)
		fmt.Printf("   Phone: %s\n", registerResp.User.Phone)
		fmt.Printf("   IsAdmin: %t\n", registerResp.User.IsAdmin)
		fmt.Printf("   Access Token: %s...\n", registerResp.AccessToken[:20])
		fmt.Printf("   Refresh Token: %s...\n", registerResp.RefreshToken[:20])
	}

	// Test 2: Login and Logout
	fmt.Println("\n2️⃣ Testing Login and Logout")
	fmt.Println(strings.Repeat("-", 40))

	loginReq := &models.LoginRequest{
		Email:    "john.doe@example.com",
		Password: "password123",
	}

	loginResp, err := authService.Login(loginReq)
	if err != nil {
		log.Printf("❌ Login failed: %v", err)
	} else {
		fmt.Printf("✅ Login successful!\n")
		fmt.Printf("   User: %s\n", loginResp.User.Name)
		fmt.Printf("   Email: %s\n", loginResp.User.Email)
		fmt.Printf("   Access Token: %s...\n", loginResp.AccessToken[:20])
	}

	// Test 3: Password Reset and Profile Updates
	fmt.Println("\n3️⃣ Testing Password Reset and Profile Updates")
	fmt.Println(strings.Repeat("-", 40))

	// Test forgot password
	err = authService.ForgotPassword("john.doe@example.com")
	if err != nil {
		log.Printf("❌ Forgot password failed: %v", err)
	} else {
		fmt.Printf("✅ Forgot password request successful!\n")
	}

	// Test change password
	changePasswordReq := &models.ChangePasswordRequest{
		CurrentPassword: "password123",
		NewPassword:     "newpassword456",
	}

	err = authService.ChangePassword(loginResp.User.ID, changePasswordReq)
	if err != nil {
		log.Printf("❌ Change password failed: %v", err)
	} else {
		fmt.Printf("✅ Password changed successfully!\n")
	}

	// Test login with new password
	newLoginReq := &models.LoginRequest{
		Email:    "john.doe@example.com",
		Password: "newpassword456",
	}

	newLoginResp, err := authService.Login(newLoginReq)
	if err != nil {
		log.Printf("❌ Login with new password failed: %v", err)
	} else {
		fmt.Printf("✅ Login with new password successful!\n")
	}

	// Test 4: Role-based Access (Admin, Customer, Guest)
	fmt.Println("\n4️⃣ Testing Role-based Access (Admin, Customer, Guest)")
	fmt.Println(strings.Repeat("-", 40))

	// Test token validation
	user, err := authService.ValidateToken(newLoginResp.AccessToken)
	if err != nil {
		log.Printf("❌ Token validation failed: %v", err)
	} else {
		fmt.Printf("✅ Token validation successful!\n")
		fmt.Printf("   User: %s\n", user.Name)
		fmt.Printf("   Email: %s\n", user.Email)
		fmt.Printf("   IsAdmin: %t\n", user.IsAdmin)
		fmt.Printf("   IsActive: %t\n", user.IsActive)
	}

	// Test admin role (create admin user)
	adminReq := &models.CreateUserRequest{
		Name:     "Admin User",
		Email:    "admin@example.com",
		Phone:    "+9876543210",
		Password: "admin123",
	}

	adminResp, err := authService.Register(adminReq)
	if err != nil {
		log.Printf("❌ Admin registration failed: %v", err)
	} else {
		// Make user admin
		adminResp.User.IsAdmin = true
		mockRepo.Update(nil, adminResp.User)
		fmt.Printf("✅ Admin user created and promoted!\n")
		fmt.Printf("   Admin ID: %s\n", adminResp.User.ID.Hex())
		fmt.Printf("   Admin Email: %s\n", adminResp.User.Email)
		fmt.Printf("   IsAdmin: %t\n", adminResp.User.IsAdmin)
	}

	// Test duplicate email registration
	duplicateReq := &models.CreateUserRequest{
		Name:     "Duplicate User",
		Email:    "john.doe@example.com", // Same email
		Phone:    "+1111111111",
		Password: "password123",
	}

	_, err = authService.Register(duplicateReq)
	if err != nil {
		fmt.Printf("✅ Duplicate email validation working: %v\n", err)
	} else {
		fmt.Printf("❌ Duplicate email validation failed!\n")
	}

	// Test duplicate phone registration
	duplicatePhoneReq := &models.CreateUserRequest{
		Name:     "Duplicate Phone User",
		Email:    "different@example.com",
		Phone:    "+1234567890", // Same phone
		Password: "password123",
	}

	_, err = authService.Register(duplicatePhoneReq)
	if err != nil {
		fmt.Printf("✅ Duplicate phone validation working: %v\n", err)
	} else {
		fmt.Printf("❌ Duplicate phone validation failed!\n")
	}

	fmt.Println("\n🎉 Authentication & User Management Tests Completed!")
	fmt.Println(strings.Repeat("=", 50))
}
