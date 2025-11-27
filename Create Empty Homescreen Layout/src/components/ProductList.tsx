import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, SlidersHorizontal, ChevronDown, Check } from 'lucide-react';
import { ProductCard } from './commerce/ProductCard';
import { productsWithDetails, ProductData, formatPrice } from '../data/jewelryData';
import { LoaderSpinner } from './LoaderSpinner';

interface ProductListProps {
  theme?: 'dark' | 'light';
  onBack: () => void;
  onProductClick: (productId: string) => void;
  category?: string;
  title?: string;
}

type SortOption = 'relevance' | 'price-low' | 'price-high' | 'rating' | 'newest';
type ViewMode = 'grid' | 'list';

const sortOptions: { value: SortOption; label: string }[] = [
  { value: 'relevance', label: 'Relevance' },
  { value: 'price-low', label: 'Price: Low to High' },
  { value: 'price-high', label: 'Price: High to Low' },
  { value: 'rating', label: 'Top Rated' },
  { value: 'newest', label: 'Newest' },
];

export function ProductList({
  theme = 'dark',
  onBack,
  onProductClick,
  category,
  title,
}: ProductListProps) {
  const [products, setProducts] = useState<ProductData[]>([]);
  const [filteredProducts, setFilteredProducts] = useState<ProductData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [sortBy, setSortBy] = useState<SortOption>('relevance');
  const [viewMode, setViewMode] = useState<ViewMode>('grid');
  const [showSortMenu, setShowSortMenu] = useState(false);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  // Load products based on category
  useEffect(() => {
    setIsLoading(true);
    const timer = setTimeout(() => {
      let filteredData = productsWithDetails;
      
      if (category && category !== 'all') {
        filteredData = productsWithDetails.filter(p => p.category === category);
      }
      
      setProducts(filteredData);
      setFilteredProducts(filteredData);
      setIsLoading(false);
    }, 600);

    return () => clearTimeout(timer);
  }, [category]);

  // Sort products
  useEffect(() => {
    let sorted = [...products];
    
    switch (sortBy) {
      case 'price-low':
        sorted.sort((a, b) => a.price - b.price);
        break;
      case 'price-high':
        sorted.sort((a, b) => b.price - a.price);
        break;
      case 'rating':
        sorted.sort((a, b) => b.rating - a.rating);
        break;
      case 'newest':
        // For now, reverse the array to simulate newest
        sorted.reverse();
        break;
      default:
        // relevance - keep original order
        break;
    }
    
    setFilteredProducts(sorted);
  }, [sortBy, products]);

  const getCategoryTitle = () => {
    if (title) return title;
    if (!category || category === 'all') return 'All Products';
    return category.charAt(0).toUpperCase() + category.slice(1);
  };

  return (
    <div
      className={`fixed inset-0 z-50 overflow-hidden ${
        theme === 'dark' ? 'bg-black text-white' : 'bg-white text-black'
      }`}
    >
      {/* Header */}
      <div
        className={`sticky top-0 z-10 backdrop-blur-xl border-b ${
          theme === 'dark'
            ? 'bg-black/80 border-white/10'
            : 'bg-white/80 border-black/10'
        }`}
      >
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-4">
            <button
              onClick={onBack}
              className={`p-2 rounded-full transition-colors ${
                theme === 'dark'
                  ? 'hover:bg-white/10'
                  : 'hover:bg-black/10'
              }`}
            >
              <X className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-heading-lg">{getCategoryTitle()}</h1>
              <p className={`text-body-sm ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
                {filteredProducts.length} items
              </p>
            </div>
          </div>

          {/* Sort & Filter */}
          <div className="flex items-center gap-3">
            <div className="relative">
              <button
                onClick={() => setShowSortMenu(!showSortMenu)}
                className={`flex items-center gap-2 px-4 py-2 rounded-full border transition-colors ${
                  theme === 'dark'
                    ? 'border-white/20 hover:bg-white/10'
                    : 'border-black/20 hover:bg-black/10'
                }`}
              >
                <SlidersHorizontal className="w-4 h-4" />
                <span className="text-body-sm">
                  {sortOptions.find(o => o.value === sortBy)?.label}
                </span>
                <ChevronDown className="w-4 h-4" />
              </button>

              {/* Sort Menu */}
              <AnimatePresence>
                {showSortMenu && (
                  <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    className={`absolute right-0 top-full mt-2 w-56 rounded-2xl border shadow-2xl overflow-hidden ${
                      theme === 'dark'
                        ? 'bg-zinc-900 border-white/10'
                        : 'bg-white border-black/10'
                    }`}
                  >
                    {sortOptions.map((option) => (
                      <button
                        key={option.value}
                        onClick={() => {
                          setSortBy(option.value);
                          setShowSortMenu(false);
                        }}
                        className={`w-full flex items-center justify-between px-4 py-3 text-body-sm transition-colors ${
                          theme === 'dark'
                            ? 'hover:bg-white/5'
                            : 'hover:bg-black/5'
                        }`}
                      >
                        <span>{option.label}</span>
                        {sortBy === option.value && (
                          <Check className="w-4 h-4" style={{ color: '#094010' }} />
                        )}
                      </button>
                    ))}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
        </div>
      </div>

      {/* Product Grid */}
      <div
        ref={scrollContainerRef}
        className="h-[calc(100vh-80px)] overflow-y-auto scrollbar-hide"
      >
        {isLoading ? (
          <div className="flex items-center justify-center h-full">
            <LoaderSpinner theme={theme} />
          </div>
        ) : (
          <div className="p-6">
            <div className="grid grid-cols-2 gap-4">
              {filteredProducts.map((product, index) => (
                <div key={product.id}>
                  <ProductCard
                    product={{
                      id: product.id,
                      name: product.name,
                      price: formatPrice(product.price),
                      originalPrice: product.originalPrice ? formatPrice(product.originalPrice) : undefined,
                      image: product.image,
                      rating: product.rating,
                      badge: product.badge,
                    }}
                    theme={theme}
                    variant="grid"
                    index={index}
                    onClick={onProductClick}
                  />
                </div>
              ))}
            </div>

            {filteredProducts.length === 0 && (
              <div className="flex flex-col items-center justify-center py-20">
                <p className={`text-body-lg mb-2 ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
                  No products found
                </p>
                <p className={`text-body-sm ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`}>
                  Try adjusting your filters
                </p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Click outside to close sort menu */}
      {showSortMenu && (
        <div
          className="fixed inset-0 z-0"
          onClick={() => setShowSortMenu(false)}
        />
      )}
    </div>
  );
}
