#!/bin/bash

# Thyne Jewels Backend Setup Script
# This script sets up the development environment for the Go backend

set -e

echo "🚀 Setting up Thyne Jewels Backend..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if Go is installed
if ! command -v go &> /dev/null; then
    print_error "Go is not installed. Please install Go 1.21 or later."
    echo "Visit: https://golang.org/dl/"
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | cut -d' ' -f3 | sed 's/go//')
REQUIRED_VERSION="1.21"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    print_error "Go version $GO_VERSION is not supported. Please install Go $REQUIRED_VERSION or later."
    exit 1
fi

print_status "Go version $GO_VERSION detected ✓"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_warning "Docker is not installed. You'll need Docker to run MongoDB and Redis."
    echo "Visit: https://docs.docker.com/get-docker/"
else
    print_status "Docker detected ✓"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_warning "Docker Compose is not installed. You'll need it to run the full stack."
    echo "Visit: https://docs.docker.com/compose/install/"
else
    print_status "Docker Compose detected ✓"
fi

print_header "Setting up Go modules..."

# Initialize Go modules if not already done
if [ ! -f "go.mod" ]; then
    print_status "Initializing Go modules..."
    go mod init thyne-jewels-backend
fi

# Download dependencies
print_status "Downloading dependencies..."
go mod download

# Tidy up modules
print_status "Tidying up modules..."
go mod tidy

print_header "Setting up environment configuration..."

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        print_status "Creating .env file from template..."
        cp env.example .env
        print_warning "Please edit .env file with your actual configuration values!"
    else
        print_error "env.example file not found!"
        exit 1
    fi
else
    print_status ".env file already exists ✓"
fi

print_header "Creating necessary directories..."

# Create directories
mkdir -p uploads
mkdir -p logs
mkdir -p temp

print_status "Directories created ✓"

print_header "Setting up database..."

# Start MongoDB and Redis with Docker Compose
if command -v docker-compose &> /dev/null; then
    print_status "Starting MongoDB and Redis with Docker Compose..."
    docker-compose up -d mongodb redis
    
    # Wait for MongoDB to be ready
    print_status "Waiting for MongoDB to be ready..."
    sleep 10
    
    # Check if MongoDB is ready
    if docker-compose exec -T mongodb mongosh --eval "db.runCommand('ping')" > /dev/null 2>&1; then
        print_status "MongoDB is ready ✓"
    else
        print_warning "MongoDB might not be ready yet. Please check manually."
    fi
else
    print_warning "Docker Compose not available. Please start MongoDB and Redis manually."
fi

print_header "Running database migrations..."

# Run database initialization
if [ -f "migrations/init-mongo.js" ]; then
    print_status "Database initialization script found ✓"
    print_warning "Database will be initialized when MongoDB starts for the first time."
else
    print_warning "Database initialization script not found!"
fi

print_header "Building the application..."

# Build the application
print_status "Building the Go application..."
if go build -o bin/server ./cmd/server; then
    print_status "Application built successfully ✓"
else
    print_error "Failed to build the application!"
    exit 1
fi

print_header "Running tests..."

# Run tests
print_status "Running tests..."
if go test ./... -v; then
    print_status "All tests passed ✓"
else
    print_warning "Some tests failed. Please check the output above."
fi

print_header "Setup complete! 🎉"

echo ""
echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Edit the .env file with your configuration values"
echo "2. Start the application with: ${YELLOW}go run cmd/server/main.go${NC}"
echo "3. Or run with Docker Compose: ${YELLOW}docker-compose up${NC}"
echo "4. The API will be available at: ${BLUE}http://localhost:8080${NC}"
echo "5. API documentation will be available at: ${BLUE}http://localhost:8080/api/v1/docs${NC}"
echo ""
echo "Useful commands:"
echo "- Start services: ${YELLOW}docker-compose up -d${NC}"
echo "- Stop services: ${YELLOW}docker-compose down${NC}"
echo "- View logs: ${YELLOW}docker-compose logs -f${NC}"
echo "- Run tests: ${YELLOW}go test ./...${NC}"
echo "- Build: ${YELLOW}go build -o bin/server ./cmd/server${NC}"
echo ""
echo "Happy coding! 💎"
