# Thyne Jewels Backend - Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### Prerequisites
- Go 1.21+ installed
- Docker and Docker Compose (optional)
- Git

### 1. Clone and Setup
```bash
cd backend
./scripts/setup.sh
```

### 2. Configure Environment
```bash
# Copy and edit environment file
cp env.example .env

# Edit with your values (at minimum, change JWT_SECRET)
nano .env
```

### 3. Start Services
```bash
# Option A: With Docker Compose (Recommended)
docker-compose up -d

# Option B: Local development
go run cmd/server/main.go
```

### 4. Test the API
```bash
# Health check
curl http://localhost:8080/health

# Get products
curl http://localhost:8080/api/v1/products
```

## 📱 Connect Your Flutter App

Update your Flutter app's API configuration:

```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  // For Android emulator, use: http://10.0.2.2:8080/api/v1
  // For iOS simulator, use: http://localhost:8080/api/v1
}
```

## 🔧 Development Workflow

### Running Tests
```bash
go test ./...
```

### Database Management
```bash
# Access MongoDB
docker-compose exec mongodb mongosh

# View logs
docker-compose logs -f

# Reset database
docker-compose down -v
docker-compose up -d
```

### Adding New Features
1. Create models in `internal/models/`
2. Add repository in `internal/repository/`
3. Implement service in `internal/services/`
4. Create handlers in `internal/handlers/`
5. Add routes in `cmd/server/main.go`

## 📊 API Testing

### Using curl
```bash
# Register user
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","phone":"+1234567890","password":"password123"}'

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get products (with token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8080/api/v1/products
```

### Using Postman
Import the API collection from `docs/postman/thyne-jewels-api.json`

## 🐳 Docker Commands

```bash
# Start all services
docker-compose up -d

# Start only database
docker-compose up -d mongodb redis

# View logs
docker-compose logs -f app

# Stop services
docker-compose down

# Rebuild and start
docker-compose up --build -d
```

## 🔍 Monitoring

### Health Checks
- API Health: http://localhost:8080/health
- MongoDB: Check Docker logs
- Redis: Check Docker logs

### Logs
```bash
# Application logs
docker-compose logs -f app

# Database logs
docker-compose logs -f mongodb

# All services
docker-compose logs -f
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Kill process on port 8080
lsof -ti:8080 | xargs kill -9

# Or change port in .env
PORT=8081
```

#### 2. MongoDB Connection Failed
```bash
# Check if MongoDB is running
docker-compose ps

# Restart MongoDB
docker-compose restart mongodb
```

#### 3. Permission Denied (macOS/Linux)
```bash
# Make setup script executable
chmod +x scripts/setup.sh
```

#### 4. Go Modules Issues
```bash
# Clean and rebuild
go clean -modcache
go mod download
go mod tidy
```

### Getting Help
1. Check the logs: `docker-compose logs -f`
2. Verify environment: Check `.env` file
3. Test connectivity: `curl http://localhost:8080/health`
4. Check MongoDB: `docker-compose exec mongodb mongosh`

## 📈 Next Steps

1. **Configure Razorpay**: Add your Razorpay keys to `.env`
2. **Set up AWS S3**: Configure for image uploads
3. **Email Service**: Configure SMTP for notifications
4. **Production Deploy**: Use the Docker setup for production
5. **Monitoring**: Add logging and metrics collection

## 🎯 Production Checklist

- [ ] Change JWT secret
- [ ] Configure Razorpay keys
- [ ] Set up SSL certificates
- [ ] Configure CORS origins
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Set up CI/CD pipeline

## 📚 Additional Resources

- [API Documentation](docs/API.md)
- [Database Schema](docs/DATABASE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Contributing Guidelines](docs/CONTRIBUTING.md)

Happy coding! 💎
