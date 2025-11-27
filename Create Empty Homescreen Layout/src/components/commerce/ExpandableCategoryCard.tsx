import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronRight, ChevronDown } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface CategoryItem {
  id: string;
  name: string;
  image?: string;
  count?: number;
}

interface PriceRangeItem {
  id: string;
  label: string;
}

interface CategoryCardProps {
  id: string;
  name: string;
  image: string;
  theme?: 'dark' | 'light';
  imageBackgroundColor?: string;
  styleItems?: CategoryItem[];
  priceRanges?: PriceRangeItem[];
  onItemClick?: (itemId: string) => void;
  isExpanded?: boolean;
  onToggle?: () => void;
  hasContent?: boolean;
  renderPanelOnly?: boolean;
  expandedCardColumn?: number; // 0 for left column, 1 for right column
}

export function ExpandableCategoryCard({
  id,
  name,
  image,
  theme = 'dark',
  imageBackgroundColor,
  styleItems = [],
  priceRanges = [],
  onItemClick,
  isExpanded = false,
  onToggle,
  hasContent: hasContentProp,
  renderPanelOnly = false,
  expandedCardColumn = 0,
}: CategoryCardProps) {
  const [activeTab, setActiveTab] = useState<'style' | 'price'>('price');

  const hasContent = hasContentProp ?? (styleItems.length > 0 || priceRanges.length > 0);
  const currentItems = activeTab === 'style' ? styleItems : [];
  const showPriceRanges = activeTab === 'price' && priceRanges.length > 0;

  // If renderPanelOnly, only render the expansion panel
  if (renderPanelOnly) {
    return (
      <AnimatePresence>
        {isExpanded && hasContent && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3, ease: [0.32, 0.72, 0, 1] }}
            className="overflow-hidden mt-2"
          >
            {/* Triangular pointer */}
            <div className={`relative w-full h-2 ${expandedCardColumn === 0 ? 'pl-[25%]' : 'pl-[75%]'}`}>
              <div 
                className={`absolute w-0 h-0 border-l-[8px] border-r-[8px] border-b-[8px] border-l-transparent border-r-transparent ${
                  theme === 'dark' ? 'border-b-white/[0.08]' : 'border-b-black/5'
                }`}
                style={{ transform: 'translateX(-50%)' }}
              />
            </div>

            <div
              className={`p-3 backdrop-blur-xl ${
                theme === 'dark'
                  ? 'bg-white/[0.02] border border-white/[0.08]'
                  : 'bg-white border border-black/5'
              }`}
              style={{ borderRadius: '16px' }}
            >
              {/* Trending Section */}
              <h4 className={`text-xs mb-2 ${
                theme === 'dark' ? 'text-white/60' : 'text-black/60'
              }`}>
                Trending
              </h4>

              {/* Horizontal Product Carousel */}
              <div className="mb-3 -mx-3 px-3 overflow-x-auto no-scrollbar">
                <div className="flex gap-2.5 pb-1">
                  {[
                    { id: '1', name: 'Diamond Ring', price: '₹45,000', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=400' },
                    { id: '2', name: 'Gold Necklace', price: '₹32,000', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=400' },
                    { id: '3', name: 'Pearl Earrings', price: '₹18,500', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400' },
                    { id: '4', name: 'Silver Bracelet', price: '₹12,000', image: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=400' },
                    { id: '5', name: 'Gemstone Ring', price: '₹28,000', image: 'https://images.unsplash.com/photo-1603561596112-0a132b757442?w=400' },
                  ].map((product, index) => (
                    <motion.button
                      key={product.id}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ duration: 0.3, delay: index * 0.05 }}
                      onClick={(e) => {
                        e.stopPropagation();
                        onItemClick?.(product.id);
                      }}
                      whileTap={{ scale: 0.97 }}
                      className="flex-shrink-0 w-[90px]"
                    >
                      <div className={`overflow-hidden transition-all duration-300 rounded-xl border ${
                        theme === 'dark' 
                          ? 'bg-white/[0.02] border-white/[0.05] hover:bg-white/[0.04] hover:border-white/[0.08]' 
                          : 'bg-white border-black/5 hover:border-black/10'
                      }`}>
                        <div className="relative aspect-square overflow-hidden rounded-t-xl">
                          <ImageWithFallback
                            src={product.image}
                            alt={product.name}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div className="p-1.5 space-y-0.5">
                          <p className={`text-[9px] line-clamp-1 ${
                            theme === 'dark' ? 'text-white/80' : 'text-black/80'
                          }`}>
                            {product.name}
                          </p>
                          <p className={`text-[10px] ${
                            theme === 'dark' ? 'text-white/60' : 'text-black/60'
                          }`}>
                            {product.price}
                          </p>
                        </div>
                      </div>
                    </motion.button>
                  ))}
                </div>
              </div>

              {/* Segmented Control */}
              {styleItems.length > 0 && priceRanges.length > 0 && (
                <div className={`flex gap-1 mb-3 p-1 ${
                  theme === 'dark'
                    ? 'bg-white/[0.03]'
                    : 'bg-black/[0.02]'
                }`} style={{ borderRadius: '10px' }}>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setActiveTab('style');
                    }}
                    className={`flex-1 py-2 px-2 text-[11px] transition-all duration-300 ${
                      activeTab === 'style'
                        ? 'bg-[#094010] text-white'
                        : theme === 'dark'
                          ? 'text-white/60 hover:text-white/80'
                          : 'text-black/60 hover:text-black/80'
                    }`}
                    style={{ borderRadius: '8px' }}
                  >
                    Shop By Style
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setActiveTab('price');
                    }}
                    className={`flex-1 py-2 px-2 text-[11px] transition-all duration-300 ${
                      activeTab === 'price'
                        ? 'bg-[#094010] text-white'
                        : theme === 'dark'
                          ? 'text-white/60 hover:text-white/80'
                          : 'text-black/60 hover:text-black/80'
                    }`}
                    style={{ borderRadius: '8px' }}
                  >
                    Shop By Price ( ₹ )
                  </button>
                </div>
              )}

              {/* Price Ranges Grid */}
              {showPriceRanges && (
                <div className="grid grid-cols-3 gap-2">
                  {priceRanges.map((range, index) => (
                    <motion.button
                      key={range.id}
                      initial={{ opacity: 0, scale: 0.9 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ duration: 0.2, delay: index * 0.03 }}
                      onClick={(e) => {
                        e.stopPropagation();
                        onItemClick?.(range.id);
                      }}
                      whileTap={{ scale: 0.97 }}
                      className={`py-2.5 px-2 text-center border transition-colors duration-200 ${
                        theme === 'dark' 
                          ? 'bg-white/[0.02] border-white/[0.05] hover:bg-white/[0.04] hover:border-white/[0.08]' 
                          : 'bg-white border-black/5 hover:border-black/10'
                      }`}
                      style={{ borderRadius: '10px' }}
                    >
                      <p className={`text-[10.5px] ${
                        theme === 'dark' ? 'text-white/90' : 'text-black/80'
                      }`}>
                        {range.label}
                      </p>
                    </motion.button>
                  ))}
                </div>
              )}

              {/* Style Items Grid */}
              {activeTab === 'style' && currentItems.length > 0 && (
                <div className="grid grid-cols-4 gap-3">
                  {currentItems.map((item, index) => (
                    <motion.button
                      key={item.id}
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ duration: 0.3, delay: index * 0.05 }}
                      onClick={(e) => {
                        e.stopPropagation();
                        onItemClick?.(item.id);
                      }}
                      whileTap={{ scale: 0.95 }}
                      className="flex flex-col items-center gap-1.5"
                    >
                      {/* Item Image */}
                      {item.image && (
                        <div
                          className={`w-14 h-14 flex items-center justify-center overflow-hidden rounded-xl border ${
                            theme === 'dark' 
                              ? 'bg-white/[0.02] border-white/[0.05]' 
                              : 'bg-white border-black/5'
                          }`}
                        >
                          <ImageWithFallback
                            src={item.image}
                            alt={item.name}
                            className="w-full h-full object-cover"
                          />
                        </div>
                      )}

                      {/* Item Name */}
                      <div className="text-center">
                        <p className={`text-[9px] leading-tight ${
                          theme === 'dark' ? 'text-white/80' : 'text-black/80'
                        }`}>
                          {item.name}
                        </p>
                        {item.count !== undefined && (
                          <p className={`text-[8px] ${
                            theme === 'dark' ? 'text-white/50' : 'text-black/50'
                          }`}>
                            {item.count} items
                          </p>
                        )}
                      </div>
                    </motion.button>
                  ))}
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    );
  }

  // Regular card rendering
  return (
    <motion.button
      onClick={() => hasContent && onToggle?.()}
      whileTap={{ scale: hasContent ? 0.98 : 1 }}
      className={`w-full flex items-center gap-2.5 px-3 py-2.5 transition-all duration-300 ${ 
        theme === 'dark'
          ? isExpanded
            ? 'bg-white/[0.04] border-2 border-white/[0.12]'
            : 'bg-white/[0.02] hover:bg-white/[0.04] border border-white/[0.05]'
          : isExpanded
            ? 'bg-black/[0.02] border-2 border-black/10'
            : 'bg-white hover:bg-black/[0.01] border border-black/5'
      }`}
      style={{ borderRadius: '14px' }}
    >
      {/* Category Image */}
      <div 
        className={`flex-shrink-0 w-10 h-10 flex items-center justify-center overflow-hidden`}
        style={{ 
          borderRadius: '50%',
          backgroundColor: imageBackgroundColor || (theme === 'dark' ? 'rgba(255,255,255,0.03)' : '#f8f8f8')
        }}
      >
        <ImageWithFallback
          src={image}
          alt={name}
          className="w-7 h-7 object-contain"
        />
      </div>

      {/* Category Name */}
      <div className="flex-1 text-left">
        <h4 className={`text-xs leading-[1.3] transition-colors duration-300 ${
          theme === 'dark'
            ? isExpanded ? 'text-white' : 'text-white/90'
            : isExpanded ? 'text-black' : 'text-black/80'
        }`}>
          {name}
        </h4>
      </div>

      {/* Chevron */}
      {hasContent && (
        <motion.div
          animate={{ rotate: isExpanded ? 0 : 0 }}
          transition={{ duration: 0.3 }}
          className={`flex-shrink-0 ${
            theme === 'dark'
              ? isExpanded ? 'text-white/80' : 'text-white/40'
              : isExpanded ? 'text-black/80' : 'text-black/40'
          }`}
        >
          {isExpanded ? (
            <ChevronDown className="w-4 h-4" />
          ) : (
            <ChevronRight className="w-4 h-4" />
          )}
        </motion.div>
      )}
    </motion.button>
  );
}
