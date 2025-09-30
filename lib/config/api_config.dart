class ApiConfig {
  // Backend API Configuration
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  // For production, you might want to use environment variables
  // static const String baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'https://your-production-api.com/api/v1',
  // );
  
  // API timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Cache configuration
  static const Duration cacheExpiration = Duration(hours: 1);
  static const bool enableOfflineMode = true;
  
  // Feature flags
  static const bool enableBackendIntegration = true;
  static const bool enableImageUpload = true;
  static const bool enableRealTimeUpdates = false;
  
  // Debug settings
  static const bool enableApiLogging = true;
  static const bool enableMockFallback = true;
}
