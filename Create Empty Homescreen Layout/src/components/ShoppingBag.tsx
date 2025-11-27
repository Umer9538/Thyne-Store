import { motion } from 'motion/react';
import { ArrowLeft, Minus, Plus, Trash2, Tag, Truck, Shield, Sparkles, TrendingUp, Star, Heart } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { useState, useEffect } from 'react';
import { ShoppingBagShimmer } from './ShoppingBagShimmer';
import { productsWithDetails, formatPrice } from '../data/jewelryData';

interface ShoppingBagProps {
  onBack: () => void;
}

interface BagItem {
  id: string;
  type: 'product' | 'bundle';
  name: string;
  price: number;
  quantity: number;
  image: string;
  images?: string[];
  variant?: string;
  maxQuantity: number;
}

export function ShoppingBag({ onBack }: ShoppingBagProps) {
  const [promoCode, setPromoCode] = useState('');
  const [appliedPromo, setAppliedPromo] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Simulate loading
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 1200);

    return () => clearTimeout(timer);
  }, []);
  
  // Get bag data from our jewelry collection
  const selectedBagProducts = [
    productsWithDetails.find(p => p.category === 'rings' && p.price < 30000),
    productsWithDetails.find(p => p.category === 'pendants'),
    productsWithDetails.find(p => p.category === 'bracelets'),
  ].filter(p => p !== undefined);

  const [bagItems, setBagItems] = useState<BagItem[]>([
    {
      id: selectedBagProducts[0]!.id,
      type: 'product',
      name: selectedBagProducts[0]!.name,
      price: selectedBagProducts[0]!.price,
      quantity: 1,
      image: selectedBagProducts[0]!.image,
      variant: 'Size: 7',
      maxQuantity: 3,
    },
    {
      id: 'bundle-bag-1',
      type: 'bundle',
      name: 'Diamond Collection Set',
      price: 41600,
      quantity: 1,
      images: [
        selectedBagProducts[1]!.image,
        selectedBagProducts[2]!.image,
        productsWithDetails.find(p => p.category === 'earrings')!.image,
      ],
      image: selectedBagProducts[1]!.image,
      maxQuantity: 2,
    },
    {
      id: selectedBagProducts[2]!.id,
      type: 'product',
      name: selectedBagProducts[2]!.name,
      price: selectedBagProducts[2]!.price,
      quantity: 2,
      image: selectedBagProducts[2]!.image,
      variant: 'Size: M',
      maxQuantity: 5,
    },
  ]);

  const updateQuantity = (id: string, delta: number) => {
    setBagItems(items =>
      items.map(item => {
        if (item.id === id) {
          const newQuantity = Math.max(1, Math.min(item.maxQuantity, item.quantity + delta));
          return { ...item, quantity: newQuantity };
        }
        return item;
      })
    );
  };

  const removeItem = (id: string) => {
    setBagItems(items => items.filter(item => item.id !== id));
  };

  const applyPromoCode = () => {
    if (promoCode.toUpperCase() === 'THYNE15') {
      setAppliedPromo('THYNE15');
    }
  };

  const subtotal = bagItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const discount = appliedPromo === 'THYNE15' ? subtotal * 0.15 : 0;
  const shipping = subtotal > 50000 ? 0 : 500;
  const total = subtotal - discount + shipping;

  // Get recommendation products
  const featuredProducts = productsWithDetails.filter(p => p.badge === 'Bestseller').slice(0, 6);
  const trendingProducts = productsWithDetails.filter(p => p.badge === 'Popular').slice(0, 6);
  const recommendedProducts = productsWithDetails.filter(p => !bagItems.find(item => item.id === p.id)).slice(0, 6);
  const similarProducts = productsWithDetails.filter(p => {
    const bagCategories = bagItems.map(item => {
      const product = productsWithDetails.find(prod => prod.id === item.id);
      return product?.category;
    });
    return bagCategories.includes(p.category) && !bagItems.find(item => item.id === p.id);
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
        <motion.button
          whileTap={{ scale: 0.95 }}
          className="w-full py-1.5 rounded-lg text-[10px] bg-[#094010] hover:bg-[#0b5012] text-white transition-colors"
        >
          Add to Bag
        </motion.button>
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
              Shopping Bag
            </h1>
            <p className="text-body-sm text-black/60">
              {bagItems.reduce((sum, item) => sum + item.quantity, 0)} items
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      {isLoading ? (
        <ShoppingBagShimmer />
      ) : (
        <div className="px-4 py-6 space-y-6 pb-48">
          {bagItems.length > 0 ? (
            <>
              {/* Trust Badges */}
              <div className="grid grid-cols-3 gap-2">
              {[
                { icon: Truck, text: 'Free Shipping', subtext: 'on ₹50k+' },
                { icon: Shield, text: 'Secure', subtext: 'Payment' },
                { icon: Tag, text: 'Best', subtext: 'Prices' },
              ].map((badge, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.05 }}
                  className="p-3 rounded-xl border text-center bg-white border-gray-200"
                >
                  <badge.icon className="w-5 h-5 mx-auto mb-1 text-[#094010]" />
                  <p className="text-footnote text-black">
                    {badge.text}
                  </p>
                  <p className="text-footnote text-black/40">
                    {badge.subtext}
                  </p>
                </motion.div>
              ))}
            </div>

            {/* Bag Items */}
            <div className="space-y-3">
              {bagItems.map((item, index) => (
                <motion.div
                  key={item.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.05 }}
                  className="p-4 rounded-2xl border transition-all duration-300 bg-white border-gray-200"
                >
                  <div className="flex gap-4">
                    {/* Image */}
                    <div className="relative">
                      {item.type === 'bundle' && item.images ? (
                        <div className="w-20 h-20 rounded-xl overflow-hidden border grid grid-cols-2 gap-0.5">
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
                        <div className="w-20 h-20 rounded-xl overflow-hidden border border-gray-200">
                          <ImageWithFallback
                            src={item.image}
                            alt={item.name}
                            className="w-full h-full object-cover"
                          />
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
                        {item.variant && (
                          <p className="text-footnote text-black/40">
                            {item.variant}
                          </p>
                        )}
                      </div>

                      <div className="flex items-center justify-between">
                        <span className="text-body text-black">
                          ₹{(item.price * item.quantity).toLocaleString()}
                        </span>

                        {/* Quantity Controls */}
                        <div className="flex items-center gap-2">
                          <motion.button
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            onClick={() => updateQuantity(item.id, -1)}
                            disabled={item.quantity <= 1}
                            className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors ${
                              item.quantity <= 1
                                ? 'bg-black/5 text-black/20 cursor-not-allowed'
                                : 'bg-black/10 hover:bg-black/20 text-black'
                            }`}
                          >
                            <Minus className="w-3 h-3" />
                          </motion.button>

                          <span className="text-body-sm min-w-[20px] text-center text-black">
                            {item.quantity}
                          </span>

                          <motion.button
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            onClick={() => updateQuantity(item.id, 1)}
                            disabled={item.quantity >= item.maxQuantity}
                            className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors ${
                              item.quantity >= item.maxQuantity
                                ? 'bg-black/5 text-black/20 cursor-not-allowed'
                                : 'bg-[#094010]/20 hover:bg-[#094010]/30 text-[#094010]'
                            }`}
                          >
                            <Plus className="w-3 h-3" />
                          </motion.button>

                          <motion.button
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            onClick={() => removeItem(item.id)}
                            className="w-7 h-7 rounded-lg flex items-center justify-center ml-1 transition-colors bg-[#401010]/20 hover:bg-[#401010]/30 text-[#401010]"
                          >
                            <Trash2 className="w-3 h-3" />
                          </motion.button>
                        </div>
                      </div>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>

            {/* Promo Code */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="p-4 rounded-2xl border bg-white border-gray-200"
            >
              <div className="flex items-center gap-2 mb-3">
                <Tag className="w-4 h-4 text-[#094010]" />
                <h3 className="text-body text-black">
                  Promo Code
                </h3>
              </div>
              
              {appliedPromo ? (
                <div className="p-3 rounded-xl flex items-center justify-between bg-[#094010]/20 border border-[#094010]/30">
                  <div className="flex items-center gap-2">
                    <Tag className="w-4 h-4 text-[#094010]" />
                    <span className="text-body-sm text-black">
                      {appliedPromo} Applied
                    </span>
                  </div>
                  <button
                    onClick={() => setAppliedPromo(null)}
                    className="text-body-sm text-[#094010] hover:text-[#0b5012]"
                  >
                    Remove
                  </button>
                </div>
              ) : (
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={promoCode}
                    onChange={(e) => setPromoCode(e.target.value)}
                    placeholder="Enter code"
                    className="flex-1 px-4 py-2 rounded-xl border outline-none transition-colors bg-gray-50 border-gray-200 text-black placeholder:text-black/30 focus:border-[#094010]/30"
                  />
                  <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={applyPromoCode}
                    className="px-6 py-2 rounded-xl transition-all duration-300 bg-[#094010] hover:bg-[#0b5012] text-white"
                  >
                    <span className="text-body-sm">Apply</span>
                  </motion.button>
                </div>
              )}
            </motion.div>

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
          </>
        ) : (
          /* Empty State */
          <div className="text-center py-16 space-y-4">
            <div className="relative inline-block">
              <div className="absolute inset-0 rounded-full bg-gradient-to-br from-[#094010] to-[#0a5015] blur-xl opacity-40" />
              <div className="relative w-20 h-20 rounded-full bg-gradient-to-br from-[#094010] to-[#0a5015] flex items-center justify-center mx-auto">
                <motion.div
                  animate={{ rotate: [0, 10, -10, 0] }}
                  transition={{ duration: 2, repeat: Infinity }}
                >
                  <svg className="w-10 h-10 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
                    <line x1="3" y1="6" x2="21" y2="6" />
                    <path d="M16 10a4 4 0 0 1-8 0" />
                  </svg>
                </motion.div>
              </div>
            </div>
            <h3 className="text-heading-md text-black">
              Your bag is empty
            </h3>
            <p className="text-body-sm text-black/60">
              Add some beautiful jewelry to get started
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
        </div>
      )}

      {/* Fixed Bottom Summary */}
      {!isLoading && bagItems.length > 0 && (
        <div className="fixed bottom-0 left-0 right-0 z-50 backdrop-blur-xl border-t transition-colors duration-500 bg-gradient-to-t from-[#fffff0] via-[#fffff0]/95 to-[#fffff0]/90 border-black/5">
          <div className="px-4 py-4 space-y-3">
            {/* Summary */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-body-sm text-black/60">
                  Subtotal
                </span>
                <span className="text-body-sm text-black">
                  ₹{subtotal.toLocaleString()}
                </span>
              </div>
              
              {appliedPromo && (
                <div className="flex items-center justify-between">
                  <span className="text-body-sm text-[#094010]">Discount (15%)</span>
                  <span className="text-body-sm text-[#094010]">
                    -₹{discount.toLocaleString()}
                  </span>
                </div>
              )}
              
              <div className="flex items-center justify-between">
                <span className="text-body-sm text-black/60">
                  Shipping
                </span>
                <span className={`text-body-sm ${
                  shipping === 0 ? 'text-[#094010]' : 'text-black'
                }`}>
                  {shipping === 0 ? 'FREE' : `₹${shipping}`}
                </span>
              </div>
              
              <div className="h-px bg-black/10" />
              
              <div className="flex items-center justify-between">
                <span className="text-heading-sm text-black">
                  Total
                </span>
                <span className="text-heading-sm text-black">
                  ₹{total.toLocaleString()}
                </span>
              </div>
            </div>

            {/* Checkout Button */}
            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="w-full py-4 rounded-xl transition-all duration-300 bg-gradient-to-r from-[#094010] to-[#0a5015] hover:from-[#0b5012] hover:to-[#0c6018] text-white shadow-lg shadow-[#094010]/30"
            >
              <span className="text-body">Proceed to Checkout</span>
            </motion.button>
          </div>
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
