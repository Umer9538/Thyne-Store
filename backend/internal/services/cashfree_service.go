package services

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"
	"time"

	"thyne-jewels-backend/internal/config"
)

// CashfreeService handles Cashfree payment operations
type CashfreeService struct {
	appID         string
	secretKey     string
	webhookSecret string
	environment   string
	baseURL       string
	apiVersion    string
	httpClient    *http.Client
}

// CashfreeOrderRequest represents the request to create an order
type CashfreeOrderRequest struct {
	OrderID         string                  `json:"order_id"`
	OrderAmount     float64                 `json:"order_amount"`
	OrderCurrency   string                  `json:"order_currency"`
	CustomerDetails CashfreeCustomerDetails `json:"customer_details"`
	OrderMeta       *CashfreeOrderMeta      `json:"order_meta,omitempty"`
	OrderNote       string                  `json:"order_note,omitempty"`
	OrderTags       map[string]string       `json:"order_tags,omitempty"`
}

// CashfreeCustomerDetails represents customer information
type CashfreeCustomerDetails struct {
	CustomerID    string `json:"customer_id"`
	CustomerPhone string `json:"customer_phone"`
	CustomerEmail string `json:"customer_email,omitempty"`
	CustomerName  string `json:"customer_name,omitempty"`
}

// CashfreeOrderMeta represents order metadata
type CashfreeOrderMeta struct {
	ReturnURL     string `json:"return_url,omitempty"`
	NotifyURL     string `json:"notify_url,omitempty"`
	PaymentMethods string `json:"payment_methods,omitempty"`
}

// CashfreeOrderResponse represents the response from creating an order
type CashfreeOrderResponse struct {
	CFOrderID        interface{} `json:"cf_order_id"` // Can be string or int64 depending on environment
	OrderID          string      `json:"order_id"`
	Entity           string      `json:"entity"`
	OrderCurrency    string      `json:"order_currency"`
	OrderAmount      float64     `json:"order_amount"`
	OrderStatus      string      `json:"order_status"`
	PaymentSessionID string      `json:"payment_session_id"`
	OrderExpiryTime  string      `json:"order_expiry_time,omitempty"`
	OrderNote        string      `json:"order_note,omitempty"`
	CreatedAt        string      `json:"created_at,omitempty"`
}

// CashfreePaymentResponse represents payment details
type CashfreePaymentResponse struct {
	CFPaymentID     interface{}            `json:"cf_payment_id"` // Can be string or int64 depending on environment
	OrderID         string                 `json:"order_id"`
	Entity          string                 `json:"entity"`
	PaymentCurrency string                 `json:"payment_currency"`
	PaymentAmount   float64                `json:"payment_amount"`
	PaymentStatus   string                 `json:"payment_status"`
	PaymentMethod   map[string]interface{} `json:"payment_method,omitempty"`
	PaymentTime     string                 `json:"payment_time,omitempty"`
	BankReference   string                 `json:"bank_reference,omitempty"`
}

// CashfreeWebhookPayload represents the webhook payload
type CashfreeWebhookPayload struct {
	Data      CashfreeWebhookData `json:"data"`
	EventTime string              `json:"event_time"`
	Type      string              `json:"type"`
}

// CashfreeWebhookData represents the data in webhook
type CashfreeWebhookData struct {
	Order   CashfreeOrderResponse   `json:"order"`
	Payment CashfreePaymentResponse `json:"payment"`
}

// CashfreeError represents an API error
type CashfreeError struct {
	Message string `json:"message"`
	Code    string `json:"code"`
	Type    string `json:"type"`
}

// NewCashfreeService creates a new Cashfree service instance
func NewCashfreeService(cfg config.CashfreeConfig) *CashfreeService {
	baseURL := "https://sandbox.cashfree.com/pg"
	if strings.ToUpper(cfg.Environment) == "PRODUCTION" {
		baseURL = "https://api.cashfree.com/pg"
	}

	return &CashfreeService{
		appID:         cfg.AppID,
		secretKey:     cfg.SecretKey,
		webhookSecret: cfg.WebhookSecret,
		environment:   cfg.Environment,
		baseURL:       baseURL,
		apiVersion:    "2025-01-01",
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// IsEnabled returns true if Cashfree is properly configured
func (s *CashfreeService) IsEnabled() bool {
	return s.appID != "" && s.secretKey != ""
}

// CreateOrder creates a new payment order in Cashfree
func (s *CashfreeService) CreateOrder(ctx context.Context, req *CashfreeOrderRequest) (*CashfreeOrderResponse, error) {
	if !s.IsEnabled() {
		return nil, errors.New("Cashfree service is not configured")
	}

	// Set default currency if not provided
	if req.OrderCurrency == "" {
		req.OrderCurrency = "INR"
	}

	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", s.baseURL+"/orders", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	s.setHeaders(httpReq)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		var apiErr CashfreeError
		if err := json.Unmarshal(body, &apiErr); err == nil && apiErr.Message != "" {
			return nil, fmt.Errorf("Cashfree API error: %s (code: %s)", apiErr.Message, apiErr.Code)
		}
		return nil, fmt.Errorf("Cashfree API error: status %d, body: %s", resp.StatusCode, string(body))
	}

	var orderResp CashfreeOrderResponse
	if err := json.Unmarshal(body, &orderResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &orderResp, nil
}

// GetOrder retrieves order details from Cashfree
func (s *CashfreeService) GetOrder(ctx context.Context, orderID string) (*CashfreeOrderResponse, error) {
	if !s.IsEnabled() {
		return nil, errors.New("Cashfree service is not configured")
	}

	httpReq, err := http.NewRequestWithContext(ctx, "GET", s.baseURL+"/orders/"+orderID, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	s.setHeaders(httpReq)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		var apiErr CashfreeError
		if err := json.Unmarshal(body, &apiErr); err == nil && apiErr.Message != "" {
			return nil, fmt.Errorf("Cashfree API error: %s", apiErr.Message)
		}
		return nil, fmt.Errorf("Cashfree API error: status %d", resp.StatusCode)
	}

	var orderResp CashfreeOrderResponse
	if err := json.Unmarshal(body, &orderResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &orderResp, nil
}

// GetPaymentsForOrder retrieves all payments for an order
func (s *CashfreeService) GetPaymentsForOrder(ctx context.Context, orderID string) ([]CashfreePaymentResponse, error) {
	if !s.IsEnabled() {
		return nil, errors.New("Cashfree service is not configured")
	}

	httpReq, err := http.NewRequestWithContext(ctx, "GET", s.baseURL+"/orders/"+orderID+"/payments", nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	s.setHeaders(httpReq)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Cashfree API error: status %d", resp.StatusCode)
	}

	var payments []CashfreePaymentResponse
	if err := json.Unmarshal(body, &payments); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return payments, nil
}

// VerifyWebhookSignature verifies the webhook signature from Cashfree
func (s *CashfreeService) VerifyWebhookSignature(payload []byte, timestamp string, signature string) bool {
	if s.webhookSecret == "" {
		return false
	}

	// Create the message to sign: timestamp + payload
	message := timestamp + string(payload)

	// Generate HMAC-SHA256
	h := hmac.New(sha256.New, []byte(s.webhookSecret))
	h.Write([]byte(message))
	expectedSignature := base64.StdEncoding.EncodeToString(h.Sum(nil))

	return hmac.Equal([]byte(signature), []byte(expectedSignature))
}

// VerifyWebhookSignatureV2 verifies webhook using the older method (sorted keys)
func (s *CashfreeService) VerifyWebhookSignatureV2(payload map[string]interface{}, signature string) bool {
	if s.webhookSecret == "" {
		return false
	}

	// Sort keys
	keys := make([]string, 0, len(payload))
	for k := range payload {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	// Concatenate values
	var postData strings.Builder
	for _, k := range keys {
		postData.WriteString(fmt.Sprintf("%v", payload[k]))
	}

	// Generate SHA256
	h := sha256.New()
	h.Write([]byte(postData.String()))
	computedSignature := base64.StdEncoding.EncodeToString(h.Sum(nil))

	return computedSignature == signature
}

// ParseWebhookPayload parses the webhook payload
func (s *CashfreeService) ParseWebhookPayload(payload []byte) (*CashfreeWebhookPayload, error) {
	var webhookPayload CashfreeWebhookPayload
	if err := json.Unmarshal(payload, &webhookPayload); err != nil {
		return nil, fmt.Errorf("failed to parse webhook payload: %w", err)
	}
	return &webhookPayload, nil
}

// IsPaymentSuccessful checks if a payment was successful
func (s *CashfreeService) IsPaymentSuccessful(status string) bool {
	return strings.ToUpper(status) == "SUCCESS" || strings.ToUpper(status) == "PAID"
}

// IsOrderPaid checks if an order is paid
func (s *CashfreeService) IsOrderPaid(status string) bool {
	return strings.ToUpper(status) == "PAID"
}

// GetEnvironment returns current environment
func (s *CashfreeService) GetEnvironment() string {
	return s.environment
}

// GetBaseURL returns the base URL
func (s *CashfreeService) GetBaseURL() string {
	return s.baseURL
}

// setHeaders sets the required headers for Cashfree API calls
func (s *CashfreeService) setHeaders(req *http.Request) {
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-client-id", s.appID)
	req.Header.Set("x-client-secret", s.secretKey)
	req.Header.Set("x-api-version", s.apiVersion)
}

// CreatePaymentLink creates a payment link (alternative to checkout)
func (s *CashfreeService) CreatePaymentLink(ctx context.Context, linkID string, amount float64, customerPhone string, customerEmail string, customerName string, purpose string, expiryTime *time.Time) (string, error) {
	if !s.IsEnabled() {
		return "", errors.New("Cashfree service is not configured")
	}

	payload := map[string]interface{}{
		"link_id":       linkID,
		"link_amount":   amount,
		"link_currency": "INR",
		"link_purpose":  purpose,
		"customer_details": map[string]string{
			"customer_phone": customerPhone,
			"customer_email": customerEmail,
			"customer_name":  customerName,
		},
		"link_notify": map[string]bool{
			"send_sms":   true,
			"send_email": true,
		},
	}

	if expiryTime != nil {
		payload["link_expiry_time"] = expiryTime.Format(time.RFC3339)
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", s.baseURL+"/links", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	s.setHeaders(httpReq)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return "", fmt.Errorf("Cashfree API error: status %d, body: %s", resp.StatusCode, string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("failed to parse response: %w", err)
	}

	if linkURL, ok := result["link_url"].(string); ok {
		return linkURL, nil
	}

	return "", errors.New("link_url not found in response")
}

// RefundPayment initiates a refund for a payment
func (s *CashfreeService) RefundPayment(ctx context.Context, orderID string, refundID string, refundAmount float64, refundNote string) error {
	if !s.IsEnabled() {
		return errors.New("Cashfree service is not configured")
	}

	payload := map[string]interface{}{
		"refund_id":     refundID,
		"refund_amount": refundAmount,
		"refund_note":   refundNote,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", s.baseURL+"/orders/"+orderID+"/refunds", bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	s.setHeaders(httpReq)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("Cashfree API error: status %d, body: %s", resp.StatusCode, string(body))
	}

	return nil
}
