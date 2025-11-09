package services

import (
	"context"
	"errors"
	"time"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type CommunityService struct {
	communityRepo repository.CommunityRepository
	userRepo      repository.UserRepository
}

func NewCommunityService(communityRepo repository.CommunityRepository, userRepo repository.UserRepository) *CommunityService {
	return &CommunityService{
		communityRepo: communityRepo,
		userRepo:      userRepo,
	}
}

// CreatePost creates a new community post
func (s *CommunityService) CreatePost(ctx context.Context, req *models.CreatePostRequest, userID primitive.ObjectID, isAdmin bool) (*models.CommunityPost, error) {
	// Get user info
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	post := &models.CommunityPost{
		UserID:      userID,
		UserName:    user.Name,
		UserAvatar:  user.ProfileImage,
		Content:     req.Content,
		Images:      req.Images,
		Videos:      req.Videos,
		Tags:        req.Tags,
		IsAdminPost: isAdmin,
		IsFeatured:  req.IsFeatured && isAdmin, // Only admins can feature posts
		IsPinned:    req.IsPinned && isAdmin,   // Only admins can pin posts
	}

	err = s.communityRepo.CreatePost(ctx, post)
	if err != nil {
		return nil, err
	}

	return post, nil
}

// GetPost retrieves a single post by ID
func (s *CommunityService) GetPost(ctx context.Context, postID primitive.ObjectID) (*models.CommunityPost, error) {
	return s.communityRepo.GetPostByID(ctx, postID)
}

// GetCommunityFeed retrieves the community feed with pagination
func (s *CommunityService) GetCommunityFeed(ctx context.Context, page, limit int, sortBy string) (*models.CommunityFeedResponse, error) {
	posts, total, err := s.communityRepo.GetAllPosts(ctx, page, limit, sortBy)
	if err != nil {
		return nil, err
	}

	totalPages := int(total) / limit
	if int(total)%limit > 0 {
		totalPages++
	}

	return &models.CommunityFeedResponse{
		Posts:      convertPostsToSlice(posts),
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: totalPages,
	}, nil
}

// GetUserPosts retrieves posts by a specific user
func (s *CommunityService) GetUserPosts(ctx context.Context, userID primitive.ObjectID, page, limit int) (*models.CommunityFeedResponse, error) {
	posts, total, err := s.communityRepo.GetPostsByUser(ctx, userID, page, limit)
	if err != nil {
		return nil, err
	}

	totalPages := int(total) / limit
	if int(total)%limit > 0 {
		totalPages++
	}

	return &models.CommunityFeedResponse{
		Posts:      convertPostsToSlice(posts),
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: totalPages,
	}, nil
}

// UpdatePost updates a community post
func (s *CommunityService) UpdatePost(ctx context.Context, postID, userID primitive.ObjectID, req *models.UpdatePostRequest, isAdmin bool) error {
	// Get existing post
	post, err := s.communityRepo.GetPostByID(ctx, postID)
	if err != nil {
		return err
	}

	// Check permission - only post owner or admin can update
	if post.UserID != userID && !isAdmin {
		return errors.New("unauthorized to update this post")
	}

	// Update fields
	if req.Content != nil {
		post.Content = *req.Content
	}
	if req.Images != nil {
		post.Images = req.Images
	}
	if req.Videos != nil {
		post.Videos = req.Videos
	}
	if req.Tags != nil {
		post.Tags = req.Tags
	}
	if req.IsFeatured != nil && isAdmin {
		post.IsFeatured = *req.IsFeatured
	}
	if req.IsPinned != nil && isAdmin {
		post.IsPinned = *req.IsPinned
	}

	return s.communityRepo.UpdatePost(ctx, postID, post)
}

// DeletePost deletes a community post
func (s *CommunityService) DeletePost(ctx context.Context, postID, userID primitive.ObjectID, isAdmin bool) error {
	// Get existing post
	post, err := s.communityRepo.GetPostByID(ctx, postID)
	if err != nil {
		return err
	}

	// Check permission - only post owner or admin can delete
	if post.UserID != userID && !isAdmin {
		return errors.New("unauthorized to delete this post")
	}

	return s.communityRepo.DeletePost(ctx, postID)
}

// LikePost toggles a like on a post
func (s *CommunityService) LikePost(ctx context.Context, postID, userID primitive.ObjectID, userName string) (bool, error) {
	// Check if already liked
	existingLike, err := s.communityRepo.GetLikeByUserAndPost(ctx, postID, userID)
	if err != nil && err != mongo.ErrNoDocuments {
		return false, err
	}

	if existingLike != nil {
		// Unlike - remove like
		err = s.communityRepo.DeleteLike(ctx, postID, userID)
		if err != nil {
			return false, err
		}
		// Decrement like count
		err = s.communityRepo.IncrementPostLikeCount(ctx, postID, -1)
		return false, err
	}

	// Like - add like
	like := &models.PostLike{
		PostID:   postID,
		UserID:   userID,
		UserName: userName,
	}
	err = s.communityRepo.CreateLike(ctx, like)
	if err != nil {
		return false, err
	}

	// Increment like count
	err = s.communityRepo.IncrementPostLikeCount(ctx, postID, 1)
	return true, err
}

// VotePost handles voting on a post
func (s *CommunityService) VotePost(ctx context.Context, postID, userID primitive.ObjectID, userName, voteType string) error {
	if voteType != "up" && voteType != "down" {
		return errors.New("invalid vote type")
	}

	// Check if already voted
	existingVote, err := s.communityRepo.GetVoteByUserAndPost(ctx, postID, userID)
	if err != nil && err != mongo.ErrNoDocuments {
		return err
	}

	if existingVote != nil {
		// If same vote type, remove vote
		if existingVote.VoteType == voteType {
			err = s.communityRepo.DeleteVote(ctx, postID, userID)
			if err != nil {
				return err
			}
			// Decrement vote count
			increment := -1
			if voteType == "down" {
				increment = 1
			}
			return s.communityRepo.IncrementPostVoteCount(ctx, postID, increment)
		}

		// Different vote type, update vote
		err = s.communityRepo.UpdateVote(ctx, postID, userID, voteType)
		if err != nil {
			return err
		}

		// Update vote count (change from +1 to -1 or vice versa = 2 points)
		increment := 2
		if voteType == "down" {
			increment = -2
		}
		return s.communityRepo.IncrementPostVoteCount(ctx, postID, increment)
	}

	// New vote
	vote := &models.PostVote{
		PostID:   postID,
		UserID:   userID,
		UserName: userName,
		VoteType: voteType,
	}
	err = s.communityRepo.CreateVote(ctx, vote)
	if err != nil {
		return err
	}

	// Increment vote count
	increment := 1
	if voteType == "down" {
		increment = -1
	}
	return s.communityRepo.IncrementPostVoteCount(ctx, postID, increment)
}

// CreateComment creates a comment on a post
func (s *CommunityService) CreateComment(ctx context.Context, req *models.CreateCommentRequest, userID primitive.ObjectID) (*models.PostComment, error) {
	// Get user info
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	comment := &models.PostComment{
		PostID:     req.PostID,
		UserID:     userID,
		UserName:   user.Name,
		UserAvatar: user.ProfileImage,
		Content:    req.Content,
	}

	err = s.communityRepo.CreateComment(ctx, comment)
	if err != nil {
		return nil, err
	}

	// Increment comment count
	err = s.communityRepo.IncrementPostCommentCount(ctx, req.PostID, 1)
	if err != nil {
		return nil, err
	}

	return comment, nil
}

// GetPostComments retrieves comments for a post
func (s *CommunityService) GetPostComments(ctx context.Context, postID primitive.ObjectID, page, limit int) ([]*models.PostComment, int64, error) {
	return s.communityRepo.GetCommentsByPost(ctx, postID, page, limit)
}

// LinkInstagram links Instagram profile to user
func (s *CommunityService) LinkInstagram(ctx context.Context, req *models.LinkInstagramRequest, userID primitive.ObjectID) (*models.InstagramProfile, error) {
	// Check if already linked
	existing, err := s.communityRepo.GetInstagramProfile(ctx, userID)
	if err == nil && existing != nil {
		// Update existing profile
		existing.InstagramID = req.InstagramID
		existing.Username = req.Username
		existing.DisplayName = req.DisplayName
		existing.ProfilePicURL = req.ProfilePicURL
		existing.Bio = req.Bio

		err = s.communityRepo.UpdateInstagramProfile(ctx, userID, existing)
		return existing, err
	}

	// Create new profile
	profile := &models.InstagramProfile{
		UserID:        userID,
		InstagramID:   req.InstagramID,
		Username:      req.Username,
		DisplayName:   req.DisplayName,
		ProfilePicURL: req.ProfilePicURL,
		Bio:           req.Bio,
	}

	err = s.communityRepo.LinkInstagram(ctx, profile)
	if err != nil {
		return nil, err
	}

	return profile, nil
}

// GetInstagramProfile retrieves Instagram profile
func (s *CommunityService) GetInstagramProfile(ctx context.Context, userID primitive.ObjectID) (*models.InstagramProfile, error) {
	return s.communityRepo.GetInstagramProfile(ctx, userID)
}

// UnlinkInstagram unlinks Instagram profile
func (s *CommunityService) UnlinkInstagram(ctx context.Context, userID primitive.ObjectID) error {
	return s.communityRepo.UnlinkInstagram(ctx, userID)
}

// GetPostEngagement retrieves engagement stats for a post
func (s *CommunityService) GetPostEngagement(ctx context.Context, postID, userID primitive.ObjectID) (*models.PostEngagement, error) {
	post, err := s.communityRepo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, err
	}

	engagement := &models.PostEngagement{
		PostID:       postID,
		LikeCount:    post.LikeCount,
		VoteCount:    post.VoteCount,
		CommentCount: post.CommentCount,
		UserLiked:    false,
		UserVoted:    "",
	}

	// Check if user liked
	like, _ := s.communityRepo.GetLikeByUserAndPost(ctx, postID, userID)
	if like != nil {
		engagement.UserLiked = true
	}

	// Check if user voted
	vote, _ := s.communityRepo.GetVoteByUserAndPost(ctx, postID, userID)
	if vote != nil {
		engagement.UserVoted = vote.VoteType
	}

	return engagement, nil
}

// ToggleFeaturePost toggles the featured status of a post (admin only)
func (s *CommunityService) ToggleFeaturePost(ctx context.Context, postID, adminID primitive.ObjectID) error {
	// Check if user is admin
	user, err := s.userRepo.GetByID(ctx, adminID)
	if err != nil || !user.IsAdmin {
		return errors.New("unauthorized")
	}

	// Get current post
	post, err := s.communityRepo.GetPostByID(ctx, postID)
	if err != nil {
		return err
	}

	// Toggle featured status
	post.IsFeatured = !post.IsFeatured
	post.UpdatedAt = time.Now()

	return s.communityRepo.UpdatePost(ctx, postID, post)
}

// TogglePinPost toggles the pinned status of a post (admin only)
func (s *CommunityService) TogglePinPost(ctx context.Context, postID, adminID primitive.ObjectID) error {
	// Check if user is admin
	user, err := s.userRepo.GetByID(ctx, adminID)
	if err != nil || !user.IsAdmin {
		return errors.New("unauthorized")
	}

	// Get current post
	post, err := s.communityRepo.GetPostByID(ctx, postID)
	if err != nil {
		return err
	}

	// Toggle pinned status
	post.IsPinned = !post.IsPinned
	post.UpdatedAt = time.Now()

	return s.communityRepo.UpdatePost(ctx, postID, post)
}

// Helper function to convert []*Post to []Post
func convertPostsToSlice(posts []*models.CommunityPost) []models.CommunityPost {
	result := make([]models.CommunityPost, len(posts))
	for i, post := range posts {
		if post != nil {
			result[i] = *post
		}
	}
	return result
}
