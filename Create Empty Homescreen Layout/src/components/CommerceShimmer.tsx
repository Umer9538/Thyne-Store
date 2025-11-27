import { ShimmerCard } from './ShimmerCard';

interface CommerceShimmerProps {
  theme?: 'dark' | 'light';
}

export function CommerceShimmer({ theme = 'dark' }: CommerceShimmerProps) {
  return (
    <div className="space-y-8 pb-8">
      {/* Hero Banner Shimmer */}
      <ShimmerCard variant="banner" theme={theme} />

      {/* Category Stories Shimmer */}
      <div className="space-y-4">
        <div className={`w-32 h-5 rounded-full ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'}`} />
        <div className="flex gap-4 overflow-x-auto no-scrollbar pb-2">
          {[...Array(6)].map((_, i) => (
            <ShimmerCard key={i} variant="category" theme={theme} index={i} />
          ))}
        </div>
      </div>

      {/* Product Grid Shimmer */}
      <div className="space-y-4">
        <div className={`w-48 h-6 rounded-full ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'}`} />
        <div className={`w-36 h-4 rounded-full ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'}`} />
        <div className="grid grid-cols-2 gap-4">
          {[...Array(6)].map((_, i) => (
            <ShimmerCard key={i} variant="product" theme={theme} index={i} />
          ))}
        </div>
      </div>

      {/* Product Carousel Shimmer */}
      <div className="space-y-4">
        <div className={`w-40 h-6 rounded-full ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'}`} />
        <div className="flex gap-4 overflow-x-auto no-scrollbar">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="min-w-[160px]">
              <ShimmerCard variant="product" theme={theme} index={i} />
            </div>
          ))}
        </div>
      </div>

      {/* List Shimmer */}
      <div className="space-y-3">
        {[...Array(3)].map((_, i) => (
          <ShimmerCard key={i} variant="list" theme={theme} index={i} />
        ))}
      </div>
    </div>
  );
}
