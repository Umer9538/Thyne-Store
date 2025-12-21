package handlers

import (
	"net/http"
	"regexp"
	"strings"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
)

// OTPHandler handles OTP-related HTTP requests
type OTPHandler struct {
	smsService       *services.SMSService
	messagingService *services.MessagingService
}

// NewOTPHandler creates a new OTP handler
func NewOTPHandler(smsService *services.SMSService) *OTPHandler {
	return &OTPHandler{
		smsService: smsService,
	}
}

// NewOTPHandlerWithMessaging creates OTP handler with Mtalkz messaging service
func NewOTPHandlerWithMessaging(smsService *services.SMSService, messagingService *services.MessagingService) *OTPHandler {
	return &OTPHandler{
		smsService:       smsService,
		messagingService: messagingService,
	}
}

// SendOTPRequest represents the request body for sending OTP
type SendOTPRequest struct {
	Phone   string `json:"phone" binding:"required"`
	Purpose string `json:"purpose"`  // login, register, reset_password, verify_phone
	Channel string `json:"channel"`  // sms, whatsapp (defaults to sms)
}

// VerifyOTPRequest represents the request body for verifying OTP
type VerifyOTPRequest struct {
	Phone string `json:"phone" binding:"required"`
	OTP   string `json:"otp" binding:"required"`
}

// SendSMSRequest represents the request body for sending SMS
type SendSMSRequest struct {
	Phone   string `json:"phone" binding:"required"`
	Message string `json:"message" binding:"required"`
}

// SendOTP godoc
// @Summary Send OTP to phone number
// @Description Sends an OTP to the specified phone number for verification via SMS or WhatsApp
// @Tags OTP
// @Accept json
// @Produce json
// @Param request body SendOTPRequest true "Phone number, purpose, and channel"
// @Success 200 {object} map[string]interface{} "OTP sent successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 500 {object} map[string]interface{} "Failed to send OTP"
// @Router /otp/send [post]
func (h *OTPHandler) SendOTP(c *gin.Context) {
	var req SendOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	// Validate phone number format
	if !isValidPhoneNumber(req.Phone) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid phone number format",
		})
		return
	}

	// Try Mtalkz messaging service first (preferred)
	if h.messagingService != nil {
		channel := models.OTPChannelSMS
		if req.Channel == "whatsapp" {
			channel = models.OTPChannelWhatsApp
		}

		mtalkzReq := &models.SendOTPRequest{
			Phone:   req.Phone,
			Channel: channel,
			Purpose: req.Purpose,
		}

		response, err := h.messagingService.SendOTP(c.Request.Context(), mtalkzReq)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Failed to send OTP",
				"details": err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success":   response.Success,
			"message":   response.Message,
			"messageId": response.MessageID,
			"expiresIn": response.ExpiresIn,
			"channel":   response.Channel,
			"phone":     maskPhoneNumber(req.Phone),
		})
		return
	}

	// Fallback to legacy Gupshup SMS service
	if h.smsService == nil || !h.smsService.IsEnabled() {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"success": false,
			"error":   "SMS service is not configured",
		})
		return
	}

	// Generate message based on purpose
	messageTemplate := getOTPMessageTemplate(req.Purpose)

	// Send OTP via legacy service
	response, err := h.smsService.SendOTP(c.Request.Context(), req.Phone, messageTemplate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to send OTP",
			"details": err.Error(),
		})
		return
	}

	if !response.Success {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   response.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":       true,
		"message":       "OTP sent successfully",
		"transactionId": response.TransactionID,
		"phone":         maskPhoneNumber(req.Phone),
		"channel":       "sms",
	})
}

// VerifyOTP godoc
// @Summary Verify OTP
// @Description Verifies the OTP entered by the user
// @Tags OTP
// @Accept json
// @Produce json
// @Param request body VerifyOTPRequest true "Phone number and OTP"
// @Success 200 {object} map[string]interface{} "OTP verified successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request or OTP"
// @Failure 500 {object} map[string]interface{} "Failed to verify OTP"
// @Router /otp/verify [post]
func (h *OTPHandler) VerifyOTP(c *gin.Context) {
	var req VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	// Validate phone number
	if !isValidPhoneNumber(req.Phone) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid phone number format",
		})
		return
	}

	// Validate OTP format (should be numeric and 4-10 digits)
	if !isValidOTP(req.OTP) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid OTP format",
		})
		return
	}

	// Try Mtalkz messaging service first (preferred)
	if h.messagingService != nil {
		mtalkzReq := &models.VerifyOTPRequest{
			Phone: req.Phone,
			OTP:   req.OTP,
		}

		response, err := h.messagingService.VerifyOTP(c.Request.Context(), mtalkzReq)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success":  false,
				"verified": false,
				"error":    "Failed to verify OTP",
				"details":  err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success":  response.Success,
			"verified": response.Verified,
			"message":  response.Message,
		})
		return
	}

	// Fallback to legacy Gupshup SMS service
	if h.smsService == nil || !h.smsService.IsEnabled() {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"success": false,
			"error":   "SMS service is not configured",
		})
		return
	}

	// Verify OTP via legacy service
	response, err := h.smsService.VerifyOTP(c.Request.Context(), req.Phone, req.OTP)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to verify OTP",
			"details": err.Error(),
		})
		return
	}

	if !response.Verified {
		c.JSON(http.StatusBadRequest, gin.H{
			"success":  false,
			"verified": false,
			"error":    response.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"verified": true,
		"message":  "OTP verified successfully",
	})
}

// ResendOTP godoc
// @Summary Resend OTP
// @Description Resends OTP to the same phone number
// @Tags OTP
// @Accept json
// @Produce json
// @Param request body SendOTPRequest true "Phone number"
// @Success 200 {object} map[string]interface{} "OTP resent successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 429 {object} map[string]interface{} "Too many requests"
// @Failure 500 {object} map[string]interface{} "Failed to resend OTP"
// @Router /otp/resend [post]
func (h *OTPHandler) ResendOTP(c *gin.Context) {
	// Resend is essentially the same as Send, Gupshup handles rate limiting
	h.SendOTP(c)
}

// SendSMS godoc
// @Summary Send SMS (Admin only)
// @Description Sends a custom SMS message to a phone number
// @Tags OTP
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body SendSMSRequest true "Phone and message"
// @Success 200 {object} map[string]interface{} "SMS sent successfully"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 500 {object} map[string]interface{} "Failed to send SMS"
// @Router /admin/sms/send [post]
func (h *OTPHandler) SendSMS(c *gin.Context) {
	var req SendSMSRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	// Validate phone number
	if !isValidPhoneNumber(req.Phone) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid phone number format",
		})
		return
	}

	// Validate message
	if len(req.Message) < 1 || len(req.Message) > 160 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Message must be between 1 and 160 characters",
		})
		return
	}

	// Check if SMS service is enabled
	if h.smsService == nil || !h.smsService.IsEnabled() {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"success": false,
			"error":   "SMS service is not configured",
		})
		return
	}

	// Send SMS
	response, err := h.smsService.SendSMS(c.Request.Context(), req.Phone, req.Message)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to send SMS",
			"details": err.Error(),
		})
		return
	}

	if !response.Success {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   response.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "SMS sent successfully",
	})
}

// GetSMSStatus godoc
// @Summary Get SMS service status
// @Description Returns the current status of the SMS service
// @Tags OTP
// @Produce json
// @Success 200 {object} map[string]interface{} "Service status"
// @Router /otp/status [get]
func (h *OTPHandler) GetSMSStatus(c *gin.Context) {
	enabled := h.smsService != nil && h.smsService.IsEnabled()

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"enabled":  enabled,
			"provider": "Gupshup",
		},
	})
}

// Helper functions

func isValidPhoneNumber(phone string) bool {
	// Remove common formatting characters
	cleaned := strings.ReplaceAll(phone, " ", "")
	cleaned = strings.ReplaceAll(cleaned, "-", "")
	cleaned = strings.ReplaceAll(cleaned, "(", "")
	cleaned = strings.ReplaceAll(cleaned, ")", "")
	cleaned = strings.TrimPrefix(cleaned, "+")

	// Must be 10-15 digits
	matched, _ := regexp.MatchString(`^\d{10,15}$`, cleaned)
	return matched
}

func isValidOTP(otp string) bool {
	// OTP should be 4-10 alphanumeric characters
	matched, _ := regexp.MatchString(`^[A-Za-z0-9]{4,10}$`, otp)
	return matched
}

func maskPhoneNumber(phone string) string {
	// Clean phone number
	cleaned := strings.ReplaceAll(phone, " ", "")
	cleaned = strings.ReplaceAll(cleaned, "-", "")
	cleaned = strings.TrimPrefix(cleaned, "+")

	if len(cleaned) < 6 {
		return "****"
	}

	// Show first 2 and last 4 digits
	// e.g., 919876543210 -> 91******3210
	return cleaned[:2] + strings.Repeat("*", len(cleaned)-6) + cleaned[len(cleaned)-4:]
}

func getOTPMessageTemplate(purpose string) string {
	switch purpose {
	case "login":
		return "Your login OTP for Thyne Jewels is %code%. Valid for 5 minutes. Do not share."
	case "register":
		return "Welcome to Thyne Jewels! Your verification OTP is %code%. Valid for 5 minutes."
	case "reset_password":
		return "Your password reset OTP for Thyne Jewels is %code%. Valid for 5 minutes."
	case "verify_phone":
		return "Your phone verification OTP for Thyne Jewels is %code%. Valid for 5 minutes."
	case "order":
		return "Your order confirmation OTP for Thyne Jewels is %code%. Valid for 5 minutes."
	default:
		return "Your OTP for Thyne Jewels is %code%. Valid for 5 minutes. Do not share with anyone."
	}
}
