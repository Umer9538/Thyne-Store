package services

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"os"
	"strings"
	"time"

	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// MessagingService handles SMS and WhatsApp messaging via Mtalkz
type MessagingService struct {
	db         *mongo.Database
	apiKey     string
	baseURL    string
	senderID   string
	httpClient *http.Client

	// Template IDs (from DLT registration)
	smsOTPTemplateID         string
	orderConfirmTemplateID   string
	paymentSuccessTemplateID string
	shippingUpdateTemplateID string

	// WhatsApp template names
	whatsappOTPTemplate     string
	whatsappOrderTemplate   string
	whatsappShippingTemplate string
}

// NewMessagingService creates a new messaging service
func NewMessagingService(db *mongo.Database) *MessagingService {
	return &MessagingService{
		db:         db,
		apiKey:     getEnvOrDefault("MTALKZ_API_KEY", ""),
		baseURL:    getEnvOrDefault("MTALKZ_BASE_URL", "https://api.mtalkz.com"),
		senderID:   getEnvOrDefault("MTALKZ_SENDER_ID", "THYNEJ"),
		httpClient: &http.Client{Timeout: 30 * time.Second},

		// SMS Template IDs
		smsOTPTemplateID:         getEnvOrDefault("MTALKZ_SMS_OTP_TEMPLATE_ID", ""),
		orderConfirmTemplateID:   getEnvOrDefault("MTALKZ_ORDER_CONFIRM_TEMPLATE_ID", ""),
		paymentSuccessTemplateID: getEnvOrDefault("MTALKZ_PAYMENT_SUCCESS_TEMPLATE_ID", ""),
		shippingUpdateTemplateID: getEnvOrDefault("MTALKZ_SHIPPING_UPDATE_TEMPLATE_ID", ""),

		// WhatsApp Template Names
		whatsappOTPTemplate:      getEnvOrDefault("MTALKZ_WHATSAPP_OTP_TEMPLATE", "otp_verification"),
		whatsappOrderTemplate:    getEnvOrDefault("MTALKZ_WHATSAPP_ORDER_TEMPLATE", "order_status_update"),
		whatsappShippingTemplate: getEnvOrDefault("MTALKZ_WHATSAPP_SHIPPING_TEMPLATE", "shipping_update"),
	}
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// ==================== OTP Methods ====================

// SendOTP generates and sends OTP via specified channel
func (s *MessagingService) SendOTP(ctx context.Context, req *models.SendOTPRequest) (*models.SendOTPResponse, error) {
	// Normalize phone number
	phone := normalizePhone(req.Phone)

	// Default channel to SMS
	channel := req.Channel
	if channel == "" {
		channel = models.OTPChannelSMS
	}

	// Check for existing OTP and cooldown
	existingOTP, err := s.getLatestOTP(ctx, phone)
	if err == nil && existingOTP != nil {
		// Check cooldown (30 seconds between resends)
		cooldownTime := existingOTP.CreatedAt.Add(time.Duration(models.OTPResendCooldown) * time.Second)
		if time.Now().Before(cooldownTime) {
			remainingSeconds := int(cooldownTime.Sub(time.Now()).Seconds())
			return &models.SendOTPResponse{
				Success:   false,
				Message:   fmt.Sprintf("Please wait %d seconds before requesting another OTP", remainingSeconds),
				ExpiresIn: remainingSeconds,
				Channel:   string(channel),
			}, nil
		}
	}

	// Generate OTP
	otp, err := generateOTP(models.OTPLength)
	if err != nil {
		return nil, fmt.Errorf("failed to generate OTP: %w", err)
	}

	// Save OTP to database
	otpRecord := &models.OTPRecord{
		ID:        primitive.NewObjectID(),
		Phone:     phone,
		OTP:       otp,
		Channel:   channel,
		Purpose:   req.Purpose,
		Verified:  false,
		Attempts:  0,
		ExpiresAt: time.Now().Add(time.Duration(models.OTPExpiryMinutes) * time.Minute),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	collection := s.db.Collection("otp_records")
	_, err = collection.InsertOne(ctx, otpRecord)
	if err != nil {
		return nil, fmt.Errorf("failed to save OTP: %w", err)
	}

	// Send OTP via appropriate channel
	var messageID string
	var sendErr error

	switch channel {
	case models.OTPChannelWhatsApp:
		messageID, sendErr = s.sendWhatsAppOTP(ctx, phone, otp)
	default:
		messageID, sendErr = s.sendSMSOTP(ctx, phone, otp)
	}

	if sendErr != nil {
		// Log the error but still return success if OTP was saved
		s.logMessage(ctx, primitive.NilObjectID, phone, channel, models.MessageTypeOTP, otp, "", "failed", sendErr.Error())
		return &models.SendOTPResponse{
			Success:   false,
			Message:   "Failed to send OTP. Please try again.",
			Channel:   string(channel),
		}, sendErr
	}

	// Log successful message
	s.logMessage(ctx, primitive.NilObjectID, phone, channel, models.MessageTypeOTP, "OTP sent", messageID, "sent", "")

	return &models.SendOTPResponse{
		Success:   true,
		Message:   fmt.Sprintf("OTP sent successfully via %s", channel),
		MessageID: messageID,
		ExpiresIn: models.OTPExpiryMinutes * 60,
		Channel:   string(channel),
	}, nil
}

// VerifyOTP verifies the OTP entered by user
func (s *MessagingService) VerifyOTP(ctx context.Context, req *models.VerifyOTPRequest) (*models.VerifyOTPResponse, error) {
	phone := normalizePhone(req.Phone)

	collection := s.db.Collection("otp_records")

	// Find the latest unverified OTP for this phone
	filter := bson.M{
		"phone":     phone,
		"verified":  false,
		"expiresAt": bson.M{"$gt": time.Now()},
	}
	opts := options.FindOne().SetSort(bson.M{"createdAt": -1})

	var otpRecord models.OTPRecord
	err := collection.FindOne(ctx, filter, opts).Decode(&otpRecord)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return &models.VerifyOTPResponse{
				Success:  false,
				Message:  "OTP expired or not found. Please request a new OTP.",
				Verified: false,
			}, nil
		}
		return nil, fmt.Errorf("failed to find OTP: %w", err)
	}

	// Check max attempts
	if otpRecord.Attempts >= models.OTPMaxAttempts {
		return &models.VerifyOTPResponse{
			Success:  false,
			Message:  "Maximum verification attempts exceeded. Please request a new OTP.",
			Verified: false,
		}, nil
	}

	// Increment attempts
	_, err = collection.UpdateOne(ctx,
		bson.M{"_id": otpRecord.ID},
		bson.M{
			"$inc": bson.M{"attempts": 1},
			"$set": bson.M{"updatedAt": time.Now()},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update attempts: %w", err)
	}

	// Verify OTP
	if otpRecord.OTP != req.OTP {
		remainingAttempts := models.OTPMaxAttempts - otpRecord.Attempts - 1
		return &models.VerifyOTPResponse{
			Success:  false,
			Message:  fmt.Sprintf("Invalid OTP. %d attempts remaining.", remainingAttempts),
			Verified: false,
		}, nil
	}

	// Mark as verified
	_, err = collection.UpdateOne(ctx,
		bson.M{"_id": otpRecord.ID},
		bson.M{"$set": bson.M{
			"verified":  true,
			"updatedAt": time.Now(),
		}},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to mark OTP as verified: %w", err)
	}

	return &models.VerifyOTPResponse{
		Success:  true,
		Message:  "OTP verified successfully",
		Verified: true,
	}, nil
}

// ResendOTP resends OTP, optionally via different channel
func (s *MessagingService) ResendOTP(ctx context.Context, req *models.ResendOTPRequest) (*models.SendOTPResponse, error) {
	// Convert to SendOTPRequest
	sendReq := &models.SendOTPRequest{
		Phone:   req.Phone,
		Channel: req.Channel,
		Purpose: "resend",
	}
	return s.SendOTP(ctx, sendReq)
}

// ==================== SMS Methods ====================

// sendSMSOTP sends OTP via SMS
func (s *MessagingService) sendSMSOTP(ctx context.Context, phone, otp string) (string, error) {
	// Format message
	message := fmt.Sprintf("Your Thyne Jewels verification code is %s. Valid for %d minutes. Do not share with anyone.", otp, models.OTPExpiryMinutes)

	return s.sendSMS(ctx, phone, message, "OTP", s.smsOTPTemplateID)
}

// sendSMS sends SMS via Mtalkz API
func (s *MessagingService) sendSMS(ctx context.Context, phone, message, msgType, templateID string) (string, error) {
	// Check if API key is configured
	if s.apiKey == "" {
		// Development mode - just log and return success
		fmt.Printf("[DEV] SMS to %s: %s\n", phone, message)
		return "dev-" + time.Now().Format("20060102150405"), nil
	}

	reqBody := models.MtalkzSMSRequest{
		Sender:     s.senderID,
		To:         phone,
		Text:       message,
		Type:       msgType,
		TemplateID: templateID,
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", s.baseURL+"/v1/sms", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", s.apiKey)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	var smsResp models.MtalkzSMSResponse
	if err := json.Unmarshal(body, &smsResp); err != nil {
		return "", fmt.Errorf("failed to parse response: %w", err)
	}

	if smsResp.Error != "" {
		return "", fmt.Errorf("mtalkz error: %s", smsResp.Error)
	}

	messageID := smsResp.ID
	if len(smsResp.Data) > 0 {
		messageID = smsResp.Data[0].MessageID
	}

	return messageID, nil
}

// SendTransactionalSMS sends a transactional SMS
func (s *MessagingService) SendTransactionalSMS(ctx context.Context, phone, templateID string, params map[string]string) (string, error) {
	// Build message from template params
	message := buildMessageFromParams(templateID, params)
	return s.sendSMS(ctx, phone, message, "TRANS", templateID)
}

// ==================== WhatsApp Methods ====================

// sendWhatsAppOTP sends OTP via WhatsApp
func (s *MessagingService) sendWhatsAppOTP(ctx context.Context, phone, otp string) (string, error) {
	template := &models.MtalkzWhatsAppTemplate{
		Name: s.whatsappOTPTemplate,
		Language: models.MtalkzTemplateLanguage{
			Code: "en",
		},
		Components: []models.MtalkzTemplateComponent{
			{
				Type: "body",
				Parameters: []models.MtalkzTemplateParameter{
					{Type: "text", Text: otp},
				},
			},
		},
	}

	return s.sendWhatsAppTemplate(ctx, phone, template)
}

// sendWhatsAppTemplate sends a WhatsApp template message
func (s *MessagingService) sendWhatsAppTemplate(ctx context.Context, phone string, template *models.MtalkzWhatsAppTemplate) (string, error) {
	// Check if API key is configured
	if s.apiKey == "" {
		// Development mode - just log and return success
		fmt.Printf("[DEV] WhatsApp template '%s' to %s\n", template.Name, phone)
		return "dev-wa-" + time.Now().Format("20060102150405"), nil
	}

	reqBody := models.MtalkzWhatsAppRequest{
		To:       phone,
		Type:     "template",
		Template: template,
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", s.baseURL+"/v1/whatsapp", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", s.apiKey)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	var waResp models.MtalkzWhatsAppResponse
	if err := json.Unmarshal(body, &waResp); err != nil {
		return "", fmt.Errorf("failed to parse response: %w", err)
	}

	if waResp.Error != "" {
		return "", fmt.Errorf("mtalkz whatsapp error: %s", waResp.Error)
	}

	return waResp.MessageID, nil
}

// SendWhatsAppText sends a plain text WhatsApp message
func (s *MessagingService) SendWhatsAppText(ctx context.Context, phone, message string) (string, error) {
	// Check if API key is configured
	if s.apiKey == "" {
		fmt.Printf("[DEV] WhatsApp text to %s: %s\n", phone, message)
		return "dev-wa-" + time.Now().Format("20060102150405"), nil
	}

	reqBody := models.MtalkzWhatsAppRequest{
		To:   phone,
		Type: "text",
		Text: &models.MtalkzWhatsAppText{
			Body: message,
		},
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", s.baseURL+"/v1/whatsapp", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", s.apiKey)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	var waResp models.MtalkzWhatsAppResponse
	if err := json.Unmarshal(body, &waResp); err != nil {
		return "", fmt.Errorf("failed to parse response: %w", err)
	}

	if waResp.Error != "" {
		return "", fmt.Errorf("mtalkz whatsapp error: %s", waResp.Error)
	}

	return waResp.MessageID, nil
}

// ==================== Transactional Messages ====================

// SendOrderConfirmation sends order confirmation via SMS and/or WhatsApp
func (s *MessagingService) SendOrderConfirmation(ctx context.Context, phone, orderID string, channel models.OTPChannel) error {
	message := fmt.Sprintf("Thank you for your order #%s! Your custom jewelry design has been received. We'll contact you within 24 hours. - Thyne Jewels", orderID)

	switch channel {
	case models.OTPChannelWhatsApp:
		template := &models.MtalkzWhatsAppTemplate{
			Name:     s.whatsappOrderTemplate,
			Language: models.MtalkzTemplateLanguage{Code: "en"},
			Components: []models.MtalkzTemplateComponent{
				{
					Type: "body",
					Parameters: []models.MtalkzTemplateParameter{
						{Type: "text", Text: orderID},
						{Type: "text", Text: "Order Received"},
					},
				},
			},
		}
		_, err := s.sendWhatsAppTemplate(ctx, phone, template)
		return err
	default:
		_, err := s.sendSMS(ctx, phone, message, "TRANS", s.orderConfirmTemplateID)
		return err
	}
}

// SendPaymentSuccess sends payment success notification
func (s *MessagingService) SendPaymentSuccess(ctx context.Context, phone, orderID, amount string) error {
	message := fmt.Sprintf("Payment of Rs.%s received for order #%s. Thank you for shopping with Thyne Jewels!", amount, orderID)
	_, err := s.sendSMS(ctx, phone, message, "TRANS", s.paymentSuccessTemplateID)
	return err
}

// SendShippingUpdate sends shipping/delivery update
func (s *MessagingService) SendShippingUpdate(ctx context.Context, phone, orderID, status, trackingURL string, channel models.OTPChannel) error {
	switch channel {
	case models.OTPChannelWhatsApp:
		template := &models.MtalkzWhatsAppTemplate{
			Name:     s.whatsappShippingTemplate,
			Language: models.MtalkzTemplateLanguage{Code: "en"},
			Components: []models.MtalkzTemplateComponent{
				{
					Type: "body",
					Parameters: []models.MtalkzTemplateParameter{
						{Type: "text", Text: orderID},
						{Type: "text", Text: status},
					},
				},
			},
		}
		_, err := s.sendWhatsAppTemplate(ctx, phone, template)
		return err
	default:
		message := fmt.Sprintf("Order #%s update: %s. Track your order: %s - Thyne Jewels", orderID, status, trackingURL)
		_, err := s.sendSMS(ctx, phone, message, "TRANS", s.shippingUpdateTemplateID)
		return err
	}
}

// ==================== Helper Methods ====================

// getLatestOTP gets the latest OTP record for a phone
func (s *MessagingService) getLatestOTP(ctx context.Context, phone string) (*models.OTPRecord, error) {
	collection := s.db.Collection("otp_records")

	filter := bson.M{
		"phone":    phone,
		"verified": false,
	}
	opts := options.FindOne().SetSort(bson.M{"createdAt": -1})

	var otpRecord models.OTPRecord
	err := collection.FindOne(ctx, filter, opts).Decode(&otpRecord)
	if err != nil {
		return nil, err
	}
	return &otpRecord, nil
}

// logMessage logs a sent message
func (s *MessagingService) logMessage(ctx context.Context, userID primitive.ObjectID, phone string, channel models.OTPChannel, msgType models.MessageType, content, messageID, status, errorMsg string) {
	collection := s.db.Collection("message_logs")

	log := models.MessageLog{
		ID:          primitive.NewObjectID(),
		UserID:      userID,
		Phone:       phone,
		Channel:     channel,
		MessageType: msgType,
		Content:     content,
		MessageID:   messageID,
		Status:      status,
		Error:       errorMsg,
		CreatedAt:   time.Now(),
	}

	_, _ = collection.InsertOne(ctx, log)
}

// generateOTP generates a random OTP of specified length
func generateOTP(length int) (string, error) {
	const digits = "0123456789"
	otp := make([]byte, length)
	for i := range otp {
		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", err
		}
		otp[i] = digits[num.Int64()]
	}
	return string(otp), nil
}

// normalizePhone normalizes phone number to include country code
func normalizePhone(phone string) string {
	// Remove any non-digit characters
	phone = strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, phone)

	// Add India country code if not present
	if len(phone) == 10 {
		phone = "91" + phone
	}

	return phone
}

// buildMessageFromParams builds message content from template params
func buildMessageFromParams(templateID string, params map[string]string) string {
	// This is a placeholder - actual implementation depends on your templates
	// In production, you'd fetch the template and replace placeholders
	var parts []string
	for key, value := range params {
		parts = append(parts, fmt.Sprintf("%s: %s", key, value))
	}
	return strings.Join(parts, ", ")
}

// IsConfigured returns true if Mtalkz API is configured
func (s *MessagingService) IsConfigured() bool {
	return s.apiKey != ""
}

// GetConfig returns the current configuration (for debugging)
func (s *MessagingService) GetConfig() map[string]string {
	return map[string]string{
		"baseURL":     s.baseURL,
		"senderID":    s.senderID,
		"configured":  fmt.Sprintf("%v", s.apiKey != ""),
	}
}
