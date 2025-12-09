package handlers

import (
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UploadHandler struct {
	uploadDir  string
	baseURL    string
	s3Service  *services.S3Service
}

func NewUploadHandler(s3Service *services.S3Service) *UploadHandler {
	// Create uploads directory if it doesn't exist (fallback for local storage)
	uploadDir := "./uploads"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		fmt.Printf("Failed to create upload directory: %v\n", err)
	}

	// Get base URL from environment or use default
	baseURL := os.Getenv("BASE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:8080"
	}

	return &UploadHandler{
		uploadDir:  uploadDir,
		baseURL:    baseURL,
		s3Service:  s3Service,
	}
}

// UploadImage handles multipart file uploads
func (h *UploadHandler) UploadImage(c *gin.Context) {
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "No image file provided",
		})
		return
	}

	// Validate file type
	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowedExts := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".gif": true, ".webp": true}
	if !allowedExts[ext] {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid file type. Allowed: jpg, jpeg, png, gif, webp",
		})
		return
	}

	// Determine folder from query param (default: products)
	folder := c.DefaultQuery("folder", "products")

	// Try S3 upload first if enabled
	if h.s3Service != nil && h.s3Service.IsEnabled() {
		imageURL, err := h.s3Service.UploadFile(c.Request.Context(), file, folder)
		if err != nil {
			fmt.Printf("S3 upload failed, falling back to local: %v\n", err)
			// Fall through to local upload
		} else {
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"data": gin.H{
					"url":      imageURL,
					"imageUrl": imageURL,
					"filename": filepath.Base(imageURL),
					"storage":  "s3",
				},
			})
			return
		}
	}

	// Fallback to local storage
	filename := fmt.Sprintf("%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)
	savePath := filepath.Join(h.uploadDir, filename)

	// Save file locally
	if err := c.SaveUploadedFile(file, savePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to save image",
		})
		return
	}

	// Generate URL
	imageURL := fmt.Sprintf("%s/uploads/%s", h.baseURL, filename)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"url":      imageURL,
			"imageUrl": imageURL,
			"filename": filename,
			"storage":  "local",
		},
	})
}

// UploadImageBase64 handles base64 encoded image uploads
func (h *UploadHandler) UploadImageBase64(c *gin.Context) {
	var req struct {
		Image    string `json:"image"`
		Filename string `json:"filename"`
		Folder   string `json:"folder"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
		})
		return
	}

	if req.Image == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "No image data provided",
		})
		return
	}

	// Default folder
	if req.Folder == "" {
		req.Folder = "products"
	}

	// Try S3 upload first if enabled
	if h.s3Service != nil && h.s3Service.IsEnabled() {
		imageURL, err := h.s3Service.UploadBase64(c.Request.Context(), req.Image, req.Folder)
		if err != nil {
			fmt.Printf("S3 base64 upload failed, falling back to local: %v\n", err)
			// Fall through to local upload
		} else {
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"data": gin.H{
					"url":      imageURL,
					"imageUrl": imageURL,
					"filename": filepath.Base(imageURL),
					"storage":  "s3",
				},
			})
			return
		}
	}

	// Fallback to local storage
	// Remove data URL prefix if present
	imageData := req.Image
	if strings.Contains(imageData, ",") {
		parts := strings.SplitN(imageData, ",", 2)
		if len(parts) == 2 {
			imageData = parts[1]
		}
	}

	// Decode base64
	decoded, err := base64.StdEncoding.DecodeString(imageData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid base64 image data",
		})
		return
	}

	// Determine file extension
	ext := ".jpg"
	if req.Filename != "" {
		ext = strings.ToLower(filepath.Ext(req.Filename))
		if ext == "" {
			ext = ".jpg"
		}
	}

	// Validate extension
	allowedExts := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".gif": true, ".webp": true}
	if !allowedExts[ext] {
		ext = ".jpg"
	}

	// Generate unique filename
	filename := fmt.Sprintf("%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)
	savePath := filepath.Join(h.uploadDir, filename)

	// Write file
	if err := os.WriteFile(savePath, decoded, 0644); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to save image",
		})
		return
	}

	// Generate URL
	imageURL := fmt.Sprintf("%s/uploads/%s", h.baseURL, filename)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"url":      imageURL,
			"imageUrl": imageURL,
			"filename": filename,
			"storage":  "local",
		},
	})
}

// UploadAIImage handles AI-generated image uploads (specifically for AI module)
func (h *UploadHandler) UploadAIImage(c *gin.Context) {
	var req struct {
		Image  string `json:"image" binding:"required"`
		Prompt string `json:"prompt"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
		})
		return
	}

	// Always use "ai-generated" folder for AI images
	folder := "ai-generated"

	// Try S3 upload first if enabled
	if h.s3Service != nil && h.s3Service.IsEnabled() {
		imageURL, err := h.s3Service.UploadBase64(c.Request.Context(), req.Image, folder)
		if err != nil {
			fmt.Printf("S3 AI image upload failed, falling back to local: %v\n", err)
			// Fall through to local upload
		} else {
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"data": gin.H{
					"url":      imageURL,
					"imageUrl": imageURL,
					"filename": filepath.Base(imageURL),
					"storage":  "s3",
				},
			})
			return
		}
	}

	// Fallback to local storage
	imageData := req.Image
	if strings.Contains(imageData, ",") {
		parts := strings.SplitN(imageData, ",", 2)
		if len(parts) == 2 {
			imageData = parts[1]
		}
	}

	decoded, err := base64.StdEncoding.DecodeString(imageData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid base64 image data",
		})
		return
	}

	// Create ai-generated subdirectory
	aiDir := filepath.Join(h.uploadDir, "ai-generated")
	if err := os.MkdirAll(aiDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to create directory",
		})
		return
	}

	filename := fmt.Sprintf("%s_%d.png", uuid.New().String(), time.Now().Unix())
	savePath := filepath.Join(aiDir, filename)

	if err := os.WriteFile(savePath, decoded, 0644); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to save image",
		})
		return
	}

	imageURL := fmt.Sprintf("%s/uploads/ai-generated/%s", h.baseURL, filename)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"url":      imageURL,
			"imageUrl": imageURL,
			"filename": filename,
			"storage":  "local",
		},
	})
}

// DeleteImage handles image deletion
func (h *UploadHandler) DeleteImage(c *gin.Context) {
	var req struct {
		URL string `json:"url" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
		})
		return
	}

	// Check if it's an S3 URL
	if h.s3Service != nil && h.s3Service.IsEnabled() && strings.Contains(req.URL, h.s3Service.GetBaseURL()) {
		if err := h.s3Service.DeleteByURL(c.Request.Context(), req.URL); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   fmt.Sprintf("Failed to delete from S3: %v", err),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Image deleted from S3",
		})
		return
	}

	// Handle local file deletion
	// Extract filename from URL
	parts := strings.Split(req.URL, "/uploads/")
	if len(parts) != 2 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid image URL",
		})
		return
	}

	filename := parts[1]
	filePath := filepath.Join(h.uploadDir, filename)

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Image not found",
		})
		return
	}

	// Delete file
	if err := os.Remove(filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to delete image",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Image deleted successfully",
	})
}
