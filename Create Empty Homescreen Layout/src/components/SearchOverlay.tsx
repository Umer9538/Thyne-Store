import { motion, AnimatePresence } from 'motion/react';
import { useState, useEffect } from 'react';
import { X, ChevronDown, ChevronUp, Sparkles, Heart, TrendingUp, Clock } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { productsWithDetails, formatPrice } from '../data/jewelryData';

interface SearchOverlayProps {
  isOpen: boolean;
  onClose: () => void;
  currentTab?: 'commerce' | 'community' | 'create';
  onNavigate?: (section: 'commerce' | 'community' | 'create', data?: any) => void;
  query: string;
  onQueryChange: (query: string) => void;
}

interface SearchResult {
  id: string;
  type: 'product' | 'collection' | 'combo' | 'new-arrival' | 'deal' | 'recently-viewed' | 'community-post' | 'ai-create';
  category: 'shop' | 'community' | 'ai';
  title: string;
  subtitle?: string;
  price?: string;
  originalPrice?: string;
  badge?: string;
  images: string[];
  engagement?: string;
}

const recentSearches = ['Gold Rings', 'Anniversary Gifts', 'Diamond Necklace'];
const trendingQueries = ['Wedding Bands', 'Rose Gold', 'Minimalist Jewelry', 'Vintage Collection'];

export function SearchOverlay({ isOpen, onClose, currentTab = 'commerce', onNavigate, query, onQueryChange }: SearchOverlayProps) {
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [collapsedSections, setCollapsedSections] = useState<Set<string>>(new Set());
  const [selectedIndex, setSelectedIndex] = useState(-1);

  // Only show overlay for commerce and community tabs
  const shouldShow = isOpen && (currentTab === 'commerce' || currentTab === 'community');

  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    const handleArrowKeys = (e: KeyboardEvent) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setSelectedIndex((prev) => Math.min(prev + 1, results.length - 1));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        setSelectedIndex((prev) => Math.max(prev - 1, -1));
      }
    };

    if (shouldShow) {
      document.addEventListener('keydown', handleEscape);
      document.addEventListener('keydown', handleArrowKeys);
      return () => {
        document.removeEventListener('keydown', handleEscape);
        document.removeEventListener('keydown', handleArrowKeys);
      };
    }
  }, [shouldShow, onClose, results.length]);

  useEffect(() => {
    if (query.length > 0) {
      setIsLoading(true);
      // Simulate AI search with shimmer
      const timer = setTimeout(() => {
        // Get real products from our jewelry data
        const searchProducts = productsWithDetails.slice(0, 3);
        
        const mockResults: SearchResult[] = [
          // Products (highest priority)
          {
            id: searchProducts[0].id,
            type: 'product',
            category: 'shop',
            title: searchProducts[0].name,
            price: formatPrice(searchProducts[0].price),
            images: [searchProducts[0].image],
          },
          {
            id: searchProducts[1].id,
            type: 'product',
            category: 'shop',
            title: searchProducts[1].name,
            price: formatPrice(searchProducts[1].price),
            images: [searchProducts[1].image],
          },
          {
            id: searchProducts[2].id,
            type: 'product',
            category: 'shop',
            title: searchProducts[2].name,
            price: formatPrice(searchProducts[2].price),
            images: [searchProducts[2].image],
          },
          // Collections
          {
            id: 'col1',
            type: 'collection',
            category: 'shop',
            title: 'Gold Collection',
            subtitle: 'Timeless gold jewelry pieces',
            images: [
              productsWithDetails.find(p => p.category === 'bangles')!.image,
              productsWithDetails.find(p => p.category === 'rings')!.image,
            ],
          },
          {
            id: 'col2',
            type: 'collection',
            category: 'shop',
            title: 'Diamond Collection',
            subtitle: 'Brilliant diamond-studded designs',
            images: [
              productsWithDetails.find(p => p.name.includes('Diamond') && p.category === 'bracelets')!.image,
              productsWithDetails.find(p => p.name.includes('Diamond') && p.category === 'earrings')!.image,
            ],
          },
          // Combos
          {
            id: 'combo1',
            type: 'combo',
            category: 'shop',
            title: 'Bridal Set',
            images: [
              productsWithDetails.find(p => p.category === 'pendants')!.image,
              productsWithDetails.find(p => p.category === 'earrings')!.image,
              productsWithDetails.find(p => p.category === 'bangles')!.image,
            ],
          },
          // New Arrivals
          {
            id: productsWithDetails.find(p => p.badge === 'New')!.id,
            type: 'new-arrival',
            category: 'shop',
            title: productsWithDetails.find(p => p.badge === 'New')!.name,
            price: formatPrice(productsWithDetails.find(p => p.badge === 'New')!.price),
            badge: 'New',
            images: [productsWithDetails.find(p => p.badge === 'New')!.image],
          },
          // Flash Deals
          {
            id: productsWithDetails.find(p => p.originalPrice)!.id,
            type: 'deal',
            category: 'shop',
            title: productsWithDetails.find(p => p.originalPrice)!.name,
            price: formatPrice(productsWithDetails.find(p => p.originalPrice)!.price),
            originalPrice: formatPrice(productsWithDetails.find(p => p.originalPrice)!.originalPrice!),
            badge: 'Deal',
            images: [productsWithDetails.find(p => p.originalPrice)!.image],
          },
          // Community
          {
            id: 'comm1',
            type: 'community-post',
            category: 'community',
            title: 'My Wedding Jewelry Journey',
            subtitle: 'Shared by @sarah_designs',
            engagement: '234 likes',
            images: ['https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=400'],
          },
          // AI Create
          {
            id: 'ai1',
            type: 'ai-create',
            category: 'ai',
            title: 'Create new in AI Playground',
            subtitle: 'Design custom jewelry with AI',
            images: [],
          },
        ];
        setResults(mockResults);
        setIsLoading(false);
      }, 600);
      return () => clearTimeout(timer);
    } else {
      setResults([]);
      setIsLoading(false);
    }
  }, [query]);

  const toggleSection = (section: string) => {
    setCollapsedSections((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(section)) {
        newSet.delete(section);
      } else {
        newSet.add(section);
      }
      return newSet;
    });
  };

  // Group results by category
  const shopResults = results.filter((r) => r.category === 'shop');
  const communityResults = results.filter((r) => r.category === 'community');
  const aiResults = results.filter((r) => r.category === 'ai');

  const products = shopResults.filter((r) => r.type === 'product');
  const collections = shopResults.filter((r) => r.type === 'collection');
  const combos = shopResults.filter((r) => r.type === 'combo');
  const newArrivals = shopResults.filter((r) => r.type === 'new-arrival');
  const deals = shopResults.filter((r) => r.type === 'deal');

  if (!shouldShow) return null;

  return (
    <AnimatePresence>
      {shouldShow && (
        <>
          {/* Invisible backdrop for closing on outside click */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 z-[59]"
            style={{ background: 'transparent' }}
          />

          {/* Results Panel - positioned above search bar */}
          <div className="fixed left-4 right-4 z-[60]" style={{ bottom: '184px', top: '176px' }}>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 20 }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              className="h-full flex flex-col"
              onClick={(e) => e.stopPropagation()}
            >

              {/* Results Panel */}
              <motion.div
                className="rounded-[20px] border backdrop-blur-xl overflow-hidden flex flex-col h-full"
                style={{
                  background: 'rgba(255, 255, 240, 0.95)',
                  borderColor: 'rgba(0, 0, 0, 0.1)',
                  boxShadow: '0 20px 60px rgba(0, 0, 0, 0.2)',
                }}
              >
                {/* Close button in top-right */}
                <div className="absolute top-4 right-4 z-10">
                  <motion.button
                    onClick={onClose}
                    whileHover={{ scale: 1.1 }}
                    whileTap={{ scale: 0.95 }}
                    className="p-2 rounded-full bg-black/5 hover:bg-black/10 text-black/50 hover:text-black/70 transition-colors backdrop-blur-sm border border-black/10"
                  >
                    <X className="w-5 h-5" />
                  </motion.button>
                </div>

                {/* Results area */}
                <div className="flex-1 overflow-y-auto custom-scrollbar">
                  {query.length === 0 ? (
                    // Idle state - Recent & Trending
                    <div className="p-6 space-y-6">
                      {/* Recent Searches */}
                      <div className="space-y-3">
                        <div className="flex items-center gap-2 text-black/50">
                          <Clock className="w-4 h-4" />
                          <span className="text-footnote uppercase tracking-wide">Recent Searches</span>
                        </div>
                        <div className="flex flex-wrap gap-2">
                          {recentSearches.map((search, i) => (
                            <motion.button
                              key={i}
                              onClick={() => onQueryChange(search)}
                              whileHover={{ scale: 1.05 }}
                              whileTap={{ scale: 0.95 }}
                              className="px-4 py-2 rounded-full border border-black/10 bg-black/5 hover:bg-black/10 text-black/70 hover:text-black text-body-sm transition-colors"
                            >
                              {search}
                            </motion.button>
                          ))}
                        </div>
                      </div>

                      {/* Trending Now */}
                      <div className="space-y-3">
                        <div className="flex items-center gap-2 text-[#094010]/70">
                          <TrendingUp className="w-4 h-4" />
                          <span className="text-footnote uppercase tracking-wide">Trending Now</span>
                        </div>
                        <div className="flex flex-wrap gap-2">
                          {trendingQueries.map((trend, i) => (
                            <motion.button
                              key={i}
                              onClick={() => onQueryChange(trend)}
                              whileHover={{ scale: 1.05 }}
                              whileTap={{ scale: 0.95 }}
                              className="px-4 py-2 rounded-full border border-[#094010]/20 bg-[#094010]/10 hover:bg-[#094010]/20 text-[#094010]/70 hover:text-[#094010] text-body-sm transition-colors"
                            >
                              {trend}
                            </motion.button>
                          ))}
                        </div>
                      </div>

                      {/* Empty state message */}
                      <div className="text-center pt-8 pb-4">
                        <Sparkles className="w-12 h-12 mx-auto mb-3 text-black/10" />
                        <p className="text-body text-black/30">
                          Start typing to search across shop, community, and AI...
                        </p>
                      </div>
                    </div>
                  ) : isLoading ? (
                    // Loading state with shimmer
                    <div className="p-6 space-y-4">
                      {[...Array(3)].map((_, i) => (
                        <div key={i} className="space-y-3">
                          <div className="h-4 w-20 bg-black/10 rounded animate-pulse" />
                          <div className="h-24 bg-black/5 rounded-xl animate-pulse" />
                        </div>
                      ))}
                    </div>
                  ) : results.length === 0 ? (
                    // No results
                    <div className="p-8 text-center">
                      <p className="text-body text-black/40 mb-4">
                        No match found. Try rephrasing or create in AI Playground.
                      </p>
                      <motion.button
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        className="px-6 py-3 rounded-full bg-gradient-to-r from-[#094010] to-[#0a5015] text-white inline-flex items-center gap-2"
                      >
                        <Sparkles className="w-4 h-4" />
                        <span>Create in AI Playground</span>
                      </motion.button>
                    </div>
                  ) : (
                    // Results loaded
                    <div className="p-6 space-y-6">
                      {/* SHOP Section */}
                      {shopResults.length > 0 && (
                        <div className="space-y-4">
                          <button
                            onClick={() => toggleSection('shop')}
                            className="w-full flex items-center justify-between group"
                          >
                            <h3 className="text-body text-black uppercase tracking-wide">Shop</h3>
                            {collapsedSections.has('shop') ? (
                              <ChevronDown className="w-4 h-4 text-black/50 group-hover:text-black/70 transition-colors" />
                            ) : (
                              <ChevronUp className="w-4 h-4 text-black/50 group-hover:text-black/70 transition-colors" />
                            )}
                          </button>

                          {!collapsedSections.has('shop') && (
                            <div className="space-y-5">
                              {/* Products */}
                              {products.length > 0 && (
                                <div className="space-y-3">
                                  <span className="text-footnote text-black/40 uppercase tracking-wide">Products</span>
                                  <div className="grid grid-cols-3 gap-3">
                                    {products.slice(0, 3).map((result, idx) => (
                                      <motion.button
                                        key={result.id}
                                        whileHover={{ scale: 1.02 }}
                                        whileTap={{ scale: 0.98 }}
                                        className={`rounded-xl border overflow-hidden transition-all ${
                                          selectedIndex === idx
                                            ? 'border-black shadow-lg shadow-black/20'
                                            : 'border-black/10 hover:border-black/50'
                                        }`}
                                        style={{ background: 'rgba(0, 0, 0, 0.05)' }}
                                      >
                                        <div className="relative aspect-square">
                                          <ImageWithFallback
                                            src={result.images[0]}
                                            alt={result.title}
                                            className="w-full h-full object-cover"
                                          />
                                          <button className="absolute top-2 right-2 p-1.5 rounded-full bg-black/40 backdrop-blur-sm hover:bg-black/60 transition-colors">
                                            <Heart className="w-3 h-3 text-white" />
                                          </button>
                                        </div>
                                        <div className="p-3 space-y-1">
                                          <p className="text-footnote text-black line-clamp-1">{result.title}</p>
                                          <p className="text-footnote text-[#094010]">{result.price}</p>
                                        </div>
                                      </motion.button>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* Collections */}
                              {collections.length > 0 && (
                                <div className="space-y-3">
                                  <span className="text-footnote text-black/40 uppercase tracking-wide">Collections</span>
                                  <div className="space-y-2">
                                    {collections.slice(0, 2).map((result) => (
                                      <motion.button
                                        key={result.id}
                                        whileHover={{ scale: 1.01 }}
                                        whileTap={{ scale: 0.99 }}
                                        className="w-full p-3 rounded-xl border border-black/10 hover:border-black/50 transition-all flex items-center gap-3"
                                        style={{ background: 'rgba(0, 0, 0, 0.05)' }}
                                      >
                                        <div className="flex -space-x-2">
                                          {result.images.slice(0, 2).map((img, i) => (
                                            <div
                                              key={i}
                                              className="w-12 h-12 rounded-lg overflow-hidden border-2 border-[#fffff0]"
                                            >
                                              <ImageWithFallback
                                                src={img}
                                                alt={`${result.title} ${i + 1}`}
                                                className="w-full h-full object-cover"
                                              />
                                            </div>
                                          ))}
                                        </div>
                                        <div className="flex-1 text-left">
                                          <p className="text-body-sm text-black">{result.title}</p>
                                          {result.subtitle && (
                                            <p className="text-footnote text-black/50">{result.subtitle}</p>
                                          )}
                                        </div>
                                      </motion.button>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* Combos/Bundles */}
                              {combos.length > 0 && (
                                <div className="space-y-3">
                                  <span className="text-footnote text-black/40 uppercase tracking-wide">Combos/Bundles</span>
                                  <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
                                    {combos.map((result) => (
                                      <motion.button
                                        key={result.id}
                                        whileHover={{ scale: 1.02 }}
                                        whileTap={{ scale: 0.98 }}
                                        className="flex-shrink-0 p-3 rounded-xl border border-black/10 hover:border-black/50 transition-all"
                                        style={{ background: 'rgba(0, 0, 0, 0.05)' }}
                                      >
                                        <div className="flex gap-1 mb-2">
                                          {result.images.slice(0, 3).map((img, i) => (
                                            <div key={i} className="w-10 h-10 rounded-lg overflow-hidden">
                                              <ImageWithFallback
                                                src={img}
                                                alt={`${result.title} ${i + 1}`}
                                                className="w-full h-full object-cover"
                                              />
                                            </div>
                                          ))}
                                        </div>
                                        <p className="text-footnote text-black">{result.title}</p>
                                      </motion.button>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* New Arrivals */}
                              {newArrivals.length > 0 && (
                                <div className="space-y-3">
                                  <span className="text-footnote text-black/40 uppercase tracking-wide">New Arrivals</span>
                                  <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
                                    {newArrivals.map((result) => (
                                      <motion.button
                                        key={result.id}
                                        whileHover={{ scale: 1.02 }}
                                        whileTap={{ scale: 0.98 }}
                                        className="flex-shrink-0 px-4 py-2 rounded-full border border-black/10 hover:border-[#094010]/50 bg-black/5 hover:bg-[#094010]/10 transition-all flex items-center gap-2"
                                      >
                                        <span className="px-2 py-0.5 rounded-full bg-[#094010] text-white text-caption">
                                          New
                                        </span>
                                        <span className="text-footnote text-black">{result.title}</span>
                                      </motion.button>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* Flash Deals */}
                              {deals.length > 0 && (
                                <div className="space-y-3">
                                  <span className="text-footnote text-black/40 uppercase tracking-wide">Flash Deals</span>
                                  <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
                                    {deals.map((result) => (
                                      <motion.button
                                        key={result.id}
                                        whileHover={{ scale: 1.02 }}
                                        whileTap={{ scale: 0.98 }}
                                        className="flex-shrink-0 px-4 py-2 rounded-full border border-black/10 hover:border-rose-500/50 bg-black/5 hover:bg-rose-600/10 transition-all flex items-center gap-2"
                                      >
                                        <span className="px-2 py-0.5 rounded-full bg-rose-600 text-white text-caption">
                                          Deal
                                        </span>
                                        <span className="text-footnote text-black">{result.title}</span>
                                      </motion.button>
                                    ))}
                                  </div>
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      )}

                      {/* Divider */}
                      {shopResults.length > 0 && (communityResults.length > 0 || aiResults.length > 0) && (
                        <div className="h-px bg-black/10" />
                      )}

                      {/* COMMUNITY Section */}
                      {communityResults.length > 0 && (
                        <div className="space-y-4">
                          <button
                            onClick={() => toggleSection('community')}
                            className="w-full flex items-center justify-between group"
                          >
                            <h3 className="text-body text-black uppercase tracking-wide">Community</h3>
                            {collapsedSections.has('community') ? (
                              <ChevronDown className="w-4 h-4 text-black/50 group-hover:text-black/70 transition-colors" />
                            ) : (
                              <ChevronUp className="w-4 h-4 text-black/50 group-hover:text-black/70 transition-colors" />
                            )}
                          </button>

                          {!collapsedSections.has('community') && (
                            <div className="space-y-2">
                              {communityResults.map((result) => (
                                <motion.button
                                  key={result.id}
                                  whileHover={{ scale: 1.01, boxShadow: '0 10px 30px rgba(0, 0, 0, 0.1)' }}
                                  whileTap={{ scale: 0.99 }}
                                  className="w-full p-3 rounded-xl border border-black/10 hover:border-black/50 transition-all flex items-center gap-3"
                                  style={{ background: 'rgba(0, 0, 0, 0.05)' }}
                                >
                                  <div className="w-12 h-12 rounded-lg overflow-hidden flex-shrink-0">
                                    <ImageWithFallback
                                      src={result.images[0]}
                                      alt={result.title}
                                      className="w-full h-full object-cover"
                                    />
                                  </div>
                                  <div className="flex-1 text-left">
                                    <p className="text-body-sm text-black">{result.title}</p>
                                    {result.subtitle && (
                                      <p className="text-footnote text-black/50">{result.subtitle}</p>
                                    )}
                                  </div>
                                  {result.engagement && (
                                    <span className="text-footnote text-black/40">{result.engagement}</span>
                                  )}
                                </motion.button>
                              ))}
                            </div>
                          )}
                        </div>
                      )}

                      {/* Divider */}
                      {(shopResults.length > 0 || communityResults.length > 0) && aiResults.length > 0 && (
                        <div className="h-px bg-black/10" />
                      )}

                      {/* AI Create Section */}
                      {aiResults.length > 0 && (
                        <div className="space-y-4">
                          <h3 className="text-body text-black uppercase tracking-wide">AI Create</h3>
                          <div className="space-y-2">
                            {aiResults.map((result) => (
                              <motion.button
                                key={result.id}
                                whileHover={{ scale: 1.02 }}
                                whileTap={{ scale: 0.98 }}
                                className="w-full p-4 rounded-xl border border-[#0a1a40]/20 bg-gradient-to-r from-[#0a1a40]/10 to-[#0c2050]/10 hover:border-[#0a1a40]/50 transition-all flex items-center gap-3"
                              >
                                <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-[#0a1a40] to-[#0c2050] flex items-center justify-center flex-shrink-0">
                                  <Sparkles className="w-6 h-6 text-white" />
                                </div>
                                <div className="flex-1 text-left">
                                  <p className="text-body-sm text-black">{result.title}</p>
                                  {result.subtitle && (
                                    <p className="text-footnote text-black/50">{result.subtitle}</p>
                                  )}
                                </div>
                              </motion.button>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </motion.div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}
