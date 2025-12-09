package services

import (
	"bytes"
	"context"
	"encoding/base64"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"
)

// S3Service handles AWS S3 operations for image storage
type S3Service struct {
	client     *s3.Client
	bucket     string
	region     string
	baseURL    string // CloudFront URL or S3 bucket URL
	isEnabled  bool
}

// S3Config holds configuration for S3 service
type S3Config struct {
	AccessKeyID     string
	SecretAccessKey string
	Region          string
	Bucket          string
	CloudFrontURL   string // Optional: CloudFront distribution URL
}

// NewS3Service creates a new S3 service instance
func NewS3Service() (*S3Service, error) {
	// Read configuration from environment variables
	accessKey := os.Getenv("AWS_ACCESS_KEY_ID")
	secretKey := os.Getenv("AWS_SECRET_ACCESS_KEY")
	region := os.Getenv("AWS_REGION")
	bucket := os.Getenv("AWS_S3_BUCKET")
	cloudFrontURL := os.Getenv("AWS_CLOUDFRONT_URL")

	// Check if S3 is configured
	if accessKey == "" || secretKey == "" || region == "" || bucket == "" {
		fmt.Println("S3 not configured - falling back to local storage")
		fmt.Printf("Missing: AccessKey=%v, SecretKey=%v, Region=%v, Bucket=%v\n",
			accessKey == "", secretKey == "", region == "", bucket == "")
		return &S3Service{
			isEnabled: false,
		}, nil
	}

	// Create AWS config with credentials
	cfg, err := config.LoadDefaultConfig(context.Background(),
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
			accessKey,
			secretKey,
			"",
		)),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	// Create S3 client
	client := s3.NewFromConfig(cfg)

	// Determine base URL for accessing files
	baseURL := cloudFrontURL
	if baseURL == "" {
		// Use S3 bucket URL if no CloudFront is configured
		baseURL = fmt.Sprintf("https://%s.s3.%s.amazonaws.com", bucket, region)
	}

	fmt.Printf("S3 Service initialized: bucket=%s, region=%s, baseURL=%s\n", bucket, region, baseURL)

	return &S3Service{
		client:    client,
		bucket:    bucket,
		region:    region,
		baseURL:   baseURL,
		isEnabled: true,
	}, nil
}

// IsEnabled returns whether S3 is configured and enabled
func (s *S3Service) IsEnabled() bool {
	return s.isEnabled
}

// GetBaseURL returns the base URL for accessing S3 files
func (s *S3Service) GetBaseURL() string {
	return s.baseURL
}

// UploadFile uploads a multipart file to S3 and returns the URL
func (s *S3Service) UploadFile(ctx context.Context, file *multipart.FileHeader, folder string) (string, error) {
	if !s.isEnabled {
		return "", fmt.Errorf("S3 is not enabled")
	}

	// Open the file
	src, err := file.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open file: %w", err)
	}
	defer src.Close()

	// Read file content
	fileBytes, err := io.ReadAll(src)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	// Generate unique filename
	ext := strings.ToLower(filepath.Ext(file.Filename))
	filename := fmt.Sprintf("%s/%s_%d%s", folder, uuid.New().String(), time.Now().Unix(), ext)

	// Determine content type
	contentType := getContentType(ext)

	// Upload to S3
	_, err = s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(filename),
		Body:        bytes.NewReader(fileBytes),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload to S3: %w", err)
	}

	// Return the full URL
	url := fmt.Sprintf("%s/%s", s.baseURL, filename)
	return url, nil
}

// UploadBytes uploads raw bytes to S3 and returns the URL
func (s *S3Service) UploadBytes(ctx context.Context, data []byte, filename string, folder string) (string, error) {
	if !s.isEnabled {
		return "", fmt.Errorf("S3 is not enabled")
	}

	// Generate unique filename
	ext := strings.ToLower(filepath.Ext(filename))
	if ext == "" {
		ext = ".jpg"
	}
	key := fmt.Sprintf("%s/%s_%d%s", folder, uuid.New().String(), time.Now().Unix(), ext)

	// Determine content type
	contentType := getContentType(ext)

	// Upload to S3
	_, err := s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(key),
		Body:        bytes.NewReader(data),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload to S3: %w", err)
	}

	// Return the full URL
	url := fmt.Sprintf("%s/%s", s.baseURL, key)
	return url, nil
}

// UploadBase64 uploads a base64 encoded image to S3 and returns the URL
func (s *S3Service) UploadBase64(ctx context.Context, base64Data string, folder string) (string, error) {
	if !s.isEnabled {
		return "", fmt.Errorf("S3 is not enabled")
	}

	// Remove data URL prefix if present
	imageData := base64Data
	ext := ".jpg"
	if strings.Contains(imageData, ",") {
		parts := strings.SplitN(imageData, ",", 2)
		if len(parts) == 2 {
			// Extract extension from MIME type
			if strings.Contains(parts[0], "png") {
				ext = ".png"
			} else if strings.Contains(parts[0], "gif") {
				ext = ".gif"
			} else if strings.Contains(parts[0], "webp") {
				ext = ".webp"
			}
			imageData = parts[1]
		}
	}

	// Decode base64
	decoded, err := decodeBase64(imageData)
	if err != nil {
		return "", fmt.Errorf("failed to decode base64: %w", err)
	}

	return s.UploadBytes(ctx, decoded, "image"+ext, folder)
}

// DeleteFile deletes a file from S3 by its key
func (s *S3Service) DeleteFile(ctx context.Context, key string) error {
	if !s.isEnabled {
		return fmt.Errorf("S3 is not enabled")
	}

	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("failed to delete from S3: %w", err)
	}

	return nil
}

// DeleteByURL deletes a file from S3 using its full URL
func (s *S3Service) DeleteByURL(ctx context.Context, url string) error {
	if !s.isEnabled {
		return fmt.Errorf("S3 is not enabled")
	}

	// Extract key from URL
	key := strings.TrimPrefix(url, s.baseURL+"/")
	if key == url {
		// URL didn't match baseURL, try to extract from S3 URL pattern
		parts := strings.SplitN(url, ".amazonaws.com/", 2)
		if len(parts) == 2 {
			key = parts[1]
		} else {
			return fmt.Errorf("could not extract key from URL: %s", url)
		}
	}

	return s.DeleteFile(ctx, key)
}

// GeneratePresignedURL generates a presigned URL for temporary access
func (s *S3Service) GeneratePresignedURL(ctx context.Context, key string, expiration time.Duration) (string, error) {
	if !s.isEnabled {
		return "", fmt.Errorf("S3 is not enabled")
	}

	presignClient := s3.NewPresignClient(s.client)

	request, err := presignClient.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	}, s3.WithPresignExpires(expiration))
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return request.URL, nil
}

// Helper function to determine content type from file extension
func getContentType(ext string) string {
	contentTypes := map[string]string{
		".jpg":  "image/jpeg",
		".jpeg": "image/jpeg",
		".png":  "image/png",
		".gif":  "image/gif",
		".webp": "image/webp",
		".svg":  "image/svg+xml",
		".pdf":  "application/pdf",
	}

	if ct, ok := contentTypes[ext]; ok {
		return ct
	}
	return "application/octet-stream"
}

// Helper function to decode base64
func decodeBase64(data string) ([]byte, error) {
	return base64.StdEncoding.DecodeString(data)
}
