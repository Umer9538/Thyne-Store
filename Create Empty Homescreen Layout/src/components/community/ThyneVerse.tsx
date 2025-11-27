import React, { useState } from 'react';
import { FeedPost, FeedPostData } from './FeedPost';
import { FullScreenPost } from './FullScreenPost';

interface ThyneVerseProps {
  onProductClick: (productId: string) => void;
  onRemix: (prompt: string) => void;
  onFullScreenChange?: (isFullScreen: boolean) => void;
  theme?: 'dark' | 'light';
}

// Mock data
const MOCK_POSTS: FeedPostData[] = [
  {
    id: '1',
    username: 'designstudio',
    userAvatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    timeAgo: '2h ago',
    mediaUrl: 'https://images.unsplash.com/photo-1559878541-926091e4c31b?w=1080',
    likes: 1243,
    comments: 87,
    caption: 'Elevate your style with timeless elegance ✨',
    isLiked: false,
    isSaved: false,
    products: [
      {
        id: 'p1',
        name: 'Silk Evening Dress',
        image: 'https://images.unsplash.com/photo-1559878541-926091e4c31b?w=200',
        price: 12999,
      },
      {
        id: 'p2',
        name: 'Statement Earrings',
        image: 'https://images.unsplash.com/photo-1668718003259-650efe62fbca?w=200',
        price: 2499,
      },
    ],
  },
  {
    id: '2',
    username: 'ai_creator_pro',
    userAvatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    timeAgo: '5h ago',
    mediaUrl: 'https://images.unsplash.com/photo-1680503504076-e5c61901c36d?w=1080',
    likes: 892,
    comments: 54,
    caption: 'AI-generated luxury meets reality',
    isLiked: true,
    isSaved: false,
    isAiGenerated: true,
    prompt: 'A minimalist luxury watch on a marble surface with soft golden lighting and elegant shadows',
    products: [
      {
        id: 'p3',
        name: 'Luxury Timepiece',
        image: 'https://images.unsplash.com/photo-1680503504076-e5c61901c36d?w=200',
        price: 45999,
      },
    ],
  },
  {
    id: '3',
    username: 'interior_dreams',
    userAvatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    timeAgo: '8h ago',
    mediaUrl: 'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?w=1080',
    likes: 2134,
    comments: 142,
    caption: 'Transform your space into a sanctuary of comfort and style',
    isLiked: false,
    isSaved: true,
    products: [
      {
        id: 'p4',
        name: 'Modern Accent Chair',
        image: 'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?w=200',
        price: 18999,
      },
      {
        id: 'p5',
        name: 'Decorative Pendant Light',
        image: 'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?w=200',
        price: 8499,
      },
      {
        id: 'p6',
        name: 'Velvet Throw Pillows',
        image: 'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?w=200',
        price: 1999,
      },
    ],
  },
  {
    id: '4',
    username: 'fashion_forward',
    userAvatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    timeAgo: '12h ago',
    mediaUrl: 'https://images.unsplash.com/photo-1668718003259-650efe62fbca?w=1080',
    likes: 1567,
    comments: 93,
    caption: 'Details that make a difference 💎',
    isLiked: false,
    isSaved: false,
    products: [
      {
        id: 'p7',
        name: 'Diamond Bracelet',
        image: 'https://images.unsplash.com/photo-1668718003259-650efe62fbca?w=200',
        price: 34999,
      },
    ],
  },
  {
    id: '5',
    username: 'creative_ai',
    userAvatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    timeAgo: '1d ago',
    mediaUrl: 'https://images.unsplash.com/photo-1519217651866-847339e674d4?w=1080',
    likes: 743,
    comments: 38,
    caption: 'Where creativity meets technology',
    isLiked: true,
    isSaved: true,
    isAiGenerated: true,
    prompt: 'A modern creative workspace with natural light, plants, and minimalist desk setup in earthy tones',
    products: [
      {
        id: 'p8',
        name: 'Ergonomic Desk',
        image: 'https://images.unsplash.com/photo-1519217651866-847339e674d4?w=200',
        price: 24999,
      },
      {
        id: 'p9',
        name: 'Designer Desk Lamp',
        image: 'https://images.unsplash.com/photo-1519217651866-847339e674d4?w=200',
        price: 5999,
      },
    ],
  },
];

export const ThyneVerse: React.FC<ThyneVerseProps> = ({ onProductClick, onRemix, onFullScreenChange, theme = 'dark' }) => {
  const [posts, setPosts] = useState(MOCK_POSTS);
  const [fullScreenPost, setFullScreenPost] = useState<number | null>(null);

  const handleFullScreenOpen = (index: number) => {
    setFullScreenPost(index);
    onFullScreenChange?.(true);
  };

  const handleFullScreenClose = () => {
    setFullScreenPost(null);
    onFullScreenChange?.(false);
  };

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

  return (
    <>
      <div className="space-y-3 pb-4">
        {posts.map((post, index) => (
          <FeedPost
            key={post.id}
            post={post}
            onMediaClick={() => handleFullScreenOpen(index)}
            onProductClick={onProductClick}
            onRemix={onRemix}
            onLike={() => handleLike(post.id)}
            onSave={() => handleSave(post.id)}
            theme={theme}
          />
        ))}
      </div>

      {fullScreenPost !== null && (
        <FullScreenPost
          posts={posts}
          initialIndex={fullScreenPost}
          onClose={handleFullScreenClose}
          onProductClick={onProductClick}
          onRemix={onRemix}
          onLike={handleLike}
          onSave={handleSave}
          theme={theme}
        />
      )}
    </>
  );
};