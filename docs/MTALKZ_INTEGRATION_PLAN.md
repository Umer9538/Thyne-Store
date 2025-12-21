# Mtalkz Integration Plan for Thyne Jewels

## Overview
Integration of Mtalkz CPaaS (Communication Platform as a Service) for SMS OTP, WhatsApp OTP, and transactional messaging.

**Documentation Sources:**
- [Mtalkz SMS API Reference](https://developers.mtalkz.com/sms)
- [Mtalkz WhatsApp Business API](https://www.mtalkz.com/whatsapp-business-api)
- [Mtalkz OTP API](https://www.mtalkz.com/developer-tools/otp-api-for-developer)

---

## 1. API Authentication

**Method:** API Key-based authentication
```
Header: apikey: <your_api_key>
Content-Type: application/json
```

**Base URL:** `https://api.mtalkz.com` (to be confirmed with Mtalkz)

---

## 2. SMS OTP Integration

### 2.1 Send OTP SMS
**Endpoint:** `POST /v1/sms`

**Request:**
```json
{
  "sender": "THYNEJ",
  "to": "91XXXXXXXXXX",
  "text": "Your Thyne Jewels verification code is {OTP}. Valid for 10 minutes. Do not share with anyone.",
  "type": "OTP",
  "templateId": "<DLT_TEMPLATE_ID>"
}
```

**Response:**
```json
{
  "id": "58d63c02-xxxx-xxxx-xxxx-xxxbb39453",
  "data": [
    {
      "recipient": "91XXXXXXXXXX",
      "messageId": "58d63c02-xxxxx-xxxxx-xxxxx-xxxx9bb39453:1"
    }
  ],
  "totalCount": 1,
  "message": "Message Sent Successfully!",
  "error": null
}
```

### 2.2 OTP Generation & Verification (Managed OTP)
**Generate OTP:** `POST /v1/verify`
```json
{
  "to": "91XXXXXXXXXX",
  "sender": "THYNEJ",
  "templateId": "<DLT_TEMPLATE_ID>",
  "otpLength": 6,
  "expiry": 600
}
```

**Verify OTP:** `POST /v1/verify/validate`
```json
{
  "to": "91XXXXXXXXXX",
  "otp": "123456"
}
```

---

## 3. WhatsApp OTP Integration

### 3.1 Send WhatsApp OTP Message
**Endpoint:** `POST /v1/whatsapp`

**Request:**
```json
{
  "to": "91XXXXXXXXXX",
  "type": "template",
  "template": {
    "name": "otp_verification",
    "language": {
      "code": "en"
    },
    "components": [
      {
        "type": "body",
        "parameters": [
          {
            "type": "text",
            "text": "123456"
          }
        ]
      },
      {
        "type": "button",
        "sub_type": "url",
        "index": "0",
        "parameters": [
          {
            "type": "text",
            "text": "123456"
          }
        ]
      }
    ]
  }
}
```

### 3.2 WhatsApp Template Types
- **Authentication** - OTP and verification messages
- **Utility** - Order updates, shipping notifications
- **Marketing** - Promotional content (requires opt-in)

---

## 4. Transactional Messages

### 4.1 Order Confirmation SMS
```json
{
  "sender": "THYNEJ",
  "to": "91XXXXXXXXXX",
  "text": "Thank you for your order #{ORDER_ID}! Your custom jewelry design has been received. We'll contact you within 24 hours. - Thyne Jewels",
  "type": "TRANS",
  "templateId": "<ORDER_CONFIRM_TEMPLATE_ID>"
}
```

### 4.2 Order Status Update (WhatsApp)
```json
{
  "to": "91XXXXXXXXXX",
  "type": "template",
  "template": {
    "name": "order_status_update",
    "language": { "code": "en" },
    "components": [
      {
        "type": "body",
        "parameters": [
          { "type": "text", "text": "ORD-12345" },
          { "type": "text", "text": "In Production" },
          { "type": "text", "text": "Dec 28, 2025" }
        ]
      }
    ]
  }
}
```

### 4.3 Message Templates Required

| Template Name | Type | Channel | Purpose |
|--------------|------|---------|---------|
| `otp_login` | OTP | SMS | Login/Registration OTP |
| `otp_verification` | Authentication | WhatsApp | WhatsApp OTP |
| `order_confirmation` | Transactional | SMS | Order placed confirmation |
| `order_status` | Utility | WhatsApp | Order status updates |
| `payment_success` | Transactional | SMS | Payment confirmation |
| `shipping_update` | Utility | WhatsApp | Delivery tracking |
| `custom_order_inquiry` | Utility | WhatsApp | Custom design follow-up |

---

## 5. Backend Implementation Plan

### 5.1 New Files Structure
```
backend/
├── internal/
│   ├── services/
│   │   └── messaging_service.go     # Mtalkz API client
│   ├── handlers/
│   │   └── otp_handler.go           # OTP endpoints
│   └── models/
│       └── messaging.go             # Message models
```

### 5.2 Go Service Implementation

```go
// internal/services/messaging_service.go
package services

type MessagingService struct {
    apiKey     string
    baseURL    string
    senderID   string
    httpClient *http.Client
}

// SMS Methods
func (s *MessagingService) SendSMSOTP(phone, otp string) error
func (s *MessagingService) SendTransactionalSMS(phone, templateID string, params map[string]string) error

// WhatsApp Methods
func (s *MessagingService) SendWhatsAppOTP(phone, otp string) error
func (s *MessagingService) SendWhatsAppTemplate(phone, templateName string, params []string) error

// OTP Management (using Mtalkz managed OTP)
func (s *MessagingService) GenerateAndSendOTP(phone string, channel string) (*OTPResponse, error)
func (s *MessagingService) VerifyOTP(phone, otp string) (bool, error)
```

### 5.3 API Endpoints to Add

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/otp/send` | Send OTP (SMS or WhatsApp) |
| POST | `/api/v1/otp/verify` | Verify OTP |
| POST | `/api/v1/otp/resend` | Resend OTP |

### 5.4 Environment Variables
```env
MTALKZ_API_KEY=your_api_key_here
MTALKZ_BASE_URL=https://api.mtalkz.com
MTALKZ_SENDER_ID=THYNEJ
MTALKZ_SMS_OTP_TEMPLATE_ID=xxx
MTALKZ_ORDER_CONFIRM_TEMPLATE_ID=xxx
MTALKZ_WHATSAPP_OTP_TEMPLATE=otp_verification
```

---

## 6. Flutter Implementation Plan

### 6.1 Update Auth Flow
```dart
// lib/services/otp_service.dart
class OTPService {
  Future<bool> sendOTP(String phone, {OTPChannel channel = OTPChannel.sms});
  Future<bool> verifyOTP(String phone, String otp);
  Future<bool> resendOTP(String phone, {OTPChannel channel});
}

enum OTPChannel { sms, whatsapp }
```

### 6.2 UI Updates
- Add WhatsApp OTP option in login/registration
- Add channel selection (SMS vs WhatsApp)
- Update OTP input screen with resend timer

---

## 7. DLT Compliance (India)

### Required Registrations
1. **Entity Registration** - Business registered on DLT portal
2. **Header/Sender ID** - "THYNEJ" approved (6 characters)
3. **Templates** - All message templates pre-approved

### Template Format Requirements
- Variables in `{#var#}` format
- Max 30 characters for sender ID content
- Unicode support for regional languages

---

## 8. Implementation Phases

### Phase 1: Backend Setup (2-3 days)
- [ ] Create messaging service with Mtalkz client
- [ ] Implement SMS OTP send/verify endpoints
- [ ] Add environment configuration
- [ ] Write unit tests

### Phase 2: WhatsApp Integration (2-3 days)
- [ ] Implement WhatsApp message sending
- [ ] Create WhatsApp OTP flow
- [ ] Handle template message responses

### Phase 3: Flutter Integration (2-3 days)
- [ ] Update OTP service to use backend
- [ ] Add WhatsApp OTP option in UI
- [ ] Implement channel selection
- [ ] Add resend with cooldown

### Phase 4: Transactional Messages (2-3 days)
- [ ] Order confirmation messages
- [ ] Payment success notifications
- [ ] Shipping/delivery updates
- [ ] Custom order status messages

### Phase 5: Testing & Go-Live (1-2 days)
- [ ] End-to-end testing
- [ ] DLT template verification
- [ ] Production deployment

---

## 9. API Rate Limits & Best Practices

- **SMS OTP**: Max 3 attempts per phone per 10 minutes
- **Resend cooldown**: 30 seconds between resends
- **OTP expiry**: 10 minutes
- **Retry logic**: Exponential backoff for API failures
- **Fallback**: SMS fallback if WhatsApp delivery fails

---

## 10. Estimated Costs (Mtalkz Pricing)

| Service | Cost |
|---------|------|
| SMS OTP | ~₹0.20-0.25 per SMS |
| WhatsApp Utility | ~₹0.35-0.50 per message |
| WhatsApp Authentication | ~₹0.30-0.40 per message |

---

## Next Steps

1. **Get API Credentials** - Request API key from Mtalkz account
2. **DLT Templates** - Submit templates for approval
3. **WhatsApp Business** - Complete Meta business verification
4. **Start Development** - Begin Phase 1 implementation

---

## Contact

**Mtalkz Support:**
- Email: support@mtalkz.com
- Phone: +91-9868629924
