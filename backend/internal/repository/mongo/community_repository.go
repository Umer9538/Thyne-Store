package mongo

import (
	"context"
	"time"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type communityRepository struct {
	postsCollection     *mongo.Collection
	likesCollection     *mongo.Collection
	votesCollection     *mongo.Collection
	commentsCollection  *mongo.Collection
	instagramCollection *mongo.Collection
}

// NewCommunityRepository creates a new community repository
func NewCommunityRepository(db *mongo.Database) repository.CommunityRepository {
	return &communityRepository{
		postsCollection:     db.Collection("community_posts"),
		likesCollection:     db.Collection("post_likes"),
		votesCollection:     db.Collection("post_votes"),
		commentsCollection:  db.Collection("post_comments"),
		instagramCollection: db.Collection("instagram_profiles"),
	}
}

// CreatePost creates a new community post
func (r *communityRepository) CreatePost(ctx context.Context, post *models.CommunityPost) error {
	post.ID = primitive.NewObjectID()
	post.CreatedAt = time.Now()
	post.UpdatedAt = time.Now()
	post.LikeCount = 0
	post.VoteCount = 0
	post.CommentCount = 0

	_, err := r.postsCollection.InsertOne(ctx, post)
	return err
}

// GetPostByID retrieves a post by ID
func (r *communityRepository) GetPostByID(ctx context.Context, id primitive.ObjectID) (*models.CommunityPost, error) {
	var post models.CommunityPost
	err := r.postsCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&post)
	if err != nil {
		return nil, err
	}
	return &post, nil
}

// GetAllPosts retrieves all approved posts with pagination (public feed only shows approved posts)
func (r *communityRepository) GetAllPosts(ctx context.Context, page, limit int, sortBy string) ([]*models.CommunityPost, int64, error) {
	skip := (page - 1) * limit

	// Determine sort order
	sortField := "createdAt"
	sortOrder := -1 // descending by default

	switch sortBy {
	case "popular":
		sortField = "likeCount"
	case "trending":
		sortField = "voteCount"
	case "oldest":
		sortField = "createdAt"
		sortOrder = 1
	}

	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: sortField, Value: sortOrder}})

	// Only show approved posts in public feed (or posts without moderation status for backwards compatibility)
	filter := bson.M{
		"$or": []bson.M{
			{"moderationStatus": models.ModerationStatusApproved},
			{"moderationStatus": bson.M{"$exists": false}}, // Backwards compatibility for old posts
			{"moderationStatus": ""},                        // Empty string fallback
		},
	}

	cursor, err := r.postsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var posts []*models.CommunityPost
	if err = cursor.All(ctx, &posts); err != nil {
		return nil, 0, err
	}

	total, err := r.postsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	return posts, total, nil
}

// GetPostsByUser retrieves posts by a specific user
func (r *communityRepository) GetPostsByUser(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]*models.CommunityPost, int64, error) {
	skip := (page - 1) * limit

	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	filter := bson.M{"userId": userID}
	cursor, err := r.postsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var posts []*models.CommunityPost
	if err = cursor.All(ctx, &posts); err != nil {
		return nil, 0, err
	}

	total, err := r.postsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	return posts, total, nil
}

// GetFeaturedPosts retrieves featured posts
func (r *communityRepository) GetFeaturedPosts(ctx context.Context, limit int) ([]*models.CommunityPost, error) {
	opts := options.Find().
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	filter := bson.M{"isFeatured": true}
	cursor, err := r.postsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var posts []*models.CommunityPost
	if err = cursor.All(ctx, &posts); err != nil {
		return nil, err
	}

	return posts, nil
}

// UpdatePost updates a community post
func (r *communityRepository) UpdatePost(ctx context.Context, id primitive.ObjectID, post *models.CommunityPost) error {
	post.UpdatedAt = time.Now()

	filter := bson.M{"_id": id}
	update := bson.M{"$set": post}

	_, err := r.postsCollection.UpdateOne(ctx, filter, update)
	return err
}

// DeletePost deletes a community post
func (r *communityRepository) DeletePost(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}
	_, err := r.postsCollection.DeleteOne(ctx, filter)
	return err
}

// IncrementPostLikeCount increments the like count
func (r *communityRepository) IncrementPostLikeCount(ctx context.Context, postID primitive.ObjectID, increment int) error {
	filter := bson.M{"_id": postID}
	update := bson.M{"$inc": bson.M{"likeCount": increment}}
	_, err := r.postsCollection.UpdateOne(ctx, filter, update)
	return err
}

// IncrementPostVoteCount increments the vote count
func (r *communityRepository) IncrementPostVoteCount(ctx context.Context, postID primitive.ObjectID, increment int) error {
	filter := bson.M{"_id": postID}
	update := bson.M{"$inc": bson.M{"voteCount": increment}}
	_, err := r.postsCollection.UpdateOne(ctx, filter, update)
	return err
}

// IncrementPostCommentCount increments the comment count
func (r *communityRepository) IncrementPostCommentCount(ctx context.Context, postID primitive.ObjectID, increment int) error {
	filter := bson.M{"_id": postID}
	update := bson.M{"$inc": bson.M{"commentCount": increment}}
	_, err := r.postsCollection.UpdateOne(ctx, filter, update)
	return err
}

// CreateLike creates a like on a post
func (r *communityRepository) CreateLike(ctx context.Context, like *models.PostLike) error {
	like.ID = primitive.NewObjectID()
	like.CreatedAt = time.Now()

	_, err := r.likesCollection.InsertOne(ctx, like)
	return err
}

// DeleteLike deletes a like
func (r *communityRepository) DeleteLike(ctx context.Context, postID, userID primitive.ObjectID) error {
	filter := bson.M{"postId": postID, "userId": userID}
	_, err := r.likesCollection.DeleteOne(ctx, filter)
	return err
}

// GetLikeByUserAndPost checks if user liked a post
func (r *communityRepository) GetLikeByUserAndPost(ctx context.Context, postID, userID primitive.ObjectID) (*models.PostLike, error) {
	var like models.PostLike
	filter := bson.M{"postId": postID, "userId": userID}
	err := r.likesCollection.FindOne(ctx, filter).Decode(&like)
	if err != nil {
		return nil, err
	}
	return &like, nil
}

// GetPostLikes retrieves all likes for a post
func (r *communityRepository) GetPostLikes(ctx context.Context, postID primitive.ObjectID) ([]*models.PostLike, error) {
	filter := bson.M{"postId": postID}
	cursor, err := r.likesCollection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var likes []*models.PostLike
	if err = cursor.All(ctx, &likes); err != nil {
		return nil, err
	}

	return likes, nil
}

// CreateVote creates a vote on a post
func (r *communityRepository) CreateVote(ctx context.Context, vote *models.PostVote) error {
	vote.ID = primitive.NewObjectID()
	vote.CreatedAt = time.Now()

	_, err := r.votesCollection.InsertOne(ctx, vote)
	return err
}

// UpdateVote updates a vote
func (r *communityRepository) UpdateVote(ctx context.Context, postID, userID primitive.ObjectID, voteType string) error {
	filter := bson.M{"postId": postID, "userId": userID}
	update := bson.M{"$set": bson.M{"voteType": voteType}}
	_, err := r.votesCollection.UpdateOne(ctx, filter, update)
	return err
}

// DeleteVote deletes a vote
func (r *communityRepository) DeleteVote(ctx context.Context, postID, userID primitive.ObjectID) error {
	filter := bson.M{"postId": postID, "userId": userID}
	_, err := r.votesCollection.DeleteOne(ctx, filter)
	return err
}

// GetVoteByUserAndPost checks if user voted on a post
func (r *communityRepository) GetVoteByUserAndPost(ctx context.Context, postID, userID primitive.ObjectID) (*models.PostVote, error) {
	var vote models.PostVote
	filter := bson.M{"postId": postID, "userId": userID}
	err := r.votesCollection.FindOne(ctx, filter).Decode(&vote)
	if err != nil {
		return nil, err
	}
	return &vote, nil
}

// CreateComment creates a comment on a post
func (r *communityRepository) CreateComment(ctx context.Context, comment *models.PostComment) error {
	comment.ID = primitive.NewObjectID()
	comment.CreatedAt = time.Now()
	comment.UpdatedAt = time.Now()
	comment.LikeCount = 0

	_, err := r.commentsCollection.InsertOne(ctx, comment)
	return err
}

// GetCommentsByPost retrieves comments for a post
func (r *communityRepository) GetCommentsByPost(ctx context.Context, postID primitive.ObjectID, page, limit int) ([]*models.PostComment, int64, error) {
	skip := (page - 1) * limit

	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	filter := bson.M{"postId": postID}
	cursor, err := r.commentsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var comments []*models.PostComment
	if err = cursor.All(ctx, &comments); err != nil {
		return nil, 0, err
	}

	total, err := r.commentsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	return comments, total, nil
}

// DeleteComment deletes a comment
func (r *communityRepository) DeleteComment(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}
	_, err := r.commentsCollection.DeleteOne(ctx, filter)
	return err
}

// LinkInstagram links an Instagram profile
func (r *communityRepository) LinkInstagram(ctx context.Context, profile *models.InstagramProfile) error {
	profile.ID = primitive.NewObjectID()
	profile.LinkedAt = time.Now()
	profile.UpdatedAt = time.Now()
	profile.IsActive = true

	_, err := r.instagramCollection.InsertOne(ctx, profile)
	return err
}

// GetInstagramProfile retrieves Instagram profile by user ID
func (r *communityRepository) GetInstagramProfile(ctx context.Context, userID primitive.ObjectID) (*models.InstagramProfile, error) {
	var profile models.InstagramProfile
	filter := bson.M{"userId": userID, "isActive": true}
	err := r.instagramCollection.FindOne(ctx, filter).Decode(&profile)
	if err != nil {
		return nil, err
	}
	return &profile, nil
}

// UpdateInstagramProfile updates an Instagram profile
func (r *communityRepository) UpdateInstagramProfile(ctx context.Context, userID primitive.ObjectID, profile *models.InstagramProfile) error {
	profile.UpdatedAt = time.Now()

	filter := bson.M{"userId": userID}
	update := bson.M{"$set": profile}

	_, err := r.instagramCollection.UpdateOne(ctx, filter, update)
	return err
}

// UnlinkInstagram unlinks an Instagram profile
func (r *communityRepository) UnlinkInstagram(ctx context.Context, userID primitive.ObjectID) error {
	filter := bson.M{"userId": userID}
	update := bson.M{"$set": bson.M{"isActive": false, "updatedAt": time.Now()}}
	_, err := r.instagramCollection.UpdateOne(ctx, filter, update)
	return err
}

// GetPostsByModerationStatus retrieves posts by moderation status (for admin moderation queue)
func (r *communityRepository) GetPostsByModerationStatus(ctx context.Context, status models.ModerationStatus, page, limit int) ([]*models.CommunityPost, int64, error) {
	skip := (page - 1) * limit

	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: "createdAt", Value: -1}}) // Most recent first

	filter := bson.M{"moderationStatus": status}

	cursor, err := r.postsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var posts []*models.CommunityPost
	if err = cursor.All(ctx, &posts); err != nil {
		return nil, 0, err
	}

	total, err := r.postsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	return posts, total, nil
}

// CountPostsByModerationStatus counts posts by moderation status
func (r *communityRepository) CountPostsByModerationStatus(ctx context.Context, status models.ModerationStatus) (int64, error) {
	filter := bson.M{"moderationStatus": status}
	return r.postsCollection.CountDocuments(ctx, filter)
}
