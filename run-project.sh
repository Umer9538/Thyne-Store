#!/bin/bash

# Thyne Jewels Project Runner (Without Docker)
# This script sets up and runs both frontend and backend locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK="✅"
CROSS="❌"
ARROW="➤"
STAR="⭐"
GEAR="⚙️"
ROCKET="🚀"

print_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    THYNE JEWELS RUNNER                       ║${NC}"
    echo -e "${PURPLE}║                 Frontend + Backend Setup                     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${CYAN}${GEAR} $1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
}

print_status() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_info() {
    echo -e "${BLUE}${ARROW} $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install file watcher if not present
install_file_watcher() {
    if ! command_exists fswatch; then
        print_info "Installing file watcher (fswatch)..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command_exists brew; then
                brew install fswatch
            else
                print_error "Homebrew not found. Please install fswatch manually: https://github.com/emcrisostomo/fswatch"
                return 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y fswatch
            elif command_exists yum; then
                sudo yum install -y fswatch
            elif command_exists pacman; then
                sudo pacman -S fswatch
            else
                print_error "Package manager not found. Please install fswatch manually"
                return 1
            fi
        else
            print_error "Unsupported OS for automatic fswatch installation"
            return 1
        fi
    fi
    return 0
}

# Function to check if a port is in use
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

# Function to kill process on port
kill_port() {
    if port_in_use $1; then
        print_warning "Port $1 is in use. Attempting to free it..."
        lsof -ti:$1 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    print_info "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            print_status "$service_name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start within $(($max_attempts * 2)) seconds"
    return 1
}

# Function to check system requirements
check_requirements() {
    print_section "Checking System Requirements"
    
    local all_good=true
    
    # Check Go
    if command_exists go; then
        local go_version=$(go version | awk '{print $3}' | sed 's/go//')
        print_status "Go $go_version installed"
        # Enforce Go >= 1.21
        local go_major=$(echo "$go_version" | cut -d. -f1)
        local go_minor=$(echo "$go_version" | cut -d. -f2)
        if [ "$go_major" -lt 1 ] || { [ "$go_major" -eq 1 ] && [ "$go_minor" -lt 21 ]; }; then
            print_error "Go 1.21+ is required (found $go_version)"
            all_good=false
        fi
    else
        print_error "Go is not installed. Please install Go 1.21+ from https://golang.org/dl/"
        all_good=false
    fi
    
    # Check Flutter
    if command_exists flutter; then
        local flutter_version=$(flutter --version | head -n 1 | awk '{print $2}')
        print_status "Flutter $flutter_version installed"
    else
        print_error "Flutter is not installed. Please install Flutter from https://flutter.dev/docs/get-started/install"
        all_good=false
    fi
    
    # Check MongoDB
    if command_exists mongod; then
        print_status "MongoDB installed"
    else
        print_error "MongoDB is not installed. Please install MongoDB from https://docs.mongodb.com/manual/installation/"
        print_info "On macOS: brew install mongodb-community"
        print_info "On Ubuntu: sudo apt-get install mongodb"
        all_good=false
    fi
    
    # Check Mongo shell
    if command_exists mongosh; then
        print_status "mongosh installed"
    elif command_exists mongo; then
        print_warning "mongosh not found; legacy 'mongo' shell will be used for initialization"
    else
        print_warning "Neither mongosh nor mongo found; database initialization will be skipped"
    fi
    
    # Check Node.js (optional, for some Flutter web features)
    if command_exists node; then
        local node_version=$(node --version)
        print_status "Node.js $node_version installed"
    else
        print_warning "Node.js not found (optional for Flutter web)"
    fi
    
    # Check for file watcher (for auto-reload functionality)
    if command_exists fswatch; then
        print_status "fswatch installed (auto-reload enabled)"
    else
        print_warning "fswatch not found (auto-reload will be disabled)"
        print_info "Install with: brew install fswatch (macOS) or apt-get install fswatch (Linux)"
    fi
    
    if [ "$all_good" = false ]; then
        print_error "Please install missing requirements and try again"
        exit 1
    fi
}

# Function to setup backend
setup_backend() {
    print_section "Setting up Backend"
    
    cd backend
    
    # Create necessary directories
    print_info "Creating necessary directories..."
    mkdir -p uploads logs temp bin
    
    # Setup environment file
    if [ ! -f ".env" ]; then
        if [ -f "env.example" ]; then
            print_info "Creating .env file from template..."
            cp env.example .env
            print_warning "Please edit .env file with your actual configuration values!"
        else
            print_error "env.example file not found!"
            exit 1
        fi
    else
        print_status ".env file already exists"
    fi
    
    # Download Go dependencies
    print_info "Downloading Go dependencies..."
    go mod download
    go mod tidy
    
    # Build the application
    print_info "Building Go application..."
    if go build -o bin/server ./cmd/server; then
        print_status "Backend built successfully"
    else
        print_error "Failed to build backend"
        exit 1
    fi
    
    cd ..
}

# Function to setup frontend
setup_frontend() {
    print_section "Setting up Frontend (Flutter)"
    
    # Clean previous builds
    print_info "Cleaning previous Flutter builds..."
    flutter clean
    
    # Get Flutter dependencies
    print_info "Getting Flutter dependencies..."
    flutter pub get
    
    # Check for Flutter issues
    print_info "Running Flutter doctor..."
    flutter doctor --android-licenses >/dev/null 2>&1 || true
    
    print_status "Frontend setup completed"
}

# Function to start MongoDB
start_mongodb() {
    print_section "Starting MongoDB"
    
    # Check if MongoDB is already running
    if pgrep mongod >/dev/null; then
        print_status "MongoDB is already running"
        return 0
    fi
    
    # Create MongoDB data directory
    local mongo_data_dir="$HOME/mongodb-data"
    mkdir -p "$mongo_data_dir"
    
    print_info "Starting MongoDB..."
    
    # Start MongoDB in background
    if command_exists brew && brew services list | grep -i "mongodb-community" >/dev/null; then
        # macOS with Homebrew (support versioned service names)
        local brew_mongo_service=$(brew services list | awk 'tolower($0) ~ /mongodb-community/ {print $1; exit}')
        if [ -n "$brew_mongo_service" ]; then
            brew services start "$brew_mongo_service"
            print_status "MongoDB started via Homebrew ($brew_mongo_service)"
        else
            print_warning "Could not detect mongodb-community service name; starting manually"
            mongod --dbpath "$mongo_data_dir" --logpath "$mongo_data_dir/mongodb.log" --fork
            pgrep -f "mongod --dbpath $mongo_data_dir" | head -n1 > mongodb.pid || true
            print_status "MongoDB started manually"
        fi
    else
        # Manual start
        mongod --dbpath "$mongo_data_dir" --logpath "$mongo_data_dir/mongodb.log" --fork
        pgrep -f "mongod --dbpath $mongo_data_dir" | head -n1 > mongodb.pid || true
        print_status "MongoDB started manually"
    fi
    
    # Wait for MongoDB to be ready
    sleep 5
    
    # Initialize database with sample data
    print_info "Initializing database..."
    if [ -f "backend/migrations/init-mongo.js" ]; then
        if command_exists mongosh; then
            mongosh thyne_jewels backend/migrations/init-mongo.js >/dev/null 2>&1 || true
            print_status "Database initialization attempted with mongosh"
        elif command_exists mongo; then
            mongo thyne_jewels backend/migrations/init-mongo.js >/dev/null 2>&1 || true
            print_status "Database initialization attempted with mongo"
        else
            print_warning "No Mongo shell available; skipping database initialization"
        fi
    fi
}

# Function to build backend
build_backend() {
    cd backend
    print_info "Building Go application..."
    if go build -o bin/server ./cmd/server; then
        print_status "Backend built successfully"
        return 0
    else
        print_error "Failed to build backend"
        return 1
    fi
    cd ..
}

# Function to start backend with auto-reload
start_backend_with_reload() {
    print_section "Starting Backend Server with Auto-Reload"
    
    cd backend
    
    # Kill any existing process on port 8080
    kill_port 8080
    
    # Export environment variables for the session
    export GIN_MODE=debug
    export PORT=8080
    export HOST=localhost
    
    # Build initial version
    if ! build_backend; then
        cd ..
        exit 1
    fi
    
    # Start the backend server
    print_info "Starting Go backend server on port 8080 with auto-reload..."
    
    # Start server in background
    nohup ./bin/server > ../backend.log 2>&1 &
    local backend_pid=$!
    echo $backend_pid > ../backend.pid
    
    cd ..
    
    # Wait for backend to be ready
    if wait_for_service "http://localhost:8080/health" "Backend API"; then
        print_status "Backend server started successfully (PID: $backend_pid)"
        print_info "Backend logs: tail -f backend.log"
        print_info "API Health: http://localhost:8080/health"
        print_info "API Base URL: http://localhost:8080/api/v1"
        
        # Start file watcher for auto-reload
        if command_exists fswatch; then
            print_info "Starting file watcher for backend auto-reload..."
            fswatch -o backend --exclude='.*\.(log|pid|tmp)$' --exclude='bin/.*' --exclude='uploads/.*' --exclude='temp/.*' | while read num; do
                print_info "Backend files changed, rebuilding and restarting..."
                
                # Kill current backend
                if [ -f "backend.pid" ]; then
                    local old_pid=$(cat backend.pid)
                    if kill -0 $old_pid 2>/dev/null; then
                        kill $old_pid
                        sleep 2
                    fi
                fi
                
                # Rebuild and restart
                cd backend
                if go build -o bin/server ./cmd/server; then
                    print_status "Backend rebuilt successfully"
                    
                    # Start new instance
                    nohup ./bin/server > ../backend.log 2>&1 &
                    local new_pid=$!
                    echo $new_pid > ../backend.pid
                    
                    print_status "Backend restarted (PID: $new_pid)"
                else
                    print_error "Backend rebuild failed, keeping old version"
                fi
                cd ..
            done &
            
            # Store watcher PID
            echo $! > backend-watcher.pid
            print_status "File watcher started for backend auto-reload"
        else
            print_warning "fswatch not available, auto-reload disabled"
        fi
    else
        print_error "Backend failed to start"
        exit 1
    fi
}

# Function to start backend (legacy, without auto-reload)
start_backend() {
    print_section "Starting Backend Server"
    
    cd backend
    
    # Kill any existing process on port 8080
    kill_port 8080
    
    # Start the backend server
    print_info "Starting Go backend server on port 8080..."
    
    # Export environment variables for the session
    export GIN_MODE=debug
    export PORT=8080
    export HOST=localhost
    
    # Start server in background
    nohup ./bin/server > ../backend.log 2>&1 &
    local backend_pid=$!
    echo $backend_pid > ../backend.pid
    
    cd ..
    
    # Wait for backend to be ready
    if wait_for_service "http://localhost:8080/health" "Backend API"; then
        print_status "Backend server started successfully (PID: $backend_pid)"
        print_info "Backend logs: tail -f backend.log"
        print_info "API Health: http://localhost:8080/health"
        print_info "API Base URL: http://localhost:8080/api/v1"
    else
        print_error "Backend failed to start"
        exit 1
    fi
}

# Function to start frontend with hot reload
start_frontend() {
    print_section "Starting Frontend (Flutter) with Hot Reload"
    
    # Clean any previous builds that might interfere with hot reload
    print_info "Preparing Flutter for hot reload..."
    flutter clean > /dev/null 2>&1
    flutter pub get > /dev/null 2>&1
    
    # Check for hot reload blockers
    print_info "Checking for hot reload compatibility..."
    local const_files=$(find lib -name "*.dart" -exec grep -l "const.*(" {} \; 2>/dev/null | wc -l | tr -d ' ')
    if [ "$const_files" -gt 0 ]; then
        print_warning "Found $const_files files with const constructors"
        print_info "If hot reload doesn't work, try hot restart (press 'R' instead of 'r')"
    fi
    
    print_info "Available Flutter run options:"
    echo "  1. Android Emulator (with hot reload)"
    echo "  2. iOS Simulator (with hot reload)"
    echo "  3. Chrome (Web) (with hot reload)"
    echo "  4. Desktop (macOS/Linux/Windows) (with hot reload)"
    echo "  5. List available devices"
    echo ""
    
    read -p "Choose an option (1-5) or press Enter for Chrome: " choice
    choice=${choice:-3}
    
    case $choice in
        1)
            print_info "Starting Flutter app on Android emulator with hot reload..."
            print_status "Hot reload enabled - press 'r' to reload, 'R' to restart, 'q' to quit"
            print_warning "Make sure Android emulator is running!"
            flutter run -d android --hot --enable-software-rendering
            ;;
        2)
            print_info "Starting Flutter app on iOS simulator with hot reload..."
            print_status "Hot reload enabled - press 'r' to reload, 'R' to restart, 'q' to quit"
            print_warning "Make sure iOS simulator is running!"
            flutter run -d ios --hot
            ;;
        3)
            print_info "Starting Flutter app in Chrome with hot reload..."
            print_status "Hot reload enabled - press 'r' to reload, 'R' to restart, 'q' to quit"
            print_info "App will be available at: http://localhost:3000"
            # Add verbose flag to see hot reload messages and optimize for web
            flutter run -d chrome --web-port=3000 --hot --dart-define=FLUTTER_WEB_USE_SKIA=false --verbose
            ;;
        4)
            print_info "Starting Flutter app on desktop with hot reload..."
            print_status "Hot reload enabled - press 'r' to reload, 'R' to restart, 'q' to quit"
            flutter run -d macos --hot
            ;;
        5)
            print_info "Available devices:"
            flutter devices
            echo ""
            read -p "Enter device ID to run on: " device_id
            if [ -n "$device_id" ]; then
                print_info "Starting Flutter app on $device_id with hot reload..."
                print_status "Hot reload enabled - press 'r' to reload, 'R' to restart, 'q' to quit"
                
                # Add specific flags based on device type
                if [[ "$device_id" == *"chrome"* ]]; then
                    flutter run -d "$device_id" --hot --dart-define=FLUTTER_WEB_USE_SKIA=false --verbose
                else
                    flutter run -d "$device_id" --hot --verbose
                fi
            else
                print_error "No device ID provided"
                exit 1
            fi
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
}

# Function for enhanced hot reload development
start_hot_reload_dev() {
    print_section "Enhanced Hot Reload Development Mode"
    
    print_info "This mode optimizes Flutter for maximum hot reload compatibility"
    
    # Clean everything for fresh start
    print_info "Cleaning project for optimal hot reload..."
    flutter clean
    flutter pub get
    
    # Remove build cache that might interfere
    rm -rf build/
    rm -rf .dart_tool/build/
    
    print_info "Available platforms for enhanced hot reload:"
    echo "  1. Chrome (Web) - Recommended for UI development"
    echo "  2. macOS Desktop - Good for testing desktop features"
    echo "  3. Android Emulator - Mobile testing"
    echo "  4. iOS Simulator - iOS testing"
    echo ""
    
    read -p "Choose platform (1-4) or press Enter for Chrome: " platform
    platform=${platform:-1}
    
    case $platform in
        1)
            print_info "Starting Chrome with enhanced hot reload..."
            print_status "🔥 Enhanced hot reload active!"
            print_info "Tips: Use Chrome DevTools (F12) for debugging"
            print_info "Hot reload: 'r' | Hot restart: 'R' | Quit: 'q'"
            
            # Start with optimal flags for hot reload
            flutter run -d chrome \
                --web-port=3000 \
                --hot \
                --dart-define=FLUTTER_WEB_USE_SKIA=false \
                --dart-define=FLUTTER_WEB_AUTO_DETECT=false \
                --verbose
            ;;
        2)
            print_info "Starting macOS Desktop with enhanced hot reload..."
            print_status "🔥 Enhanced hot reload active!"
            print_info "Hot reload: 'r' | Hot restart: 'R' | Quit: 'q'"
            
            flutter run -d macos \
                --hot \
                --verbose
            ;;
        3)
            print_info "Starting Android with enhanced hot reload..."
            print_status "🔥 Enhanced hot reload active!"
            print_warning "Make sure Android emulator is running!"
            print_info "Hot reload: 'r' | Hot restart: 'R' | Quit: 'q'"
            
            flutter run -d android \
                --hot \
                --verbose
            ;;
        4)
            print_info "Starting iOS with enhanced hot reload..."
            print_status "🔥 Enhanced hot reload active!"
            print_warning "Make sure iOS simulator is running!"
            print_info "Hot reload: 'r' | Hot restart: 'R' | Quit: 'q'"
            
            flutter run -d ios \
                --hot \
                --verbose
            ;;
        *)
            print_error "Invalid platform selection"
            exit 1
            ;;
    esac
}

# Function to show running services
show_services() {
    print_section "Running Services"
    
    echo -e "${GREEN}Services Status:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # MongoDB
    if pgrep mongod >/dev/null; then
        echo -e "${GREEN}${CHECK} MongoDB${NC}        Running"
        echo -e "   ${BLUE}${ARROW} Database: thyne_jewels${NC}"
        echo -e "   ${BLUE}${ARROW} Connection: mongodb://localhost:27017${NC}"
    else
        echo -e "${RED}${CROSS} MongoDB${NC}        Not running"
    fi
    
    # Backend
    if [ -f "backend.pid" ] && kill -0 $(cat backend.pid) 2>/dev/null; then
        echo -e "${GREEN}${CHECK} Backend API${NC}     Running on port 8080"
        echo -e "   ${BLUE}${ARROW} Health Check: http://localhost:8080/health${NC}"
        echo -e "   ${BLUE}${ARROW} API Base: http://localhost:8080/api/v1${NC}"
        echo -e "   ${BLUE}${ARROW} Logs: tail -f backend.log${NC}"
    else
        echo -e "${RED}${CROSS} Backend API${NC}     Not running"
    fi
    
    echo ""
    # Backend file watcher
    if [ -f "backend-watcher.pid" ] && kill -0 $(cat backend-watcher.pid) 2>/dev/null; then
        echo -e "${GREEN}${CHECK} File Watcher${NC}    Running (backend auto-reload enabled)"
        echo -e "   ${BLUE}${ARROW} Monitoring: backend/ directory${NC}"
    else
        echo -e "${YELLOW}⚠️  File Watcher${NC}    Not running (auto-reload disabled)"
    fi
    
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}Stop all services:${NC}     ./run-project.sh stop"
    echo -e "${YELLOW}View backend logs:${NC}     tail -f backend.log"
    echo -e "${YELLOW}Test API:${NC}              curl http://localhost:8080/health"
    echo -e "${YELLOW}MongoDB shell:${NC}         mongosh thyne_jewels"
    echo -e "${YELLOW}Flutter hot reload:${NC}    r (in Flutter console)"
    echo -e "${YELLOW}Backend auto-reload:${NC}   Automatic on file changes"
}

# Function to stop all services
stop_services() {
    print_section "Stopping All Services"
    
    # Stop backend file watcher
    if [ -f "backend-watcher.pid" ]; then
        local watcher_pid=$(cat backend-watcher.pid)
        if kill -0 $watcher_pid 2>/dev/null; then
            print_info "Stopping backend file watcher (PID: $watcher_pid)..."
            kill $watcher_pid
            rm -f backend-watcher.pid
            print_status "Backend file watcher stopped"
        fi
    fi
    
    # Stop backend
    if [ -f "backend.pid" ]; then
        local backend_pid=$(cat backend.pid)
        if kill -0 $backend_pid 2>/dev/null; then
            print_info "Stopping backend server (PID: $backend_pid)..."
            kill $backend_pid
            rm -f backend.pid
            print_status "Backend stopped"
        fi
    fi
    
    # Stop MongoDB (if started by this script)
    if command_exists brew && brew services list | grep -i "mongodb-community" | grep -i started >/dev/null; then
        print_info "Stopping MongoDB (Homebrew service)..."
        local brew_mongo_service=$(brew services list | awk 'tolower($0) ~ /mongodb-community/ && tolower($0) ~ /started/ {print $1; exit}')
        if [ -n "$brew_mongo_service" ]; then
            brew services stop "$brew_mongo_service" || true
            print_status "MongoDB service stopped ($brew_mongo_service)"
        fi
    fi

    # Stop manually started mongod
    if [ -f "mongodb.pid" ]; then
        local mongo_pid=$(cat mongodb.pid)
        if kill -0 $mongo_pid 2>/dev/null; then
            print_info "Stopping MongoDB (PID: $mongo_pid)..."
            kill $mongo_pid || true
            rm -f mongodb.pid
            print_status "MongoDB stopped"
        fi
    fi
    
    # Clean up
    kill_port 8080
    kill_port 3000
    
    print_status "All services stopped"
}

# Function to show help
show_help() {
    print_header
    
    echo -e "${CYAN}Usage:${NC}"
    echo "  ./run-project.sh [command] [options]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}     Start all services with auto-reload (default)"
    echo -e "  ${GREEN}dev${NC}       Start in development mode with auto-reload"
    echo -e "  ${GREEN}stop${NC}      Stop all services"
    echo -e "  ${GREEN}restart${NC}   Restart all services"
    echo -e "  ${GREEN}status${NC}    Show service status"
    echo -e "  ${GREEN}setup${NC}     Setup project dependencies only"
    echo -e "  ${GREEN}backend${NC}   Start only backend services with auto-reload"
    echo -e "  ${GREEN}frontend${NC}  Start only frontend with hot reload"
    echo -e "  ${GREEN}hotdev${NC}    Enhanced hot reload development mode"
    echo -e "  ${GREEN}troubleshoot${NC} Diagnose hot reload issues"
    echo -e "  ${GREEN}help${NC}      Show this help message"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  ./run-project.sh              # Start everything with auto-reload"
    echo "  ./run-project.sh dev          # Start in development mode"
    echo "  ./run-project.sh backend      # Start only backend with auto-reload"
    echo "  ./run-project.sh hotdev       # Enhanced hot reload for frontend"
    echo "  ./run-project.sh stop         # Stop all services"
    echo ""
    echo -e "${CYAN}Auto-Reload Features:${NC}"
    echo "  • Backend: Automatically rebuilds and restarts on Go file changes"
    echo "  • Frontend: Flutter hot reload enabled (press 'r' to reload)"
    echo "  • File watcher: Uses fswatch for monitoring file changes"
    echo ""
    echo -e "${CYAN}Requirements:${NC}"
    echo "  • Go 1.21+"
    echo "  • Flutter 3.9.0+"
    echo "  • MongoDB"
    echo "  • Git"
    echo -e "  • fswatch (for auto-reload) - ${YELLOW}brew install fswatch${NC}"
}

# Function to troubleshoot hot reload issues
troubleshoot_hot_reload() {
    print_section "Hot Reload Troubleshooting"
    
    print_info "Checking Flutter hot reload configuration..."
    
    # Check Flutter version
    local flutter_version=$(flutter --version | head -n 1 | awk '{print $2}')
    print_status "Flutter version: $flutter_version"
    
    # Check if we're in debug mode
    if [ -d "build" ]; then
        print_status "Build directory exists"
    else
        print_warning "No build directory found - this is normal for first run"
    fi
    
    # Check pubspec.yaml for potential issues
    if grep -q "flutter:" pubspec.yaml; then
        print_status "pubspec.yaml looks valid"
    else
        print_error "pubspec.yaml might have issues"
    fi
    
    # Check for common hot reload blockers
    print_info "Checking for common hot reload issues..."
    
    # Check for const constructors that might block hot reload
    local const_issues=$(find lib -name "*.dart" -exec grep -l "const.*(" {} \; 2>/dev/null | wc -l)
    if [ "$const_issues" -gt 0 ]; then
        print_warning "Found $const_issues files with const constructors - these can sometimes interfere with hot reload"
    fi
    
    # Check for main function modifications
    if grep -q "void main()" lib/main.dart; then
        print_status "main() function found"
    else
        print_warning "main() function might have issues"
    fi
    
    echo ""
    print_info "Hot Reload Tips:"
    echo "  1. Make sure you're running in debug mode (not release)"
    echo "  2. Try pressing 'R' (capital R) for hot restart instead of 'r'"
    echo "  3. Avoid changing main(), initState(), or dispose() methods"
    echo "  4. If hot reload fails, try hot restart (R) or full restart"
    echo "  5. For web, try using Chrome DevTools for better debugging"
    echo ""
    
    print_info "Quick fixes to try:"
    echo "  • flutter clean && flutter pub get"
    echo "  • Restart your IDE/editor"
    echo "  • Use 'flutter run --verbose' for detailed output"
    echo "  • Check console for hot reload error messages"
}

# Main execution
main() {
    case "${1:-start}" in
        "start"|"dev")
            print_header
            check_requirements
            
            # Try to install fswatch if not present
            if ! command_exists fswatch; then
                print_warning "fswatch not found. Attempting to install for auto-reload functionality..."
                install_file_watcher || print_warning "Could not install fswatch automatically. Auto-reload may be limited."
            fi
            
            setup_backend
            setup_frontend
            start_mongodb
            start_backend_with_reload
            show_services
            echo ""
            print_info "Backend is running with auto-reload. Press Ctrl+C to start frontend or run './run-project.sh frontend' in another terminal"
            read -p "Press Enter to start frontend with hot reload..."
            start_frontend
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 2
            main start
            ;;
        "status")
            show_services
            ;;
        "setup")
            print_header
            check_requirements
            
            # Try to install fswatch if not present
            if ! command_exists fswatch; then
                print_warning "fswatch not found. Attempting to install for auto-reload functionality..."
                install_file_watcher || print_warning "Could not install fswatch automatically. Install manually for auto-reload."
            fi
            
            setup_backend
            setup_frontend
            print_status "Setup completed! Run './run-project.sh start' to launch services with auto-reload"
            ;;
        "backend")
            print_header
            check_requirements
            
            # Try to install fswatch if not present
            if ! command_exists fswatch; then
                print_warning "fswatch not found. Attempting to install for auto-reload functionality..."
                install_file_watcher || print_warning "Could not install fswatch automatically. Backend will run without auto-reload."
            fi
            
            setup_backend
            start_mongodb
            start_backend_with_reload
            show_services
            print_info "Backend services are running with auto-reload. Use Ctrl+C to stop."
            # Keep script running
            trap stop_services EXIT
            while true; do
                sleep 10
            done
            ;;
        "frontend")
            print_header
            check_requirements
            setup_frontend
            start_frontend
            ;;
        "hotdev"|"hot-reload")
            print_header
            check_requirements
            setup_frontend
            start_hot_reload_dev
            ;;
        "troubleshoot"|"debug")
            troubleshoot_hot_reload
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Trap Ctrl+C to stop services gracefully
trap stop_services EXIT

# Run main function with all arguments
main "$@"
