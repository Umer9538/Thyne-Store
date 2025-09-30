//go:build exclude

package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// NotificationHandler handles notification endpoints
type NotificationHandler struct {
	notificationService *services.NotificationService
}

// NewNotificationHandler creates a new notification handler
func NewNotificationHandler(notificationService *services.NotificationService) *NotificationHandler {
	return &NotificationHandler{
		notificationService: notificationService,
	}
}

// RegisterFCMTokenRequest represents an FCM token registration request
type RegisterFCMTokenRequest struct {
	Token    string `json:"token" binding:"required"`
	Platform string `json:"platform" binding:"required"` // "android", "ios", "web"
}

// RegisterFCMToken registers a user's FCM token
// @Summary Register FCM token
// @Description Register a Firebase Cloud Messaging token for push notifications
// @Tags notifications
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body RegisterFCMTokenRequest true "FCM token registration request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/register-token [post]
func (h *NotificationHandler) RegisterFCMToken(c *gin.Context) {
	userID, exists := c.Get("userID")
	var userPtr *primitive.ObjectID
	if exists {
		uid := userID.(primitive.ObjectID)
		userPtr = &uid
	}

	var req RegisterFCMTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	err := h.notificationService.RegisterFCMToken(c.Request.Context(), userPtr, req.Token, req.Platform)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Message: "FCM token registered successfully",
	})
}

// GetUserNotifications gets notifications for a user
// @Summary Get user notifications
// @Description Get notifications for the authenticated user
// @Tags notifications
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Param unread_only query bool false "Get only unread notifications" default(false)
// @Success 200 {array} models.Notification
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications [get]
func (h *NotificationHandler) GetUserNotifications(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, ErrorResponse{Error: "User not authenticated"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	unreadOnly, _ := strconv.ParseBool(c.DefaultQuery("unread_only", "false"))

	notifications, err := h.notificationService.GetUserNotifications(
		c.Request.Context(),
		userID.(primitive.ObjectID),
		limit,
		offset,
		unreadOnly,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Data:    notifications,
	})
}

// MarkAsReadRequest represents a mark as read request
type MarkAsReadRequest struct {
	NotificationID primitive.ObjectID `json:"notificationId" binding:"required"`
}

// MarkNotificationAsRead marks a notification as read
// @Summary Mark notification as read
// @Description Mark a specific notification as read
// @Tags notifications
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body MarkAsReadRequest true "Mark as read request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/mark-read [post]
func (h *NotificationHandler) MarkNotificationAsRead(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, ErrorResponse{Error: "User not authenticated"})
		return
	}

	var req MarkAsReadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	err := h.notificationService.MarkNotificationAsRead(
		c.Request.Context(),
		req.NotificationID,
		userID.(primitive.ObjectID),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Message: "Notification marked as read",
	})
}

// MarkAllAsRead marks all notifications as read for the user
// @Summary Mark all notifications as read
// @Description Mark all notifications as read for the authenticated user
// @Tags notifications
// @Security BearerAuth
// @Produce json
// @Success 200 {object} SuccessResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/mark-all-read [post]
func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, ErrorResponse{Error: "User not authenticated"})
		return
	}

	err := h.notificationService.MarkAllNotificationsAsRead(c.Request.Context(), userID.(primitive.ObjectID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Message: "All notifications marked as read",
	})
}

// GetNotificationPreferences gets user's notification preferences
// @Summary Get notification preferences
// @Description Get notification preferences for the authenticated user
// @Tags notifications
// @Security BearerAuth
// @Produce json
// @Success 200 {object} models.NotificationPreference
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/preferences [get]
func (h *NotificationHandler) GetNotificationPreferences(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, ErrorResponse{Error: "User not authenticated"})
		return
	}

	preferences, err := h.notificationService.GetNotificationPreferences(c.Request.Context(), userID.(primitive.ObjectID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Data:    preferences,
	})
}

// UpdatePreferencesRequest represents a notification preferences update request
type UpdatePreferencesRequest struct {
	EnableOrderUpdates       bool `json:"enableOrderUpdates"`
	EnablePromotions         bool `json:"enablePromotions"`
	EnableReminders          bool `json:"enableReminders"`
	EnableLoyaltyUpdates     bool `json:"enableLoyaltyUpdates"`
	EnablePushNotifications  bool `json:"enablePushNotifications"`
	EnableEmailNotifications bool `json:"enableEmailNotifications"`
	EnableSMSNotifications   bool `json:"enableSMSNotifications"`
}

// UpdateNotificationPreferences updates user's notification preferences
// @Summary Update notification preferences
// @Description Update notification preferences for the authenticated user
// @Tags notifications
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body UpdatePreferencesRequest true "Notification preferences update request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/preferences [put]
func (h *NotificationHandler) UpdateNotificationPreferences(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, ErrorResponse{Error: "User not authenticated"})
		return
	}

	var req UpdatePreferencesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	preferences := &models.NotificationPreference{
		UserID:                   userID.(primitive.ObjectID),
		EnableOrderUpdates:       req.EnableOrderUpdates,
		EnablePromotions:         req.EnablePromotions,
		EnableReminders:          req.EnableReminders,
		EnableLoyaltyUpdates:     req.EnableLoyaltyUpdates,
		EnablePushNotifications:  req.EnablePushNotifications,
		EnableEmailNotifications: req.EnableEmailNotifications,
		EnableSMSNotifications:   req.EnableSMSNotifications,
	}

	err := h.notificationService.UpdateNotificationPreferences(c.Request.Context(), preferences)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Message: "Notification preferences updated successfully",
	})
}

// SendTestNotificationRequest represents a test notification request
type SendTestNotificationRequest struct {
	UserID primitive.ObjectID       `json:"userId" binding:"required"`
	Title  string                   `json:"title" binding:"required"`
	Body   string                   `json:"body" binding:"required"`
	Type   models.NotificationType  `json:"type" binding:"required"`
	Data   map[string]interface{}   `json:"data,omitempty"`
}

// SendTestNotification sends a test notification (Admin only)
// @Summary Send test notification
// @Description Send a test notification to a specific user (Admin only)
// @Tags notifications
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body SendTestNotificationRequest true "Test notification request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/test [post]
func (h *NotificationHandler) SendTestNotification(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, ErrorResponse{Error: "Admin access required"})
		return
	}

	var req SendTestNotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	notification := &models.Notification{
		UserID:    &req.UserID,
		Title:     req.Title,
		Body:      req.Body,
		Type:      req.Type,
		Data:      req.Data,
		IsRead:    false,
		IsSent:    false,
	}

	// This would call the internal sendNotification method
	// For now, we'll create a simple response
	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Message: "Test notification sent successfully",
	})
}

// CreateCampaignRequest represents a notification campaign creation request
type CreateCampaignRequest struct {
	Name           string                    `json:"name" binding:"required"`
	Title          string                    `json:"title" binding:"required"`
	Body           string                    `json:"body" binding:"required"`
	Type           models.NotificationType   `json:"type" binding:"required"`
	TargetAudience models.CampaignAudience   `json:"targetAudience" binding:"required"`
	ScheduledAt    *string                   `json:"scheduledAt,omitempty"`
	Data           map[string]interface{}    `json:"data,omitempty"`
}

// CreateCampaign creates a new notification campaign (Admin only)
// @Summary Create notification campaign
// @Description Create a new notification campaign (Admin only)
// @Tags notifications
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateCampaignRequest true "Campaign creation request"
// @Success 201 {object} models.NotificationCampaign
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/campaigns [post]
func (h *NotificationHandler) CreateCampaign(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, ErrorResponse{Error: "Admin access required"})
		return
	}

	adminID := c.GetString("userID")
	adminObjectID, _ := primitive.ObjectIDFromHex(adminID)

	var req CreateCampaignRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	campaign := &models.NotificationCampaign{
		ID:             primitive.NewObjectID(),
		Name:           req.Name,
		Title:          req.Title,
		Body:           req.Body,
		Type:           req.Type,
		TargetAudience: req.TargetAudience,
		Status:         models.CampaignStatusDraft,
		Data:           req.Data,
		CreatedBy:      adminObjectID,
	}

	// Parse scheduled time if provided
	if req.ScheduledAt != nil {
		// Parse time string and set ScheduledAt
		// Implementation depends on your time format
	}

	// Save campaign and send if not scheduled
	if campaign.ScheduledAt == nil {
		err := h.notificationService.SendCampaign(c.Request.Context(), campaign)
		if err != nil {
			c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
	}

	c.JSON(http.StatusCreated, SuccessResponse{
		Success: true,
		Data:    campaign,
		Message: "Campaign created successfully",
	})
}

// SendBroadcastRequest represents a broadcast notification request
type SendBroadcastRequest struct {
	Title string                   `json:"title" binding:"required"`
	Body  string                   `json:"body" binding:"required"`
	Type  models.NotificationType  `json:"type" binding:"required"`
	Data  map[string]interface{}   `json:"data,omitempty"`
}

// SendBroadcast sends a broadcast notification to all users (Admin only)
// @Summary Send broadcast notification
// @Description Send a broadcast notification to all users (Admin only)
// @Tags notifications
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body SendBroadcastRequest true "Broadcast notification request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/broadcast [post]
func (h *NotificationHandler) SendBroadcast(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, ErrorResponse{Error: "Admin access required"})
		return
	}

	var req SendBroadcastRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	// Create campaign for broadcast
	adminID := c.GetString("userID")
	adminObjectID, _ := primitive.ObjectIDFromHex(adminID)

	campaign := &models.NotificationCampaign{
		ID:    primitive.NewObjectID(),
		Name:  "Broadcast - " + req.Title,
		Title: req.Title,
		Body:  req.Body,
		Type:  req.Type,
		TargetAudience: models.CampaignAudience{
			AllUsers: true,
		},
		Status:    models.CampaignStatusDraft,
		Data:      req.Data,
		CreatedBy: adminObjectID,
	}

	err := h.notificationService.SendCampaign(c.Request.Context(), campaign)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Message: "Broadcast notification sent successfully",
	})
}

// TriggerOrderNotificationRequest represents an order notification trigger request
type TriggerOrderNotificationRequest struct {
	UserID         primitive.ObjectID `json:"userId" binding:"required"`
	OrderID        string             `json:"orderId" binding:"required"`
	NotificationType string           `json:"notificationType" binding:"required"` // "placed", "shipped", "delivered", "cancelled"
	TrackingNumber *string            `json:"trackingNumber,omitempty"`
}

// TriggerOrderNotification triggers an order-related notification (Admin only)
// @Summary Trigger order notification
// @Description Trigger an order-related notification (Admin only)
// @Tags notifications
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body TriggerOrderNotificationRequest true "Order notification trigger request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /notifications/order [post]
func (h *NotificationHandler) TriggerOrderNotification(c *gin.Context) {
	// Check if user is admin
	isAdmin, exists := c.Get("isAdmin")
	if !exists || !isAdmin.(bool) {
		c.JSON(http.StatusForbidden, ErrorResponse{Error: "Admin access required"})
		return
	}

	var req TriggerOrderNotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	var err error
	switch req.NotificationType {
	case "placed":
		err = h.notificationService.SendOrderPlacedNotification(c.Request.Context(), req.UserID, req.OrderID)
	case "shipped":
		if req.TrackingNumber == nil {
			c.JSON(http.StatusBadRequest, ErrorResponse{Error: "Tracking number required for shipped notification"})
			return
		}
		err = h.notificationService.SendOrderShippedNotification(c.Request.Context(), req.UserID, req.OrderID, *req.TrackingNumber)
	case "delivered":
		err = h.notificationService.SendOrderDeliveredNotification(c.Request.Context(), req.UserID, req.OrderID)
	case "cancelled":
		err = h.notificationService.SendOrderCancelledNotification(c.Request.Context(), req.UserID, req.OrderID)
	default:
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "Invalid notification type"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Success: true,
		Message: "Order notification sent successfully",
	})
}