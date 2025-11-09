package handlers

import (
	"net/http"
	"strconv"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/services"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type CommunityHandler struct {
	communityService *services.CommunityService
}

func NewCommunityHandler(communityService *services.CommunityService) *CommunityHandler {
	return &CommunityHandler{
		communityService: communityService,
	}
}

// CreatePost creates a new community post
func (h *CommunityHandler) CreatePost(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Check if admin
	role, _ := c.Get("role")
	isAdmin := role == "admin"

	var req models.CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	post, err := h.communityService.CreatePost(c.Request.Context(), &req, userID, isAdmin)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    post,
	})
}

// GetPost retrieves a single post
func (h *CommunityHandler) GetPost(c *gin.Context) {
	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	post, err := h.communityService.GetPost(c.Request.Context(), postID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    post,
	})
}

// GetCommunityFeed retrieves the community feed
func (h *CommunityHandler) GetCommunityFeed(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	sortBy := c.DefaultQuery("sortBy", "latest") // latest, popular, trending

	feed, err := h.communityService.GetCommunityFeed(c.Request.Context(), page, limit, sortBy)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch feed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    feed,
	})
}

// GetUserPosts retrieves posts by a specific user
func (h *CommunityHandler) GetUserPosts(c *gin.Context) {
	userID, err := primitive.ObjectIDFromHex(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	feed, err := h.communityService.GetUserPosts(c.Request.Context(), userID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user posts"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    feed,
	})
}

// UpdatePost updates a community post
func (h *CommunityHandler) UpdatePost(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	// Check if admin
	role, _ := c.Get("role")
	isAdmin := role == "admin"

	var req models.UpdatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.communityService.UpdatePost(c.Request.Context(), postID, userID, &req, isAdmin)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post updated successfully",
	})
}

// DeletePost deletes a community post
func (h *CommunityHandler) DeletePost(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	// Check if admin
	role, _ := c.Get("role")
	isAdmin := role == "admin"

	err = h.communityService.DeletePost(c.Request.Context(), postID, userID, isAdmin)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post deleted successfully",
	})
}

// LikePost toggles a like on a post
func (h *CommunityHandler) LikePost(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userName, _ := c.Get("userName")
	liked, err := h.communityService.LikePost(c.Request.Context(), postID, userID, userName.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to like post"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"liked":   liked,
	})
}

// VotePost handles voting on a post
func (h *CommunityHandler) VotePost(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	var req struct {
		VoteType string `json:"voteType" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userName, _ := c.Get("userName")
	err = h.communityService.VotePost(c.Request.Context(), postID, userID, userName.(string), req.VoteType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Vote recorded successfully",
	})
}

// CreateComment creates a comment on a post
func (h *CommunityHandler) CreateComment(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var req models.CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	comment, err := h.communityService.CreateComment(c.Request.Context(), &req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create comment"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    comment,
	})
}

// GetPostComments retrieves comments for a post
func (h *CommunityHandler) GetPostComments(c *gin.Context) {
	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	comments, total, err := h.communityService.GetPostComments(c.Request.Context(), postID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch comments"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"comments": comments,
			"total":    total,
			"page":     page,
			"limit":    limit,
		},
	})
}

// LinkInstagram links Instagram profile
func (h *CommunityHandler) LinkInstagram(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var req models.LinkInstagramRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, err := h.communityService.LinkInstagram(c.Request.Context(), &req, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to link Instagram"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    profile,
	})
}

// GetInstagramProfile retrieves Instagram profile
func (h *CommunityHandler) GetInstagramProfile(c *gin.Context) {
	userID, err := primitive.ObjectIDFromHex(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	profile, err := h.communityService.GetInstagramProfile(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Instagram profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    profile,
	})
}

// UnlinkInstagram unlinks Instagram profile
func (h *CommunityHandler) UnlinkInstagram(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	err = h.communityService.UnlinkInstagram(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unlink Instagram"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Instagram unlinked successfully",
	})
}

// GetPostEngagement retrieves engagement stats for a post
func (h *CommunityHandler) GetPostEngagement(c *gin.Context) {
	userIDStr, _ := c.Get("userID")
	userID, _ := primitive.ObjectIDFromHex(userIDStr.(string))

	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	engagement, err := h.communityService.GetPostEngagement(c.Request.Context(), postID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch engagement"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    engagement,
	})
}

// ==================== Admin Endpoints ====================

// ToggleFeaturePost toggles the featured status of a post (admin only)
func (h *CommunityHandler) ToggleFeaturePost(c *gin.Context) {
	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userIDStr, _ := c.Get("userID")
	userID, _ := primitive.ObjectIDFromHex(userIDStr.(string))

	err = h.communityService.ToggleFeaturePost(c.Request.Context(), postID, userID)
	if err != nil {
		if err.Error() == "unauthorized" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to toggle feature status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Feature status toggled successfully",
	})
}

// TogglePinPost toggles the pinned status of a post (admin only)
func (h *CommunityHandler) TogglePinPost(c *gin.Context) {
	postID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userIDStr, _ := c.Get("userID")
	userID, _ := primitive.ObjectIDFromHex(userIDStr.(string))

	err = h.communityService.TogglePinPost(c.Request.Context(), postID, userID)
	if err != nil {
		if err.Error() == "unauthorized" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to toggle pin status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Pin status toggled successfully",
	})
}
