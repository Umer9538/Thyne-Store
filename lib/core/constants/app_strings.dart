/// Centralized string constants for the app.
///
/// Usage:
/// ```dart
/// Text(AppStrings.appName)
/// ```
class AppStrings {
  AppStrings._(); // Private constructor to prevent instantiation

  // ============== App Info ==============
  static const String appName = 'Thyne Jewels';
  static const String appTagline = 'Exquisite Jewelry, Timeless Elegance';

  // ============== Auth Strings ==============
  static const String welcomeTitle = 'Welcome to THYNE';
  static const String loginSubtitle = 'Sign up or log in to continue';
  static const String adminPortal = 'Admin Portal';
  static const String adminLoginSubtitle = 'Sign in with your admin credentials';
  static const String createAccount = 'Create Account';
  static const String createAccountSubtitle = 'Join us to explore exclusive jewelry';

  // ============== Button Labels ==============
  static const String continueText = 'Continue';
  static const String skip = 'SKIP';
  static const String admin = 'Admin';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String register = 'Register';
  static const String save = 'Save';
  static const String saveChanges = 'Save Changes';
  static const String cancel = 'Cancel';
  static const String submit = 'Submit';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String remove = 'Remove';
  static const String apply = 'Apply';
  static const String clear = 'Clear';
  static const String done = 'Done';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String retry = 'Retry';
  static const String resend = 'Resend';
  static const String verify = 'Verify';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sort = 'Sort';
  static const String viewAll = 'View All';
  static const String seeMore = 'See More';
  static const String showLess = 'Show Less';

  // ============== Form Labels ==============
  static const String email = 'Email';
  static const String emailAddress = 'Email Address';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String phoneNumber = 'Phone Number';
  static const String fullName = 'Full Name';
  static const String name = 'Name';
  static const String address = 'Address';
  static const String city = 'City';
  static const String state = 'State';
  static const String pincode = 'Pincode';
  static const String country = 'Country';

  // ============== Placeholders ==============
  static const String emailPlaceholder = 'admin@thynejewels.com';
  static const String passwordPlaceholder = '********';
  static const String searchPlaceholder = 'Search for jewelry...';
  static const String phonePlaceholder = 'Enter phone number';

  // ============== Success Messages ==============
  static const String otpSentSuccess = 'OTP sent successfully';
  static const String otpVerifiedSuccess = 'OTP verified successfully';
  static const String profileUpdatedSuccess = 'Profile updated successfully!';
  static const String orderPlacedSuccess = 'Order placed successfully!';
  static const String addressSavedSuccess = 'Address saved successfully!';
  static const String itemAddedToCart = 'Item added to cart';
  static const String itemRemovedFromCart = 'Item removed from cart';
  static const String itemAddedToWishlist = 'Item added to wishlist';
  static const String itemRemovedFromWishlist = 'Item removed from wishlist';

  // ============== Error Messages ==============
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection';
  static const String invalidCredentials = 'Invalid email or password';
  static const String otpSendFailed = 'Failed to send OTP. Please try again.';
  static const String otpVerifyFailed = 'Failed to verify OTP. Please try again.';
  static const String accessDenied = 'Access denied. Admin privileges required.';
  static const String sessionExpired = 'Session expired. Please login again.';
  static const String serviceUnavailable = 'Service temporarily unavailable';
  static const String smsServiceNotConfigured = 'SMS service is not configured';

  // ============== Validation Messages ==============
  static const String enterEmail = 'Please enter your email';
  static const String validEmail = 'Please enter a valid email address';
  static const String enterPassword = 'Please enter your password';
  static const String passwordMinLength = 'Password must be at least 6 characters';
  static const String enterPhone = 'Please enter your phone number';
  static const String validPhone = 'Please enter a valid phone number';
  static const String enterName = 'Please enter your name';
  static const String enterOtp = 'Please enter the OTP';
  static const String passwordsNotMatch = 'Passwords do not match';
  static const String agreeToTerms = 'Please agree to the terms and conditions';

  // ============== Labels ==============
  static const String forgotPassword = 'Forgot Password?';
  static const String rememberMe = 'Remember Me';
  static const String termsOfService = 'Terms of Service';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsAndConditions = 'Terms and Conditions';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String byContinuingYouAgree = 'By continuing, you agree to our';
  static const String and = 'and';

  // ============== Notification Preferences ==============
  static const String notifyOrdersUpdates = 'Notify me of orders, updates and offers';
  static const String subscribeNewsletter = 'Subscribe to email newsletter';

  // ============== Admin ==============
  static const String adminAccessOnly = 'Admin Access Only';
  static const String adminAccessWarning = 'This portal is restricted to authorized personnel only. All login attempts are logged.';

  // ============== OTP ==============
  static const String enterVerificationCode = 'Enter Verification Code';
  static const String otpSentTo = 'We sent a 6-digit code to';
  static const String didntReceiveCode = "Didn't receive the code?";
  static const String resendOtp = 'Resend OTP';
  static const String resendIn = 'Resend in';

  // ============== Profile ==============
  static const String editProfile = 'Edit Profile';
  static const String myProfile = 'My Profile';
  static const String myOrders = 'My Orders';
  static const String myAddresses = 'My Addresses';
  static const String myWishlist = 'My Wishlist';
  static const String settings = 'Settings';
  static const String tapToChangePhoto = 'Tap camera icon to change photo';

  // ============== Products ==============
  static const String products = 'Products';
  static const String categories = 'Categories';
  static const String collections = 'Collections';
  static const String newArrivals = 'New Arrivals';
  static const String bestSellers = 'Best Sellers';
  static const String featured = 'Featured';
  static const String onSale = 'On Sale';
  static const String addToCart = 'Add to Cart';
  static const String buyNow = 'Buy Now';
  static const String outOfStock = 'Out of Stock';
  static const String inStock = 'In Stock';
  static const String limitedStock = 'Limited Stock';

  // ============== Cart ==============
  static const String cart = 'Cart';
  static const String myCart = 'My Cart';
  static const String cartEmpty = 'Your cart is empty';
  static const String cartEmptySubtitle = 'Looks like you haven\'t added anything to your cart yet';
  static const String subtotal = 'Subtotal';
  static const String shipping = 'Shipping';
  static const String tax = 'Tax';
  static const String total = 'Total';
  static const String proceedToCheckout = 'Proceed to Checkout';
  static const String continueShopping = 'Continue Shopping';

  // ============== Checkout ==============
  static const String checkout = 'Checkout';
  static const String shippingAddress = 'Shipping Address';
  static const String paymentMethod = 'Payment Method';
  static const String orderSummary = 'Order Summary';
  static const String placeOrder = 'Place Order';

  // ============== Orders ==============
  static const String orders = 'Orders';
  static const String orderHistory = 'Order History';
  static const String orderDetails = 'Order Details';
  static const String trackOrder = 'Track Order';
  static const String orderPlaced = 'Order Placed';
  static const String orderConfirmed = 'Order Confirmed';
  static const String orderShipped = 'Order Shipped';
  static const String orderDelivered = 'Order Delivered';
  static const String orderCancelled = 'Order Cancelled';

  // ============== Empty States ==============
  static const String noProducts = 'No products found';
  static const String noOrders = 'No orders yet';
  static const String noAddresses = 'No addresses saved';
  static const String noItemsInWishlist = 'Your wishlist is empty';
  static const String noSearchResults = 'No results found';
  static const String noNotifications = 'No notifications';

  // ============== Loading States ==============
  static const String loading = 'Loading...';
  static const String saving = 'Saving...';
  static const String processing = 'Processing...';
  static const String pleaseWait = 'Please wait...';

  // ============== Misc ==============
  static const String gallery = 'Gallery';
  static const String camera = 'Camera';
  static const String optional = 'Optional';
  static const String required = 'Required';
}
