import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, Heart, ShoppingBag } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface Story {
  id: string;
  username: string;
  avatar: string;
  image: string;
  hasViewed: boolean;
  products?: Array<{
    id: string;
    name: string;
    price: number;
  }>;
}

interface StoriesProps {
  theme?: 'dark' | 'light';
  onProductClick?: (productId: string) => void;
}

const MOCK_STORIES: Story[] = [
  {
    id: '1',
    username: 'You',
    avatar: 'https://images.unsplash.com/photo-1620818563803-e24c9325c7ae?w=100',
    image: '',
    hasViewed: false,
  },
  {
    id: '2',
    username: 'fashionista',
    avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
    image: 'https://images.unsplash.com/photo-1719518411339-5158cea86caf?w=1080',
    hasViewed: false,
    products: [
      { id: 'p1', name: 'Silk Dress', price: 24999 },
      { id: 'p2', name: 'Gold Necklace', price: 8999 },
    ],
  },
  {
    id: '3',
    username: 'luxestyle',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
    image: 'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=1080',
    hasViewed: true,
    products: [
      { id: 'p3', name: 'Diamond Ring', price: 45999 },
    ],
  },
  {
    id: '4',
    username: 'minimal.chic',
    avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
    image: 'https://images.unsplash.com/photo-1563418754681-55ab8367b1c0?w=1080',
    hasViewed: false,
    products: [
      { id: 'p4', name: 'Designer Handbag', price: 34999 },
    ],
  },
  {
    id: '5',
    username: 'jewelrybox',
    avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100',
    image: 'https://images.unsplash.com/photo-1722340321190-1c7b7384e89b?w=1080',
    hasViewed: false,
    products: [
      { id: 'p5', name: 'Pearl Earrings', price: 6999 },
    ],
  },
  {
    id: '6',
    username: 'glamour.daily',
    avatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=100',
    image: 'https://images.unsplash.com/photo-1654707636005-5b5a96c11ab2?w=1080',
    hasViewed: true,
    products: [
      { id: 'p6', name: 'Luxury Watch', price: 89999 },
    ],
  },
];

export function Stories({ theme = 'light', onProductClick }: StoriesProps) {
  const [selectedStory, setSelectedStory] = useState<number | null>(null);
  const [progress, setProgress] = useState(0);

  const handleStoryClick = (index: number) => {
    if (MOCK_STORIES[index].id === '1') {
      // Handle "Add Your Story" action
      return;
    }
    setSelectedStory(index);
    setProgress(0);

    // Auto-advance story after 5 seconds
    const timer = setTimeout(() => {
      if (index < MOCK_STORIES.length - 1) {
        setSelectedStory(index + 1);
        setProgress(0);
      } else {
        setSelectedStory(null);
      }
    }, 5000);

    return () => clearTimeout(timer);
  };

  const handleClose = () => {
    setSelectedStory(null);
    setProgress(0);
  };

  const handlePrevious = () => {
    if (selectedStory !== null && selectedStory > 0) {
      setSelectedStory(selectedStory - 1);
      setProgress(0);
    }
  };

  const handleNext = () => {
    if (selectedStory !== null && selectedStory < MOCK_STORIES.length - 1) {
      setSelectedStory(selectedStory + 1);
      setProgress(0);
    } else {
      handleClose();
    }
  };

  return (
    <>
      {/* Stories Bar */}
      <div className="overflow-x-auto scrollbar-hide bg-[#fffff0] border-b border-black/5">
        <div className="flex gap-4 px-5 py-4">
          {MOCK_STORIES.map((story, index) => (
            <button
              key={story.id}
              onClick={() => handleStoryClick(index)}
              className="flex-shrink-0 flex flex-col items-center gap-1.5"
            >
              <div className="relative">
                {/* Gradient border for unviewed stories */}
                {!story.hasViewed && story.id !== '1' && (
                  <div
                    className="absolute -inset-0.5 rounded-full"
                    style={{
                      background: 'linear-gradient(45deg, #401010, #801020, #401010)',
                    }}
                  />
                )}
                
                {/* Avatar container */}
                <div className={`relative w-16 h-16 rounded-full overflow-hidden ${
                  story.hasViewed || story.id === '1' ? 'ring-2 ring-black/10' : 'ring-2 ring-[#fffff0]'
                }`}>
                  {story.id === '1' ? (
                    <div className="w-full h-full bg-gradient-to-br from-black/5 to-black/10 flex items-center justify-center">
                      <div className="w-8 h-8 rounded-full bg-[#401010] flex items-center justify-center">
                        <span className="text-white text-xl">+</span>
                      </div>
                    </div>
                  ) : (
                    <ImageWithFallback
                      src={story.avatar}
                      alt={story.username}
                      className="w-full h-full object-cover"
                    />
                  )}
                </div>
              </div>
              
              {/* Username */}
              <span className="text-xs text-black/70 max-w-[64px] truncate">
                {story.username}
              </span>
            </button>
          ))}
        </div>
        
        <style>{`
          .scrollbar-hide::-webkit-scrollbar {
            display: none;
          }
          .scrollbar-hide {
            -ms-overflow-style: none;
            scrollbar-width: none;
          }
        `}</style>
      </div>

      {/* Full Screen Story Viewer */}
      <AnimatePresence>
        {selectedStory !== null && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black z-[100] flex items-center justify-center"
            onClick={handleClose}
          >
            <div className="relative w-full h-full max-w-md mx-auto" onClick={(e) => e.stopPropagation()}>
              {/* Progress bars */}
              <div className="absolute top-0 left-0 right-0 z-20 flex gap-1 p-2">
                {MOCK_STORIES.map((_, index) => (
                  <div
                    key={index}
                    className="flex-1 h-0.5 bg-white/30 rounded-full overflow-hidden"
                  >
                    {index < selectedStory && (
                      <div className="h-full bg-white" />
                    )}
                    {index === selectedStory && (
                      <motion.div
                        className="h-full bg-white"
                        initial={{ width: '0%' }}
                        animate={{ width: '100%' }}
                        transition={{ duration: 5, ease: 'linear' }}
                        onAnimationComplete={handleNext}
                      />
                    )}
                  </div>
                ))}
              </div>

              {/* Header */}
              <div className="absolute top-4 left-0 right-0 z-20 flex items-center justify-between px-4 mt-4">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-full overflow-hidden ring-2 ring-white">
                    <ImageWithFallback
                      src={MOCK_STORIES[selectedStory].avatar}
                      alt={MOCK_STORIES[selectedStory].username}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <span className="text-white text-sm">{MOCK_STORIES[selectedStory].username}</span>
                  <span className="text-white/60 text-xs">2h</span>
                </div>
                
                <button
                  onClick={handleClose}
                  className="w-8 h-8 flex items-center justify-center rounded-full bg-black/30 backdrop-blur-sm"
                >
                  <X className="w-5 h-5 text-white" />
                </button>
              </div>

              {/* Story Image */}
              <div className="w-full h-full">
                <ImageWithFallback
                  src={MOCK_STORIES[selectedStory].image}
                  alt="Story"
                  className="w-full h-full object-cover"
                />
              </div>

              {/* Tap zones for navigation */}
              <div className="absolute inset-0 flex">
                <div className="flex-1" onClick={handlePrevious} />
                <div className="flex-1" onClick={handleNext} />
              </div>

              {/* Products overlay */}
              {MOCK_STORIES[selectedStory].products && (
                <div className="absolute bottom-20 left-0 right-0 z-20 px-4">
                  <div className="bg-black/60 backdrop-blur-md rounded-2xl p-3 space-y-2">
                    {MOCK_STORIES[selectedStory].products?.map((product) => (
                      <button
                        key={product.id}
                        onClick={() => onProductClick?.(product.id)}
                        className="w-full flex items-center justify-between p-2 rounded-xl bg-white/10 hover:bg-white/20 transition-colors"
                      >
                        <div className="flex items-center gap-2">
                          <ShoppingBag className="w-4 h-4 text-white" />
                          <span className="text-white text-sm">{product.name}</span>
                        </div>
                        <span className="text-white">₹{product.price.toLocaleString()}</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Bottom actions */}
              <div className="absolute bottom-6 left-0 right-0 z-20 flex items-center justify-center gap-4 px-4">
                <button className="flex items-center gap-2 px-4 py-2 rounded-full bg-white/20 backdrop-blur-sm">
                  <Heart className="w-5 h-5 text-white" />
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
