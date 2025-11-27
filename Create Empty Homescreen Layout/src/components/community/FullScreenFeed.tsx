import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, Heart, Share2, Bookmark, MoreVertical } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { MinimalPostData } from './MinimalFeedPost';

interface FullScreenFeedProps {
  posts: MinimalPostData[];
  initialIndex: number;
  onClose: () => void;
  onLike: (postId: string) => void;
  onSave: (postId: string) => void;
  onProductClick: (productId: string) => void;
  theme?: 'dark' | 'light';
}

export function FullScreenFeed({
  posts,
  initialIndex,
  onClose,
  onLike,
  onSave,
  onProductClick,
  theme = 'light',
}: FullScreenFeedProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const handleScroll = () => {
      const scrollTop = container.scrollTop;
      const viewportHeight = window.innerHeight;
      const newIndex = Math.round(scrollTop / viewportHeight);
      if (newIndex !== currentIndex && newIndex >= 0 && newIndex < posts.length) {
        setCurrentIndex(newIndex);
      }
    };

    container.addEventListener('scroll', handleScroll);
    
    // Scroll to initial index
    container.scrollTo({
      top: initialIndex * window.innerHeight,
      behavior: 'instant' as ScrollBehavior,
    });

    return () => container.removeEventListener('scroll', handleScroll);
  }, [initialIndex]);

  const handleDoubleTap = (postId: string, e: React.MouseEvent) => {
    const post = posts.find((p) => p.id === postId);
    if (post && !post.isLiked) {
      onLike(postId);
      
      // Show heart animation
      const heart = document.createElement('div');
      heart.innerHTML = '❤️';
      heart.style.position = 'absolute';
      heart.style.fontSize = '100px';
      heart.style.left = e.clientX - 50 + 'px';
      heart.style.top = e.clientY - 50 + 'px';
      heart.style.pointerEvents = 'none';
      heart.style.animation = 'heartPop 0.8s ease-out forwards';
      heart.style.zIndex = '1000';
      document.body.appendChild(heart);
      setTimeout(() => heart.remove(), 800);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black z-[100]"
    >
      <div
        ref={containerRef}
        className="h-full w-full overflow-y-scroll snap-y snap-mandatory"
        style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
      >
        {posts.map((post) => (
          <div
            key={post.id}
            className="relative h-screen w-full snap-start flex items-center justify-center"
          >
            {/* Image */}
            <div
              className="absolute inset-0"
              onDoubleClick={(e) => handleDoubleTap(post.id, e)}
            >
              <ImageWithFallback
                src={post.images[0]}
                alt={post.caption}
                className="w-full h-full object-cover"
              />
              
              {/* Gradient overlays */}
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-black/40" />
            </div>

            {/* Top bar */}
            <div className="absolute top-0 left-0 right-0 p-4 flex items-center justify-between z-10">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full overflow-hidden ring-2 ring-white">
                  <ImageWithFallback
                    src={post.userAvatar}
                    alt={post.username}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex flex-col">
                  <span className="text-white">{post.username}</span>
                  <span className="text-white/60 text-xs">{post.timeAgo}</span>
                </div>
              </div>
              
              <button
                onClick={onClose}
                className="w-10 h-10 flex items-center justify-center rounded-full bg-black/30 backdrop-blur-sm"
              >
                <X className="w-5 h-5 text-white" />
              </button>
            </div>

            {/* Right side actions */}
            <div className="absolute right-4 bottom-32 flex flex-col items-center gap-6 z-10">
              <motion.button
                whileTap={{ scale: 0.9 }}
                onClick={() => onLike(post.id)}
                className="flex flex-col items-center gap-1"
              >
                <div className="w-12 h-12 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
                  <Heart
                    className={`w-7 h-7 ${
                      post.isLiked ? 'fill-red-600 text-red-600' : 'text-white'
                    }`}
                  />
                </div>
                <span className="text-white text-xs">{formatCount(post.likes)}</span>
              </motion.button>

              <button className="flex flex-col items-center gap-1">
                <div className="w-12 h-12 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
                  <Share2 className="w-7 h-7 text-white" />
                </div>
              </button>

              <button
                onClick={() => onSave(post.id)}
                className="flex flex-col items-center gap-1"
              >
                <div className="w-12 h-12 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
                  <Bookmark
                    className={`w-7 h-7 ${
                      post.isSaved ? 'fill-[#401010] text-[#401010]' : 'text-white'
                    }`}
                  />
                </div>
              </button>

              <button className="flex flex-col items-center gap-1">
                <div className="w-12 h-12 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
                  <MoreVertical className="w-7 h-7 text-white" />
                </div>
              </button>
            </div>

            {/* Bottom caption and products */}
            <div className="absolute bottom-0 left-0 right-0 z-10 pb-6">
              {/* Caption */}
              <div className="px-4 pb-3">
                <p className="text-white">
                  <span className="font-medium">{post.username}</span>{' '}
                  {post.caption}{' '}
                  {post.hashtags?.map((tag) => (
                    <span key={tag} className="text-white/80">
                      #{tag}{' '}
                    </span>
                  ))}
                </p>
              </div>

              {/* Product Cards Horizontal Scroll */}
              {post.products && post.products.length > 0 && (
                <div className="px-4">
                  <div className="flex gap-3 overflow-x-auto scrollbar-hide pb-2">
                    {post.products.map((product) => (
                      <button
                        key={product.id}
                        onClick={() => onProductClick(product.id)}
                        className="flex-shrink-0 bg-white/95 backdrop-blur-sm rounded-2xl p-3 flex items-center gap-3 min-w-[200px]"
                      >
                        <div className="w-12 h-12 rounded-xl overflow-hidden ring-2 ring-[#401010]/20">
                          <ImageWithFallback
                            src={product.image}
                            alt={product.name}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div className="flex flex-col items-start flex-1">
                          <span className="text-black text-sm font-medium truncate max-w-[120px]">
                            {product.name}
                          </span>
                          <span className="text-[#401010]">
                            ₹{product.price.toLocaleString()}
                          </span>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

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
        div::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </motion.div>
  );
}

function formatCount(count: number): string {
  if (count >= 1000000) {
    return (count / 1000000).toFixed(1) + 'M';
  }
  if (count >= 1000) {
    return (count / 1000).toFixed(1) + 'K';
  }
  return count.toString();
}
