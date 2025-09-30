# Thyne Jewels Project Runner for Windows PowerShell
# This script sets up and runs both frontend and backend locally without Docker

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "status", "setup", "backend", "frontend", "help")]
    [string]$Command = "start"
)

# Enable colors in PowerShell
$Host.UI.RawUI.WindowTitle = "Thyne Jewels Project Runner"

# Color functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "➤ $Message" -ForegroundColor Cyan }
function Write-Section { param($Title) 
    Write-Host "`n⚙️  $Title" -ForegroundColor Magenta
    Write-Host ("=" * 60) -ForegroundColor Magenta
}

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                    THYNE JEWELS RUNNER                       ║" -ForegroundColor Magenta
    Write-Host "║                 Frontend + Backend Setup                     ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

function Test-Command {
    param($CommandName)
    return Get-Command $CommandName -ErrorAction SilentlyContinue
}

function Test-Port {
    param($Port)
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
        return $connection
    } catch {
        return $false
    }
}

function Stop-PortProcess {
    param($Port)
    if (Test-Port $Port) {
        Write-Warning "Port $Port is in use. Attempting to free it..."
        try {
            $processes = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
            foreach ($process in $processes) {
                Stop-Process -Id $process -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 2
            Write-Success "Port $Port freed"
        } catch {
            Write-Warning "Could not free port $Port automatically"
        }
    }
}

function Wait-ForService {
    param($Url, $ServiceName, $MaxAttempts = 30)
    
    Write-Info "Waiting for $ServiceName to be ready..."
    
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Success "$ServiceName is ready!"
                return $true
            }
        } catch {
            # Service not ready yet
        }
        
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 2
    }
    
    Write-Error "$ServiceName failed to start within $($MaxAttempts * 2) seconds"
    return $false
}

function Test-Requirements {
    Write-Section "Checking System Requirements"
    
    $allGood = $true
    
    # Check Go
    if (Test-Command "go") {
        $goVersion = (go version) -replace "go version go", "" -replace " .*", ""
        Write-Success "Go $goVersion installed"
    } else {
        Write-Error "Go is not installed. Please install Go 1.21+ from https://golang.org/dl/"
        $allGood = $false
    }
    
    # Check Flutter
    if (Test-Command "flutter") {
        $flutterVersion = (flutter --version | Select-String "Flutter").Line -replace "Flutter ", "" -replace " •.*", ""
        Write-Success "Flutter $flutterVersion installed"
    } else {
        Write-Error "Flutter is not installed. Please install Flutter from https://flutter.dev/docs/get-started/install"
        $allGood = $false
    }
    
    # Check MongoDB
    if (Test-Command "mongod") {
        Write-Success "MongoDB installed"
    } else {
        Write-Error "MongoDB is not installed. Please install MongoDB from https://docs.mongodb.com/manual/installation/"
        Write-Info "Download from: https://www.mongodb.com/try/download/community"
        $allGood = $false
    }
    
    # Check Node.js (optional)
    if (Test-Command "node") {
        $nodeVersion = node --version
        Write-Success "Node.js $nodeVersion installed"
    } else {
        Write-Warning "Node.js not found (optional for Flutter web)"
    }
    
    if (-not $allGood) {
        Write-Error "Please install missing requirements and try again"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

function Setup-Backend {
    Write-Section "Setting up Backend"
    
    Push-Location "backend"
    
    try {
        # Create necessary directories
        Write-Info "Creating necessary directories..."
        @("uploads", "logs", "temp", "bin") | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
            }
        }
        
        # Setup environment file
        if (-not (Test-Path ".env")) {
            if (Test-Path "env.example") {
                Write-Info "Creating .env file from template..."
                Copy-Item "env.example" ".env"
                Write-Warning "Please edit .env file with your actual configuration values!"
            } else {
                Write-Error "env.example file not found!"
                exit 1
            }
        } else {
            Write-Success ".env file already exists"
        }
        
        # Download Go dependencies
        Write-Info "Downloading Go dependencies..."
        go mod download
        go mod tidy
        
        # Build the application
        Write-Info "Building Go application..."
        $buildResult = go build -o "bin\server.exe" ".\cmd\server"
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Backend built successfully"
        } else {
            Write-Error "Failed to build backend"
            exit 1
        }
    } finally {
        Pop-Location
    }
}

function Setup-Frontend {
    Write-Section "Setting up Frontend (Flutter)"
    
    # Clean previous builds
    Write-Info "Cleaning previous Flutter builds..."
    flutter clean
    
    # Get Flutter dependencies
    Write-Info "Getting Flutter dependencies..."
    flutter pub get
    
    # Check for Flutter issues
    Write-Info "Running Flutter doctor..."
    flutter doctor --android-licenses 2>$null | Out-Null
    
    Write-Success "Frontend setup completed"
}

function Start-MongoDB {
    Write-Section "Starting MongoDB"
    
    # Check if MongoDB is already running
    $mongoProcess = Get-Process -Name "mongod" -ErrorAction SilentlyContinue
    if ($mongoProcess) {
        Write-Success "MongoDB is already running"
        return
    }
    
    # Create MongoDB data directory
    $mongoDataDir = "$env:USERPROFILE\mongodb-data"
    if (-not (Test-Path $mongoDataDir)) {
        New-Item -ItemType Directory -Path $mongoDataDir -Force | Out-Null
    }
    
    Write-Info "Starting MongoDB..."
    
    # Start MongoDB in background
    $mongoArgs = @(
        "--dbpath", "`"$mongoDataDir`"",
        "--logpath", "`"$mongoDataDir\mongodb.log`""
    )
    
    Start-Process -FilePath "mongod" -ArgumentList $mongoArgs -WindowStyle Hidden
    Write-Success "MongoDB started"
    
    # Wait for MongoDB to be ready
    Start-Sleep -Seconds 5
    
    # Initialize database with sample data
    Write-Info "Initializing database..."
    if (Test-Path "backend\migrations\init-mongo.js") {
        try {
            mongosh thyne_jewels "backend\migrations\init-mongo.js" 2>$null | Out-Null
            Write-Success "Database initialized with sample data"
        } catch {
            Write-Warning "Could not initialize database with sample data"
        }
    }
}

function Start-Backend {
    Write-Section "Starting Backend Server"
    
    Push-Location "backend"
    
    try {
        # Kill any existing process on port 8080
        Stop-PortProcess 8080
        
        # Start the backend server
        Write-Info "Starting Go backend server on port 8080..."
        
        # Set environment variables
        $env:GIN_MODE = "debug"
        $env:PORT = "8080"
        $env:HOST = "localhost"
        
        # Start server in background
        $backendJob = Start-Job -ScriptBlock {
            Set-Location $using:PWD
            .\bin\server.exe
        }
        
        $backendJob.Id | Out-File "..\backend.pid" -Encoding ASCII
        
        # Wait for backend to be ready
        if (Wait-ForService "http://localhost:8080/health" "Backend API") {
            Write-Success "Backend server started successfully (Job ID: $($backendJob.Id))"
            Write-Info "Backend logs: Get-Job $($backendJob.Id) | Receive-Job"
            Write-Info "API Health: http://localhost:8080/health"
            Write-Info "API Base URL: http://localhost:8080/api/v1"
        } else {
            Write-Error "Backend failed to start"
            Stop-Job $backendJob -ErrorAction SilentlyContinue
            Remove-Job $backendJob -ErrorAction SilentlyContinue
            exit 1
        }
    } finally {
        Pop-Location
    }
}

function Start-Frontend {
    Write-Section "Starting Frontend (Flutter)"
    
    Write-Info "Available Flutter run options:"
    Write-Host "  1. Android Emulator"
    Write-Host "  2. Chrome (Web)"
    Write-Host "  3. Desktop (Windows)"
    Write-Host "  4. List available devices"
    Write-Host ""
    
    $choice = Read-Host "Choose an option (1-4) or press Enter for Chrome"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "2" }
    
    switch ($choice) {
        "1" {
            Write-Info "Starting Flutter app on Android emulator..."
            flutter run -d android
        }
        "2" {
            Write-Info "Starting Flutter app in Chrome..."
            flutter run -d chrome --web-port=3000
        }
        "3" {
            Write-Info "Starting Flutter app on Windows desktop..."
            flutter run -d windows
        }
        "4" {
            Write-Info "Available devices:"
            flutter devices
            Write-Host ""
            $deviceId = Read-Host "Enter device ID to run on"
            if (-not [string]::IsNullOrWhiteSpace($deviceId)) {
                flutter run -d $deviceId
            } else {
                Write-Error "No device ID provided"
                exit 1
            }
        }
        default {
            Write-Error "Invalid option"
            exit 1
        }
    }
}

function Show-Services {
    Write-Section "Running Services"
    
    Write-Host "Services Status:" -ForegroundColor Green
    Write-Host ("━" * 62)
    
    # MongoDB
    $mongoProcess = Get-Process -Name "mongod" -ErrorAction SilentlyContinue
    if ($mongoProcess) {
        Write-Host "✅ MongoDB        Running" -ForegroundColor Green
        Write-Host "   ➤ Database: thyne_jewels" -ForegroundColor Cyan
        Write-Host "   ➤ Connection: mongodb://localhost:27017" -ForegroundColor Cyan
    } else {
        Write-Host "❌ MongoDB        Not running" -ForegroundColor Red
    }
    
    # Backend
    if ((Test-Path "backend.pid") -and (Test-Port 8080)) {
        Write-Host "✅ Backend API     Running on port 8080" -ForegroundColor Green
        Write-Host "   ➤ Health Check: http://localhost:8080/health" -ForegroundColor Cyan
        Write-Host "   ➤ API Base: http://localhost:8080/api/v1" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Backend API     Not running" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Useful Commands:" -ForegroundColor Cyan
    Write-Host ("━" * 62)
    Write-Host "Stop all services:     .\run-project.ps1 stop" -ForegroundColor Yellow
    Write-Host "Test API:              curl http://localhost:8080/health" -ForegroundColor Yellow
    Write-Host "MongoDB shell:         mongosh thyne_jewels" -ForegroundColor Yellow
    Write-Host "Flutter hot reload:    r (in Flutter console)" -ForegroundColor Yellow
}

function Stop-Services {
    Write-Section "Stopping All Services"
    
    # Stop backend
    if (Test-Path "backend.pid") {
        $jobId = Get-Content "backend.pid" -ErrorAction SilentlyContinue
        if ($jobId) {
            Write-Info "Stopping backend server (Job ID: $jobId)..."
            Stop-Job -Id $jobId -ErrorAction SilentlyContinue
            Remove-Job -Id $jobId -Force -ErrorAction SilentlyContinue
            Remove-Item "backend.pid" -ErrorAction SilentlyContinue
            Write-Success "Backend stopped"
        }
    }
    
    # Stop MongoDB
    $mongoProcess = Get-Process -Name "mongod" -ErrorAction SilentlyContinue
    if ($mongoProcess) {
        Write-Info "Stopping MongoDB..."
        Stop-Process -Name "mongod" -Force -ErrorAction SilentlyContinue
        Write-Success "MongoDB stopped"
    }
    
    # Clean up ports
    Stop-PortProcess 8080
    Stop-PortProcess 3000
    
    Write-Success "All services stopped"
}

function Show-Help {
    Show-Header
    
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\run-project.ps1 [command]"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  start     Start all services (default)" -ForegroundColor Green
    Write-Host "  stop      Stop all services" -ForegroundColor Green
    Write-Host "  restart   Restart all services" -ForegroundColor Green
    Write-Host "  status    Show service status" -ForegroundColor Green
    Write-Host "  setup     Setup project dependencies only" -ForegroundColor Green
    Write-Host "  backend   Start only backend services" -ForegroundColor Green
    Write-Host "  frontend  Start only frontend" -ForegroundColor Green
    Write-Host "  help      Show this help message" -ForegroundColor Green
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\run-project.ps1              # Start everything"
    Write-Host "  .\run-project.ps1 backend      # Start only backend"
    Write-Host "  .\run-project.ps1 stop         # Stop all services"
    Write-Host ""
    Write-Host "Requirements:" -ForegroundColor Cyan
    Write-Host "  • Go 1.21+"
    Write-Host "  • Flutter 3.9.0+"
    Write-Host "  • MongoDB"
    Write-Host "  • Git"
}

# Main execution
try {
    switch ($Command) {
        "start" {
            Show-Header
            Test-Requirements
            Setup-Backend
            Setup-Frontend
            Start-MongoDB
            Start-Backend
            Show-Services
            Write-Host ""
            Write-Info "Backend is running. Press Enter to start frontend..."
            Read-Host
            Start-Frontend
        }
        "stop" {
            Stop-Services
        }
        "restart" {
            Stop-Services
            Start-Sleep -Seconds 2
            & $MyInvocation.MyCommand.Path "start"
        }
        "status" {
            Show-Services
        }
        "setup" {
            Show-Header
            Test-Requirements
            Setup-Backend
            Setup-Frontend
            Write-Success "Setup completed! Run '.\run-project.ps1 start' to launch services"
        }
        "backend" {
            Show-Header
            Test-Requirements
            Setup-Backend
            Start-MongoDB
            Start-Backend
            Show-Services
            Write-Info "Backend services are running. Press any key to stop."
            Read-Host
            Stop-Services
        }
        "frontend" {
            Show-Header
            Test-Requirements
            Setup-Frontend
            Start-Frontend
        }
        "help" {
            Show-Help
        }
    }
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Read-Host "Press Enter to exit"
    exit 1
} finally {
    Write-Host ""
    Write-Host "Thank you for using Thyne Jewels Runner!" -ForegroundColor Green
}
