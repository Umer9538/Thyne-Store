import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, Heart, Share2, ShoppingBag, ChevronDown, Star, Package, Truck, Shield, ArrowLeft, MapPin, RotateCcw, Sparkles, Camera, Upload } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { ProductCard } from './commerce/ProductCard';
import { FullScreenPost } from './community/FullScreenPost';
import { FeedPostData } from './community/FeedPost';
import Masonry from 'react-responsive-masonry';

export interface Review {
  id: string;
  username: string;
  userAvatar: string;
  rating: number;
  comment: string;
  timeAgo: string;
  verified: boolean;
  media?: string[];
  helpful: number;
}

export interface ProductDetailData {
  id: string;
  name: string;
  price: number;
  originalPrice?: number;
  images: string[];
  description: string;
  rating?: number;
  reviewCount?: number;
  badge?: string;
  sizes?: string[];
  colors?: Array<{ name: string; hex: string }>;
  details: {
    material?: string;
    care?: string;
    origin?: string;
    sku?: string;
    weight?: string;
    dimensions?: string;
  };
  features?: string[];
  inStock: boolean;
  deliveryInfo?: string;
  reviews?: Review[];
}

interface ProductDetailProps {
  product: ProductDetailData;
  theme?: 'dark' | 'light';
  onClose: () => void;
  onAddToBag?: (productId: string, size?: string, color?: string) => void;
  onAddToWishlist?: (productId: string) => void;
  similarProducts?: Array<{
    id: string;
    name: string;
    price: string;
    image: string;
  }>;
  onSimilarProductClick?: (productId: string) => void;
}

export const ProductDetail: React.FC<ProductDetailProps> = ({
  product,
  theme = 'dark',
  onClose,
  onAddToBag,
  onAddToWishlist,
  similarProducts = [],
  onSimilarProductClick,
}) => {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [selectedSize, setSelectedSize] = useState<string | null>(product.sizes?.[0] || null);
  const [selectedColor, setSelectedColor] = useState<string | null>(product.colors?.[0]?.name || null);
  const [isWishlisted, setIsWishlisted] = useState(false);
  const [expandedAccordion, setExpandedAccordion] = useState<string | null>('description');
  
  // Review states
  const [showWriteReview, setShowWriteReview] = useState(false);
  const [reviewRating, setReviewRating] = useState(0);
  const [reviewComment, setReviewComment] = useState('');
  const [reviewMedia, setReviewMedia] = useState<string[]>([]);
  const [fullScreenReviewIndex, setFullScreenReviewIndex] = useState<number | null>(null);
  const [hoverRating, setHoverRating] = useState(0);
  const [pincode, setPincode] = useState('');

  // Mock reviews with media
  const mockReviews: Review[] = product.reviews || [
    {
      id: 'r1',
      username: 'priya_sharma',
      userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      rating: 5,
      comment: 'Absolutely stunning! The quality exceeded my expectations. Perfect for special occasions.',
      timeAgo: '2 days ago',
      verified: true,
      media: [
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800',
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=800',
      ],
      helpful: 24,
    },
    {
      id: 'r2',
      username: 'fashionista_maya',
      userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      rating: 4,
      comment: 'Beautiful design and great craftsmanship. Slightly heavier than I expected but still love it!',
      timeAgo: '5 days ago',
      verified: true,
      media: [
        'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800',
      ],
      helpful: 18,
    },
    {
      id: 'r3',
      username: 'rohit_k',
      userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      rating: 5,
      comment: 'Bought this as a gift for my wife. She absolutely loves it! Great packaging too.',
      timeAgo: '1 week ago',
      verified: true,
      media: [
        'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=800',
        'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=800',
        'https://images.unsplash.com/photo-1603561591411-07134e71a2a9?w=800',
      ],
      helpful: 32,
    },
    {
      id: 'r4',
      username: 'neha_designs',
      userAvatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      rating: 5,
      comment: 'Perfect! Exactly as shown in the pictures. Fast delivery and excellent customer service.',
      timeAgo: '2 weeks ago',
      verified: true,
      media: [
        'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=800',
      ],
      helpful: 15,
    },
  ];

  // Get all review media for masonry grid
  const allReviewMedia = mockReviews.flatMap(review => 
    (review.media || []).map(mediaUrl => ({
      reviewId: review.id,
      mediaUrl,
      username: review.username,
      userAvatar: review.userAvatar,
      rating: review.rating,
      comment: review.comment,
      timeAgo: review.timeAgo,
    }))
  );

  // Convert reviews to FeedPostData format for FullScreenPost
  const reviewPostsData: FeedPostData[] = allReviewMedia.map((media, index) => ({
    id: `review-${index}`,
    username: media.username,
    userAvatar: media.userAvatar,
    timeAgo: media.timeAgo,
    mediaUrl: media.mediaUrl,
    likes: 0,
    comments: 0,
    caption: media.comment,
    isLiked: false,
    isSaved: false,
    products: [{
      id: product.id,
      name: product.name,
      image: product.images[0],
      price: product.price,
    }],
  }));

  const handleAddToBag = () => {
    if (onAddToBag) {
      onAddToBag(product.id, selectedSize || undefined, selectedColor || undefined);
    }
  };

  const handleToggleWishlist = () => {
    setIsWishlisted(!isWishlisted);
    if (onAddToWishlist && !isWishlisted) {
      onAddToWishlist(product.id);
    }
  };

  const handleSubmitReview = () => {
    if (reviewRating === 0) {
      alert('Please select a rating');
      return;
    }
    
    // In a real app, this would submit to a backend
    console.log('Review submitted:', {
      rating: reviewRating,
      comment: reviewComment,
      media: reviewMedia,
      productId: product.id,
    });
    
    // Reset form
    setReviewRating(0);
    setReviewComment('');
    setReviewMedia([]);
    setShowWriteReview(false);
    
    alert('Thank you for your review!');
  };

  const handleMediaClick = (index: number) => {
    setFullScreenReviewIndex(index);
  };

  const savingsPercent = product.originalPrice
    ? Math.round(((product.originalPrice - product.price) / product.originalPrice) * 100)
    : 0;

  const toggleAccordion = (section: string) => {
    setExpandedAccordion(expandedAccordion === section ? null : section);
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className={`fixed inset-0 z-50 overflow-y-auto ${
        theme === 'dark' ? 'bg-black' : 'bg-white'
      }`}
    >
      {/* Header - Minimal */}
      <div className={`sticky top-0 z-10 backdrop-blur-xl border-b ${
        theme === 'dark'
          ? 'bg-black/80 border-white/5'
          : 'bg-white/80 border-black/5'
      }`}>
        <div className="flex items-center justify-between px-4 py-3">
          <button
            onClick={onClose}
            className={`p-2 -ml-2 transition-colors ${
              theme === 'dark'
                ? 'hover:bg-white/5 text-white'
                : 'hover:bg-black/5 text-black'
            }`}
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div className="flex items-center gap-1">
            <button
              onClick={handleToggleWishlist}
              className={`p-2 transition-all duration-300 ${
                theme === 'dark'
                  ? 'hover:bg-white/5 text-white'
                  : 'hover:bg-black/5 text-black'
              }`}
            >
              <Heart
                className="w-5 h-5 transition-colors"
                style={isWishlisted ? { fill: '#401010', color: '#401010' } : {}}
              />
            </button>
            <button
              className={`p-2 transition-colors ${
                theme === 'dark'
                  ? 'hover:bg-white/5 text-white'
                  : 'hover:bg-black/5 text-black'
              }`}
            >
              <Share2 className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="pb-24">
        {/* Image Gallery with Thumbnails */}
        <div className="relative">
          {/* Main Image */}
          <div className="relative aspect-square bg-gradient-to-b from-white/[0.02] to-transparent">
            <ImageWithFallback
              src={product.images[currentImageIndex]}
              alt={product.name}
              className="w-full h-full object-cover"
            />
            
            {/* Badge on Image */}
            {product.badge && (
              <div className={`absolute top-3 left-3 px-2.5 py-1 text-[10px] tracking-wider uppercase backdrop-blur-md ${
                product.badge === 'New' ? 'text-white' :
                product.badge === 'Bestseller' ? 'text-white' :
                'bg-black/60 text-white'
              }`}
              style={
                product.badge === 'Bestseller' ? { background: 'rgba(9, 64, 16, 0.9)' } 
                : product.badge === 'New' ? { background: 'rgba(10, 26, 64, 0.9)' }
                : {}
              }>
                {product.badge}
              </div>
            )}
          </div>

          {/* Thumbnail Navigation */}
          {product.images.length > 1 && (
            <div className="px-4 py-3">
              <div className="flex gap-2 overflow-x-auto no-scrollbar">
                {product.images.map((image, index) => (
                  <button
                    key={index}
                    onClick={() => setCurrentImageIndex(index)}
                    className={`flex-shrink-0 w-16 h-16 border-2 transition-all ${
                      index === currentImageIndex
                        ? ''
                        : theme === 'dark'
                        ? 'border-white/10 hover:border-white/20'
                        : 'border-black/10 hover:border-black/20'
                    }`}
                    style={index === currentImageIndex ? { borderColor: '#094010' } : {}}
                  >
                    <ImageWithFallback
                      src={image}
                      alt={`${product.name} ${index + 1}`}
                      className="w-full h-full object-cover"
                    />
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Product Info */}
        <div className="px-4 space-y-4">
          {/* Title */}
          <div>
            <h1 className={`text-xl leading-tight mb-1 ${
              theme === 'dark' ? 'text-white' : 'text-black'
            }`}>
              {product.name}
            </h1>
            
            {/* Rating */}
            {product.rating && (
              <div className="flex items-center gap-2 mt-2">
                <div className={`flex items-center gap-1 px-2 py-0.5 ${
                  theme === 'dark' ? 'bg-white/5' : 'bg-black/5'
                }`}>
                  <Star className="w-3.5 h-3.5" style={{ fill: '#094010', color: '#094010' }} />
                  <span className={`text-sm ${theme === 'dark' ? 'text-white/90' : 'text-black/90'}`}>
                    {product.rating}
                  </span>
                </div>
                {product.reviewCount && (
                  <span className={`text-sm ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`}>
                    {product.reviewCount} reviews
                  </span>
                )}
              </div>
            )}
          </div>

          {/* Price */}
          <div className="flex items-center gap-2 pt-1">
            <span className={`text-2xl ${
              theme === 'dark' ? 'text-white' : 'text-black'
            }`}>
              ₹{product.price.toLocaleString('en-IN')}
            </span>
            {product.originalPrice && (
              <>
                <span className={`text-base line-through ${
                  theme === 'dark' ? 'text-white/30' : 'text-black/30'
                }`}>
                  ₹{product.originalPrice.toLocaleString('en-IN')}
                </span>
                <span className="text-xs px-2 py-0.5 border" style={{
                  background: 'rgba(9, 64, 16, 0.2)',
                  color: '#094010',
                  borderColor: 'rgba(9, 64, 16, 0.3)'
                }}>
                  {savingsPercent}% OFF
                </span>
              </>
            )}
          </div>

          {/* Tax Info */}
          <p className={`text-xs ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`}>
            Inclusive of all taxes
          </p>

          {/* Size Selector */}
          {product.sizes && product.sizes.length > 0 && (
            <div className="pt-2">
              <div className="flex items-center justify-between mb-3">
                <h3 className={`text-sm ${
                  theme === 'dark' ? 'text-white/80' : 'text-black/80'
                }`}>
                  Select Size
                </h3>
                <button className="text-xs hover:opacity-80" style={{ color: '#094010' }}>
                  Size Guide
                </button>
              </div>
              <div className="flex flex-wrap gap-2">
                {product.sizes.map((size) => (
                  <button
                    key={size}
                    onClick={() => setSelectedSize(size)}
                    className={`min-w-[60px] px-4 py-2.5 text-sm border transition-all ${
                      selectedSize === size
                        ? ''
                        : theme === 'dark'
                        ? 'border-white/10 text-white/70 hover:border-white/20'
                        : 'border-black/10 text-black/70 hover:border-black/20'
                    }`}
                    style={selectedSize === size ? {
                      borderColor: '#094010',
                      background: 'rgba(9, 64, 16, 0.1)',
                      color: '#094010'
                    } : {}}
                  >
                    {size}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Delivery Check */}
          <div className={`p-4 border ${
            theme === 'dark'
              ? 'bg-white/[0.02] border-white/5'
              : 'bg-black/[0.02] border-black/5'
          }`}>
            <div className="flex items-start gap-3">
              <MapPin className={`w-5 h-5 mt-0.5 flex-shrink-0 ${
                theme === 'dark' ? 'text-white/60' : 'text-black/60'
              }`} />
              <div className="flex-1">
                <div className="flex gap-2">
                  <input
                    type="text"
                    placeholder="Enter pincode"
                    value={pincode}
                    onChange={(e) => setPincode(e.target.value)}
                    className={`flex-1 px-3 py-2 text-sm border bg-transparent outline-none ${
                      theme === 'dark'
                        ? 'border-white/10 text-white placeholder-white/30'
                        : 'border-black/10 text-black placeholder-black/30'
                    }`}
                  />
                  <button className="px-4 py-2 text-sm border hover:opacity-80" style={{
                    color: '#094010',
                    borderColor: 'rgba(9, 64, 16, 0.3)',
                    background: 'transparent'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(9, 64, 16, 0.1)'}
                  onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}>
                    Check
                  </button>
                </div>
                <p className={`text-xs mt-2 ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`}>
                  Get delivery date & free pickup options
                </p>
              </div>
            </div>
          </div>

          {/* Trust Badges */}
          <div className={`grid grid-cols-3 gap-3 p-4 border ${
            theme === 'dark'
              ? 'bg-white/[0.02] border-white/5'
              : 'bg-black/[0.02] border-black/5'
          }`}>
            <div className="flex flex-col items-center text-center gap-1.5">
              <div className={`w-10 h-10 flex items-center justify-center border ${
                theme === 'dark' ? 'border-white/10' : 'border-black/10'
              }`}>
                <RotateCcw className="w-5 h-5" style={{ color: '#094010' }} />
              </div>
              <span className={`text-[10px] leading-tight ${
                theme === 'dark' ? 'text-white/60' : 'text-black/60'
              }`}>
                Easy Returns
              </span>
            </div>
            <div className="flex flex-col items-center text-center gap-1.5">
              <div className={`w-10 h-10 flex items-center justify-center border ${
                theme === 'dark' ? 'border-white/10' : 'border-black/10'
              }`}>
                <Truck className="w-5 h-5" style={{ color: '#094010' }} />
              </div>
              <span className={`text-[10px] leading-tight ${
                theme === 'dark' ? 'text-white/60' : 'text-black/60'
              }`}>
                Free Shipping
              </span>
            </div>
            <div className="flex flex-col items-center text-center gap-1.5">
              <div className={`w-10 h-10 flex items-center justify-center border ${
                theme === 'dark' ? 'border-white/10' : 'border-black/10'
              }`}>
                <Sparkles className="w-5 h-5" style={{ color: '#094010' }} />
              </div>
              <span className={`text-[10px] leading-tight ${
                theme === 'dark' ? 'text-white/60' : 'text-black/60'
              }`}>
                Certified
              </span>
            </div>
          </div>

          {/* Accordion Sections */}
          <div className="space-y-0 pt-2">
            {/* Product Details */}
            <div className={`border-t ${
              theme === 'dark' ? 'border-white/5' : 'border-black/5'
            }`}>
              <button
                onClick={() => toggleAccordion('details')}
                className={`w-full py-4 flex items-center justify-between ${
                  theme === 'dark' ? 'text-white' : 'text-black'
                }`}
              >
                <span className="text-sm">Product Details</span>
                <ChevronDown className={`w-4 h-4 transition-transform duration-300 ${
                  expandedAccordion === 'details' ? 'rotate-180' : ''
                } ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`} />
              </button>
              <AnimatePresence>
                {expandedAccordion === 'details' && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden"
                  >
                    <div className="pb-4 space-y-2">
                      {product.details.material && (
                        <div className="flex justify-between text-sm">
                          <span className={theme === 'dark' ? 'text-white/40' : 'text-black/40'}>
                            Material
                          </span>
                          <span className={theme === 'dark' ? 'text-white/80' : 'text-black/80'}>
                            {product.details.material}
                          </span>
                        </div>
                      )}
                      {product.details.weight && (
                        <div className="flex justify-between text-sm">
                          <span className={theme === 'dark' ? 'text-white/40' : 'text-black/40'}>
                            Weight
                          </span>
                          <span className={theme === 'dark' ? 'text-white/80' : 'text-black/80'}>
                            {product.details.weight}
                          </span>
                        </div>
                      )}
                      {product.details.dimensions && (
                        <div className="flex justify-between text-sm">
                          <span className={theme === 'dark' ? 'text-white/40' : 'text-black/40'}>
                            Dimensions
                          </span>
                          <span className={theme === 'dark' ? 'text-white/80' : 'text-black/80'}>
                            {product.details.dimensions}
                          </span>
                        </div>
                      )}
                      {product.details.sku && (
                        <div className="flex justify-between text-sm">
                          <span className={theme === 'dark' ? 'text-white/40' : 'text-black/40'}>
                            SKU
                          </span>
                          <span className={theme === 'dark' ? 'text-white/80' : 'text-black/80'}>
                            {product.details.sku}
                          </span>
                        </div>
                      )}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            {/* Description */}
            <div className={`border-t ${
              theme === 'dark' ? 'border-white/5' : 'border-black/5'
            }`}>
              <button
                onClick={() => toggleAccordion('description')}
                className={`w-full py-4 flex items-center justify-between ${
                  theme === 'dark' ? 'text-white' : 'text-black'
                }`}
              >
                <span className="text-sm">Description</span>
                <ChevronDown className={`w-4 h-4 transition-transform duration-300 ${
                  expandedAccordion === 'description' ? 'rotate-180' : ''
                } ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`} />
              </button>
              <AnimatePresence>
                {expandedAccordion === 'description' && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden"
                  >
                    <div className={`pb-4 text-sm leading-relaxed ${
                      theme === 'dark' ? 'text-white/60' : 'text-black/60'
                    }`}>
                      {product.description}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            {/* Care Instructions */}
            {product.details.care && (
              <div className={`border-t ${
                theme === 'dark' ? 'border-white/5' : 'border-black/5'
              }`}>
                <button
                  onClick={() => toggleAccordion('care')}
                  className={`w-full py-4 flex items-center justify-between ${
                    theme === 'dark' ? 'text-white' : 'text-black'
                  }`}
                >
                  <span className="text-sm">Care Instructions</span>
                  <ChevronDown className={`w-4 h-4 transition-transform duration-300 ${
                    expandedAccordion === 'care' ? 'rotate-180' : ''
                  } ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`} />
                </button>
                <AnimatePresence>
                  {expandedAccordion === 'care' && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.2 }}
                      className="overflow-hidden"
                    >
                      <div className={`pb-4 text-sm leading-relaxed ${
                        theme === 'dark' ? 'text-white/60' : 'text-black/60'
                      }`}>
                        {product.details.care}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            )}

            {/* Delivery & Returns */}
            <div className={`border-t ${
              theme === 'dark' ? 'border-white/5' : 'border-black/5'
            }`}>
              <button
                onClick={() => toggleAccordion('delivery')}
                className={`w-full py-4 flex items-center justify-between ${
                  theme === 'dark' ? 'text-white' : 'text-black'
                }`}
              >
                <span className="text-sm">Delivery & Returns</span>
                <ChevronDown className={`w-4 h-4 transition-transform duration-300 ${
                  expandedAccordion === 'delivery' ? 'rotate-180' : ''
                } ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`} />
              </button>
              <AnimatePresence>
                {expandedAccordion === 'delivery' && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden"
                  >
                    <div className={`pb-4 text-sm leading-relaxed space-y-3 ${
                      theme === 'dark' ? 'text-white/60' : 'text-black/60'
                    }`}>
                      <div>
                        <p className={`mb-1 ${theme === 'dark' ? 'text-white/80' : 'text-black/80'}`}>
                          Free Delivery
                        </p>
                        <p>Get free delivery on all orders. Estimated delivery in 4-7 business days.</p>
                      </div>
                      <div>
                        <p className={`mb-1 ${theme === 'dark' ? 'text-white/80' : 'text-black/80'}`}>
                          Easy Returns
                        </p>
                        <p>Return within 7 days of delivery. Products must be in original condition with tags intact.</p>
                      </div>
                      {product.deliveryInfo && (
                        <div>
                          <p>{product.deliveryInfo}</p>
                        </div>
                      )}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            {/* Reviews Section */}
            <div className="pt-6 border-t border-white/5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <h3 className={`text-base ${
                    theme === 'dark' ? 'text-white' : 'text-black'
                  }`}>
                    Reviews
                  </h3>
                  {product.rating && (
                    <div className="flex items-center gap-1.5">
                      <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                      <span className={`text-sm ${
                        theme === 'dark' ? 'text-white/80' : 'text-black/80'
                      }`}>
                        {product.rating}
                      </span>
                      <span className={`text-xs ${
                        theme === 'dark' ? 'text-white/40' : 'text-black/40'
                      }`}>
                        ({mockReviews.length})
                      </span>
                    </div>
                  )}
                </div>
                <button
                  onClick={() => setShowWriteReview(!showWriteReview)}
                  className={`text-xs px-3 py-1.5 transition-colors ${
                    showWriteReview
                      ? 'bg-rose-500 text-white'
                      : theme === 'dark'
                      ? 'bg-white/5 text-rose-500 hover:bg-white/10'
                      : 'bg-black/5 text-rose-500 hover:bg-black/10'
                  }`}
                >
                  {showWriteReview ? 'Cancel' : 'Write Review'}
                </button>
              </div>

              {/* Write Review Form */}
              <AnimatePresence>
                {showWriteReview && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden mb-6"
                  >
                    <div className={`p-4 space-y-4 ${
                      theme === 'dark' ? 'bg-white/[0.02]' : 'bg-black/[0.02]'
                    }`}>
                      {/* Star Rating */}
                      <div>
                        <label className={`text-xs mb-2 block ${
                          theme === 'dark' ? 'text-white/60' : 'text-black/60'
                        }`}>
                          Your Rating *
                        </label>
                        <div className="flex gap-2">
                          {[1, 2, 3, 4, 5].map((star) => (
                            <button
                              key={star}
                              onClick={() => setReviewRating(star)}
                              onMouseEnter={() => setHoverRating(star)}
                              onMouseLeave={() => setHoverRating(0)}
                              className="transition-transform hover:scale-110"
                            >
                              <Star
                                className={`w-8 h-8 ${
                                  star <= (hoverRating || reviewRating)
                                    ? 'fill-yellow-400 text-yellow-400'
                                    : theme === 'dark'
                                    ? 'text-white/20'
                                    : 'text-black/20'
                                }`}
                              />
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Comment */}
                      <div>
                        <label className={`text-xs mb-2 block ${
                          theme === 'dark' ? 'text-white/60' : 'text-black/60'
                        }`}>
                          Your Review (Optional)
                        </label>
                        <textarea
                          value={reviewComment}
                          onChange={(e) => setReviewComment(e.target.value)}
                          placeholder="Share your experience with this product..."
                          rows={4}
                          className={`w-full px-3 py-2 text-sm resize-none border transition-colors ${
                            theme === 'dark'
                              ? 'bg-black/20 border-white/10 text-white placeholder-white/30 focus:border-rose-500/50'
                              : 'bg-white border-black/10 text-black placeholder-black/30 focus:border-rose-500/50'
                          } focus:outline-none`}
                        />
                      </div>

                      {/* Media Upload */}
                      <div>
                        <label className={`text-xs mb-2 block ${
                          theme === 'dark' ? 'text-white/60' : 'text-black/60'
                        }`}>
                          Add Photos (Optional)
                        </label>
                        <button className={`w-full py-8 border-2 border-dashed transition-colors flex flex-col items-center gap-2 ${
                          theme === 'dark'
                            ? 'border-white/10 hover:border-rose-500/50 text-white/40 hover:text-rose-500'
                            : 'border-black/10 hover:border-rose-500/50 text-black/40 hover:text-rose-500'
                        }`}>
                          <Camera className="w-6 h-6" />
                          <span className="text-xs">Click to upload photos</span>
                        </button>
                      </div>

                      {/* Submit Button */}
                      <button
                        onClick={handleSubmitReview}
                        disabled={reviewRating === 0}
                        className={`w-full py-3 text-sm tracking-wide uppercase transition-all ${
                          reviewRating === 0
                            ? theme === 'dark'
                              ? 'bg-white/10 text-white/30 cursor-not-allowed'
                              : 'bg-black/10 text-black/30 cursor-not-allowed'
                            : 'bg-rose-500 text-white hover:bg-rose-600'
                        }`}
                      >
                        Submit Review
                      </button>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>

              {/* Review Media Masonry Grid */}
              {allReviewMedia.length > 0 && (
                <div className="mb-6">
                  <h4 className={`text-sm mb-3 ${
                    theme === 'dark' ? 'text-white/70' : 'text-black/70'
                  }`}>
                    Customer Photos ({allReviewMedia.length})
                  </h4>
                  <Masonry columnsCount={3} gutter="8px">
                    {allReviewMedia.map((media, index) => (
                      <div
                        key={index}
                        onClick={() => handleMediaClick(index)}
                        className="cursor-pointer overflow-hidden relative group"
                      >
                        <ImageWithFallback
                          src={media.mediaUrl}
                          alt={`Review by ${media.username}`}
                          className="w-full h-auto object-cover transition-transform duration-300 group-hover:scale-105"
                        />
                        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors duration-300" />
                        <div className="absolute bottom-2 left-2 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                          <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                          <span className="text-white text-xs drop-shadow-lg">{media.rating}</span>
                        </div>
                      </div>
                    ))}
                  </Masonry>
                </div>
              )}

              {/* Individual Reviews */}
              <div className="space-y-4">
                {mockReviews.map((review) => (
                  <div
                    key={review.id}
                    className={`p-4 border ${
                      theme === 'dark' ? 'border-white/5' : 'border-black/5'
                    }`}
                  >
                    <div className="flex items-start gap-3 mb-3">
                      <ImageWithFallback
                        src={review.userAvatar}
                        alt={review.username}
                        className="w-10 h-10 rounded-full object-cover"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <span className={`text-sm ${
                            theme === 'dark' ? 'text-white' : 'text-black'
                          }`}>
                            {review.username}
                          </span>
                          {review.verified && (
                            <span className="text-[10px] px-1.5 py-0.5" style={{
                              background: 'rgba(9, 64, 16, 0.2)',
                              color: '#094010'
                            }}>
                              VERIFIED
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-2">
                          <div className="flex gap-0.5">
                            {[...Array(5)].map((_, i) => (
                              <Star
                                key={i}
                                className={`w-3 h-3 ${
                                  i < review.rating
                                    ? 'fill-yellow-400 text-yellow-400'
                                    : theme === 'dark'
                                    ? 'text-white/20'
                                    : 'text-black/20'
                                }`}
                              />
                            ))}
                          </div>
                          <span className={`text-xs ${
                            theme === 'dark' ? 'text-white/40' : 'text-black/40'
                          }`}>
                            {review.timeAgo}
                          </span>
                        </div>
                      </div>
                    </div>
                    <p className={`text-sm leading-relaxed mb-3 ${
                      theme === 'dark' ? 'text-white/70' : 'text-black/70'
                    }`}>
                      {review.comment}
                    </p>
                    {review.helpful > 0 && (
                      <button className={`text-xs ${
                        theme === 'dark' ? 'text-white/40 hover:text-white/60' : 'text-black/40 hover:text-black/60'
                      } transition-colors`}>
                        Helpful ({review.helpful})
                      </button>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Similar Products */}
          {similarProducts.length > 0 && (
            <div className="pt-6 border-t border-white/5">
              <h3 className={`text-sm mb-4 ${
                theme === 'dark' ? 'text-white' : 'text-black'
              }`}>
                Similar Products
              </h3>
              <div className="grid grid-cols-2 gap-3">
                {similarProducts.slice(0, 4).map((item, index) => (
                  <ProductCard
                    key={item.id}
                    product={{
                      id: item.id,
                      name: item.name,
                      price: item.price,
                      image: item.image,
                    }}
                    theme={theme}
                    variant="compact"
                    index={index}
                    onClick={onSimilarProductClick}
                  />
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Sticky Bottom CTA */}
      <div className={`fixed bottom-0 left-0 right-0 p-4 backdrop-blur-xl border-t ${
        theme === 'dark'
          ? 'bg-black/90 border-white/5'
          : 'bg-white/90 border-black/5'
      }`}>
        <div className="flex gap-3">
          <button
            onClick={handleToggleWishlist}
            className={`p-3 border transition-all ${
              isWishlisted
                ? ''
                : theme === 'dark'
                ? 'border-white/10 hover:border-white/20'
                : 'border-black/10 hover:border-black/20'
            }`}
            style={isWishlisted ? {
              borderColor: 'rgba(64, 16, 16, 0.5)',
              background: 'rgba(64, 16, 16, 0.1)'
            } : {}}
          >
            <Heart 
              className="w-5 h-5"
              style={
                isWishlisted ? { fill: '#401010', color: '#401010' }
                : theme === 'dark' ? { color: 'white' }
                : { color: 'black' }
              }
            />
          </button>
          <button
            onClick={handleAddToBag}
            disabled={!product.inStock}
            className={`flex-1 py-3 px-6 flex items-center justify-center gap-2 text-sm uppercase tracking-wider transition-all ${
              product.inStock
                ? 'text-white hover:opacity-90'
                : theme === 'dark'
                ? 'bg-white/5 text-white/30 cursor-not-allowed'
                : 'bg-black/5 text-black/30 cursor-not-allowed'
            }`}
            style={product.inStock ? {
              background: '#094010',
              boxShadow: '0 4px 20px rgba(9, 64, 16, 0.3)'
            } : {}}
          >
            <ShoppingBag className="w-5 h-5" />
            <span>
              {product.inStock ? 'Add to Bag' : 'Out of Stock'}
            </span>
          </button>
        </div>
      </div>

      {/* Full Screen Review Media Viewer */}
      {fullScreenReviewIndex !== null && (
        <FullScreenPost
          posts={reviewPostsData}
          initialIndex={fullScreenReviewIndex}
          onClose={() => setFullScreenReviewIndex(null)}
          onProductClick={() => {}}
          theme={theme}
        />
      )}
    </motion.div>
  );
};
