# Thyne Jewels Backend API

A Go-based REST API for the Thyne Jewels e-commerce platform built with MongoDB.

## 🏗️ Architecture

- **Framework**: Gin HTTP framework
- **Database**: MongoDB with official Go driver
- **Authentication**: JWT tokens
- **Payment**: Razorpay integration
- **Validation**: Go validator
- **Configuration**: Environment variables

## 📁 Project Structure

```
backend/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── config/
│   ├── handlers/
│   ├── middleware/
│   ├── models/
│   ├── repository/
│   ├── services/
│   └── utils/
├── pkg/
├── migrations/
├── docs/
├── docker-compose.yml
├── Dockerfile
├── go.mod
├── go.sum
└── .env.example
```

## 🗄️ Database Collections

### Users Collection
```json
{
  "_id": "ObjectId",
  "name": "string",
  "email": "string (unique)",
  "phone": "string",
  "password": "string (hashed)",
  "profileImage": "string (URL)",
  "addresses": [
    {
      "id": "string",
      "street": "string",
      "city": "string",
      "state": "string",
      "zipCode": "string",
      "country": "string",
      "isDefault": "boolean"
    }
  ],
  "isActive": "boolean",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### Products Collection
```json
{
  "_id": "ObjectId",
  "name": "string",
  "description": "string",
  "price": "number",
  "originalPrice": "number",
  "images": ["string"],
  "category": "string",
  "subcategory": "string",
  "metalType": "string",
  "stoneType": "string",
  "weight": "number",
  "size": "string",
  "stockQuantity": "number",
  "rating": "number",
  "reviewCount": "number",
  "tags": ["string"],
  "isAvailable": "boolean",
  "isFeatured": "boolean",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### Carts Collection
```json
{
  "_id": "ObjectId",
  "userId": "string (ObjectId reference)",
  "guestSessionId": "string (for guest users)",
  "items": [
    {
      "productId": "ObjectId",
      "quantity": "number",
      "addedAt": "datetime"
    }
  ],
  "couponCode": "string",
  "discount": "number",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### Orders Collection
```json
{
  "_id": "ObjectId",
  "orderNumber": "string (unique)",
  "userId": "string (ObjectId reference)",
  "guestSessionId": "string (for guest orders)",
  "items": [
    {
      "productId": "ObjectId",
      "quantity": "number",
      "price": "number"
    }
  ],
  "shippingAddress": {
    "street": "string",
    "city": "string",
    "state": "string",
    "zipCode": "string",
    "country": "string"
  },
  "paymentMethod": "string",
  "paymentStatus": "string",
  "razorpayOrderId": "string",
  "razorpayPaymentId": "string",
  "status": "string",
  "subtotal": "number",
  "tax": "number",
  "shipping": "number",
  "discount": "number",
  "total": "number",
  "trackingNumber": "string",
  "createdAt": "datetime",
  "updatedAt": "datetime",
  "deliveredAt": "datetime"
}
```

### Reviews Collection
```json
{
  "_id": "ObjectId",
  "userId": "ObjectId",
  "userName": "string",
  "productId": "ObjectId",
  "rating": "number (1-5)",
  "comment": "string",
  "images": ["string"],
  "isVerified": "boolean",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### Guest Sessions Collection
```json
{
  "_id": "ObjectId",
  "sessionId": "string (unique)",
  "email": "string",
  "phone": "string",
  "name": "string",
  "cartItems": [
    {
      "productId": "ObjectId",
      "quantity": "number",
      "addedAt": "datetime"
    }
  ],
  "createdAt": "datetime",
  "lastActivity": "datetime",
  "expiresAt": "datetime"
}
```

## 🚀 Quick Start

1. **Clone and Setup**
```bash
cd backend
go mod init thyne-jewels-backend
go mod tidy
```

2. **Environment Setup**
```bash
cp .env.example .env
# Edit .env with your configurations
```

3. **Run with Docker**
```bash
docker-compose up -d
```

4. **Run Locally**
```bash
go run cmd/server/main.go
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/forgot-password` - Forgot password
- `POST /api/auth/reset-password` - Reset password

### Products
- `GET /api/products` - Get all products (with filters)
- `GET /api/products/:id` - Get product by ID
- `GET /api/products/categories` - Get product categories
- `GET /api/products/featured` - Get featured products
- `GET /api/products/search` - Search products

### Cart
- `GET /api/cart` - Get user cart
- `POST /api/cart/add` - Add item to cart
- `PUT /api/cart/update` - Update cart item quantity
- `DELETE /api/cart/:productId` - Remove item from cart
- `POST /api/cart/coupon` - Apply coupon code
- `DELETE /api/cart/coupon` - Remove coupon code

### Orders
- `POST /api/orders` - Create new order
- `GET /api/orders` - Get user orders
- `GET /api/orders/:id` - Get order by ID
- `PUT /api/orders/:id/cancel` - Cancel order
- `GET /api/orders/:id/tracking` - Track order

### Payment
- `POST /api/payment/create-order` - Create Razorpay order
- `POST /api/payment/verify` - Verify payment
- `POST /api/payment/webhook` - Razorpay webhook

### Reviews
- `GET /api/products/:id/reviews` - Get product reviews
- `POST /api/products/:id/reviews` - Add product review
- `PUT /api/reviews/:id` - Update review
- `DELETE /api/reviews/:id` - Delete review

### Guest
- `POST /api/guest/session` - Create guest session
- `GET /api/guest/session/:id` - Get guest session
- `PUT /api/guest/session/:id` - Update guest session
- `DELETE /api/guest/session/:id` - Delete guest session

## 🔧 Configuration

Create a `.env` file with the following variables:

```env
# Server
PORT=8080
HOST=localhost

# Database
MONGODB_URI=mongodb://localhost:27017
MONGODB_NAME=thyne_jewels

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRY=24h

# Razorpay
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret
RAZORPAY_WEBHOOK_SECRET=your-webhook-secret

# AWS S3 (for image uploads)
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=your-aws-region
AWS_S3_BUCKET=your-s3-bucket-name

# Email (for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# App Settings
APP_NAME=Thyne Jewels
APP_URL=http://localhost:8080
FRONTEND_URL=http://localhost:3000
```

## 🐳 Docker Support

The project includes Docker and Docker Compose configuration for easy deployment:

```bash
# Start MongoDB and Redis
docker-compose up -d mongodb redis

# Build and run the application
docker-compose up --build
```

## 📚 Development

### Running Tests
```bash
go test ./...
```

### Code Generation
```bash
# Generate mocks
go generate ./...
```

### Database Migrations
```bash
go run migrations/main.go
```

## 🔒 Security Features

- JWT-based authentication
- Password hashing with bcrypt
- Input validation and sanitization
- CORS configuration
- Rate limiting
- Request logging
- Secure headers

## 📊 Monitoring

- Request/response logging
- Error tracking
- Performance metrics
- Health check endpoints

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request
