import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Heart, Share2, ShoppingBag, Plus, Check, Package, Truck, Shield, ChevronRight, Star } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface BundleProduct {
  id: string;
  name: string;
  price: number;
  image: string;
  description?: string;
}

export interface BundleDetailData {
  id: string;
  name: string;
  description: string;
  products: BundleProduct[];
  totalPrice: number;
  discountedPrice: number;
  savings: number;
  savingsPercent: number;
  mainImage: string;
  rating?: number;
  reviewCount?: number;
  features?: string[];
  deliveryInfo?: string;
  inStock: boolean;
}

interface BundleDetailProps {
  bundle: BundleDetailData;
  onClose: () => void;
  onAddToBag?: (bundleId: string) => void;
  onAddToWishlist?: (bundleId: string) => void;
  onProductClick?: (productId: string) => void;
  similarBundles?: Array<{
    id: string;
    name: string;
    price: number;
    originalPrice: number;
    image: string;
  }>;
}

export const BundleDetail: React.FC<BundleDetailProps> = ({
  bundle,
  onClose,
  onAddToBag,
  onAddToWishlist,
  onProductClick,
  similarBundles = [],
}) => {
  const [isWishlisted, setIsWishlisted] = useState(false);
  const [expandedSection, setExpandedSection] = useState<'description' | 'products' | 'delivery' | null>('description');
  const [selectedProducts, setSelectedProducts] = useState<Set<string>>(new Set(bundle.products.map(p => p.id)));

  const handleToggleWishlist = () => {
    setIsWishlisted(!isWishlisted);
    if (onAddToWishlist && !isWishlisted) {
      onAddToWishlist(bundle.id);
    }
  };

  const handleAddToBag = () => {
    if (onAddToBag) {
      onAddToBag(bundle.id);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 overflow-y-auto bg-[#fffff0]"
    >
      {/* Header */}
      <div className="sticky top-0 z-10 backdrop-blur-xl border-b bg-[#fffff0]/80 border-[#094010]/20">
        <div className="flex items-center justify-between p-4">
          <button
            onClick={onClose}
            className="p-2 rounded-full transition-colors hover:bg-[#094010]/10 text-black"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="px-4 py-1.5 rounded-full bg-[#094010] text-white text-sm">
            Bundle Deal
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={handleToggleWishlist}
              className="p-2 rounded-full transition-all duration-300 hover:bg-[#094010]/10 text-black"
            >
              <Heart
                className={`w-6 h-6 transition-colors ${
                  isWishlisted ? 'fill-[#401010] text-[#401010]' : ''
                }`}
              />
            </button>
            <button
              className="p-2 rounded-full transition-colors hover:bg-[#094010]/10 text-black"
            >
              <Share2 className="w-6 h-6" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto">
        {/* Main Image */}
        <div className="relative aspect-[4/3]">
          <ImageWithFallback
            src={bundle.mainImage}
            alt={bundle.name}
            className="w-full h-full object-cover"
          />
          
          {/* Savings Badge */}
          <div className="absolute top-4 left-4 px-4 py-2 rounded-full backdrop-blur-xl bg-gradient-to-r from-[#094010] to-[#0a5015] text-white shadow-lg">
            Save ₹{bundle.savings.toLocaleString()} ({bundle.savingsPercent}% OFF)
          </div>
        </div>

        {/* Bundle Info */}
        <div className="p-6 space-y-6">
          {/* Title & Rating */}
          <div>
            <h1 className="text-2xl mb-2 text-black">
              {bundle.name}
            </h1>
            {bundle.rating && (
              <div className="flex items-center gap-2">
                <div className="flex items-center gap-1">
                  <Star className="w-5 h-5 fill-yellow-400 text-yellow-400" />
                  <span className="text-black">
                    {bundle.rating}
                  </span>
                </div>
                {bundle.reviewCount && (
                  <span className="text-zinc-600">
                    ({bundle.reviewCount} reviews)
                  </span>
                )}
              </div>
            )}
          </div>

          {/* Price */}
          <div>
            <div className="flex items-baseline gap-3 mb-2">
              <span className="text-3xl text-black">
                ₹{bundle.discountedPrice.toLocaleString()}
              </span>
              <span className="text-xl line-through text-zinc-400">
                ₹{bundle.totalPrice.toLocaleString()}
              </span>
            </div>
            <p className="text-sm text-[#094010]">
              You save ₹{bundle.savings.toLocaleString()} when you buy these together
            </p>
          </div>

          {/* Stock Status */}
          <div className={`flex items-center gap-2 ${
            bundle.inStock ? 'text-[#094010]' : 'text-[#401010]'
          }`}>
            <div className={`w-2 h-2 rounded-full ${
              bundle.inStock ? 'bg-[#094010]' : 'bg-[#401010]'
            }`} />
            <span>{bundle.inStock ? 'In Stock' : 'Out of Stock'}</span>
          </div>

          {/* Bundle Products Preview */}
          <div className="p-4 border rounded-2xl bg-gradient-to-br from-[#094010]/10 to-[#0a5015]/5 border-[#094010]/20">
            <h3 className="mb-4 text-black">
              Bundle Includes ({bundle.products.length} items)
            </h3>
            <div className="flex items-center gap-3 overflow-x-auto pb-2">
              {bundle.products.map((product, index) => (
                <React.Fragment key={product.id}>
                  <div className="flex-shrink-0 relative">
                    <div className={`w-20 h-20 rounded-xl overflow-hidden border-2 ${
                      selectedProducts.has(product.id)
                        ? 'border-[#094010]'
                        : 'border-zinc-300'
                    }`}>
                      <ImageWithFallback
                        src={product.image}
                        alt={product.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    {selectedProducts.has(product.id) && (
                      <div className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-[#094010] flex items-center justify-center">
                        <Check className="w-3 h-3 text-white" />
                      </div>
                    )}
                  </div>
                  {index < bundle.products.length - 1 && (
                    <Plus className="flex-shrink-0 w-4 h-4 text-zinc-400" />
                  )}
                </React.Fragment>
              ))}
            </div>
          </div>

          {/* Features */}
          {bundle.features && bundle.features.length > 0 && (
            <div className="p-4 rounded-2xl border bg-[#094010]/10 border-[#094010]/20">
              <div className="grid grid-cols-3 gap-4">
                <div className="flex flex-col items-center text-center gap-2">
                  <Package className="w-8 h-8 text-[#094010]" />
                  <span className="text-sm text-zinc-700">
                    Premium Quality
                  </span>
                </div>
                <div className="flex flex-col items-center text-center gap-2">
                  <Truck className="w-8 h-8 text-[#094010]" />
                  <span className="text-sm text-zinc-700">
                    Free Delivery
                  </span>
                </div>
                <div className="flex flex-col items-center text-center gap-2">
                  <Shield className="w-8 h-8 text-[#094010]" />
                  <span className="text-sm text-zinc-700">
                    Secure Payment
                  </span>
                </div>
              </div>
            </div>
          )}

          {/* Expandable Sections */}
          <div className="space-y-3">
            {/* Description */}
            <div className="rounded-2xl border overflow-hidden bg-white/50 border-[#094010]/20">
              <button
                onClick={() => setExpandedSection(expandedSection === 'description' ? null : 'description')}
                className="w-full p-4 text-left flex items-center justify-between text-black"
              >
                <span>Bundle Description</span>
                <ChevronRight className={`w-5 h-5 transition-transform duration-300 ${
                  expandedSection === 'description' ? 'rotate-90' : ''
                }`} />
              </button>
              <AnimatePresence>
                {expandedSection === 'description' && (
                  <motion.div
                    initial={{ height: 0 }}
                    animate={{ height: 'auto' }}
                    exit={{ height: 0 }}
                    className="overflow-hidden"
                  >
                    <div className="p-4 pt-0 text-zinc-700">
                      {bundle.description}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            {/* Product Details */}
            <div className="rounded-2xl border overflow-hidden bg-white/50 border-[#094010]/20">
              <button
                onClick={() => setExpandedSection(expandedSection === 'products' ? null : 'products')}
                className="w-full p-4 text-left flex items-center justify-between text-black"
              >
                <span>Product Details</span>
                <ChevronRight className={`w-5 h-5 transition-transform duration-300 ${
                  expandedSection === 'products' ? 'rotate-90' : ''
                }`} />
              </button>
              <AnimatePresence>
                {expandedSection === 'products' && (
                  <motion.div
                    initial={{ height: 0 }}
                    animate={{ height: 'auto' }}
                    exit={{ height: 0 }}
                    className="overflow-hidden"
                  >
                    <div className="p-4 pt-0 space-y-4">
                      {bundle.products.map((product) => (
                        <button
                          key={product.id}
                          onClick={() => onProductClick?.(product.id)}
                          className="w-full p-3 rounded-xl border transition-all duration-300 flex items-center gap-3 bg-white/60 border-[#094010]/20 hover:border-[#094010]/50"
                        >
                          <div className="w-16 h-16 rounded-lg overflow-hidden flex-shrink-0">
                            <ImageWithFallback
                              src={product.image}
                              alt={product.name}
                              className="w-full h-full object-cover"
                            />
                          </div>
                          <div className="flex-1 text-left">
                            <h4 className="mb-1 text-black">
                              {product.name}
                            </h4>
                            {product.description && (
                              <p className="text-sm text-zinc-600">
                                {product.description}
                              </p>
                            )}
                            <p className="mt-1 text-[#094010]">
                              ₹{product.price.toLocaleString()}
                            </p>
                          </div>
                          <ChevronRight className="w-5 h-5 text-zinc-400" />
                        </button>
                      ))}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            {/* Delivery Info */}
            {bundle.deliveryInfo && (
              <div className="rounded-2xl border overflow-hidden bg-white/50 border-[#094010]/20">
                <button
                  onClick={() => setExpandedSection(expandedSection === 'delivery' ? null : 'delivery')}
                  className="w-full p-4 text-left flex items-center justify-between text-black"
                >
                  <span>Delivery & Returns</span>
                  <ChevronRight className={`w-5 h-5 transition-transform duration-300 ${
                    expandedSection === 'delivery' ? 'rotate-90' : ''
                  }`} />
                </button>
                <AnimatePresence>
                  {expandedSection === 'delivery' && (
                    <motion.div
                      initial={{ height: 0 }}
                      animate={{ height: 'auto' }}
                      exit={{ height: 0 }}
                      className="overflow-hidden"
                    >
                      <div className="p-4 pt-0 text-zinc-700">
                        {bundle.deliveryInfo}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            )}
          </div>

          {/* Similar Bundles */}
          {similarBundles.length > 0 && (
            <div className="pt-6">
              <h3 className="mb-4 text-black">
                Similar Bundles
              </h3>
              <div className="grid grid-cols-2 gap-4">
                {similarBundles.map((item) => (
                  <div
                    key={item.id}
                    className="rounded-xl border overflow-hidden bg-white/50 border-[#094010]/20"
                  >
                    <div className="aspect-square relative">
                      <ImageWithFallback
                        src={item.image}
                        alt={item.name}
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute top-2 right-2 px-2 py-1 rounded-full text-xs bg-[#094010] text-white">
                        Bundle
                      </div>
                    </div>
                    <div className="p-3">
                      <h4 className="text-sm line-clamp-1 mb-2 text-black">
                        {item.name}
                      </h4>
                      <div className="flex items-center gap-2">
                        <p className="text-black">
                          ₹{item.price.toLocaleString()}
                        </p>
                        <p className="text-sm line-through text-zinc-400">
                          ₹{item.originalPrice.toLocaleString()}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Sticky Bottom CTA */}
      <div className="sticky bottom-0 p-4 backdrop-blur-xl border-t bg-[#fffff0]/80 border-[#094010]/20">
        <button
          onClick={handleAddToBag}
          disabled={!bundle.inStock}
          className={`w-full py-4 rounded-2xl flex items-center justify-center gap-3 transition-all duration-300 ${
            bundle.inStock
              ? 'bg-gradient-to-r from-[#094010] to-[#0a5015] hover:from-[#0b5012] hover:to-[#0c6018] text-white shadow-lg shadow-[#094010]/30'
              : 'bg-zinc-200 text-zinc-400 cursor-not-allowed'
          }`}
        >
          <ShoppingBag className="w-6 h-6" />
          <span className="text-lg">
            {bundle.inStock ? 'Add Bundle to Bag' : 'Out of Stock'}
          </span>
        </button>
      </div>
    </motion.div>
  );
};
