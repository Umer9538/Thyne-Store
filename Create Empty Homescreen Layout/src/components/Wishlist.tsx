import { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Heart, ShoppingBag, Trash2, Share2, Sparkles, TrendingUp, Star } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { WishlistShimmer } from './WishlistShimmer';
import { productsWithDetails, formatPrice } from '../data/jewelryData';

interface WishlistProps {
  onBack: () => void;
  onAddToBag: (id: string) => void;
}

interface WishlistItem {
  id: string;
  type: 'product' | 'bundle';
  name: string;
  price: number;
  originalPrice?: number;
  image: string;
  images?: string[]; // for bundles
  rating?: number;
  inStock: boolean;
  addedDate: string;
}

export function Wishlist({ onBack, onAddToBag }: WishlistProps) {
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Simulate loading
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 1200);

    return () => clearTimeout(timer);
  }, []);

  // Get wishlist data from our jewelry collection
  const selectedProducts = [
    productsWithDetails.find(p => p.category === 'rings' && p.badge === 'Popular'),
    productsWithDetails.find(p => p.category === 'pendants' && p.badge === 'Bestseller'),
    productsWithDetails.find(p => p.category === 'bracelets'),
    productsWithDetails.find(p => p.category === 'earrings' && p.badge),
  ].filter(p => p !== undefined);

  const wishlistItems: WishlistItem[] = [
    {
      id: selectedProducts[0]!.id,
      type: 'product',
      name: selectedProducts[0]!.name,
      price: selectedProducts[0]!.price,
      originalPrice: selectedProducts[0]!.originalPrice,
      image: selectedProducts[0]!.image,
      rating: selectedProducts[0]!.rating,
      inStock: true,
      addedDate: '2 days ago',
    },
    {
      id: 'bundle-1',
      type: 'bundle',
      name: 'Diamond Collection Set',
      price: 41600,
      originalPrice: 52000,
      images: [
        selectedProducts[1]!.image,
        selectedProducts[2]!.image,
        selectedProducts[3]!.image,
      ],
      image: selectedProducts[1]!.image,
      inStock: true,
      addedDate: '5 days ago',
    },
    {
      id: selectedProducts[1]!.id,
      type: 'product',
      name: selectedProducts[1]!.name,
      price: selectedProducts[1]!.price,
      originalPrice: selectedProducts[1]!.originalPrice,
      image: selectedProducts[1]!.image,
      rating: selectedProducts[1]!.rating,
      inStock: false,
      addedDate: '1 week ago',
    },
    {
      id: selectedProducts[2]!.id,
      type: 'product',
      name: selectedProducts[2]!.name,
      price: selectedProducts[2]!.price,
      originalPrice: selectedProducts[2]!.originalPrice,
      image: selectedProducts[2]!.image,
      rating: selectedProducts[2]!.rating,
      inStock: true,
      addedDate: '1 week ago',
    },
  ];

  const inStockCount = wishlistItems.filter(item => item.inStock).length;
  const totalValue = wishlistItems.reduce((sum, item) => sum + item.price, 0);

  // Get recommendation products
  const featuredProducts = productsWithDetails.filter(p => p.badge === 'Bestseller').slice(0, 6);
  const trendingProducts = productsWithDetails.filter(p => p.badge === 'Popular').slice(0, 6);
  const recommendedProducts = productsWithDetails.filter(p => !wishlistItems.find(item => item.id === p.id)).slice(0, 6);
  const similarProducts = productsWithDetails.filter(p => {
    const wishlistCategories = wishlistItems.map(item => {
      const product = productsWithDetails.find(prod => prod.id === item.id);
      return product?.category;
    });
    return wishlistCategories.includes(p.category) && !wishlistItems.find(item => item.id === p.id);
  }).slice(0, 6);

  const ProductCard = ({ product }: { product: typeof productsWithDetails[0] }) => (
    <motion.div
      whileHover={{ y: -4 }}
      className="flex-shrink-0 w-40 bg-white rounded-2xl border border-gray-200 overflow-hidden"
    >
      <div className="relative aspect-square overflow-hidden bg-gray-50">
        <ImageWithFallback
          src={product.image}
          alt={product.name}
          className="w-full h-full object-cover"
        />
        {product.badge && (
          <div className="absolute top-2 right-2 px-2 py-0.5 rounded-full text-[10px] bg-[#094010] text-white">
            {product.badge}
          </div>
        )}
      </div>
      <div className="p-3">
        <h4 className="text-xs text-black line-clamp-2 mb-1">{product.name}</h4>
        <div className="flex items-center justify-between mb-2">
          <span className="text-xs text-black">₹{product.price.toLocaleString()}</span>
          {product.originalPrice && (
            <span className="text-[10px] line-through text-black/40">
              ₹{product.originalPrice.toLocaleString()}
            </span>
          )}
        </div>
        <div className="flex gap-1">
          <motion.button
            whileTap={{ scale: 0.95 }}
            className="flex-1 py-1.5 rounded-lg text-[10px] bg-[#094010] hover:bg-[#0b5012] text-white transition-colors"
          >
            Add to Bag
          </motion.button>
          <motion.button
            whileTap={{ scale: 0.95 }}
            className="p-1.5 rounded-lg bg-pink-50 hover:bg-pink-100 transition-colors"
          >
            <Heart className="w-3 h-3 text-pink-600" />
          </motion.button>
        </div>
      </div>
    </motion.div>
  );

  return (
    <div className="min-h-screen transition-colors duration-500 bg-[#fffff0]">
      {/* Header */}
      <div className="sticky top-0 z-50 backdrop-blur-xl border-b transition-colors duration-500 bg-gradient-to-b from-[#fffff0] via-[#fffff0]/95 to-[#fffff0]/90 border-black/5">
        <div className="flex items-center gap-4 px-4 py-4">
          <motion.button
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onClick={onBack}
            className="p-2 rounded-full transition-colors bg-black/5 hover:bg-black/10"
          >
            <ArrowLeft className="w-5 h-5 text-black" />
          </motion.button>
          
          <div className="flex-1">
            <h1 className="text-heading-lg text-black">
              Wishlist
            </h1>
            <p className="text-body-sm text-black/60">
              {wishlistItems.length} items • {inStockCount} in stock
            </p>
          </div>

          <motion.button
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            className="p-2 rounded-full transition-colors bg-black/5 hover:bg-black/10"
          >
            <Share2 className="w-5 h-5 text-black" />
          </motion.button>
        </div>
      </div>

      {/* Content */}
      {isLoading ? (
        <WishlistShimmer />
      ) : (
        <div className="px-4 py-6 space-y-6">
          {/* Stats Card */}
          <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="p-4 rounded-2xl border bg-gradient-to-br from-[#094010]/10 to-[#0a5015]/5 border-[#094010]/20"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-footnote text-black/60">
                Total Value
              </p>
              <p className="text-heading-md text-black">
                ₹{totalValue.toLocaleString()}
              </p>
            </div>
            <div className="relative">
              <div className="absolute inset-0 rounded-full bg-gradient-to-br from-pink-500 to-rose-500 blur-md opacity-60" />
              <div className="relative w-12 h-12 rounded-full bg-gradient-to-br from-pink-600 to-rose-600 flex items-center justify-center shadow-lg">
                <Heart className="w-6 h-6 text-white fill-white" />
              </div>
            </div>
          </div>
        </motion.div>

        {/* Wishlist Items */}
        <div className="space-y-4">
          {wishlistItems.map((item, index) => (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
              className="p-4 rounded-2xl border transition-all duration-300 bg-white border-gray-200"
            >
              <div className="flex gap-4">
                {/* Image */}
                <div className="relative">
                  {item.type === 'bundle' && item.images ? (
                    <div className="w-24 h-24 rounded-xl overflow-hidden border grid grid-cols-2 gap-0.5">
                      {item.images.slice(0, 4).map((img, i) => (
                        <div key={i} className="relative">
                          <ImageWithFallback
                            src={img}
                            alt={`${item.name} ${i + 1}`}
                            className="w-full h-full object-cover"
                          />
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="w-24 h-24 rounded-xl overflow-hidden border border-gray-200">
                      <ImageWithFallback
                        src={item.image}
                        alt={item.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                  )}
                  
                  {!item.inStock && (
                    <div className="absolute inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center rounded-xl">
                      <span className="text-footnote text-white">Out of Stock</span>
                    </div>
                  )}

                  {item.type === 'bundle' && (
                    <div className="absolute -top-1 -right-1 px-2 py-0.5 rounded-full text-footnote bg-purple-500 text-white">
                      Bundle
                    </div>
                  )}
                </div>

                {/* Info */}
                <div className="flex-1 space-y-2">
                  <div>
                    <h3 className="text-body text-black">
                      {item.name}
                    </h3>
                    <p className="text-footnote text-black/40">
                      Added {item.addedDate}
                    </p>
                  </div>

                  <div className="flex items-center gap-2">
                    <span className="text-body text-black">
                      ₹{item.price.toLocaleString()}
                    </span>
                    {item.originalPrice && (
                      <>
                        <span className="text-footnote line-through text-black/40">
                          ₹{item.originalPrice.toLocaleString()}
                        </span>
                        <span className="text-footnote text-[#094010]">
                          {Math.round((1 - item.price / item.originalPrice) * 100)}% off
                        </span>
                      </>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex gap-2 pt-2">
                    <motion.button
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={() => onAddToBag(item.id)}
                      disabled={!item.inStock}
                      className={`flex-1 px-4 py-2 rounded-xl flex items-center justify-center gap-2 transition-all duration-300 ${
                        item.inStock
                          ? 'bg-[#094010] hover:bg-[#0b5012] text-white'
                          : 'bg-black/5 text-black/40 cursor-not-allowed'
                      }`}
                    >
                      <ShoppingBag className="w-4 h-4" />
                      <span className="text-body-sm">
                        {item.inStock ? 'Add to Bag' : 'Notify Me'}
                      </span>
                    </motion.button>

                    <motion.button
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      className="p-2 rounded-xl transition-colors bg-black/5 hover:bg-[#401010]/20 text-black/60 hover:text-[#401010]"
                    >
                      <Trash2 className="w-4 h-4" />
                    </motion.button>
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Empty State (show when wishlist is empty) */}
        {wishlistItems.length === 0 && (
          <div className="text-center py-16 space-y-4">
            <div className="relative inline-block">
              <div className="absolute inset-0 rounded-full bg-gradient-to-br from-pink-500 to-rose-500 blur-xl opacity-40" />
              <div className="relative w-20 h-20 rounded-full bg-gradient-to-br from-pink-600 to-rose-600 flex items-center justify-center mx-auto">
                <Heart className="w-10 h-10 text-white" />
              </div>
            </div>
            <h3 className="text-heading-md text-black">
              Your wishlist is empty
            </h3>
            <p className="text-body-sm text-black/60">
              Start adding items you love to your wishlist
            </p>
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={onBack}
              className="px-6 py-3 rounded-xl transition-all duration-300 bg-[#094010] hover:bg-[#0b5012] text-white"
            >
              <span className="text-body">Start Shopping</span>
            </motion.button>
          </div>
        )}

        {/* Featured Products */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          <div className="flex items-center gap-2 mb-3">
            <Star className="w-4 h-4 text-[#094010]" />
            <h3 className="text-body text-black">Featured Products</h3>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
            {featuredProducts.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </motion.div>

        {/* Similar Items */}
        {similarProducts.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
          >
            <div className="flex items-center gap-2 mb-3">
              <Heart className="w-4 h-4 text-[#094010]" />
              <h3 className="text-body text-black">Similar Items</h3>
            </div>
            <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
              {similarProducts.map((product) => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          </motion.div>
        )}

        {/* Recommended for You */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
        >
          <div className="flex items-center gap-2 mb-3">
            <Sparkles className="w-4 h-4 text-[#094010]" />
            <h3 className="text-body text-black">Recommended for You</h3>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
            {recommendedProducts.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </motion.div>

        {/* Trending Now */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
        >
          <div className="flex items-center gap-2 mb-3">
            <TrendingUp className="w-4 h-4 text-[#094010]" />
            <h3 className="text-body text-black">Trending Now</h3>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
            {trendingProducts.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </motion.div>
        </div>
      )}

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
  );
}
