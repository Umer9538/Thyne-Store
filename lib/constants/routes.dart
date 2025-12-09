/// Centralized route constants for the application.
/// Use these constants instead of hardcoded route strings.
class Routes {
  Routes._();

  // Auth routes
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String adminLogin = '/admin-login';

  // Main routes
  static const String home = '/home';
  static const String homeFigma = '/home-figma';
  static const String homeOld = '/home-old';
  static const String homeLegacy = '/home-legacy';

  // Shopping routes
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String guestCheckout = '/guest-checkout';
  static const String search = '/search';
  static const String wishlist = '/wishlist';
  static const String loyalty = '/loyalty';

  // Order routes
  static const String orders = '/orders';
  static const String orderHistory = '/order-history';
  static const String trackOrder = '/track-order';

  // Profile routes
  static const String profile = '/profile';
  static const String addresses = '/addresses';

  // Community routes
  static const String community = '/community';
  static const String communityCreate = '/community/create';

  // Admin routes
  static const String admin = '/admin';
  static const String adminProducts = '/admin/products';
  static const String adminCategories = '/admin/categories';
  static const String adminInventory = '/admin/inventory';
  static const String adminOrders = '/admin/orders';
  static const String adminCustomOrders = '/admin/custom-orders';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminCustomers = '/admin/customers';
  static const String adminStorefront = '/admin/storefront';
  static const String adminStorefrontData = '/admin/storefront-data';
  static const String adminEvents = '/admin/events';
  static const String adminBanners = '/admin/banners';
  static const String adminHomepageLayout = '/admin/homepage-layout';
  static const String adminThemes = '/admin/themes';
  static const String adminCommunity = '/admin/community';
  static const String adminStoreSettings = '/admin/store-settings';

  // Admin Dynamic Content routes
  static const String adminDynamicContent = '/admin/dynamic-content';
  static const String adminDealsOfDay = '/admin/deals-of-day';
  static const String adminDealsOfDayCreate = '/admin/deals-of-day/create';
  static const String adminBundleDeals = '/admin/bundle-deals';
  static const String adminBundleDealsCreate = '/admin/bundle-deals/create';
  static const String adminFlashSales = '/admin/flash-sales';
  static const String adminFlashSalesCreate = '/admin/flash-sales/create';
  static const String adminShowcases360 = '/admin/showcases-360';
  static const String adminShowcases360Create = '/admin/showcases-360/create';
  static const String adminBrands = '/admin/brands';

  /// All route entries for MaterialApp routes property
  static const List<String> allRoutes = [
    onboarding,
    login,
    adminLogin,
    home,
    homeFigma,
    homeOld,
    homeLegacy,
    cart,
    checkout,
    guestCheckout,
    search,
    wishlist,
    loyalty,
    orders,
    orderHistory,
    trackOrder,
    profile,
    addresses,
    community,
    communityCreate,
    admin,
    adminProducts,
    adminCategories,
    adminInventory,
    adminOrders,
    adminCustomOrders,
    adminAnalytics,
    adminCustomers,
    adminStorefront,
    adminStorefrontData,
    adminEvents,
    adminBanners,
    adminHomepageLayout,
    adminThemes,
    adminCommunity,
    adminStoreSettings,
    adminDynamicContent,
    adminDealsOfDay,
    adminDealsOfDayCreate,
    adminBundleDeals,
    adminBundleDealsCreate,
    adminFlashSales,
    adminFlashSalesCreate,
    adminShowcases360,
    adminShowcases360Create,
    adminBrands,
  ];
}
