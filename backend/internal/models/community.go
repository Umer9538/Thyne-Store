package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ModerationStatus represents the moderation state of a community post
type ModerationStatus string

const (
	ModerationStatusPending  ModerationStatus = "pending"
	ModerationStatusApproved ModerationStatus = "approved"
	ModerationStatusRejected ModerationStatus = "rejected"
)

// PostTagSource indicates where the tagged product came from
type PostTagSource string

const (
	PostTagSourceProduct PostTagSource = "product" // Direct product selection from catalog
	PostTagSourceOrder   PostTagSource = "order"   // Product selected from user's order history
)

// ProductCustomizationTag represents customization options selected for a tagged product
type ProductCustomizationTag struct {
	SelectedMetal   string            `json:"selectedMetal,omitempty" bson:"selectedMetal,omitempty"`
	SelectedPlating string            `json:"selectedPlating,omitempty" bson:"selectedPlating,omitempty"`
	StoneColors     map[string]string `json:"stoneColors,omitempty" bson:"stoneColors,omitempty"`
	SelectedSize    string            `json:"selectedSize,omitempty" bson:"selectedSize,omitempty"`
	EngravingText   string            `json:"engravingText,omitempty" bson:"engravingText,omitempty"`
	Thickness       *float64          `json:"thickness,omitempty" bson:"thickness,omitempty"`
}

// ProductTag represents a product tagged in a community post
type ProductTag struct {
	ID            string                   `json:"id" bson:"id"`
	Name          string                   `json:"name" bson:"name"`
	Price         float64                  `json:"price" bson:"price"`
	ImageURL      string                   `json:"imageUrl" bson:"imageUrl"`
	Customization *ProductCustomizationTag `json:"customization,omitempty" bson:"customization,omitempty"`
	OrderID       string                   `json:"orderId,omitempty" bson:"orderId,omitempty"`
	OrderNumber   string                   `json:"orderNumber,omitempty" bson:"orderNumber,omitempty"`
}

// OrderTag represents an order tagged in a community post
type OrderTag struct {
	OrderID     string       `json:"orderId" bson:"orderId"`
	OrderNumber string       `json:"orderNumber" bson:"orderNumber"`
	OrderDate   time.Time    `json:"orderDate" bson:"orderDate"`
	OrderTotal  float64      `json:"orderTotal" bson:"orderTotal"`
	Products    []ProductTag `json:"products" bson:"products"`
}

// CommunityPost represents a post in the community section
type CommunityPost struct {
	ID               primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID           primitive.ObjectID `json:"userId" bson:"userId" validate:"required"`
	UserName         string             `json:"userName" bson:"userName"`
	UserAvatar       string             `json:"userAvatar,omitempty" bson:"userAvatar,omitempty"`
	Content          string             `json:"content" bson:"content" validate:"required,min=1,max=5000"`
	Images           []string           `json:"images,omitempty" bson:"images,omitempty"`
	Videos           []string           `json:"videos,omitempty" bson:"videos,omitempty"`
	LikeCount        int                `json:"likeCount" bson:"likeCount"`
	VoteCount        int                `json:"voteCount" bson:"voteCount"`
	CommentCount     int                `json:"commentCount" bson:"commentCount"`
	Tags             []string           `json:"tags,omitempty" bson:"tags,omitempty"`
	// Product/Order tagging
	Products         []ProductTag       `json:"products,omitempty" bson:"products,omitempty"`
	Order            *OrderTag          `json:"order,omitempty" bson:"order,omitempty"`
	TagSource        PostTagSource      `json:"tagSource,omitempty" bson:"tagSource,omitempty"`
	IsAdminPost      bool               `json:"isAdminPost" bson:"isAdminPost"`
	IsFeatured       bool               `json:"isFeatured" bson:"isFeatured"`
	IsPinned         bool               `json:"isPinned" bson:"isPinned"`
	// Moderation fields
	ModerationStatus ModerationStatus   `json:"moderationStatus" bson:"moderationStatus"`
	RejectionReason  string             `json:"rejectionReason,omitempty" bson:"rejectionReason,omitempty"`
	ModeratedBy      primitive.ObjectID `json:"moderatedBy,omitempty" bson:"moderatedBy,omitempty"`
	ModeratedAt      *time.Time         `json:"moderatedAt,omitempty" bson:"moderatedAt,omitempty"`
	CreatedAt        time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt        time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// PostLike represents a like on a community post
type PostLike struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	PostID    primitive.ObjectID `json:"postId" bson:"postId" validate:"required"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId" validate:"required"`
	UserName  string            `json:"userName" bson:"userName"`
	CreatedAt time.Time         `json:"createdAt" bson:"createdAt"`
}

// PostVote represents a vote on a community post
type PostVote struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	PostID    primitive.ObjectID `json:"postId" bson:"postId" validate:"required"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId" validate:"required"`
	UserName  string            `json:"userName" bson:"userName"`
	VoteType  string            `json:"voteType" bson:"voteType" validate:"required,oneof=up down"` // up or down
	CreatedAt time.Time         `json:"createdAt" bson:"createdAt"`
}

// PostComment represents a comment on a community post
type PostComment struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	PostID    primitive.ObjectID `json:"postId" bson:"postId" validate:"required"`
	UserID    primitive.ObjectID `json:"userId" bson:"userId" validate:"required"`
	UserName  string            `json:"userName" bson:"userName"`
	UserAvatar string           `json:"userAvatar,omitempty" bson:"userAvatar,omitempty"`
	Content   string            `json:"content" bson:"content" validate:"required,min=1,max=1000"`
	LikeCount int               `json:"likeCount" bson:"likeCount"`
	CreatedAt time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// InstagramProfile represents a user's Instagram integration
type InstagramProfile struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID        primitive.ObjectID `json:"userId" bson:"userId" validate:"required"`
	InstagramID   string            `json:"instagramId" bson:"instagramId" validate:"required"`
	Username      string            `json:"username" bson:"username" validate:"required"`
	DisplayName   string            `json:"displayName,omitempty" bson:"displayName,omitempty"`
	ProfilePicURL string            `json:"profilePicUrl,omitempty" bson:"profilePicUrl,omitempty"`
	Bio           string            `json:"bio,omitempty" bson:"bio,omitempty"`
	FollowerCount int               `json:"followerCount,omitempty" bson:"followerCount,omitempty"`
	FollowingCount int              `json:"followingCount,omitempty" bson:"followingCount,omitempty"`
	PostCount     int               `json:"postCount,omitempty" bson:"postCount,omitempty"`
	IsVerified    bool              `json:"isVerified" bson:"isVerified"`
	IsActive      bool              `json:"isActive" bson:"isActive"`
	LinkedAt      time.Time         `json:"linkedAt" bson:"linkedAt"`
	UpdatedAt     time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// CreatePostRequest represents the request to create a community post
type CreatePostRequest struct {
	Content    string        `json:"content" validate:"required,min=1,max=5000"`
	Images     []string      `json:"images,omitempty"`
	Videos     []string      `json:"videos,omitempty"`
	Tags       []string      `json:"tags,omitempty"`
	Products   []ProductTag  `json:"products,omitempty"`   // Tagged products
	Order      *OrderTag     `json:"order,omitempty"`      // Tagged order
	TagSource  PostTagSource `json:"tagSource,omitempty"`  // Source of tagged item
	IsFeatured bool          `json:"isFeatured,omitempty"`
	IsPinned   bool          `json:"isPinned,omitempty"`
}

// UpdatePostRequest represents the request to update a community post
type UpdatePostRequest struct {
	Content    *string  `json:"content,omitempty" validate:"omitempty,min=1,max=5000"`
	Images     []string `json:"images,omitempty"`
	Videos     []string `json:"videos,omitempty"`
	Tags       []string `json:"tags,omitempty"`
	IsFeatured *bool    `json:"isFeatured,omitempty"`
	IsPinned   *bool    `json:"isPinned,omitempty"`
}

// CreateCommentRequest represents the request to create a comment
type CreateCommentRequest struct {
	PostID  primitive.ObjectID `json:"postId" validate:"required"`
	Content string            `json:"content" validate:"required,min=1,max=1000"`
}

// LinkInstagramRequest represents the request to link Instagram profile
type LinkInstagramRequest struct {
	InstagramID   string `json:"instagramId" validate:"required"`
	Username      string `json:"username" validate:"required"`
	DisplayName   string `json:"displayName,omitempty"`
	ProfilePicURL string `json:"profilePicUrl,omitempty"`
	Bio           string `json:"bio,omitempty"`
}

// ModeratePostRequest represents the request to moderate a community post
type ModeratePostRequest struct {
	Action string `json:"action" validate:"required,oneof=approve reject"` // approve or reject
	Reason string `json:"reason,omitempty"`                                 // Required when rejecting
}

// CommunityFeedResponse represents the response for community feed
type CommunityFeedResponse struct {
	Posts      []CommunityPost `json:"posts"`
	Total      int64          `json:"total"`
	Page       int            `json:"page"`
	Limit      int            `json:"limit"`
	TotalPages int            `json:"totalPages"`
}

// PostEngagement represents engagement stats for a post
type PostEngagement struct {
	PostID       primitive.ObjectID `json:"postId"`
	LikeCount    int               `json:"likeCount"`
	VoteCount    int               `json:"voteCount"`
	CommentCount int               `json:"commentCount"`
	UserLiked    bool              `json:"userLiked"`
	UserVoted    string            `json:"userVoted,omitempty"` // "up", "down", or empty
}
