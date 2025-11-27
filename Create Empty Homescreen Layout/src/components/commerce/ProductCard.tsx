import { motion } from 'motion/react';
import { Heart, ShoppingBag, Star } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface ProductCardProps {
  product: {
    id: string;
    name: string;
    price: string;
    originalPrice?: string;
    image: string;
    rating?: number;
    badge?: string;
    views?: number;
    rank?: number;
  };
  theme?: 'dark' | 'light';
  index?: number;
  variant?: 'default' | 'trending' | 'compact' | 'grid';
  onClick?: (productId: string) => void;
}

export function ProductCard({ product, theme = 'dark', index = 0, variant = 'default', onClick }: ProductCardProps) {
  // Generate random review count for demo
  const reviewCount = Math.floor(Math.random() * 500) + 50;

  if (variant === 'compact') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: index * 0.05, duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
        onClick={() => onClick?.(product.id)}
        className="group cursor-pointer"
      >
        <div className={`overflow-hidden transition-all duration-500 rounded-xl ${
          theme === 'dark'
            ? 'bg-white/[0.02] hover:bg-white/[0.04]'
            : 'bg-black/[0.02] hover:bg-black/[0.04]'
        }`}>
          <div className="relative aspect-square overflow-hidden rounded-t-xl">
            <ImageWithFallback
              src={product.image}
              alt={product.name}
              className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
            />
            
            {/* Badge - Compact & Sleek */}
            {product.badge && (
              <div className={`absolute top-1.5 left-1.5 px-1.5 py-0.5 text-[8px] tracking-wider uppercase backdrop-blur-md shadow-lg rounded ${
                product.badge === 'Bestseller' ? 'bg-emerald-500/90 text-white' :
                product.badge === 'New' ? 'bg-blue-500/90 text-white' :
                product.badge === 'Trending' ? 'bg-pink-500/90 text-white' :
                product.badge === 'For You' ? 'bg-purple-500/90 text-white' :
                theme === 'dark'
                  ? 'bg-black/60 text-white'
                  : 'bg-white/80 text-black'
              }`}>
                {product.badge}
              </div>
            )}

            {/* Rating on Image - Bottom Left */}
            {product.rating && (
              <div className="absolute bottom-1.5 left-1.5 flex items-center gap-0.5 px-1.5 py-0.5 backdrop-blur-md bg-black/50 text-white text-[9px] rounded">
                <Star className="w-2.5 h-2.5 fill-yellow-400 text-yellow-400" />
                <span>{product.rating}</span>
                <span className="text-white/60">({reviewCount})</span>
              </div>
            )}
            
            <motion.button
              whileTap={{ scale: 0.9 }}
              onClick={(e) => {
                e.stopPropagation();
              }}
              className={`absolute top-1.5 right-1.5 p-1 backdrop-blur-md transition-all duration-300 rounded-full ${
                theme === 'dark'
                  ? 'bg-black/40 hover:bg-black/60 text-white'
                  : 'bg-white/60 hover:bg-white/80 text-black'
              }`}
            >
              <Heart className="w-3 h-3" />
            </motion.button>
          </div>
          <div className="p-2 space-y-1.5">
            <h4 className={`text-[11px] line-clamp-2 leading-tight ${
              theme === 'dark' ? 'text-white/90' : 'text-black/90'
            }`}>
              {product.name}
            </h4>
            <div className="flex items-baseline gap-1.5">
              <span className={`text-[13px] ${
                theme === 'dark' ? 'text-white' : 'text-black'
              }`}>
                {product.price}
              </span>
              {product.originalPrice && (
                <span className={`text-[10px] line-through ${
                  theme === 'dark' ? 'text-white/30' : 'text-black/30'
                }`}>
                  {product.originalPrice}
                </span>
              )}
            </div>
          </div>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1, duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
      className="group cursor-pointer"
    >
      <div className={`overflow-hidden transition-all duration-500 rounded-xl ${
        theme === 'dark'
          ? 'bg-white/[0.02] hover:bg-white/[0.04]'
          : 'bg-black/[0.02] hover:bg-black/[0.04]'
      }`}>
        {/* Image */}
        <div 
          onClick={() => onClick?.(product.id)}
          className="relative aspect-square overflow-hidden rounded-t-xl"
        >
          <ImageWithFallback
            src={product.image}
            alt={product.name}
            className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
          />
          
          {/* Badge - Compact & Sleek */}
          {product.badge && (
            <div className={`absolute top-2 left-2 px-2 py-0.5 text-[9px] tracking-wider uppercase backdrop-blur-md shadow-lg rounded ${
              product.badge === 'Bestseller' ? 'bg-emerald-500/90 text-white' :
              product.badge === 'New' ? 'bg-blue-500/90 text-white' :
              product.badge === 'Trending' ? 'bg-pink-500/90 text-white' :
              product.badge === 'For You' ? 'bg-purple-500/90 text-white' :
              product.badge === 'Exclusive' ? 'bg-amber-500/90 text-white' :
              theme === 'dark'
                ? 'bg-black/60 text-white'
                : 'bg-white/80 text-black'
            }`}>
              {product.badge}
            </div>
          )}

          {/* Rating on Image - Bottom Left */}
          {product.rating && (
            <div className="absolute bottom-1.5 left-1.5 flex items-center gap-0.5 px-1.5 py-0.5 backdrop-blur-md bg-black/50 text-white text-[9px] rounded">
              <Star className="w-2.5 h-2.5 fill-yellow-400 text-yellow-400" />
              <span>{product.rating}</span>
              <span className="text-white/60">({reviewCount})</span>
            </div>
          )}
          
          {/* Wishlist button */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={(e) => {
              e.stopPropagation();
            }}
            className={`absolute top-1.5 right-1.5 p-1 backdrop-blur-md transition-all duration-300 rounded-full ${
              theme === 'dark'
                ? 'bg-black/40 hover:bg-black/60 text-white'
                : 'bg-white/60 hover:bg-white/80 text-black'
            }`}
          >
            <Heart className="w-3 h-3" />
          </motion.button>
        </div>
        
        {/* Details */}
        <div className="p-2 space-y-1.5">
          <div 
            onClick={() => onClick?.(product.id)}
            className="space-y-1"
          >
            <h4 className={`text-[11px] line-clamp-2 leading-tight min-h-[2rem] ${
              theme === 'dark' ? 'text-white/90' : 'text-black/90'
            }`}>
              {product.name}
            </h4>
            
            <div className="flex items-baseline gap-1.5 pt-0.5">
              <span className={`text-[13px] ${
                theme === 'dark' ? 'text-white' : 'text-black'
              }`}>
                {product.price}
              </span>
              {product.originalPrice && (
                <>
                  <span className={`text-[10px] line-through ${
                    theme === 'dark' ? 'text-white/30' : 'text-black/30'
                  }`}>
                    {product.originalPrice}
                  </span>
                  <span className="text-[9px] text-emerald-500">
                    {(() => {
                      const originalPrice = typeof product.originalPrice === 'string' 
                        ? parseFloat(product.originalPrice.replace(/[^0-9.]/g, ''))
                        : product.originalPrice;
                      const currentPrice = typeof product.price === 'string'
                        ? parseFloat(product.price.replace(/[^0-9.]/g, ''))
                        : product.price;
                      return Math.round(((originalPrice - currentPrice) / originalPrice) * 100);
                    })()}% OFF
                  </span>
                </>
              )}
            </div>
          </div>
          
          {/* Add to Bag Button - Full Width */}
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={(e) => {
              e.stopPropagation();
              // Handle add to bag
            }}
            className={`w-full flex items-center justify-center gap-1.5 py-2 text-[10px] uppercase tracking-wider transition-all duration-300 ${
              theme === 'dark'
                ? 'bg-white/5 hover:bg-emerald-500/20 border border-white/10 hover:border-emerald-500/50 text-white/80 hover:text-emerald-400'
                : 'bg-black/5 hover:bg-emerald-50 border border-black/10 hover:border-emerald-400 text-black/80 hover:text-emerald-600'
            }`}
          >
            <ShoppingBag className="w-3 h-3" />
            <span>Add to Bag</span>
          </motion.button>
        </div>
      </div>
    </motion.div>
  );
}
