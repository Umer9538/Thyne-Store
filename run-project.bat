@echo off
REM Thyne Jewels Project Runner for Windows (Without Docker)
REM This script sets up and runs both frontend and backend locally

setlocal EnableDelayedExpansion

REM Set colors (Windows 10+)
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "PURPLE=[95m"
set "CYAN=[96m"
set "NC=[0m"

REM Unicode symbols (fallback for older Windows)
set "CHECK=✓"
set "CROSS=✗"
set "ARROW=>"
set "GEAR=*"

echo.
echo %PURPLE%╔══════════════════════════════════════════════════════════════╗%NC%
echo %PURPLE%║                    THYNE JEWELS RUNNER                       ║%NC%
echo %PURPLE%║                 Frontend + Backend Setup                     ║%NC%
echo %PURPLE%╚══════════════════════════════════════════════════════════════╝%NC%
echo.

REM Function to print status messages
:print_status
echo %GREEN%%CHECK% %~1%NC%
goto :eof

:print_error
echo %RED%%CROSS% %~1%NC%
goto :eof

:print_warning
echo %YELLOW%⚠ %~1%NC%
goto :eof

:print_info
echo %BLUE%%ARROW% %~1%NC%
goto :eof

:print_section
echo.
echo %CYAN%%GEAR% %~1%NC%
echo %CYAN%===========================================================%NC%
goto :eof

REM Function to check if a command exists
:command_exists
where %1 >nul 2>&1
exit /b %errorlevel%

REM Function to check if port is in use
:port_in_use
netstat -an | find ":%1 " | find "LISTENING" >nul 2>&1
exit /b %errorlevel%

REM Function to kill process on port
:kill_port
call :port_in_use %1
if !errorlevel! equ 0 (
    call :print_warning "Port %1 is in use. Attempting to free it..."
    for /f "tokens=5" %%a in ('netstat -ano ^| find ":%1 " ^| find "LISTENING"') do (
        taskkill /F /PID %%a >nul 2>&1
    )
    timeout /t 2 >nul
)
goto :eof

REM Function to wait for service
:wait_for_service
set "url=%~1"
set "service_name=%~2"
set "max_attempts=30"
set "attempt=1"

call :print_info "Waiting for %service_name% to be ready..."

:wait_loop
if !attempt! gtr !max_attempts! (
    call :print_error "%service_name% failed to start within 60 seconds"
    exit /b 1
)

curl -s "%url%" >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "%service_name% is ready!"
    exit /b 0
)

echo|set /p="."
timeout /t 2 >nul
set /a attempt+=1
goto wait_loop

REM Function to check system requirements
:check_requirements
call :print_section "Checking System Requirements"

set "all_good=true"

REM Check Go
call :command_exists go
if !errorlevel! equ 0 (
    for /f "tokens=3" %%i in ('go version') do (
        set "go_version=%%i"
        set "go_version=!go_version:go=!"
        call :print_status "Go !go_version! installed"
    )
) else (
    call :print_error "Go is not installed. Please install Go 1.21+ from https://golang.org/dl/"
    set "all_good=false"
)

REM Check Flutter
call :command_exists flutter
if !errorlevel! equ 0 (
    for /f "tokens=2" %%i in ('flutter --version ^| find "Flutter"') do (
        call :print_status "Flutter %%i installed"
        goto flutter_found
    )
    :flutter_found
) else (
    call :print_error "Flutter is not installed. Please install Flutter from https://flutter.dev/docs/get-started/install"
    set "all_good=false"
)

REM Check MongoDB
call :command_exists mongod
if !errorlevel! equ 0 (
    call :print_status "MongoDB installed"
) else (
    call :print_error "MongoDB is not installed. Please install MongoDB from https://docs.mongodb.com/manual/installation/"
    call :print_info "Download from: https://www.mongodb.com/try/download/community"
    set "all_good=false"
)

REM Check Node.js (optional)
call :command_exists node
if !errorlevel! equ 0 (
    for /f "tokens=1" %%i in ('node --version') do (
        call :print_status "Node.js %%i installed"
    )
) else (
    call :print_warning "Node.js not found (optional for Flutter web)"
)

if "!all_good!" == "false" (
    call :print_error "Please install missing requirements and try again"
    pause
    exit /b 1
)
goto :eof

REM Function to setup backend
:setup_backend
call :print_section "Setting up Backend"

cd backend

REM Create necessary directories
call :print_info "Creating necessary directories..."
if not exist "uploads" mkdir uploads
if not exist "logs" mkdir logs
if not exist "temp" mkdir temp
if not exist "bin" mkdir bin

REM Setup environment file
if not exist ".env" (
    if exist "env.example" (
        call :print_info "Creating .env file from template..."
        copy env.example .env >nul
        call :print_warning "Please edit .env file with your actual configuration values!"
    ) else (
        call :print_error "env.example file not found!"
        pause
        exit /b 1
    )
) else (
    call :print_status ".env file already exists"
)

REM Download Go dependencies
call :print_info "Downloading Go dependencies..."
go mod download
go mod tidy

REM Build the application
call :print_info "Building Go application..."
go build -o bin\server.exe .\cmd\server
if !errorlevel! equ 0 (
    call :print_status "Backend built successfully"
) else (
    call :print_error "Failed to build backend"
    pause
    exit /b 1
)

cd ..
goto :eof

REM Function to setup frontend
:setup_frontend
call :print_section "Setting up Frontend (Flutter)"

REM Clean previous builds
call :print_info "Cleaning previous Flutter builds..."
flutter clean

REM Get Flutter dependencies
call :print_info "Getting Flutter dependencies..."
flutter pub get

REM Check for Flutter issues
call :print_info "Running Flutter doctor..."
flutter doctor --android-licenses >nul 2>&1

call :print_status "Frontend setup completed"
goto :eof

REM Function to start MongoDB
:start_mongodb
call :print_section "Starting MongoDB"

REM Check if MongoDB is already running
tasklist /FI "IMAGENAME eq mongod.exe" 2>NUL | find /I /N "mongod.exe" >nul
if !errorlevel! equ 0 (
    call :print_status "MongoDB is already running"
    goto :eof
)

REM Create MongoDB data directory
set "mongo_data_dir=%USERPROFILE%\mongodb-data"
if not exist "!mongo_data_dir!" mkdir "!mongo_data_dir!"

call :print_info "Starting MongoDB..."

REM Start MongoDB in background
start /B mongod --dbpath "!mongo_data_dir!" --logpath "!mongo_data_dir!\mongodb.log"
call :print_status "MongoDB started"

REM Wait for MongoDB to be ready
timeout /t 5 >nul

REM Initialize database with sample data
call :print_info "Initializing database..."
if exist "backend\migrations\init-mongo.js" (
    mongosh thyne_jewels backend\migrations\init-mongo.js >nul 2>&1
    call :print_status "Database initialized with sample data"
)
goto :eof

REM Function to start backend
:start_backend
call :print_section "Starting Backend Server"

cd backend

REM Kill any existing process on port 8080
call :kill_port 8080

REM Start the backend server
call :print_info "Starting Go backend server on port 8080..."

REM Set environment variables
set GIN_MODE=debug
set PORT=8080
set HOST=localhost

REM Start server in background
start /B bin\server.exe > ..\backend.log 2>&1

cd ..

REM Wait for backend to be ready
call :wait_for_service "http://localhost:8080/health" "Backend API"
if !errorlevel! equ 0 (
    call :print_status "Backend server started successfully"
    call :print_info "Backend logs: type backend.log"
    call :print_info "API Health: http://localhost:8080/health"
    call :print_info "API Base URL: http://localhost:8080/api/v1"
) else (
    call :print_error "Backend failed to start"
    pause
    exit /b 1
)
goto :eof

REM Function to start frontend
:start_frontend
call :print_section "Starting Frontend (Flutter)"

call :print_info "Available Flutter run options:"
echo   1. Android Emulator
echo   2. Chrome (Web)
echo   3. Desktop (Windows)
echo   4. List available devices
echo.

set /p "choice=Choose an option (1-4) or press Enter for Chrome: "
if "!choice!" == "" set "choice=2"

if "!choice!" == "1" (
    call :print_info "Starting Flutter app on Android emulator..."
    flutter run -d android
) else if "!choice!" == "2" (
    call :print_info "Starting Flutter app in Chrome..."
    flutter run -d chrome --web-port=3000
) else if "!choice!" == "3" (
    call :print_info "Starting Flutter app on Windows desktop..."
    flutter run -d windows
) else if "!choice!" == "4" (
    call :print_info "Available devices:"
    flutter devices
    echo.
    set /p "device_id=Enter device ID to run on: "
    if not "!device_id!" == "" (
        flutter run -d "!device_id!"
    ) else (
        call :print_error "No device ID provided"
        pause
        exit /b 1
    )
) else (
    call :print_error "Invalid option"
    pause
    exit /b 1
)
goto :eof

REM Function to show running services
:show_services
call :print_section "Running Services"

echo %GREEN%Services Status:%NC%
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM MongoDB
tasklist /FI "IMAGENAME eq mongod.exe" 2>NUL | find /I /N "mongod.exe" >nul
if !errorlevel! equ 0 (
    echo %GREEN%%CHECK% MongoDB%NC%        Running
    echo    %BLUE%%ARROW% Database: thyne_jewels%NC%
    echo    %BLUE%%ARROW% Connection: mongodb://localhost:27017%NC%
) else (
    echo %RED%%CROSS% MongoDB%NC%        Not running
)

REM Backend
call :port_in_use 8080
if !errorlevel! equ 0 (
    echo %GREEN%%CHECK% Backend API%NC%     Running on port 8080
    echo    %BLUE%%ARROW% Health Check: http://localhost:8080/health%NC%
    echo    %BLUE%%ARROW% API Base: http://localhost:8080/api/v1%NC%
    echo    %BLUE%%ARROW% Logs: type backend.log%NC%
) else (
    echo %RED%%CROSS% Backend API%NC%     Not running
)

echo.
echo %CYAN%Useful Commands:%NC%
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo %YELLOW%Stop all services:%NC%     run-project.bat stop
echo %YELLOW%View backend logs:%NC%     type backend.log
echo %YELLOW%Test API:%NC%              curl http://localhost:8080/health
echo %YELLOW%MongoDB shell:%NC%         mongosh thyne_jewels
echo %YELLOW%Flutter hot reload:%NC%    r (in Flutter console)
goto :eof

REM Function to stop all services
:stop_services
call :print_section "Stopping All Services"

REM Stop backend
call :kill_port 8080
call :print_status "Backend stopped"

REM Stop MongoDB
tasklist /FI "IMAGENAME eq mongod.exe" 2>NUL | find /I /N "mongod.exe" >nul
if !errorlevel! equ 0 (
    call :print_info "Stopping MongoDB..."
    taskkill /F /IM mongod.exe >nul 2>&1
    call :print_status "MongoDB stopped"
)

REM Clean up
call :kill_port 3000

call :print_status "All services stopped"
goto :eof

REM Function to show help
:show_help
echo.
echo %PURPLE%╔══════════════════════════════════════════════════════════════╗%NC%
echo %PURPLE%║                    THYNE JEWELS RUNNER                       ║%NC%
echo %PURPLE%║                 Frontend + Backend Setup                     ║%NC%
echo %PURPLE%╚══════════════════════════════════════════════════════════════╝%NC%
echo.

echo %CYAN%Usage:%NC%
echo   run-project.bat [command]
echo.
echo %CYAN%Commands:%NC%
echo   %GREEN%start%NC%     Start all services (default)
echo   %GREEN%stop%NC%      Stop all services
echo   %GREEN%restart%NC%   Restart all services
echo   %GREEN%status%NC%    Show service status
echo   %GREEN%setup%NC%     Setup project dependencies only
echo   %GREEN%backend%NC%   Start only backend services
echo   %GREEN%frontend%NC%  Start only frontend
echo   %GREEN%help%NC%      Show this help message
echo.
echo %CYAN%Examples:%NC%
echo   run-project.bat              # Start everything
echo   run-project.bat backend      # Start only backend
echo   run-project.bat stop         # Stop all services
echo.
echo %CYAN%Requirements:%NC%
echo   • Go 1.21+
echo   • Flutter 3.9.0+
echo   • MongoDB
echo   • Git
goto :eof

REM Main execution
if "%~1" == "" goto start
if "%~1" == "start" goto start
if "%~1" == "stop" goto stop
if "%~1" == "restart" goto restart
if "%~1" == "status" goto status
if "%~1" == "setup" goto setup
if "%~1" == "backend" goto backend
if "%~1" == "frontend" goto frontend
if "%~1" == "help" goto help
if "%~1" == "-h" goto help
if "%~1" == "--help" goto help

call :print_error "Unknown command: %~1"
call :show_help
pause
exit /b 1

:start
call :check_requirements
call :setup_backend
call :setup_frontend
call :start_mongodb
call :start_backend
call :show_services
echo.
call :print_info "Backend is running. Press any key to start frontend..."
pause >nul
call :start_frontend
goto end

:stop
call :stop_services
goto end

:restart
call :stop_services
timeout /t 2 >nul
goto start

:status
call :show_services
goto end

:setup
call :check_requirements
call :setup_backend
call :setup_frontend
call :print_status "Setup completed! Run 'run-project.bat start' to launch services"
goto end

:backend
call :check_requirements
call :setup_backend
call :start_mongodb
call :start_backend
call :show_services
call :print_info "Backend services are running. Press any key to stop."
pause >nul
call :stop_services
goto end

:frontend
call :check_requirements
call :setup_frontend
call :start_frontend
goto end

:help
call :show_help
goto end

:end
echo.
echo %GREEN%Thank you for using Thyne Jewels Runner!%NC%
pause
