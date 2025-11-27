import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Heart, MessageCircle, Share2, Volume2, VolumeX, ShoppingBag, Play, Pause } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface ReelData {
  id: string;
  username: string;
  userAvatar: string;
  thumbnail: string;
  videoUrl?: string;
  likes: number;
  comments: number;
  caption: string;
  isLiked: boolean;
  products?: Array<{
    id: string;
    name: string;
    price: number;
  }>;
  hashtags?: string[];
}

interface NewSpotlightProps {
  onProductClick: (productId: string) => void;
  theme?: 'dark' | 'light';
}

const MOCK_REELS: ReelData[] = [
  {
    id: '1',
    username: 'fashionista',
    userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
    thumbnail: 'https://images.unsplash.com/photo-1719518411339-5158cea86caf?w=1080',
    likes: 45720,
    comments: 892,
    caption: 'Summer collection is here! ☀️',
    isLiked: false,
    hashtags: ['summer', 'fashion', 'ootd'],
    products: [
      { id: 'p1', name: 'Flowy Maxi Dress', price: 24999 },
      { id: 'p2', name: 'Gold Sandals', price: 8999 },
    ],
  },
  {
    id: '2',
    username: 'glam.guru',
    userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
    thumbnail: 'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=1080',
    likes: 38942,
    comments: 654,
    caption: 'Accessorize like a pro 💎',
    isLiked: true,
    hashtags: ['jewelry', 'accessories', 'style'],
    products: [
      { id: 'p3', name: 'Diamond Necklace', price: 67999 },
    ],
  },
  {
    id: '3',
    username: 'style.icon',
    userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
    thumbnail: 'https://images.unsplash.com/photo-1563418754681-55ab8367b1c0?w=1080',
    likes: 52183,
    comments: 1204,
    caption: 'Transition from day to night effortlessly ✨',
    isLiked: false,
    hashtags: ['daytonight', 'fashion', 'style'],
    products: [
      { id: 'p4', name: 'Convertible Dress', price: 19999 },
      { id: 'p5', name: 'Statement Clutch', price: 12999 },
    ],
  },
  {
    id: '4',
    username: 'luxury.lane',
    userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100',
    thumbnail: 'https://images.unsplash.com/photo-1722340321190-1c7b7384e89b?w=1080',
    likes: 61247,
    comments: 1532,
    caption: 'Invest in timeless pieces 💫',
    isLiked: true,
    hashtags: ['luxury', 'investment', 'timeless'],
    products: [
      { id: 'p6', name: 'Luxury Watch', price: 145999 },
    ],
  },
  {
    id: '5',
    username: 'trendsetter',
    userAvatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=100',
    thumbnail: 'https://images.unsplash.com/photo-1654707636005-5b5a96c11ab2?w=1080',
    likes: 43892,
    comments: 987,
    caption: 'Setting trends, not following them 🔥',
    isLiked: false,
    hashtags: ['trendsetter', 'fashion', 'style'],
    products: [
      { id: 'p7', name: 'Designer Jacket', price: 34999 },
      { id: 'p8', name: 'Leather Boots', price: 18999 },
    ],
  },
];

export function NewSpotlight({ onProductClick, theme = 'light' }: NewSpotlightProps) {
  const [reels, setReels] = useState(MOCK_REELS);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isMuted, setIsMuted] = useState(true);
  const [isPaused, setIsPaused] = useState(false);
  const [showProducts, setShowProducts] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const handleScroll = () => {
      const scrollTop = container.scrollTop;
      const viewportHeight = window.innerHeight;
      const newIndex = Math.round(scrollTop / viewportHeight);
      if (newIndex !== currentIndex) {
        setCurrentIndex(newIndex);
        setShowProducts(false);
      }
    };

    container.addEventListener('scroll', handleScroll);
    return () => container.removeEventListener('scroll', handleScroll);
  }, [currentIndex]);

  const handleLike = (reelId: string) => {
    setReels(
      reels.map((reel) =>
        reel.id === reelId
          ? {
              ...reel,
              isLiked: !reel.isLiked,
              likes: reel.isLiked ? reel.likes - 1 : reel.likes + 1,
            }
          : reel
      )
    );
  };

  const handleDoubleTap = (reelId: string, e: React.MouseEvent) => {
    const reel = reels.find((r) => r.id === reelId);
    if (reel && !reel.isLiked) {
      handleLike(reelId);
      
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
    <div
      ref={containerRef}
      className="fixed inset-0 bg-black overflow-y-scroll snap-y snap-mandatory"
      style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
    >
      {reels.map((reel, index) => (
        <div
          key={reel.id}
          className="relative h-screen w-full snap-start flex items-center justify-center"
        >
          {/* Video/Image */}
          <div
            className="absolute inset-0"
            onDoubleClick={(e) => handleDoubleTap(reel.id, e)}
          >
            <ImageWithFallback
              src={reel.thumbnail}
              alt={reel.caption}
              className="w-full h-full object-cover"
            />
            
            {/* Gradient overlays */}
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/20" />
          </div>

          {/* Top bar */}
          <div className="absolute top-0 left-0 right-0 p-4 flex items-center justify-between z-10">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full overflow-hidden ring-2 ring-white">
                <ImageWithFallback
                  src={reel.userAvatar}
                  alt={reel.username}
                  className="w-full h-full object-cover"
                />
              </div>
              <span className="text-white">{reel.username}</span>
              <button className="px-4 py-1 rounded-full border border-white text-white text-sm">
                Follow
              </button>
            </div>
            <button
              onClick={() => setIsMuted(!isMuted)}
              className="w-10 h-10 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center"
            >
              {isMuted ? (
                <VolumeX className="w-5 h-5 text-white" />
              ) : (
                <Volume2 className="w-5 h-5 text-white" />
              )}
            </button>
          </div>

          {/* Right side actions */}
          <div className="absolute right-4 bottom-24 flex flex-col items-center gap-6 z-10">
            <motion.button
              whileTap={{ scale: 0.9 }}
              onClick={() => handleLike(reel.id)}
              className="flex flex-col items-center gap-1"
            >
              <div className="w-12 h-12 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
                <Heart
                  className={`w-7 h-7 ${
                    reel.isLiked ? 'fill-[#401010] text-[#401010]' : 'text-white'
                  }`}
                />
              </div>
              <span className="text-white text-xs">{formatCount(reel.likes)}</span>
            </motion.button>

            <button className="flex flex-col items-center gap-1">
              <div className="w-12 h-12 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
                <MessageCircle className="w-7 h-7 text-white" />
              </div>
              <span className="text-white text-xs">{formatCount(reel.comments)}</span>
            </button>

            <button className="flex flex-col items-center gap-1">
              <div className="w-12 h-12 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
                <Share2 className="w-7 h-7 text-white" />
              </div>
            </button>

            {reel.products && reel.products.length > 0 && (
              <button
                onClick={() => setShowProducts(!showProducts)}
                className="flex flex-col items-center gap-1"
              >
                <div className="w-12 h-12 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
                  <ShoppingBag className="w-7 h-7 text-white" />
                </div>
              </button>
            )}
          </div>

          {/* Bottom caption */}
          <div className="absolute bottom-0 left-0 right-0 p-4 z-10">
            <p className="text-white mb-2">
              {reel.caption}{' '}
              {reel.hashtags?.map((tag) => (
                <span key={tag} className="text-white/80">
                  #{tag}{' '}
                </span>
              ))}
            </p>
          </div>

          {/* Products sheet */}
          <AnimatePresence>
            {showProducts && reel.products && (
              <motion.div
                initial={{ y: '100%' }}
                animate={{ y: 0 }}
                exit={{ y: '100%' }}
                transition={{ type: 'spring', damping: 30, stiffness: 300 }}
                className="absolute bottom-0 left-0 right-0 bg-white rounded-t-3xl p-5 z-20 max-h-[60vh] overflow-y-auto"
              >
                <div className="w-12 h-1 bg-black/10 rounded-full mx-auto mb-4" />
                <h3 className="text-black mb-4">Products in this video</h3>
                <div className="space-y-3">
                  {reel.products.map((product) => (
                    <button
                      key={product.id}
                      onClick={() => {
                        onProductClick(product.id);
                        setShowProducts(false);
                      }}
                      className="w-full flex items-center justify-between p-3 rounded-2xl bg-black/5 hover:bg-black/10 transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-xl bg-black/10 flex items-center justify-center">
                          <ShoppingBag className="w-6 h-6 text-black/40" />
                        </div>
                        <span className="text-black">{product.name}</span>
                      </div>
                      <span className="text-black">₹{product.price.toLocaleString()}</span>
                    </button>
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      ))}

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
      `}</style>
    </div>
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
