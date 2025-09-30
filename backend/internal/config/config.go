package config

import (
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Razorpay RazorpayConfig
	AWS      AWSConfig
	Email    EmailConfig
	App      AppConfig
	Security SecurityConfig
	File     FileConfig
	Tax      TaxConfig
	Firebase FirebaseConfig
}

type ServerConfig struct {
	Port string
	Host string
	Mode string
}

type DatabaseConfig struct {
	URI  string
	Name string
}

type JWTConfig struct {
	Secret           string
	Expiry           string
	RefreshExpiry    string
}

type RazorpayConfig struct {
	KeyID     string
	KeySecret string
	WebhookSecret string
}

type AWSConfig struct {
	AccessKeyID     string
	SecretAccessKey string
	Region          string
	S3Bucket        string
}

type EmailConfig struct {
	SMTPHost     string
	SMTPPort     int
	SMTPUsername string
	SMTPPassword string
	FromName     string
}

type AppConfig struct {
	Name        string
	URL         string
	FrontendURL string
	APIVersion  string
}

type SecurityConfig struct {
	BcryptCost           int
	RateLimitPerMinute   int
	CORSAllowedOrigins   []string
}

type FileConfig struct {
	MaxFileSize      int64
	AllowedImageTypes []string
}

type TaxConfig struct {
	TaxRate                float64
	FreeShippingThreshold  float64
	ShippingCost          float64
}

type FirebaseConfig struct {
	CredentialsPath string
	ProjectID       string
}

func Load() *Config {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Set up Viper
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("../config")
	viper.AddConfigPath("../../config")

	// Set defaults
	setDefaults()

	// Read config file (optional)
	if err := viper.ReadInConfig(); err != nil {
		log.Printf("Error reading config file: %v", err)
	}

	// Enable reading from environment variables
	viper.AutomaticEnv()

	return &Config{
		Server: ServerConfig{
			Port: getEnv("PORT", "8080"),
			Host: getEnv("HOST", "localhost"),
			Mode: getEnv("GIN_MODE", "debug"),
		},
		Database: DatabaseConfig{
			URI:  getEnv("MONGODB_URI", "mongodb://localhost:27017"),
			Name: getEnv("MONGODB_NAME", "thyne_jewels"),
		},
		JWT: JWTConfig{
			Secret:        getEnv("JWT_SECRET", "your-super-secret-jwt-key"),
			Expiry:        getEnv("JWT_EXPIRY", "24h"),
			RefreshExpiry: getEnv("REFRESH_TOKEN_EXPIRY", "168h"),
		},
		Razorpay: RazorpayConfig{
			KeyID:        getEnv("RAZORPAY_KEY_ID", ""),
			KeySecret:    getEnv("RAZORPAY_KEY_SECRET", ""),
			WebhookSecret: getEnv("RAZORPAY_WEBHOOK_SECRET", ""),
		},
		AWS: AWSConfig{
			AccessKeyID:     getEnv("AWS_ACCESS_KEY_ID", ""),
			SecretAccessKey: getEnv("AWS_SECRET_ACCESS_KEY", ""),
			Region:          getEnv("AWS_REGION", "us-east-1"),
			S3Bucket:        getEnv("AWS_S3_BUCKET", ""),
		},
		Email: EmailConfig{
			SMTPHost:     getEnv("SMTP_HOST", "smtp.gmail.com"),
			SMTPPort:     getEnvAsInt("SMTP_PORT", 587),
			SMTPUsername: getEnv("SMTP_USERNAME", ""),
			SMTPPassword: getEnv("SMTP_PASSWORD", ""),
			FromName:     getEnv("SMTP_FROM_NAME", "Thyne Jewels"),
		},
		App: AppConfig{
			Name:        getEnv("APP_NAME", "Thyne Jewels"),
			URL:         getEnv("APP_URL", "http://localhost:8080"),
			FrontendURL: getEnv("FRONTEND_URL", "http://localhost:3000"),
			APIVersion:  getEnv("API_VERSION", "v1"),
		},
		Security: SecurityConfig{
			BcryptCost:         getEnvAsInt("BCRYPT_COST", 12),
			RateLimitPerMinute: getEnvAsInt("RATE_LIMIT_PER_MINUTE", 100),
			CORSAllowedOrigins: strings.Split(getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000"), ","),
		},
		File: FileConfig{
			MaxFileSize:      getEnvAsInt64("MAX_FILE_SIZE", 10485760), // 10MB
			AllowedImageTypes: strings.Split(getEnv("ALLOWED_IMAGE_TYPES", "jpg,jpeg,png,webp"), ","),
		},
		Tax: TaxConfig{
			TaxRate:               getEnvAsFloat64("TAX_RATE", 0.18),
			FreeShippingThreshold: getEnvAsFloat64("FREE_SHIPPING_THRESHOLD", 1000),
			ShippingCost:         getEnvAsFloat64("SHIPPING_COST", 99),
		},
		Firebase: FirebaseConfig{
			CredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", ""),
			ProjectID:       getEnv("FIREBASE_PROJECT_ID", ""),
		},
	}
}

func setDefaults() {
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("HOST", "localhost")
	viper.SetDefault("GIN_MODE", "debug")
	viper.SetDefault("MONGODB_URI", "mongodb://localhost:27017")
	viper.SetDefault("MONGODB_NAME", "thyne_jewels")
	viper.SetDefault("JWT_SECRET", "your-super-secret-jwt-key")
	viper.SetDefault("JWT_EXPIRY", "24h")
	viper.SetDefault("REFRESH_TOKEN_EXPIRY", "168h")
	viper.SetDefault("BCRYPT_COST", 12)
	viper.SetDefault("RATE_LIMIT_PER_MINUTE", 100)
	viper.SetDefault("CORS_ALLOWED_ORIGINS", "http://localhost:3000")
	viper.SetDefault("MAX_FILE_SIZE", 10485760)
	viper.SetDefault("ALLOWED_IMAGE_TYPES", "jpg,jpeg,png,webp")
	viper.SetDefault("TAX_RATE", 0.18)
	viper.SetDefault("FREE_SHIPPING_THRESHOLD", 1000)
	viper.SetDefault("SHIPPING_COST", 99)
	viper.SetDefault("DEFAULT_PAGE_SIZE", 20)
	viper.SetDefault("MAX_PAGE_SIZE", 100)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsInt64(key string, defaultValue int64) int64 {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.ParseInt(value, 10, 64); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsFloat64(key string, defaultValue float64) float64 {
	if value := os.Getenv(key); value != "" {
		if floatValue, err := strconv.ParseFloat(value, 64); err == nil {
			return floatValue
		}
	}
	return defaultValue
}
