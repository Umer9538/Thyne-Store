import React, { useState } from 'react';
import { MinimalFeedPost, MinimalPostData } from './MinimalFeedPost';
import { FullScreenFeed } from './FullScreenFeed';

interface NewThyneVerseProps {
  onProductClick: (productId: string) => void;
  onFullScreenChange?: (isFullScreen: boolean) => void;
  theme?: 'dark' | 'light';
}

const MOCK_POSTS: MinimalPostData[] = [
  {
    id: '1',
    username: 'luxe.fashion',
    userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
    timeAgo: '2h',
    images: [
      'https://images.unsplash.com/photo-1719518411339-5158cea86caf?w=1080',
      'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=1080',
    ],
    likes: 2847,
    comments: 124,
    caption: 'Elegance never goes out of style',
    isLiked: false,
    isSaved: false,
    hashtags: ['luxury', 'fashion', 'ootd'],
    products: [
      { 
        id: 'p1', 
        name: 'Silk Gown', 
        price: 34999, 
        image: 'https://images.unsplash.com/photo-1719518411339-5158cea86caf?w=200'
      },
      { 
        id: 'p2', 
        name: 'Gold Necklace', 
        price: 12999, 
        image: 'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=200'
      },
    ],
  },
  {
    id: '2',
    username: 'minimal.vibes',
    userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
    timeAgo: '5h',
    images: [
      'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=1080',
    ],
    likes: 1923,
    comments: 87,
    caption: 'Less is more ✨',
    isLiked: true,
    isSaved: false,
    hashtags: ['minimalist', 'jewelry', 'aesthetic'],
    products: [
      { 
        id: 'p3', 
        name: 'Diamond Ring', 
        price: 45999, 
        image: 'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=200'
      },
    ],
  },
  {
    id: '3',
    username: 'style.insider',
    userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
    timeAgo: '8h',
    images: [
      'https://images.unsplash.com/photo-1563418754681-55ab8367b1c0?w=1080',
      'https://images.unsplash.com/photo-1722340321190-1c7b7384e89b?w=1080',
      'https://images.unsplash.com/photo-1654707636005-5b5a96c11ab2?w=1080',
    ],
    likes: 3421,
    comments: 203,
    caption: 'Creating moments that matter 💫',
    isLiked: false,
    isSaved: true,
    hashtags: ['fashion', 'style', 'glamour'],
    products: [
      { 
        id: 'p4', 
        name: 'Designer Bag', 
        price: 28999, 
        image: 'https://images.unsplash.com/photo-1563418754681-55ab8367b1c0?w=200'
      },
      { 
        id: 'p5', 
        name: 'Pearl Earrings', 
        price: 7999, 
        image: 'https://images.unsplash.com/photo-1722340321190-1c7b7384e89b?w=200'
      },
    ],
  },
  {
    id: '4',
    username: 'glam.diary',
    userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100',
    timeAgo: '12h',
    images: [
      'https://images.unsplash.com/photo-1722340321190-1c7b7384e89b?w=1080',
    ],
    likes: 1654,
    comments: 92,
    caption: 'Shine bright like a diamond',
    isLiked: false,
    isSaved: false,
    hashtags: ['jewelry', 'luxury', 'glam'],
    products: [
      { 
        id: 'p6', 
        name: 'Diamond Bracelet', 
        price: 56999, 
        image: 'https://images.unsplash.com/photo-1722340321190-1c7b7384e89b?w=200'
      },
    ],
  },
  {
    id: '5',
    username: 'haute.couture',
    userAvatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=100',
    timeAgo: '1d',
    images: [
      'https://images.unsplash.com/photo-1654707636005-5b5a96c11ab2?w=1080',
    ],
    likes: 4283,
    comments: 267,
    caption: 'Couture at its finest 👗',
    isLiked: true,
    isSaved: true,
    hashtags: ['couture', 'designer', 'fashion'],
    products: [
      { 
        id: 'p7', 
        name: 'Designer Watch', 
        price: 89999, 
        image: 'https://images.unsplash.com/photo-1654707636005-5b5a96c11ab2?w=200'
      },
    ],
  },
  {
    id: '6',
    username: 'chic.styles',
    userAvatar: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=100',
    timeAgo: '1d',
    images: [
      'https://images.unsplash.com/photo-1620818563803-e24c9325c7ae?w=1080',
    ],
    likes: 2156,
    comments: 143,
    caption: 'Timeless elegance',
    isLiked: false,
    isSaved: false,
    hashtags: ['timeless', 'elegant', 'style'],
    products: [
      { 
        id: 'p8', 
        name: 'Silk Scarf', 
        price: 8999, 
        image: 'https://images.unsplash.com/photo-1620818563803-e24c9325c7ae?w=200'
      },
    ],
  },
];

export function NewThyneVerse({ onProductClick, onFullScreenChange, theme = 'light' }: NewThyneVerseProps) {
  const [posts, setPosts] = useState(MOCK_POSTS);
  const [selectedPostIndex, setSelectedPostIndex] = useState<number | null>(null);

  const handleLike = (postId: string) => {
    setPosts(
      posts.map((post) =>
        post.id === postId
          ? {
              ...post,
              isLiked: !post.isLiked,
              likes: post.isLiked ? post.likes - 1 : post.likes + 1,
            }
          : post
      )
    );
  };

  const handleSave = (postId: string) => {
    setPosts(
      posts.map((post) =>
        post.id === postId ? { ...post, isSaved: !post.isSaved } : post
      )
    );
  };

  const handleImageClick = (postId: string) => {
    const index = posts.findIndex((p) => p.id === postId);
    setSelectedPostIndex(index);
    onFullScreenChange?.(true);
  };

  const handleCloseFullScreen = () => {
    setSelectedPostIndex(null);
    onFullScreenChange?.(false);
  };

  return (
    <div className="bg-[#fffff0] min-h-screen">
      {/* Feed */}
      <div className="pb-32">
        {posts.map((post) => (
          <MinimalFeedPost
            key={post.id}
            post={post}
            onLike={() => handleLike(post.id)}
            onSave={() => handleSave(post.id)}
            onProductClick={onProductClick}
            onImageClick={() => handleImageClick(post.id)}
            theme={theme}
          />
        ))}
      </div>

      {/* Full Screen View */}
      {selectedPostIndex !== null && (
        <FullScreenFeed
          posts={posts}
          initialIndex={selectedPostIndex}
          onClose={handleCloseFullScreen}
          onLike={handleLike}
          onSave={handleSave}
          onProductClick={onProductClick}
          theme={theme}
        />
      )}
    </div>
  );
}
