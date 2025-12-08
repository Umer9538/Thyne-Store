package repository

import (
	"context"
	"thyne-jewels-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CommunityRepository defines the interface for community data operations
type CommunityRepository interface {
	// Post operations
	CreatePost(ctx context.Context, post *models.CommunityPost) error
	GetPostByID(ctx context.Context, id primitive.ObjectID) (*models.CommunityPost, error)
	GetAllPosts(ctx context.Context, page, limit int, sortBy string) ([]*models.CommunityPost, int64, error)
	GetPostsByUser(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]*models.CommunityPost, int64, error)
	GetFeaturedPosts(ctx context.Context, limit int) ([]*models.CommunityPost, error)
	UpdatePost(ctx context.Context, id primitive.ObjectID, post *models.CommunityPost) error
	DeletePost(ctx context.Context, id primitive.ObjectID) error
	IncrementPostLikeCount(ctx context.Context, postID primitive.ObjectID, increment int) error
	IncrementPostVoteCount(ctx context.Context, postID primitive.ObjectID, increment int) error
	IncrementPostCommentCount(ctx context.Context, postID primitive.ObjectID, increment int) error

	// Moderation operations
	GetPostsByModerationStatus(ctx context.Context, status models.ModerationStatus, page, limit int) ([]*models.CommunityPost, int64, error)
	CountPostsByModerationStatus(ctx context.Context, status models.ModerationStatus) (int64, error)

	// Like operations
	CreateLike(ctx context.Context, like *models.PostLike) error
	DeleteLike(ctx context.Context, postID, userID primitive.ObjectID) error
	GetLikeByUserAndPost(ctx context.Context, postID, userID primitive.ObjectID) (*models.PostLike, error)
	GetPostLikes(ctx context.Context, postID primitive.ObjectID) ([]*models.PostLike, error)

	// Vote operations
	CreateVote(ctx context.Context, vote *models.PostVote) error
	UpdateVote(ctx context.Context, postID, userID primitive.ObjectID, voteType string) error
	DeleteVote(ctx context.Context, postID, userID primitive.ObjectID) error
	GetVoteByUserAndPost(ctx context.Context, postID, userID primitive.ObjectID) (*models.PostVote, error)

	// Comment operations
	CreateComment(ctx context.Context, comment *models.PostComment) error
	GetCommentsByPost(ctx context.Context, postID primitive.ObjectID, page, limit int) ([]*models.PostComment, int64, error)
	DeleteComment(ctx context.Context, id primitive.ObjectID) error

	// Instagram operations
	LinkInstagram(ctx context.Context, profile *models.InstagramProfile) error
	GetInstagramProfile(ctx context.Context, userID primitive.ObjectID) (*models.InstagramProfile, error)
	UpdateInstagramProfile(ctx context.Context, userID primitive.ObjectID, profile *models.InstagramProfile) error
	UnlinkInstagram(ctx context.Context, userID primitive.ObjectID) error
}
