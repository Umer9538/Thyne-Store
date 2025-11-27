import { HeroBanner } from './HeroBanner';
import { CategoryStories } from './CategoryStories';
import { ProductCarousel } from './ProductCarousel';
import { OccasionCards } from './OccasionCards';
import { PriceRangeCards } from './PriceRangeCards';
import { ComboBundle } from './ComboBundle';
import { FlashDeals } from './FlashDeals';
import { CollectionCard } from './CollectionCard';
import { ProductCard } from './ProductCard';
import { TopCategories } from './TopCategories';
import { FeatureCarousel } from './FeatureCarousel';
import { productsWithDetails, formatPrice, getProductsByCategory } from '../../data/jewelryData';

interface CommerceContentProps {
  theme?: 'dark' | 'light';
  category?: string;
  onProductClick?: (productId: string) => void;
  onBundleClick?: (bundleId: string) => void;
  onViewAllClick?: (category?: string, title?: string) => void;
  onCollectionClick?: (category: string, title: string) => void;
}

export function CommerceContent({ theme = 'light', category = 'all', onProductClick, onBundleClick, onViewAllClick, onCollectionClick }: CommerceContentProps) {
  // Get products from our jewelry data
  const allJewelry = productsWithDetails;
  
  const categories = [
    { id: 'rings', name: 'Rings', image: 'https://images.unsplash.com/photo-1666374553312-2e82fd1edbff?w=400' },
    { id: 'pendants', name: 'Pendants', image: 'https://images.unsplash.com/photo-1671696564980-02ac81b3f629?w=400' },
    { id: 'earrings', name: 'Earrings', image: 'https://images.unsplash.com/photo-1584948221378-93841f589fb7?w=400' },
    { id: 'bracelets', name: 'Bracelets', image: 'https://images.unsplash.com/photo-1612437830721-4f8eab90c5a9?w=400' },
    { id: 'bangles', name: 'Bangles', image: 'https://images.unsplash.com/photo-1758995116383-f51775896add?w=400' },
    { id: 'nosepins', name: 'Nose Pins', image: 'https://images.unsplash.com/photo-1708126755423-d3676adf2190?w=400' },
  ];

  // Handpicked products - select first 4 products with badges
  const handpickedProducts = allJewelry
    .filter(p => p.badge)
    .slice(0, 4)
    .map(p => ({
      id: p.id,
      name: p.name,
      price: formatPrice(p.price),
      originalPrice: p.originalPrice ? formatPrice(p.originalPrice) : undefined,
      image: p.image,
      rating: p.rating,
      badge: p.badge,
    }));

  // Trending products - select products with "Trending" badge or high ratings
  const trendingProducts = allJewelry
    .filter(p => p.badge === 'Trending' || p.rating >= 4.8)
    .slice(0, 4)
    .map((p, index) => ({
      id: p.id,
      name: p.name,
      price: formatPrice(p.price),
      image: p.image,
      rating: p.rating,
      views: 12450 - (index * 1500),
      rank: index + 1,
    }));

  // Recently viewed - mix of different categories
  const recentlyViewed = [
    allJewelry.find(p => p.category === 'rings'),
    allJewelry.find(p => p.category === 'pendants'),
    allJewelry.find(p => p.category === 'nosepins'),
  ]
    .filter(p => p !== undefined)
    .map(p => ({
      id: p!.id,
      name: p!.name,
      price: formatPrice(p!.price),
      image: p!.image,
      rating: p!.rating,
    }));

  const occasions = [
    { id: 'engagement', name: 'Engagement', icon: '💍', gradient: 'from-pink-500 to-rose-500', count: 245 },
    { id: 'wedding', name: 'Wedding', icon: '👰', gradient: 'from-purple-500 to-pink-500', count: 389 },
    { id: 'anniversary', name: 'Anniversary', icon: '💝', gradient: 'from-red-500 to-rose-500', count: 156 },
    { id: 'birthday', name: 'Birthday', icon: '🎂', gradient: 'from-yellow-500 to-orange-500', count: 198 },
    { id: 'festival', name: 'Festival', icon: '🪔', gradient: 'from-orange-500 to-amber-500', count: 267 },
    { id: 'everyday', name: 'Everyday', icon: '✨', gradient: 'from-emerald-500 to-teal-500', count: 423 },
  ];

  const priceRanges = [
    { id: 'under-10k', label: 'Under 10k', min: 0, max: 10000, count: 234 },
    { id: '10k-25k', label: '10k-25k', min: 10000, max: 25000, count: 456, popular: true },
    { id: '25k-50k', label: '25k-50k', min: 25000, max: 50000, count: 389 },
    { id: '50k-100k', label: '50k-100k', min: 50000, max: 100000, count: 178 },
    { id: '100k-plus', label: '100k+', min: 100000, max: null, count: 89 },
  ];

  // Flash deals - products with discounts
  const flashDeals = allJewelry
    .filter(p => p.originalPrice)
    .slice(0, 3)
    .map(p => {
      const discount = Math.round(((p.originalPrice! - p.price) / p.originalPrice!) * 100);
      return {
        id: p.id,
        name: p.name,
        price: formatPrice(p.price),
        originalPrice: formatPrice(p.originalPrice!),
        image: p.image,
        rating: p.rating,
        badge: `${discount}% OFF`,
      };
    });

  // Combo bundle - create a set from different categories
  const bundleProducts = [
    allJewelry.find(p => p.category === 'pendants' && p.price > 30000),
    allJewelry.find(p => p.category === 'earrings' && p.price > 20000),
    allJewelry.find(p => p.category === 'bangles'),
  ].filter(p => p !== undefined);
  
  const totalBundlePrice = bundleProducts.reduce((sum, p) => sum + p!.price, 0);
  const bundleDiscount = Math.round(totalBundlePrice * 0.2);
  
  const comboBundle = {
    id: 'combo1',
    name: 'Complete Your Look',
    products: bundleProducts.map(p => ({
      id: p!.id,
      name: p!.name,
      price: p!.price,
      image: p!.image,
    })),
    totalPrice: totalBundlePrice,
    discountedPrice: totalBundlePrice - bundleDiscount,
    savings: bundleDiscount,
    savingsPercent: 20,
  };

  // Collections - group products from our catalog
  const collections = [
    {
      id: 'col1',
      name: 'Gold Collection',
      description: 'Timeless gold jewelry pieces',
      images: [
        allJewelry.find(p => p.category === 'bangles')?.image,
        allJewelry.find(p => p.category === 'rings')?.image,
        allJewelry.find(p => p.category === 'pendants' && p.name.includes('Gold'))?.image,
        allJewelry.find(p => p.category === 'earrings')?.image,
      ].filter(img => img !== undefined) as string[],
      itemCount: allJewelry.filter(p => p.name.includes('Gold')).length,
    },
    {
      id: 'col2',
      name: 'Diamond Dreams',
      description: 'Sparkling diamond jewelry',
      images: [
        allJewelry.find(p => p.name.includes('Diamond') && p.category === 'rings')?.image,
        allJewelry.find(p => p.name.includes('Diamond') && p.category === 'earrings')?.image,
      ].filter(img => img !== undefined) as string[],
      itemCount: allJewelry.filter(p => p.name.includes('Diamond')).length,
    },
  ];

  const newArrivals = allJewelry
    .slice(0, 3)
    .map(p => ({
      id: p.id,
      name: p.name,
      price: formatPrice(p.price),
      image: p.image,
      rating: p.rating,
      badge: 'New',
    }));

  const flashDealsEndTime = new Date(Date.now() + 4 * 60 * 60 * 1000); // 4 hours from now

  // Category-specific views with Top Categories + Feature Carousel
  if (category === 'women') {
    const featuredCollections = [
      {
        id: 'heritage-gold',
        title: 'Heritage Gold',
        subtitle: 'Timeless pieces crafted with tradition',
        image: 'https://images.unsplash.com/photo-1758995115682-1452a1a9e35b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxlbGVnYW50JTIwZ29sZCUyMGpld2Vscnl8ZW58MXx8fHwxNzYxNzQxMDk2fDA&ixlib=rb-4.1.0&q=80&w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Explore',
      },
      {
        id: 'diamond-luxe',
        title: 'Diamond Luxe',
        subtitle: 'Brilliance that captivates',
        image: 'https://images.unsplash.com/photo-1590156118368-607652ab307a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaWFtb25kJTIwbmVja2xhY2UlMjBsdXh1cnl8ZW58MXx8fHwxNzYxNzQ0NjcwfDA&ixlib=rb-4.1.0&q=80&w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Shop Now',
      },
      {
        id: 'pearl-elegance',
        title: 'Pearl Elegance',
        subtitle: 'Sophistication in every detail',
        image: 'https://images.unsplash.com/photo-1758744154415-9eebb509fc15?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZWFybCUyMGVhcnJpbmdzJTIwZWxlZ2FudHxlbnwxfHx8fDE3NjE2NjI0MzZ8MA&ixlib=rb-4.1.0&q=80&w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Discover',
      },
      {
        id: 'bridal-collection',
        title: 'Bridal Dreams',
        subtitle: 'Perfect for your special day',
        image: 'https://images.unsplash.com/photo-1607007790046-4a558c42850a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxicmlkYWwlMjBqZXdlbHJ5JTIwd2VkZGluZ3xlbnwxfHx8fDE3NjE3NTA5ODl8MA&ixlib=rb-4.1.0&q=80&w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'View All',
      },
    ];

    return (
      <div className="py-6 space-y-8">
        <TopCategories theme={theme} onItemClick={onViewAllClick} />
        <FeatureCarousel 
          title="Featured Collections" 
          features={featuredCollections} 
          theme={theme}
          onCardClick={(id) => onCollectionClick?.('women', id)}
        />
      </div>
    );
  }

  // Men's section
  if (category === 'men') {
    const mensFeaturedCollections = [
      {
        id: 'executive-gold',
        title: 'Executive Collection',
        subtitle: 'Refined pieces for the modern man',
        image: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Explore',
      },
      {
        id: 'platinum-power',
        title: 'Platinum Power',
        subtitle: 'Bold statements in precious metal',
        image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Shop Now',
      },
      {
        id: 'minimal-bands',
        title: 'Minimal Bands',
        subtitle: 'Understated elegance',
        image: 'https://images.unsplash.com/photo-1614015270921-161579a36d57?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Discover',
      },
      {
        id: 'formal-cufflinks',
        title: 'Formal Essentials',
        subtitle: 'Complete your professional look',
        image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'View All',
      },
    ];

    return (
      <div className="py-6 space-y-8">
        <TopCategories theme={theme} onItemClick={onViewAllClick} />
        <FeatureCarousel 
          title="Featured Collections" 
          features={mensFeaturedCollections} 
          theme={theme}
          onCardClick={(id) => onCollectionClick?.('men', id)}
        />
      </div>
    );
  }

  // Inclusive section
  if (category === 'inclusive') {
    const inclusiveFeaturedCollections = [
      {
        id: 'unisex-minimalist',
        title: 'Unisex Minimalist',
        subtitle: 'Designs for everyone',
        image: 'https://images.unsplash.com/photo-1603561596112-0a132b757442?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Explore',
      },
      {
        id: 'pride-collection',
        title: 'Pride Collection',
        subtitle: 'Celebrate love & diversity',
        image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Shop Now',
      },
      {
        id: 'neutral-designs',
        title: 'Neutral Designs',
        subtitle: 'Timeless & versatile',
        image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Discover',
      },
      {
        id: 'custom-engravings',
        title: 'Custom Engravings',
        subtitle: 'Make it uniquely yours',
        image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'View All',
      },
    ];

    return (
      <div className="py-6 space-y-8">
        <TopCategories theme={theme} onItemClick={onViewAllClick} />
        <FeatureCarousel 
          title="Featured Collections" 
          features={inclusiveFeaturedCollections} 
          theme={theme}
          onCardClick={(id) => onCollectionClick?.('inclusive', id)}
        />
      </div>
    );
  }

  // Kids section
  if (category === 'kids') {
    const kidsFeaturedCollections = [
      {
        id: 'little-charms',
        title: 'Little Charms',
        subtitle: 'Adorable pieces for little ones',
        image: 'https://images.unsplash.com/photo-1610458101708-7e9bd5ec7ae7?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Explore',
      },
      {
        id: 'birthstone-collection',
        title: 'Birthstone Magic',
        subtitle: 'Personalized for your child',
        image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Shop Now',
      },
      {
        id: 'safe-wear',
        title: 'Safe & Gentle',
        subtitle: 'Designed for delicate skin',
        image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'Discover',
      },
      {
        id: 'gift-sets',
        title: 'Gift Sets',
        subtitle: 'Perfect for special occasions',
        image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=1080',
        gradient: 'from-black/60 via-black/40 to-transparent',
        cta: 'View All',
      },
    ];

    return (
      <div className="py-6 space-y-8">
        <TopCategories theme={theme} onItemClick={onViewAllClick} />
        <FeatureCarousel 
          title="Featured Collections" 
          features={kidsFeaturedCollections} 
          theme={theme}
          onCardClick={(id) => onCollectionClick?.('kids', id)}
        />
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-6">
      {/* 1. Hero Banner */}
      <HeroBanner theme={theme} />

      {/* 2. Category Stories */}
      <CategoryStories categories={categories} theme={theme} />

      {/* 3. Handpicked For You */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h3 className={`text-[15px] ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
              Handpicked For You
            </h3>
            <p className={`text-[11px] ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
              Based on your preferences
            </p>
          </div>
          <button
            onClick={() => onViewAllClick?.('all', 'Handpicked For You')}
            className={`text-[11px] px-3 py-1.5 rounded-full transition-all duration-300 ${
              theme === 'dark'
                ? 'text-emerald-400 hover:text-emerald-300 hover:bg-emerald-500/10'
                : 'text-emerald-600 hover:text-emerald-700 hover:bg-emerald-500/10'
            }`}
          >
            View All
          </button>
        </div>
        <div className="grid grid-cols-2 gap-2">
          {handpickedProducts.map((product, index) => (
            <ProductCard key={product.id} product={product} theme={theme} index={index} onClick={onProductClick} />
          ))}
        </div>
      </div>

      {/* 4. Trending Now */}
      <ProductCarousel
        title="Trending Now"
        subtitle="Most viewed this week"
        products={trendingProducts}
        theme={theme}
        variant="trending"
        onProductClick={onProductClick}
        onViewAllClick={() => onViewAllClick?.('all', 'Trending Now')}
      />

      {/* 5. Recently Viewed */}
      {recentlyViewed.length > 0 && (
        <ProductCarousel
          title="Recently Viewed"
          subtitle="Pick up where you left off"
          products={recentlyViewed}
          theme={theme}
          variant="compact"
          onProductClick={onProductClick}
          onViewAllClick={() => onViewAllClick?.('all', 'Recently Viewed')}
        />
      )}

      {/* 6. Shop by Occasion */}
      <OccasionCards occasions={occasions} theme={theme} />

      {/* 7. Shop by Budget */}
      <PriceRangeCards ranges={priceRanges} theme={theme} />

      {/* 8. Flash Deals */}
      <FlashDeals 
        products={flashDeals} 
        endTime={flashDealsEndTime} 
        theme={theme}
        onProductClick={onProductClick}
      />

      {/* 9. Complete Your Look (Combo) */}
      <div className="space-y-4">
        <h3 className={`text-heading-sm ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
          Complete Your Look
        </h3>
        <ComboBundle combo={comboBundle} theme={theme} onClick={onBundleClick} />
      </div>

      {/* 10. Collections */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h3 className={`text-[15px] ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
            Curated Collections
          </h3>
          <button
            onClick={() => onViewAllClick?.('all', 'Collections')}
            className={`text-[11px] px-3 py-1.5 rounded-full transition-all duration-300 ${
              theme === 'dark'
                ? 'text-emerald-400 hover:text-emerald-300 hover:bg-emerald-500/10'
                : 'text-emerald-600 hover:text-emerald-700 hover:bg-emerald-500/10'
            }`}
          >
            View All
          </button>
        </div>
        <div className="grid grid-cols-2 gap-2">
          {collections.map((collection, index) => (
            <CollectionCard 
              key={collection.id} 
              collection={collection} 
              theme={theme} 
              index={index}
              onClick={onCollectionClick}
            />
          ))}
        </div>
      </div>

      {/* 11. New Arrivals */}
      <ProductCarousel
        title="New Arrivals"
        subtitle="Fresh additions to our catalog"
        products={newArrivals}
        theme={theme}
        variant="compact"
        onProductClick={onProductClick}
        onViewAllClick={() => onViewAllClick?.('all', 'New Arrivals')}
      />
    </div>
  );
}
