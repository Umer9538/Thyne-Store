package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// OTPChannel represents the channel for OTP delivery
type OTPChannel string

const (
	OTPChannelSMS      OTPChannel = "sms"
	OTPChannelWhatsApp OTPChannel = "whatsapp"
)

// MessageType represents the type of message
type MessageType string

const (
	MessageTypeOTP           MessageType = "otp"
	MessageTypeTransactional MessageType = "transactional"
	MessageTypePromotional   MessageType = "promotional"
)

// OTPRecord stores OTP information in database
type OTPRecord struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Phone     string             `bson:"phone" json:"phone"`
	OTP       string             `bson:"otp" json:"otp"`
	Channel   OTPChannel         `bson:"channel" json:"channel"`
	Purpose   string             `bson:"purpose" json:"purpose"` // login, registration, reset_password
	Verified  bool               `bson:"verified" json:"verified"`
	Attempts  int                `bson:"attempts" json:"attempts"`
	ExpiresAt time.Time          `bson:"expiresAt" json:"expiresAt"`
	CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// MessageLog stores sent message logs
type MessageLog struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID      primitive.ObjectID `bson:"userId,omitempty" json:"userId,omitempty"`
	Phone       string             `bson:"phone" json:"phone"`
	Channel     OTPChannel         `bson:"channel" json:"channel"`
	MessageType MessageType        `bson:"messageType" json:"messageType"`
	TemplateID  string             `bson:"templateId,omitempty" json:"templateId,omitempty"`
	Content     string             `bson:"content" json:"content"`
	MessageID   string             `bson:"messageId,omitempty" json:"messageId,omitempty"`
	Status      string             `bson:"status" json:"status"` // sent, delivered, failed
	Error       string             `bson:"error,omitempty" json:"error,omitempty"`
	CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
}

// SendOTPRequest represents request to send OTP
type SendOTPRequest struct {
	Phone   string     `json:"phone" binding:"required"`
	Channel OTPChannel `json:"channel"` // defaults to sms
	Purpose string     `json:"purpose"` // login, registration, reset_password
}

// SendOTPResponse represents response after sending OTP
type SendOTPResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	MessageID string `json:"messageId,omitempty"`
	ExpiresIn int    `json:"expiresIn"` // seconds
	Channel   string `json:"channel"`
}

// VerifyOTPRequest represents request to verify OTP
type VerifyOTPRequest struct {
	Phone string `json:"phone" binding:"required"`
	OTP   string `json:"otp" binding:"required"`
}

// VerifyOTPResponse represents response after verifying OTP
type VerifyOTPResponse struct {
	Success  bool   `json:"success"`
	Message  string `json:"message"`
	Verified bool   `json:"verified"`
}

// ResendOTPRequest represents request to resend OTP
type ResendOTPRequest struct {
	Phone   string     `json:"phone" binding:"required"`
	Channel OTPChannel `json:"channel"` // can switch channel on resend
}

// MtalkzSMSRequest represents Mtalkz SMS API request
type MtalkzSMSRequest struct {
	Sender     string `json:"sender"`
	To         string `json:"to"`
	Text       string `json:"text"`
	Type       string `json:"type"` // OTP, TRANS, PROMO
	TemplateID string `json:"templateId,omitempty"`
}

// MtalkzSMSResponse represents Mtalkz SMS API response
type MtalkzSMSResponse struct {
	ID    string `json:"id"`
	Data  []struct {
		Recipient string `json:"recipient"`
		MessageID string `json:"messageId"`
	} `json:"data"`
	TotalCount int         `json:"totalCount"`
	Message    string      `json:"message"`
	Error      interface{} `json:"error,omitempty"` // Can be bool (false) or string
}

// GetError returns error as string, handling both bool and string types
func (r *MtalkzSMSResponse) GetError() string {
	if r.Error == nil {
		return ""
	}
	switch v := r.Error.(type) {
	case string:
		return v
	case bool:
		if v {
			return "unknown error"
		}
		return ""
	default:
		return ""
	}
}

// MtalkzWhatsAppRequest represents Mtalkz WhatsApp API request
type MtalkzWhatsAppRequest struct {
	To       string                    `json:"to"`
	Type     string                    `json:"type"` // template, text
	Template *MtalkzWhatsAppTemplate   `json:"template,omitempty"`
	Text     *MtalkzWhatsAppText       `json:"text,omitempty"`
}

// MtalkzWhatsAppTemplate represents WhatsApp template message
type MtalkzWhatsAppTemplate struct {
	Name       string                          `json:"name"`
	Language   MtalkzTemplateLanguage          `json:"language"`
	Components []MtalkzTemplateComponent       `json:"components,omitempty"`
}

// MtalkzTemplateLanguage represents template language
type MtalkzTemplateLanguage struct {
	Code string `json:"code"` // en, hi, etc.
}

// MtalkzTemplateComponent represents template component
type MtalkzTemplateComponent struct {
	Type       string                    `json:"type"` // header, body, button
	SubType    string                    `json:"sub_type,omitempty"`
	Index      string                    `json:"index,omitempty"`
	Parameters []MtalkzTemplateParameter `json:"parameters,omitempty"`
}

// MtalkzTemplateParameter represents template parameter
type MtalkzTemplateParameter struct {
	Type string `json:"type"` // text, image, document
	Text string `json:"text,omitempty"`
}

// MtalkzWhatsAppText represents WhatsApp text message
type MtalkzWhatsAppText struct {
	Body string `json:"body"`
}

// MtalkzWhatsAppResponse represents Mtalkz WhatsApp API response
type MtalkzWhatsAppResponse struct {
	Success   bool        `json:"success"`
	MessageID string      `json:"messageId,omitempty"`
	Error     interface{} `json:"error,omitempty"` // Can be bool (false) or string
}

// GetError returns error as string, handling both bool and string types
func (r *MtalkzWhatsAppResponse) GetError() string {
	if r.Error == nil {
		return ""
	}
	switch v := r.Error.(type) {
	case string:
		return v
	case bool:
		if v {
			return "unknown error"
		}
		return ""
	default:
		return ""
	}
}

// SendTransactionalRequest represents request to send transactional message
type SendTransactionalRequest struct {
	Phone      string            `json:"phone" binding:"required"`
	Channel    OTPChannel        `json:"channel"`
	TemplateID string            `json:"templateId" binding:"required"`
	Params     map[string]string `json:"params"`
}

// OrderNotificationRequest represents order notification request
type OrderNotificationRequest struct {
	Phone       string     `json:"phone" binding:"required"`
	OrderID     string     `json:"orderId" binding:"required"`
	OrderStatus string     `json:"orderStatus" binding:"required"`
	Channel     OTPChannel `json:"channel"`
	ExtraParams map[string]string `json:"extraParams,omitempty"`
}

// OTP Configuration constants
const (
	OTPLength         = 6
	OTPExpiryMinutes  = 10
	OTPMaxAttempts    = 3
	OTPResendCooldown = 30 // seconds
)
