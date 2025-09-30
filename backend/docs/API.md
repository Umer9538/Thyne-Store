# Thyne Jewels API Documentation

## Overview

The Thyne Jewels API is a RESTful service built with Go and MongoDB, designed to power a jewelry e-commerce platform. This API provides endpoints for user authentication, product management, shopping cart functionality, order processing, and payment integration.

## Base URL

```
http://localhost:8080/api/v1
```

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "data": {},
  "message": "Operation successful"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

## Pagination

For endpoints that return lists, pagination is supported:

```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

## Endpoints

### Authentication

#### Register User
```http
POST /auth/register
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00Z"
    },
    "accessToken": "jwt_token",
    "refreshToken": "refresh_token",
    "expiresIn": 86400
  }
}
```

#### Login User
```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

#### Refresh Token
```http
POST /auth/refresh
```

**Request Body:**
```json
{
  "refreshToken": "refresh_token"
}
```

#### Forgot Password
```http
POST /auth/forgot-password
```

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

### Users

#### Get User Profile
```http
GET /users/profile
Authorization: Bearer <token>
```

#### Update User Profile
```http
PUT /users/profile
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "name": "John Smith",
  "phone": "+1234567891"
}
```

#### Add Address
```http
POST /users/addresses
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "street": "123 Main St",
  "city": "New York",
  "state": "NY",
  "zipCode": "10001",
  "country": "USA",
  "isDefault": true
}
```

### Products

#### Get Products
```http
GET /products
```

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 20)
- `category` (string): Filter by category
- `subcategory` (string): Filter by subcategory
- `metalType` (string): Filter by metal type
- `stoneType` (string): Filter by stone type
- `minPrice` (float): Minimum price filter
- `maxPrice` (float): Maximum price filter
- `sortBy` (string): Sort by (price_low, price_high, rating, newest, popularity)
- `search` (string): Search query

**Response:**
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id": "product_id",
        "name": "Diamond Solitaire Ring",
        "description": "A stunning solitaire diamond ring...",
        "price": 85000,
        "originalPrice": 100000,
        "images": ["image_url_1", "image_url_2"],
        "category": "Rings",
        "subcategory": "Engagement",
        "metalType": "18K White Gold",
        "stoneType": "Diamond",
        "weight": 3.5,
        "size": "6",
        "stockQuantity": 5,
        "rating": 4.8,
        "reviewCount": 124,
        "tags": ["diamond", "engagement", "solitaire"],
        "isAvailable": true,
        "isFeatured": true,
        "createdAt": "2024-01-01T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

#### Get Product by ID
```http
GET /products/{id}
```

#### Get Categories
```http
GET /products/categories
```

#### Get Featured Products
```http
GET /products/featured
```

#### Search Products
```http
GET /products/search?q=diamond&category=Rings
```

### Cart

#### Get Cart
```http
GET /cart
Authorization: Bearer <token> (optional for guest)
```

#### Add to Cart
```http
POST /cart/add
Authorization: Bearer <token> (optional for guest)
```

**Request Body:**
```json
{
  "productId": "product_id",
  "quantity": 1
}
```

#### Update Cart Item
```http
PUT /cart/update
Authorization: Bearer <token> (optional for guest)
```

**Request Body:**
```json
{
  "productId": "product_id",
  "quantity": 2
}
```

#### Remove from Cart
```http
DELETE /cart/remove/{productId}
Authorization: Bearer <token> (optional for guest)
```

#### Apply Coupon
```http
POST /cart/coupon
Authorization: Bearer <token> (optional for guest)
```

**Request Body:**
```json
{
  "couponCode": "FIRST10"
}
```

#### Clear Cart
```http
DELETE /cart/clear
Authorization: Bearer <token> (optional for guest)
```

### Orders

#### Create Order
```http
POST /orders
Authorization: Bearer <token> (optional for guest)
```

**Request Body:**
```json
{
  "items": [
    {
      "productId": "product_id",
      "quantity": 1
    }
  ],
  "shippingAddress": {
    "street": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "USA"
  },
  "paymentMethod": "razorpay",
  "couponCode": "FIRST10"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "order": {
      "id": "order_id",
      "orderNumber": "ORD123456789",
      "status": "pending",
      "paymentStatus": "pending",
      "items": [...],
      "shippingAddress": {...},
      "subtotal": 85000,
      "tax": 15300,
      "shipping": 0,
      "discount": 8500,
      "total": 91800,
      "createdAt": "2024-01-01T00:00:00Z"
    },
    "paymentOrder": {
      "id": "razorpay_order_id",
      "amount": 91800,
      "currency": "INR"
    }
  }
}
```

#### Get Orders
```http
GET /orders
Authorization: Bearer <token> (optional for guest)
```

#### Get Order by ID
```http
GET /orders/{id}
Authorization: Bearer <token> (optional for guest)
```

#### Cancel Order
```http
PUT /orders/{id}/cancel
Authorization: Bearer <token> (optional for guest)
```

#### Track Order
```http
GET /orders/{id}/tracking
Authorization: Bearer <token> (optional for guest)
```

### Payment

#### Create Payment Order
```http
POST /payment/create-order
Authorization: Bearer <token> (optional for guest)
```

**Request Body:**
```json
{
  "orderId": "order_id",
  "amount": 91800,
  "currency": "INR"
}
```

#### Verify Payment
```http
POST /payment/verify
```

**Request Body:**
```json
{
  "razorpayOrderId": "order_id",
  "razorpayPaymentId": "payment_id",
  "razorpaySignature": "signature"
}
```

#### Payment Webhook
```http
POST /payment/webhook
```

### Reviews

#### Create Review
```http
POST /reviews
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "productId": "product_id",
  "rating": 5,
  "comment": "Excellent product, highly recommended!",
  "images": ["image_url_1"]
}
```

#### Update Review
```http
PUT /reviews/{id}
Authorization: Bearer <token>
```

#### Delete Review
```http
DELETE /reviews/{id}
Authorization: Bearer <token>
```

#### Get Product Reviews
```http
GET /products/{id}/reviews
```

### Guest Sessions

#### Create Guest Session
```http
POST /guest/session
```

**Request Body:**
```json
{
  "email": "guest@example.com",
  "phone": "+1234567890",
  "name": "Guest User"
}
```

#### Get Guest Session
```http
GET /guest/session/{sessionId}
```

#### Update Guest Session
```http
PUT /guest/session/{sessionId}
```

#### Delete Guest Session
```http
DELETE /guest/session/{sessionId}
```

## Error Codes

| Code | Description |
|------|-------------|
| `INVALID_INPUT` | Invalid request data |
| `UNAUTHORIZED` | Authentication required |
| `FORBIDDEN` | Access denied |
| `NOT_FOUND` | Resource not found |
| `CONFLICT` | Resource already exists |
| `PAYMENT_FAILED` | Payment processing failed |
| `INSUFFICIENT_STOCK` | Product out of stock |
| `COUPON_INVALID` | Invalid or expired coupon |
| `SERVER_ERROR` | Internal server error |

## Rate Limiting

The API implements rate limiting to prevent abuse:
- 100 requests per minute per IP address
- Authenticated users have higher limits

## Webhooks

### Razorpay Webhook Events

The API listens for the following Razorpay webhook events:

- `payment.captured`: Payment successfully captured
- `payment.failed`: Payment failed
- `order.paid`: Order marked as paid

## Testing

Use the following test credentials:

**User Account:**
- Email: `test@example.com`
- Password: `password123`

**Test Coupons:**
- `FIRST10`: 10% discount (min ₹1000)
- `JEWEL20`: 20% discount (min ₹5000)

## SDK Examples

### JavaScript/TypeScript

```javascript
const API_BASE = 'http://localhost:8080/api/v1';

// Login
const loginResponse = await fetch(`${API_BASE}/auth/login`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'password123'
  })
});

const { data } = await loginResponse.json();
const token = data.accessToken;

// Get products
const productsResponse = await fetch(`${API_BASE}/products`, {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

### Flutter/Dart

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ThyneJewelsAPI {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  String? token;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['data']['accessToken'];
      return data['data'];
    }
    throw Exception('Login failed');
  }

  Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['products'];
    }
    throw Exception('Failed to load products');
  }
}
```

## Support

For API support and questions:
- Email: support@thynejewels.com
- Documentation: [API Docs](http://localhost:8080/docs)
- GitHub Issues: [Report Issues](https://github.com/thynejewels/backend/issues)
