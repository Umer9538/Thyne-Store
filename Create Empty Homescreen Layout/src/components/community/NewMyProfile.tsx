import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Grid3x3, Bookmark, Plus, MoreVertical } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface NewMyProfileProps {
  onMediaClick: (mediaId: string) => void;
  onUploadClick: () => void;
  onCameraClick: () => void;
  theme?: 'dark' | 'light';
}

const MOCK_PROFILE = {
  username: 'your_username',
  name: 'Your Name',
  avatar: 'https://images.unsplash.com/photo-1620818563803-e24c9325c7ae?w=200',
  bio: 'Fashion enthusiast | Style curator ✨\nLiving life in style 💫',
  website: 'thyne.app',
  posts: 127,
  likes: 45200,
};

const MOCK_POSTS = [
  {
    id: '1',
    image: 'https://images.unsplash.com/photo-1719518411339-5158cea86caf?w=500',
    likes: 2847,
    comments: 124,
  },
  {
    id: '2',
    image: 'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=500',
    likes: 1923,
    comments: 87,
  },
  {
    id: '3',
    image: 'https://images.unsplash.com/photo-1563418754681-55ab8367b1c0?w=500',
    likes: 3421,
    comments: 203,
  },
  {
    id: '4',
    image: 'https://images.unsplash.com/photo-1722340321190-1c7b7384e89b?w=500',
    likes: 1654,
    comments: 92,
  },
  {
    id: '5',
    image: 'https://images.unsplash.com/photo-1654707636005-5b5a96c11ab2?w=500',
    likes: 4283,
    comments: 267,
  },
  {
    id: '6',
    image: 'https://images.unsplash.com/photo-1620818563803-e24c9325c7ae?w=500',
    likes: 2156,
    comments: 143,
  },
  {
    id: '7',
    image: 'https://images.unsplash.com/photo-1719518411339-5158cea86caf?w=500',
    likes: 3892,
    comments: 198,
  },
  {
    id: '8',
    image: 'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=500',
    likes: 1567,
    comments: 76,
  },
  {
    id: '9',
    image: 'https://images.unsplash.com/photo-1563418754681-55ab8367b1c0?w=500',
    likes: 2934,
    comments: 167,
  },
];

const MOCK_SAVED = [
  {
    id: 's1',
    image: 'https://images.unsplash.com/photo-1722340321190-1c7b7384e89b?w=500',
  },
  {
    id: 's2',
    image: 'https://images.unsplash.com/photo-1654707636005-5b5a96c11ab2?w=500',
  },
  {
    id: 's3',
    image: 'https://images.unsplash.com/photo-1620818563803-e24c9325c7ae?w=500',
  },
];

export function NewMyProfile({ onMediaClick, onUploadClick, onCameraClick, theme = 'light' }: NewMyProfileProps) {
  const [activeTab, setActiveTab] = useState<'posts' | 'saved'>('posts');

  const formatNumber = (num: number) => {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
  };

  return (
    <div className="bg-[#fffff0] min-h-screen pb-32">
      {/* Header */}
      <div className="px-5 py-4 border-b border-black/5 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="text-black text-lg">{MOCK_PROFILE.username}</span>
          <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none">
            <path d="M7 10L12 15L17 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={onUploadClick}>
            <svg className="w-6 h-6 text-black" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="3" y="3" width="18" height="18" rx="2" />
              <path d="M12 8v8M8 12h8" />
            </svg>
          </button>
          <button>
            <MoreVertical className="w-6 h-6 text-black" />
          </button>
        </div>
      </div>

      {/* Profile Info */}
      <div className="px-5 py-5">
        {/* Stats Row */}
        <div className="flex items-center justify-between mb-5">
          <div className="w-20 h-20 rounded-full overflow-hidden ring-1 ring-black/10">
            <ImageWithFallback
              src={MOCK_PROFILE.avatar}
              alt={MOCK_PROFILE.name}
              className="w-full h-full object-cover"
            />
          </div>
          
          <div className="flex items-center gap-12">
            <div className="flex flex-col items-center">
              <span className="text-black">{MOCK_PROFILE.posts}</span>
              <span className="text-black/40 text-sm">Posts</span>
            </div>
            <div className="flex flex-col items-center">
              <span className="text-black">{formatNumber(MOCK_PROFILE.likes)}</span>
              <span className="text-black/40 text-sm">Likes</span>
            </div>
          </div>
        </div>

        {/* Bio */}
        <div className="mb-4">
          <p className="text-black mb-1">{MOCK_PROFILE.name}</p>
          <p className="text-black/60 text-sm whitespace-pre-line">{MOCK_PROFILE.bio}</p>
          <a href="#" className="text-[#401010] text-sm">{MOCK_PROFILE.website}</a>
        </div>

        {/* Action Button */}
        <div>
          <button 
            onClick={onUploadClick}
            className="w-full bg-[#401010] hover:bg-[#401010]/90 text-[#fffff0] py-2.5 rounded-xl transition-colors flex items-center justify-center gap-2"
          >
            <Plus className="w-5 h-5" />
            Add Post
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-black/5">
        <button
          onClick={() => setActiveTab('posts')}
          className={`flex-1 py-3 flex items-center justify-center gap-2 relative ${
            activeTab === 'posts' ? 'text-black' : 'text-black/40'
          }`}
        >
          <Grid3x3 className="w-5 h-5" />
          {activeTab === 'posts' && (
            <motion.div
              layoutId="profileTab"
              className="absolute bottom-0 left-0 right-0 h-0.5"
              style={{ backgroundColor: '#401010' }}
            />
          )}
        </button>
        <button
          onClick={() => setActiveTab('saved')}
          className={`flex-1 py-3 flex items-center justify-center gap-2 relative ${
            activeTab === 'saved' ? 'text-black' : 'text-black/40'
          }`}
        >
          <Bookmark className="w-5 h-5" />
          {activeTab === 'saved' && (
            <motion.div
              layoutId="profileTab"
              className="absolute bottom-0 left-0 right-0 h-0.5"
              style={{ backgroundColor: '#401010' }}
            />
          )}
        </button>
      </div>

      {/* Grid */}
      {activeTab === 'posts' ? (
        <div className="grid grid-cols-3 gap-0.5">
          {MOCK_POSTS.map((post) => (
            <button
              key={post.id}
              onClick={() => onMediaClick(post.id)}
              className="relative aspect-square overflow-hidden bg-black/5"
            >
              <ImageWithFallback
                src={post.image}
                alt={`Post ${post.id}`}
                className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
              />
              {/* Hover overlay */}
              <div className="absolute inset-0 bg-black/40 opacity-0 hover:opacity-100 transition-opacity flex items-center justify-center gap-4">
                <div className="flex items-center gap-1 text-white">
                  <svg className="w-5 h-5 fill-white" viewBox="0 0 24 24">
                    <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                  </svg>
                  <span className="text-sm">{formatNumber(post.likes)}</span>
                </div>
                <div className="flex items-center gap-1 text-white">
                  <svg className="w-5 h-5 fill-white" viewBox="0 0 24 24">
                    <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                  </svg>
                  <span className="text-sm">{formatNumber(post.comments)}</span>
                </div>
              </div>
            </button>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-3 gap-0.5">
          {MOCK_SAVED.map((post) => (
            <button
              key={post.id}
              onClick={() => onMediaClick(post.id)}
              className="relative aspect-square overflow-hidden bg-black/5"
            >
              <ImageWithFallback
                src={post.image}
                alt={`Saved ${post.id}`}
                className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
              />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
