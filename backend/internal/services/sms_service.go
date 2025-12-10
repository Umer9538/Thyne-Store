package services

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

// SMSService handles SMS and OTP operations via Gupshup
type SMSService struct {
	userID         string
	password       string
	entityID       string
	templateID     string
	encryptionKey  string
	baseURL        string
	otpCodeLength  int
	otpCodeType    string
	useEncryption  bool
	httpClient     *http.Client
}

// GupshupConfig holds configuration for Gupshup SMS service
type GupshupConfig struct {
	UserID        string
	Password      string
	EntityID      string
	TemplateID    string
	EncryptionKey string
	OTPCodeLength int
	OTPCodeType   string // NUMERIC, ALPHABETIC, ALPHANUMERIC
	UseEncryption bool
}

// SMSResponse represents Gupshup API response
type SMSResponse struct {
	Success       bool   `json:"success"`
	TransactionID string `json:"transactionId,omitempty"`
	Message       string `json:"message"`
	Phone         string `json:"phone,omitempty"`
}

// OTPSendResponse represents the response from sending OTP
type OTPSendResponse struct {
	Success       bool   `json:"success"`
	TransactionID string `json:"transactionId"`
	Message       string `json:"message"`
	Phone         string `json:"phone"`
}

// OTPVerifyResponse represents the response from verifying OTP
type OTPVerifyResponse struct {
	Success       bool   `json:"success"`
	Verified      bool   `json:"verified"`
	Message       string `json:"message"`
	TransactionID string `json:"transactionId,omitempty"`
}

// NewSMSService creates a new SMS service with Gupshup
func NewSMSService() (*SMSService, error) {
	userID := os.Getenv("GUPSHUP_USER_ID")
	password := os.Getenv("GUPSHUP_PASSWORD")

	if userID == "" || password == "" {
		return nil, errors.New("GUPSHUP_USER_ID and GUPSHUP_PASSWORD are required")
	}

	otpCodeLength := 6 // Default 6 digits
	otpCodeType := "NUMERIC" // Default numeric

	service := &SMSService{
		userID:        userID,
		password:      password,
		entityID:      os.Getenv("GUPSHUP_ENTITY_ID"),
		templateID:    os.Getenv("GUPSHUP_TEMPLATE_ID"),
		encryptionKey: os.Getenv("GUPSHUP_ENCRYPTION_KEY"),
		baseURL:       "https://enterprise.smsgupshup.com/GatewayAPI/rest",
		otpCodeLength: otpCodeLength,
		otpCodeType:   otpCodeType,
		useEncryption: os.Getenv("GUPSHUP_USE_ENCRYPTION") == "true",
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}

	return service, nil
}

// NewSMSServiceWithConfig creates SMS service with explicit config
func NewSMSServiceWithConfig(cfg GupshupConfig) (*SMSService, error) {
	if cfg.UserID == "" || cfg.Password == "" {
		return nil, errors.New("UserID and Password are required")
	}

	otpCodeLength := cfg.OTPCodeLength
	if otpCodeLength == 0 {
		otpCodeLength = 6
	}

	otpCodeType := cfg.OTPCodeType
	if otpCodeType == "" {
		otpCodeType = "NUMERIC"
	}

	return &SMSService{
		userID:        cfg.UserID,
		password:      cfg.Password,
		entityID:      cfg.EntityID,
		templateID:    cfg.TemplateID,
		encryptionKey: cfg.EncryptionKey,
		baseURL:       "https://enterprise.smsgupshup.com/GatewayAPI/rest",
		otpCodeLength: otpCodeLength,
		otpCodeType:   otpCodeType,
		useEncryption: cfg.UseEncryption,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}, nil
}

// IsEnabled returns true if the SMS service is properly configured
func (s *SMSService) IsEnabled() bool {
	return s.userID != "" && s.password != ""
}

// SendOTP sends an OTP to the specified phone number
// Phone should be in format: 919876543210 (country code + number)
func (s *SMSService) SendOTP(ctx context.Context, phone string, messageTemplate string) (*OTPSendResponse, error) {
	if !s.IsEnabled() {
		return nil, errors.New("SMS service is not enabled")
	}

	// Clean phone number - remove any spaces, dashes, or + prefix
	phone = cleanPhoneNumber(phone)

	// Default message template if not provided
	if messageTemplate == "" {
		messageTemplate = "Your OTP for Thyne Jewels is %code%. Valid for 5 minutes. Do not share with anyone."
	}

	// Build query parameters
	params := url.Values{}
	params.Set("userid", s.userID)
	params.Set("password", s.password)
	params.Set("method", "TWO_FACTOR_AUTH")
	params.Set("v", "1.1")
	params.Set("phone_no", phone)
	params.Set("msg", messageTemplate)
	params.Set("format", "json")
	params.Set("otpCodeLength", fmt.Sprintf("%d", s.otpCodeLength))
	params.Set("otpCodeType", s.otpCodeType)

	// Add DLT parameters if configured (required for India)
	if s.entityID != "" {
		params.Set("principalEntityId", s.entityID)
	}
	if s.templateID != "" {
		params.Set("dltTemplateId", s.templateID)
	}

	// Make the request
	reqURL := s.baseURL + "?" + params.Encode()

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send OTP request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Parse response - Gupshup returns pipe-separated values
	// Format: success | phone | transactionId | message
	responseStr := strings.TrimSpace(string(body))

	return parseGupshupOTPResponse(responseStr, phone)
}

// VerifyOTP verifies the OTP entered by user
func (s *SMSService) VerifyOTP(ctx context.Context, phone string, otpCode string) (*OTPVerifyResponse, error) {
	if !s.IsEnabled() {
		return nil, errors.New("SMS service is not enabled")
	}

	// Clean phone number
	phone = cleanPhoneNumber(phone)

	// Build query parameters for verification
	params := url.Values{}
	params.Set("userid", s.userID)
	params.Set("password", s.password)
	params.Set("method", "TWO_FACTOR_AUTH")
	params.Set("v", "1.1")
	params.Set("phone_no", phone)
	params.Set("otp_code", otpCode)
	params.Set("format", "json")

	// Make the request
	reqURL := s.baseURL + "?" + params.Encode()

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to verify OTP request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Parse response
	responseStr := strings.TrimSpace(string(body))

	return parseGupshupVerifyResponse(responseStr, phone)
}

// SendSMS sends a regular SMS message (not OTP)
func (s *SMSService) SendSMS(ctx context.Context, phone string, message string) (*SMSResponse, error) {
	if !s.IsEnabled() {
		return nil, errors.New("SMS service is not enabled")
	}

	// Clean phone number
	phone = cleanPhoneNumber(phone)

	// Build query parameters
	params := url.Values{}
	params.Set("userid", s.userID)
	params.Set("password", s.password)
	params.Set("method", "sendMessage")
	params.Set("send_to", phone)
	params.Set("msg", message)
	params.Set("msg_type", "TEXT")
	params.Set("format", "json")
	params.Set("v", "1.1")

	// Add DLT parameters if configured
	if s.entityID != "" {
		params.Set("principalEntityId", s.entityID)
	}
	if s.templateID != "" {
		params.Set("dltTemplateId", s.templateID)
	}

	// Make the request
	reqURL := s.baseURL + "?" + params.Encode()

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send SMS request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Parse response
	responseStr := strings.TrimSpace(string(body))
	parts := strings.Split(responseStr, "|")

	if len(parts) >= 1 && strings.TrimSpace(parts[0]) == "success" {
		return &SMSResponse{
			Success: true,
			Message: "SMS sent successfully",
			Phone:   phone,
		}, nil
	}

	return &SMSResponse{
		Success: false,
		Message: responseStr,
		Phone:   phone,
	}, nil
}

// SendOTPWithEncryption sends OTP using encrypted payload (more secure)
func (s *SMSService) SendOTPWithEncryption(ctx context.Context, phone string, messageTemplate string) (*OTPSendResponse, error) {
	if !s.IsEnabled() {
		return nil, errors.New("SMS service is not enabled")
	}

	if s.encryptionKey == "" {
		return nil, errors.New("encryption key not configured")
	}

	// Clean phone number
	phone = cleanPhoneNumber(phone)

	// Default message template
	if messageTemplate == "" {
		messageTemplate = "Your OTP for Thyne Jewels is %code%. Valid for 5 minutes."
	}

	// Build query string for encryption (exclude userid)
	params := url.Values{}
	params.Set("password", s.password)
	params.Set("method", "TWO_FACTOR_AUTH")
	params.Set("v", "1.1")
	params.Set("phone_no", phone)
	params.Set("msg", messageTemplate)
	params.Set("format", "json")
	params.Set("otpCodeLength", fmt.Sprintf("%d", s.otpCodeLength))
	params.Set("otpCodeType", s.otpCodeType)

	if s.entityID != "" {
		params.Set("principalEntityId", s.entityID)
	}
	if s.templateID != "" {
		params.Set("dltTemplateId", s.templateID)
	}

	queryString := params.Encode()

	// Encrypt the query string
	encryptedData, err := encryptAES256GCM(queryString, s.encryptionKey)
	if err != nil {
		return nil, fmt.Errorf("failed to encrypt payload: %w", err)
	}

	// Make request with encrypted data
	reqURL := fmt.Sprintf("%s?userid=%s&encrdata=%s", s.baseURL, s.userID, url.QueryEscape(encryptedData))

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send OTP request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	responseStr := strings.TrimSpace(string(body))
	return parseGupshupOTPResponse(responseStr, phone)
}

// Helper functions

func cleanPhoneNumber(phone string) string {
	// Remove spaces, dashes, parentheses
	phone = strings.ReplaceAll(phone, " ", "")
	phone = strings.ReplaceAll(phone, "-", "")
	phone = strings.ReplaceAll(phone, "(", "")
	phone = strings.ReplaceAll(phone, ")", "")

	// Remove + prefix if present
	phone = strings.TrimPrefix(phone, "+")

	// If number doesn't start with country code, assume India (91)
	if len(phone) == 10 {
		phone = "91" + phone
	}

	return phone
}

func parseGupshupOTPResponse(responseStr string, phone string) (*OTPSendResponse, error) {
	// Try parsing as JSON first
	var jsonResp map[string]interface{}
	if err := json.Unmarshal([]byte(responseStr), &jsonResp); err == nil {
		// JSON response
		success := false
		if status, ok := jsonResp["status"].(string); ok {
			success = status == "success"
		}

		transactionID := ""
		if txn, ok := jsonResp["transactionId"].(string); ok {
			transactionID = txn
		}

		message := ""
		if msg, ok := jsonResp["message"].(string); ok {
			message = msg
		}

		return &OTPSendResponse{
			Success:       success,
			TransactionID: transactionID,
			Message:       message,
			Phone:         phone,
		}, nil
	}

	// Parse pipe-separated response
	// Format: success | phone | transactionId | message
	// Or: error | errorMessage
	parts := strings.Split(responseStr, "|")

	for i := range parts {
		parts[i] = strings.TrimSpace(parts[i])
	}

	if len(parts) >= 1 && parts[0] == "success" {
		transactionID := ""
		message := "OTP sent successfully"

		if len(parts) >= 3 {
			transactionID = parts[2]
		}
		if len(parts) >= 4 {
			message = parts[3]
		}

		return &OTPSendResponse{
			Success:       true,
			TransactionID: transactionID,
			Message:       message,
			Phone:         phone,
		}, nil
	}

	// Error response
	errorMsg := responseStr
	if len(parts) >= 2 {
		errorMsg = parts[1]
	}

	return &OTPSendResponse{
		Success: false,
		Message: errorMsg,
		Phone:   phone,
	}, nil
}

func parseGupshupVerifyResponse(responseStr string, phone string) (*OTPVerifyResponse, error) {
	// Try parsing as JSON first
	var jsonResp map[string]interface{}
	if err := json.Unmarshal([]byte(responseStr), &jsonResp); err == nil {
		success := false
		if status, ok := jsonResp["status"].(string); ok {
			success = status == "success"
		}

		verified := false
		message := ""
		if msg, ok := jsonResp["message"].(string); ok {
			message = msg
			verified = strings.Contains(strings.ToLower(msg), "matched")
		}

		return &OTPVerifyResponse{
			Success:  success,
			Verified: success && verified,
			Message:  message,
		}, nil
	}

	// Parse pipe-separated response
	parts := strings.Split(responseStr, "|")

	for i := range parts {
		parts[i] = strings.TrimSpace(parts[i])
	}

	if len(parts) >= 1 && parts[0] == "success" {
		message := ""
		if len(parts) >= 4 {
			message = parts[3]
		}

		// Check if OTP matched
		verified := strings.Contains(strings.ToLower(message), "matched")

		return &OTPVerifyResponse{
			Success:  true,
			Verified: verified,
			Message:  message,
		}, nil
	}

	// Error or OTP not matched
	errorMsg := responseStr
	if len(parts) >= 2 {
		errorMsg = parts[1]
	}

	// Check if it's "OTP not matched" vs actual error
	notMatched := strings.Contains(strings.ToLower(responseStr), "not matched") ||
		strings.Contains(strings.ToLower(responseStr), "invalid") ||
		strings.Contains(strings.ToLower(responseStr), "expired")

	return &OTPVerifyResponse{
		Success:  !notMatched, // API call succeeded even if OTP didn't match
		Verified: false,
		Message:  errorMsg,
	}, nil
}

// AES-256-GCM encryption for secure API calls
func encryptAES256GCM(plaintext string, keyHex string) (string, error) {
	// Key should be 32 bytes (256 bits) in hex = 64 characters
	if len(keyHex) != 64 {
		return "", errors.New("encryption key must be 64 hex characters (256 bits)")
	}

	key := make([]byte, 32)
	for i := 0; i < 32; i++ {
		fmt.Sscanf(keyHex[i*2:i*2+2], "%02x", &key[i])
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// Generate 12-byte IV
	iv := make([]byte, 12)
	if _, err := io.ReadFull(rand.Reader, iv); err != nil {
		return "", err
	}

	// Encrypt
	ciphertext := gcm.Seal(nil, iv, []byte(plaintext), nil)

	// Combine IV + ciphertext + auth tag and base64 encode
	combined := append(iv, ciphertext...)

	return base64.URLEncoding.EncodeToString(combined), nil
}
