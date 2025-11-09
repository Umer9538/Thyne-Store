class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final List<String> images;
  final List<String> videos;
  final int likeCount;
  final int voteCount;
  final int commentCount;
  final List<String> tags;
  final bool isAdminPost;
  final bool isFeatured;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.images = const [],
    this.videos = const [],
    this.likeCount = 0,
    this.voteCount = 0,
    this.commentCount = 0,
    this.tags = const [],
    this.isAdminPost = false,
    this.isFeatured = false,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userAvatar: json['userAvatar']?.toString(),
      content: json['content']?.toString() ?? '',
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      likeCount: json['likeCount'] ?? 0,
      voteCount: json['voteCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      isAdminPost: json['isAdminPost'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isPinned: json['isPinned'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'images': images,
      'videos': videos,
      'likeCount': likeCount,
      'voteCount': voteCount,
      'commentCount': commentCount,
      'tags': tags,
      'isAdminPost': isAdminPost,
      'isFeatured': isFeatured,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userAvatar: json['userAvatar']?.toString(),
      content: json['content']?.toString() ?? '',
      likeCount: json['likeCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PostEngagement {
  final String postId;
  final int likeCount;
  final int voteCount;
  final int commentCount;
  final bool userLiked;
  final String userVoted; // "up", "down", or ""

  PostEngagement({
    required this.postId,
    this.likeCount = 0,
    this.voteCount = 0,
    this.commentCount = 0,
    this.userLiked = false,
    this.userVoted = '',
  });

  factory PostEngagement.fromJson(Map<String, dynamic> json) {
    return PostEngagement(
      postId: json['postId']?.toString() ?? '',
      likeCount: json['likeCount'] ?? 0,
      voteCount: json['voteCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      userLiked: json['userLiked'] ?? false,
      userVoted: json['userVoted']?.toString() ?? '',
    );
  }
}

class InstagramProfile {
  final String id;
  final String userId;
  final String instagramId;
  final String username;
  final String? displayName;
  final String? profilePicUrl;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isVerified;
  final bool isActive;
  final DateTime linkedAt;
  final DateTime updatedAt;

  InstagramProfile({
    required this.id,
    required this.userId,
    required this.instagramId,
    required this.username,
    this.displayName,
    this.profilePicUrl,
    this.bio,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.isVerified = false,
    this.isActive = true,
    required this.linkedAt,
    required this.updatedAt,
  });

  factory InstagramProfile.fromJson(Map<String, dynamic> json) {
    return InstagramProfile(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      instagramId: json['instagramId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      profilePicUrl: json['profilePicUrl']?.toString(),
      bio: json['bio']?.toString(),
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postCount: json['postCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      linkedAt: json['linkedAt'] != null
          ? DateTime.parse(json['linkedAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'instagramId': instagramId,
      'username': username,
      'displayName': displayName,
      'profilePicUrl': profilePicUrl,
      'bio': bio,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'linkedAt': linkedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CommunityFeedResponse {
  final List<CommunityPost> posts;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  CommunityFeedResponse({
    required this.posts,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory CommunityFeedResponse.fromJson(Map<String, dynamic> json) {
    return CommunityFeedResponse(
      posts: (json['posts'] as List<dynamic>?)
              ?.map((post) => CommunityPost.fromJson(post as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
