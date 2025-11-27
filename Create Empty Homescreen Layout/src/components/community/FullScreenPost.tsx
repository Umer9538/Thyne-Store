import React, { useState, useRef, useEffect } from 'react';
import { X, Heart, Share2, Bookmark, Sparkles, ChevronUp, ChevronDown } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { FeedPostData, Product } from './FeedPost';
import { motion, AnimatePresence } from 'motion/react';

interface FullScreenPostProps {
  posts: FeedPostData[];
  initialIndex: number;
  onClose: () => void;
  onProductClick: (productId: string) => void;
  onRemix?: (prompt: string) => void;
  onLike?: (postId: string) => void;
  onSave?: (postId: string) => void;
  theme?: 'dark' | 'light';
}

export const FullScreenPost: React.FC<FullScreenPostProps> = ({
  posts,
  initialIndex,
  onClose,
  onProductClick,
  onRemix,
  onLike,
  onSave,
  theme = 'dark',
}) => {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [showProducts, setShowProducts] = useState(false);
  const [touchStart, setTouchStart] = useState(0);
  const [touchEnd, setTouchEnd] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);

  const currentPost = posts[currentIndex];

  const handleNext = () => {
    if (currentIndex < posts.length - 1) {
      setCurrentIndex(currentIndex + 1);
      setShowProducts(false);
    }
  };

  const handlePrevious = () => {
    if (currentIndex > 0) {
      setCurrentIndex(currentIndex - 1);
      setShowProducts(false);
    }
  };

  const handleTouchStart = (e: React.TouchEvent) => {
    setTouchStart(e.touches[0].clientY);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    setTouchEnd(e.touches[0].clientY);
  };

  const handleTouchEnd = () => {
    if (touchStart - touchEnd > 100) {
      // Swipe up
      handleNext();
    }
    if (touchStart - touchEnd < -100) {
      // Swipe down
      handlePrevious();
    }
    setTouchStart(0);
    setTouchEnd(0);
  };

  // Handle wheel scroll
  useEffect(() => {
    let scrollTimeout: NodeJS.Timeout;
    let isScrolling = false;

    const handleWheel = (e: WheelEvent) => {
      if (isScrolling) return;

      if (e.deltaY > 30) {
        isScrolling = true;
        handleNext();
        scrollTimeout = setTimeout(() => {
          isScrolling = false;
        }, 500);
      } else if (e.deltaY < -30) {
        isScrolling = true;
        handlePrevious();
        scrollTimeout = setTimeout(() => {
          isScrolling = false;
        }, 500);
      }
    };

    const container = containerRef.current;
    if (container) {
      container.addEventListener('wheel', handleWheel, { passive: true });
    }

    return () => {
      if (container) {
        container.removeEventListener('wheel', handleWheel);
      }
      clearTimeout(scrollTimeout);
    };
  }, [currentIndex, posts.length]);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black z-50"
      ref={containerRef}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      {/* Close Button */}
      <button
        onClick={onClose}
        className="absolute top-6 right-6 z-50 p-2 rounded-full bg-zinc-900/80 backdrop-blur-xl border border-zinc-800 hover:bg-zinc-800 transition-colors duration-200"
      >
        <X className="w-6 h-6 text-zinc-100" />
      </button>

      {/* Main Content */}
      <AnimatePresence mode="wait">
        <motion.div
          key={currentIndex}
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -50 }}
          transition={{ duration: 0.3 }}
          className="h-full flex flex-col"
        >
          {/* Media */}
          <div className="flex-1 relative flex items-center justify-center bg-black">
            <ImageWithFallback
              src={currentPost.mediaUrl}
              alt="Full screen media"
              className="max-w-full max-h-full object-contain"
            />

            {/* Navigation Arrows */}
            {currentIndex > 0 && (
              <button
                onClick={handlePrevious}
                className="absolute top-1/2 left-4 -translate-y-1/2 p-3 rounded-full bg-zinc-900/80 backdrop-blur-xl border border-zinc-800 hover:bg-zinc-800 transition-all duration-200"
              >
                <ChevronUp className="w-6 h-6 text-zinc-100" />
              </button>
            )}
            {currentIndex < posts.length - 1 && (
              <button
                onClick={handleNext}
                className="absolute bottom-1/2 right-4 translate-y-1/2 p-3 rounded-full bg-zinc-900/80 backdrop-blur-xl border border-zinc-800 hover:bg-zinc-800 transition-all duration-200"
              >
                <ChevronDown className="w-6 h-6 text-zinc-100" />
              </button>
            )}
          </div>

          {/* Bottom Section */}
          <div className="bg-gradient-to-t from-black via-black/95 to-transparent">
            {/* User Info & Actions */}
            <div className="px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-red-500 to-rose-600 p-0.5">
                  <ImageWithFallback
                    src={currentPost.userAvatar}
                    alt={currentPost.username}
                    className="w-full h-full rounded-full object-cover"
                  />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <p className="text-zinc-100">{currentPost.username}</p>
                    {currentPost.isAiGenerated && (
                      <div className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-gradient-to-r from-red-500/20 to-rose-500/20 border border-red-400/30">
                        <Sparkles className="w-3 h-3 text-red-400" />
                        <span className="text-xs text-red-400">AI</span>
                      </div>
                    )}
                  </div>
                  <p className="text-xs text-zinc-500">{currentPost.timeAgo}</p>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <button 
                  onClick={() => onLike?.(currentPost.id)}
                  className="group flex flex-col items-center gap-1 transition-transform duration-200 active:scale-90"
                >
                  <Heart className={`w-7 h-7 transition-colors duration-200 ${
                    currentPost.isLiked
                      ? 'fill-rose-500 text-rose-500'
                      : theme === 'dark'
                      ? 'text-zinc-400 group-hover:text-rose-500'
                      : 'text-zinc-600 group-hover:text-rose-500'
                  }`} />
                  <span className={`text-xs ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{currentPost.likes}</span>
                </button>
                <button className="group flex flex-col items-center gap-1 transition-transform duration-200 active:scale-90">
                  <Share2 className={`w-7 h-7 transition-colors duration-200 ${
                    theme === 'dark'
                      ? 'text-zinc-400 group-hover:text-zinc-200'
                      : 'text-zinc-600 group-hover:text-zinc-800'
                  }`} />
                </button>
                <button 
                  onClick={() => onSave?.(currentPost.id)}
                  className="group flex flex-col items-center gap-1 transition-transform duration-200 active:scale-90"
                >
                  <Bookmark className={`w-7 h-7 transition-colors duration-200 ${
                    currentPost.isSaved
                      ? 'fill-rose-400 text-rose-400'
                      : theme === 'dark'
                      ? 'text-zinc-400 group-hover:text-rose-400'
                      : 'text-zinc-600 group-hover:text-rose-500'
                  }`} />
                </button>
              </div>
            </div>

            {/* Caption */}
            {currentPost.caption && (
              <div className="px-6 pb-3">
                <p className="text-sm text-zinc-300">
                  <span className="text-zinc-100 mr-2">{currentPost.username}</span>
                  {currentPost.caption}
                </p>
              </div>
            )}

            {/* Toggle Products Button */}
            {currentPost.products.length > 0 && (
              <div className="px-6 pb-4">
                <button
                  onClick={() => setShowProducts(!showProducts)}
                  className="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-red-600/20 to-rose-600/20 border border-red-500/30 hover:from-red-600/30 hover:to-rose-600/30 text-red-400 transition-all duration-300 flex items-center justify-between"
                >
                  <span>
                    View Products ({currentPost.products.length})
                  </span>
                  <ChevronUp
                    className={`w-5 h-5 transition-transform duration-300 ${
                      showProducts ? 'rotate-180' : ''
                    }`}
                  />
                </button>
              </div>
            )}

            {/* Product Cards */}
            <AnimatePresence>
              {showProducts && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.3 }}
                  className="px-6 pb-4 overflow-hidden"
                >
                  <div className="space-y-3 max-h-60 overflow-y-auto">
                    {currentPost.products.map((product) => (
                      <button
                        key={product.id}
                        onClick={() => onProductClick(product.id)}
                        className="w-full p-4 rounded-xl bg-zinc-900/60 backdrop-blur-xl border border-red-900/30 hover:border-red-500/50 hover:bg-zinc-900/80 transition-all duration-300 flex items-center gap-4"
                      >
                        <div className="w-16 h-16 rounded-lg overflow-hidden bg-zinc-950">
                          <ImageWithFallback
                            src={product.image}
                            alt={product.name}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div className="flex-1 text-left">
                          <p className="text-zinc-100">{product.name}</p>
                          {product.price && (
                            <p className="text-red-400">₹{product.price.toLocaleString()}</p>
                          )}
                        </div>
                      </button>
                    ))}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* AI Remix Section */}
            {currentPost.isAiGenerated && currentPost.prompt && (
              <div className="px-6 pb-6">
                <div className="p-4 rounded-xl bg-gradient-to-br from-red-950/40 to-rose-950/40 border border-red-800/30">
                  <p className="text-xs text-red-400/70 mb-2">Prompt</p>
                  <p className="text-sm text-zinc-300 mb-4">"{currentPost.prompt}"</p>
                  <button
                    onClick={() => onRemix?.(currentPost.prompt!)}
                    className="w-full py-3 px-4 rounded-lg bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-500 hover:to-rose-500 text-white transition-all duration-300 flex items-center justify-center gap-2"
                  >
                    <Sparkles className="w-5 h-5" />
                    Remix this creation
                  </button>
                </div>
              </div>
            )}
          </div>
        </motion.div>
      </AnimatePresence>
    </motion.div>
  );
};