import { ProductCard } from './ProductCard';

interface Product {
  id: string;
  name: string;
  price: string;
  originalPrice?: string;
  image: string;
  rating?: number;
  badge?: string;
  views?: number;
  rank?: number;
}

interface ProductCarouselProps {
  title: string;
  subtitle?: string;
  products: Product[];
  theme?: 'dark' | 'light';
  variant?: 'default' | 'trending' | 'compact';
  showViewAll?: boolean;
  onProductClick?: (productId: string) => void;
  onViewAllClick?: () => void;
}

export function ProductCarousel({
  title,
  subtitle,
  products,
  theme = 'dark',
  variant = 'default',
  showViewAll = true,
  onProductClick,
  onViewAllClick,
}: ProductCarouselProps) {
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <div>
          <h3 className={`text-[15px] ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
            {title}
          </h3>
          {subtitle && (
            <p className={`text-[11px] ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
              {subtitle}
            </p>
          )}
        </div>
        {showViewAll && (
          <button
            onClick={onViewAllClick}
            className={`text-[11px] px-3 py-1.5 rounded-full transition-all duration-300 ${
              theme === 'dark'
                ? 'text-emerald-400 hover:text-emerald-300 hover:bg-emerald-500/10'
                : 'text-emerald-600 hover:text-emerald-700 hover:bg-emerald-500/10'
            }`}
          >
            View All
          </button>
        )}
      </div>

      <div className="flex gap-2 overflow-x-auto no-scrollbar pb-2">
        {products.map((product, index) => (
          <div key={product.id} className={variant === 'compact' ? 'min-w-[130px]' : 'min-w-[150px]'}>
            <ProductCard product={product} theme={theme} index={index} variant={variant} onClick={onProductClick} />
          </div>
        ))}
      </div>
    </div>
  );
}
