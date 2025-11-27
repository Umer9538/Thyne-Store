import { useState, useEffect, useRef } from 'react';
import { CollapsibleAppBar } from './components/CollapsibleAppBar';
import { CollapsibleBottomToolbar } from './components/CollapsibleBottomToolbar';
import { CommerceTopNav } from './components/CommerceTopNav';
import { CommunityTopNav } from './components/CommunityTopNav';
import { CreateTopNav } from './components/CreateTopNav';
import { CommerceContent } from './components/commerce/CommerceContent';
import { CommerceShimmer } from './components/CommerceShimmer';
import { Wishlist } from './components/Wishlist';
import { ShoppingBag } from './components/ShoppingBag';
import { SearchOverlay } from './components/SearchOverlay';
import { CreateSection } from './components/CreateSection';
import { CommunitySection } from './components/CommunitySection';
import { ProductDetail, ProductDetailData } from './components/ProductDetail';
import { BundleDetail, BundleDetailData } from './components/BundleDetail';
import { ProductList } from './components/ProductList';
import { SplashScreen } from './components/SplashScreen';
import { SignUpLoginScreen } from './components/SignUpLoginScreen';
import { OTPScreen } from './components/OTPScreen';
import { productsWithDetails } from './data/jewelryData';

type AuthFlow = 'splash' | 'signup' | 'otp' | 'authenticated';

export default function App() {
  const [authFlow, setAuthFlow] = useState<AuthFlow>('splash');
  const [userContact, setUserContact] = useState<string>('');
  const [isHeaderVisible, setIsHeaderVisible] = useState(true);
  const [isToolbarVisible, setIsToolbarVisible] = useState(true);
  const [selectedTab, setSelectedTab] = useState<'commerce' | 'community' | 'create'>('commerce');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [communityTab, setCommunityTab] = useState<'verse' | 'spotlight' | 'profile'>('verse');
  const [createTab, setCreateTab] = useState<'chat' | 'creations' | 'history'>('chat');
  
  // App operates only in light mode
  const theme = 'light';
  const [isLoading, setIsLoading] = useState(true);
  const [currentScreen, setCurrentScreen] = useState<'main' | 'wishlist' | 'bag' | 'product' | 'bundle' | 'productlist'>('main');
  const [productListCategory, setProductListCategory] = useState<string>('all');
  const [productListTitle, setProductListTitle] = useState<string>('All Products');
  const [bagItemCount, setBagItemCount] = useState(3); // Mock count
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [remixPrompt, setRemixPrompt] = useState('');
  const [isFullScreenOpen, setIsFullScreenOpen] = useState(false);
  const [currentProductId, setCurrentProductId] = useState<string | null>(null);
  const [currentBundleId, setCurrentBundleId] = useState<string | null>(null);
  const lastScrollY = useRef(0);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  // Mock product data
  const mockProducts: { [key: string]: ProductDetailData } = {
    'p1': {
      id: 'p1',
      name: 'Premium Silk Evening Dress',
      price: 12999,
      originalPrice: 16999,
      images: [
        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=1080',
        'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=1080',
        'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=1080',
      ],
      description: 'Elevate your evening wardrobe with this stunning silk dress. Crafted from premium quality silk with an elegant drape, this dress features a timeless silhouette that flatters every body type. Perfect for formal events, cocktail parties, or special occasions.',
      rating: 4.8,
      reviewCount: 234,
      badge: 'Bestseller',
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      colors: [
        { name: 'Forest Green', hex: '#094010' },
        { name: 'Black', hex: '#000000' },
        { name: 'Navy', hex: '#1e3a8a' },
      ],
      details: {
        material: '100% Mulberry Silk',
        care: 'Dry clean only',
        origin: 'Made in Italy',
        sku: 'SED-2024-001',
      },
      features: ['Premium Quality', 'Free Delivery', 'Secure Payment'],
      inStock: true,
      deliveryInfo: 'Free express delivery on orders over ₹2,000. Standard delivery in 3-5 business days. Easy returns within 30 days.',
    },
    'p2': {
      id: 'p2',
      name: 'Diamond Statement Earrings',
      price: 2499,
      images: [
        'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=1080',
        'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=1080',
      ],
      description: 'Add a touch of sparkle to any outfit with these exquisite diamond statement earrings. Featuring brilliant-cut diamonds set in premium sterling silver, these earrings catch the light beautifully.',
      rating: 4.9,
      reviewCount: 156,
      details: {
        material: 'Sterling Silver, Cubic Zirconia',
        care: 'Wipe with soft cloth',
        origin: 'Made in India',
        sku: 'EAR-2024-002',
      },
      features: ['Premium Quality', 'Free Delivery', 'Secure Payment'],
      inStock: true,
      deliveryInfo: 'Free delivery on all jewelry. Arrives in luxury packaging. 14-day return policy.',
    },
  };

  // Mock bundle data
  const mockBundles: { [key: string]: BundleDetailData } = {
    'b1': {
      id: 'b1',
      name: 'Complete Luxury Evening Set',
      description: 'Get the complete luxury evening look with this curated bundle. Includes our bestselling silk evening dress paired perfectly with statement diamond earrings. Save big when you buy them together!',
      products: [
        {
          id: 'p1',
          name: 'Premium Silk Evening Dress',
          price: 12999,
          image: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400',
          description: 'Elegant silk evening dress',
        },
        {
          id: 'p2',
          name: 'Diamond Statement Earrings',
          price: 2499,
          image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400',
          description: 'Sparkling diamond earrings',
        },
      ],
      totalPrice: 15498,
      discountedPrice: 13499,
      savings: 1999,
      savingsPercent: 13,
      mainImage: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1080',
      rating: 4.9,
      reviewCount: 89,
      features: ['Premium Quality', 'Free Delivery', 'Secure Payment'],
      deliveryInfo: 'Free express delivery on all bundles. Ships together in premium packaging. 30-day easy returns.',
      inStock: true,
    },
  };

  // Simulate initial data loading (only when authenticated)
  useEffect(() => {
    if (authFlow === 'authenticated') {
      const timer = setTimeout(() => {
        setIsLoading(false);
      }, 1500);
      return () => clearTimeout(timer);
    }
  }, [authFlow]);

  // Simulate loading when category changes
  useEffect(() => {
    if (selectedCategory !== 'all') {
      setIsLoading(true);
      const timer = setTimeout(() => {
        setIsLoading(false);
      }, 800);
      return () => clearTimeout(timer);
    }
  }, [selectedCategory]);

  // Show nav bars when changing tabs
  useEffect(() => {
    setIsHeaderVisible(true);
    setIsToolbarVisible(true);
    lastScrollY.current = 0;
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = 0;
    }
  }, [selectedTab]);

  // Show nav bars when exiting fullscreen (without resetting scroll)
  useEffect(() => {
    if (!isFullScreenOpen) {
      setIsHeaderVisible(true);
      setIsToolbarVisible(true);
    }
  }, [isFullScreenOpen]);

  useEffect(() => {
    const handleScroll = () => {
      const container = scrollContainerRef.current;
      if (!container) return;

      // Don't hide/show nav when in fullscreen mode
      if (isFullScreenOpen) return;

      const currentScrollY = container.scrollTop;
      const scrollDiff = currentScrollY - lastScrollY.current;
      
      // Only trigger if scrolled more than 5px (avoid jittery behavior)
      if (Math.abs(scrollDiff) < 5) return;
      
      // Scrolling UP - hide both (collapse when going up)
      if (scrollDiff < 0 && currentScrollY > 50) {
        setIsHeaderVisible(false);
        setIsToolbarVisible(false);
      } 
      // Scrolling DOWN - show both (expand when scrolling down)
      else if (scrollDiff > 0) {
        setIsHeaderVisible(true);
        setIsToolbarVisible(true);
      }
      
      lastScrollY.current = currentScrollY;
    };

    const container = scrollContainerRef.current;
    if (container) {
      container.addEventListener('scroll', handleScroll, { passive: true });
      return () => container.removeEventListener('scroll', handleScroll);
    }
  }, [isFullScreenOpen]);

  const handleWishlistClick = () => {
    setCurrentScreen('wishlist');
  };

  const handleBagClick = () => {
    setCurrentScreen('bag');
  };

  const handleBackToMain = () => {
    setCurrentScreen('main');
  };

  const handleAddToBag = (id: string) => {
    // Mock add to bag
    setBagItemCount(prev => prev + 1);
  };

  const handleSearchClick = () => {
    // Only open search overlay for commerce and community
    if (selectedTab === 'commerce' || selectedTab === 'community') {
      setIsSearchOpen(true);
    }
  };

  const handleSearchClose = () => {
    setIsSearchOpen(false);
    setSearchQuery('');
  };

  const handleProductClick = (productId: string) => {
    setCurrentProductId(productId);
    setCurrentScreen('product');
  };

  const handleBundleClick = (bundleId: string) => {
    setCurrentBundleId(bundleId);
    setCurrentScreen('bundle');
  };

  const handleViewAllClick = (category?: string, title?: string) => {
    setProductListCategory(category || 'all');
    setProductListTitle(title || 'All Products');
    setCurrentScreen('productlist');
  };

  const handleCollectionClick = (category: string, title: string) => {
    setProductListCategory(category);
    setProductListTitle(title);
    setCurrentScreen('productlist');
  };

  const handleRemixPrompt = (prompt: string) => {
    setRemixPrompt(prompt);
  };

  const handleNavigateToCreate = () => {
    setSelectedTab('create');
  };

  // Keyboard shortcut for search (Cmd+K / Ctrl+K)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        if (selectedTab === 'commerce' || selectedTab === 'community') {
          setIsSearchOpen(true);
        }
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [selectedTab]);

  // Auth flow screens
  if (authFlow === 'splash') {
    return <SplashScreen onComplete={() => setAuthFlow('signup')} />;
  }

  if (authFlow === 'signup') {
    return (
      <SignUpLoginScreen
        onContinue={(contact) => {
          setUserContact(contact);
          setAuthFlow('otp');
        }}
        onSkip={() => setAuthFlow('authenticated')}
        onBack={() => setAuthFlow('splash')}
      />
    );
  }

  if (authFlow === 'otp') {
    return (
      <OTPScreen
        contact={userContact}
        onVerify={() => setAuthFlow('authenticated')}
        onBack={() => setAuthFlow('signup')}
      />
    );
  }

  // Show wishlist or bag screens
  if (currentScreen === 'wishlist') {
    return <Wishlist onBack={handleBackToMain} onAddToBag={handleAddToBag} />;
  }

  if (currentScreen === 'bag') {
    return <ShoppingBag onBack={handleBackToMain} />;
  }

  // Show product list screen
  if (currentScreen === 'productlist') {
    return (
      <ProductList
        onBack={handleBackToMain}
        onProductClick={handleProductClick}
        category={productListCategory}
        title={productListTitle}
      />
    );
  }

  // Show product detail screen - convert jewelry data to ProductDetailData
  if (currentScreen === 'product' && currentProductId) {
    // Try to find in jewelry data first
    const jewelryProduct = productsWithDetails.find(p => p.id === currentProductId);
    
    if (jewelryProduct) {
      const product: ProductDetailData = {
        id: jewelryProduct.id,
        name: jewelryProduct.name,
        price: jewelryProduct.price,
        originalPrice: jewelryProduct.originalPrice,
        images: [jewelryProduct.image, jewelryProduct.image, jewelryProduct.image], // Use same image multiple times
        description: jewelryProduct.description || `Exquisite ${jewelryProduct.name.toLowerCase()} crafted with precision and elegance. Perfect for any occasion, this piece combines traditional craftsmanship with contemporary design.`,
        rating: jewelryProduct.rating,
        reviewCount: Math.floor(Math.random() * 200) + 50,
        badge: jewelryProduct.badge,
        details: {
          material: jewelryProduct.category === 'bangles' ? '22K Gold' : 
                    jewelryProduct.category === 'pendants' ? 'Gold Plated Sterling Silver' :
                    jewelryProduct.category === 'rings' ? '18K Gold' : 
                    '14K Gold',
          care: 'Clean with soft cloth, avoid harsh chemicals. Store in a dry place away from moisture. Remove before bathing or swimming.',
          origin: 'Made in India',
          sku: jewelryProduct.id.toUpperCase(),
          weight: jewelryProduct.category === 'bangles' ? '15-20g' :
                  jewelryProduct.category === 'rings' ? '3-5g' :
                  jewelryProduct.category === 'pendants' ? '2-4g' :
                  '8-12g',
          dimensions: jewelryProduct.category === 'bangles' ? '2.6 inches diameter' :
                      jewelryProduct.category === 'rings' ? 'Adjustable' :
                      jewelryProduct.category === 'pendants' ? '1.5 x 1 inch' :
                      'Standard',
        },
        features: ['Hallmark Certified', 'Free Delivery', 'Secure Payment', 'Easy Returns'],
        inStock: true,
        deliveryInfo: 'Free delivery on all jewelry. Ships in 2-3 business days. 30-day return policy.',
      };

      // Get similar products from same category
      const similarProducts = productsWithDetails
        .filter(p => p.category === jewelryProduct.category && p.id !== jewelryProduct.id)
        .slice(0, 4)
        .map(p => ({
          id: p.id,
          name: p.name,
          price: `₹${p.price.toLocaleString('en-IN')}`,
          image: p.image,
        }));

      return (
        <ProductDetail
          product={product}
          theme={theme}
          onClose={handleBackToMain}
          onAddToBag={(productId, size, color) => {
            handleAddToBag(productId);
            console.log('Added to bag:', productId, size, color);
          }}
          onAddToWishlist={(productId) => {
            console.log('Added to wishlist:', productId);
          }}
          similarProducts={similarProducts}
          onSimilarProductClick={handleProductClick}
        />
      );
    }
    
    // Fallback to mock products
    if (mockProducts[currentProductId]) {
      const product = mockProducts[currentProductId];
      return (
        <ProductDetail
          product={product}
          theme={theme}
          onClose={handleBackToMain}
          onAddToBag={(productId, size, color) => {
            handleAddToBag(productId);
            console.log('Added to bag:', productId, size, color);
          }}
          onAddToWishlist={(productId) => {
            console.log('Added to wishlist:', productId);
          }}
          similarProducts={[
            {
              id: 'p3',
              name: 'Velvet Evening Gown',
              price: '₹14,999',
              image: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400',
            },
            {
              id: 'p4',
              name: 'Satin Cocktail Dress',
              price: '₹9,999',
              image: 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=400',
            },
          ]}
          onSimilarProductClick={handleProductClick}
        />
      );
    }
  }

  // Show bundle detail screen
  if (currentScreen === 'bundle' && currentBundleId && mockBundles[currentBundleId]) {
    const bundle = mockBundles[currentBundleId];
    return (
      <BundleDetail
        bundle={bundle}
        onClose={handleBackToMain}
        onAddToBag={(bundleId) => {
          handleAddToBag(bundleId);
          console.log('Added bundle to bag:', bundleId);
        }}
        onAddToWishlist={(bundleId) => {
          console.log('Added bundle to wishlist:', bundleId);
        }}
        onProductClick={handleProductClick}
        similarBundles={[
          {
            id: 'b2',
            name: 'Weekend Casual Bundle',
            price: 8999,
            originalPrice: 11999,
            image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400',
          },
          {
            id: 'b3',
            name: 'Office Essentials Bundle',
            price: 12999,
            originalPrice: 16999,
            image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400',
          },
        ]}
      />
    );
  }

  return (
    <div className="h-screen w-screen overflow-hidden transition-colors duration-500 bg-[#fffff0]">
      {/* Collapsible App Bar - hide when fullscreen is open */}
      {!isFullScreenOpen && (
        <CollapsibleAppBar 
          isVisible={isHeaderVisible} 
          onWishlistClick={handleWishlistClick}
          onBagClick={handleBagClick}
          bagItemCount={bagItemCount}
        />
      )}

      {/* Commerce Top Nav - Sticky below app bar, moves to top when app bar hides */}
      {selectedTab === 'commerce' && !isFullScreenOpen && (
        <CommerceTopNav
          isVisible={isHeaderVisible}
          selectedCategory={selectedCategory}
          onCategoryChange={setSelectedCategory}
        />
      )}

      {/* Community Top Nav */}
      {selectedTab === 'community' && !isFullScreenOpen && (
        <CommunityTopNav
          isVisible={isHeaderVisible}
          selectedTab={communityTab}
          onTabChange={setCommunityTab}
          theme={theme}
        />
      )}

      {/* Create Top Nav */}
      {selectedTab === 'create' && !isFullScreenOpen && (
        <CreateTopNav
          isVisible={isHeaderVisible}
          selectedTab={createTab}
          onTabChange={setCreateTab}
        />
      )}

      {/* Main Content Area */}
      <div 
        ref={scrollContainerRef}
        className={`h-full w-full overflow-y-auto ${
          isFullScreenOpen ? 'pt-0 pb-0' :
          selectedTab === 'commerce' ? 'pt-[180px] pb-[200px]' 
          : selectedTab === 'create' ? 'pt-[228px] pb-[200px]' 
          : selectedTab === 'community' ? 'pt-[104px] pb-[200px]' 
          : 'pt-16 pb-36'
        }`}
        style={{
          scrollbarWidth: 'none',
          msOverflowStyle: 'none',
        }}
      >
        <style>{`
          div::-webkit-scrollbar {
            display: none;
          }
        `}</style>
        
        {/* Content Area */}
        <div className={isFullScreenOpen ? 'px-0' : 'px-4'}>
          {selectedTab === 'commerce' && (
            <>
              {isLoading ? (
                <CommerceShimmer />
              ) : (
                <CommerceContent 
                  theme={theme}
                  category={selectedCategory}
                  onProductClick={handleProductClick}
                  onBundleClick={handleBundleClick}
                  onViewAllClick={handleViewAllClick}
                  onCollectionClick={handleCollectionClick}
                />
              )}
            </>
          )}

          {selectedTab === 'community' && (
            <CommunitySection 
              activeTab={communityTab}
              onProductClick={handleProductClick}
              onRemixPrompt={handleRemixPrompt}
              onNavigateToCreate={handleNavigateToCreate}
              onFullScreenChange={setIsFullScreenOpen}
              theme={theme}
            />
          )}

          {selectedTab === 'create' && (
            <CreateSection activeTab={createTab} initialPrompt={remixPrompt} />
          )}
        </div>
      </div>

      {/* Collapsible Bottom Toolbar - hide when fullscreen is open */}
      {!isFullScreenOpen && (
        <CollapsibleBottomToolbar 
          isVisible={isToolbarVisible} 
          selectedTab={selectedTab}
          onTabChange={setSelectedTab}
          theme={theme}
          onSearchClick={handleSearchClick}
          searchQuery={searchQuery}
          onSearchQueryChange={setSearchQuery}
          isSearchOpen={isSearchOpen}
        />
      )}

      {/* Search Overlay - appears above search bar */}
      <SearchOverlay 
        isOpen={isSearchOpen}
        onClose={handleSearchClose}
        currentTab={selectedTab}
        query={searchQuery}
        onQueryChange={setSearchQuery}
      />
    </div>
  );
}
