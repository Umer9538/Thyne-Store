import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Heart, Share2, Bookmark, MoreHorizontal } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

export interface MinimalPostData {
  id: string;
  username: string;
  userAvatar: string;
  timeAgo: string;
  images: string[];
  likes: number;
  comments: number;
  caption: string;
  isLiked: boolean;
  isSaved: boolean;
  products?: Array<{
    id: string;
    name: string;
    price: number;
    image: string;
  }>;
  hashtags?: string[];
}

interface MinimalFeedPostProps {
  post: MinimalPostData;
  onLike: () => void;
  onSave: () => void;
  onProductClick: (productId: string) => void;
  onImageClick: () => void;
  theme?: 'dark' | 'light';
}

export function MinimalFeedPost({
  post,
  onLike,
  onSave,
  onProductClick,
  onImageClick,
  theme = 'light',
}: MinimalFeedPostProps) {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [doubleTapTimeout, setDoubleTapTimeout] = useState<NodeJS.Timeout | null>(null);

  const handleImageTap = (e: React.MouseEvent) => {
    e.stopPropagation();
    
    if (doubleTapTimeout) {
      // Double tap detected
      clearTimeout(doubleTapTimeout);
      setDoubleTapTimeout(null);
      if (!post.isLiked) {
        onLike();
      }
      // Show heart animation
      const heart = document.createElement('div');
      heart.innerHTML = '❤️';
      heart.style.position = 'absolute';
      heart.style.fontSize = '80px';
      heart.style.left = e.clientX - 40 + 'px';
      heart.style.top = e.clientY - 40 + 'px';
      heart.style.pointerEvents = 'none';
      heart.style.animation = 'heartPop 0.8s ease-out forwards';
      document.body.appendChild(heart);
      setTimeout(() => heart.remove(), 800);
    } else {
      // First tap - open full screen
      const timeout = setTimeout(() => {
        onImageClick();
        setDoubleTapTimeout(null);
      }, 300);
      setDoubleTapTimeout(timeout);
    }
  };

  const nextImage = () => {
    setCurrentImageIndex((prev) => (prev + 1) % post.images.length);
  };

  const prevImage = () => {
    setCurrentImageIndex((prev) => (prev - 1 + post.images.length) % post.images.length);
  };

  return (
    <div className="bg-[#fffff0] mb-3">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full overflow-hidden ring-1 ring-black/10">
            <ImageWithFallback
              src={post.userAvatar}
              alt={post.username}
              className="w-full h-full object-cover"
            />
          </div>
          <div className="flex flex-col">
            <span className="text-black">{post.username}</span>
            <span className="text-xs text-black/40">{post.timeAgo}</span>
          </div>
        </div>
        <button className="p-1">
          <MoreHorizontal className="w-5 h-5 text-black/60" />
        </button>
      </div>

      {/* Image Carousel */}
      <div className="relative aspect-square bg-black/5">
        <div className="relative w-full h-full" onClick={handleImageTap}>
          <ImageWithFallback
            src={post.images[currentImageIndex]}
            alt={`Post by ${post.username}`}
            className="w-full h-full object-cover cursor-pointer"
          />
        </div>

        {/* Navigation arrows for multiple images */}
        {post.images.length > 1 && (
          <>
            <button
              onClick={(e) => {
                e.stopPropagation();
                prevImage();
              }}
              className="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/20 backdrop-blur-sm flex items-center justify-center text-white"
            >
              ‹
            </button>
            <button
              onClick={(e) => {
                e.stopPropagation();
                nextImage();
              }}
              className="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/20 backdrop-blur-sm flex items-center justify-center text-white"
            >
              ›
            </button>
            
            {/* Dots indicator */}
            <div className="absolute bottom-2 left-1/2 -translate-x-1/2 flex gap-1">
              {post.images.map((_, index) => (
                <div
                  key={index}
                  className={`w-1.5 h-1.5 rounded-full transition-all ${
                    index === currentImageIndex ? 'bg-white w-3' : 'bg-white/50'
                  }`}
                />
              ))}
            </div>
          </>
        )}
      </div>

      {/* Actions */}
      <div className="flex items-center justify-between px-4 py-3">
        <div className="flex items-center gap-4">
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={onLike}
            className="flex items-center gap-1"
          >
            <Heart
              className={`w-6 h-6 transition-colors ${
                post.isLiked ? 'fill-red-600 text-red-600' : 'text-black'
              }`}
            />
          </motion.button>
          <button className="flex items-center gap-1">
            <Share2 className="w-6 h-6 text-black" />
          </button>
        </div>
        <motion.button whileTap={{ scale: 0.9 }} onClick={onSave}>
          <Bookmark
            className={`w-6 h-6 transition-colors ${
              post.isSaved ? 'fill-[#401010] text-[#401010]' : 'text-black'
            }`}
          />
        </motion.button>
      </div>

      {/* Likes */}
      <div className="px-4 pb-2">
        <span className="text-black">
          {post.likes.toLocaleString()} likes
        </span>
      </div>

      {/* Caption */}
      <div className="px-4 pb-2">
        <span className="text-black">
          <span className="font-medium">{post.username}</span>{' '}
          {post.caption}{' '}
          {post.hashtags?.map((tag) => (
            <span key={tag} className="text-[#401010]">
              #{tag}{' '}
            </span>
          ))}
        </span>
      </div>

      {/* Product Cards Row */}
      {post.products && post.products.length > 0 && (
        <div className="px-4 pb-4">
          <div className="flex gap-3 overflow-x-auto scrollbar-hide">
            {post.products.map((product) => (
              <button
                key={product.id}
                onClick={(e) => {
                  e.stopPropagation();
                  onProductClick(product.id);
                }}
                className="flex-shrink-0 flex flex-col items-center gap-2"
              >
                <div className="w-14 h-14 rounded-full overflow-hidden ring-2 ring-[#401010]/20 hover:ring-[#401010]/40 transition-all">
                  <ImageWithFallback
                    src={product.image}
                    alt={product.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex flex-col items-center">
                  <span className="text-xs text-black/70 max-w-[56px] truncate">
                    {product.name}
                  </span>
                  <span className="text-xs text-[#401010]">
                    ₹{product.price.toLocaleString()}
                  </span>
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      <style>{`
        @keyframes heartPop {
          0% {
            transform: scale(0);
            opacity: 1;
          }
          50% {
            transform: scale(1.2);
            opacity: 0.8;
          }
          100% {
            transform: scale(1) translateY(-100px);
            opacity: 0;
          }
        }
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </div>
  );
}
