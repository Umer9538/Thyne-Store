class ApiConfig {
  // Backend API Configuration
  // Use environment variable for production, default to localhost:8080 for development
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  // Production URL (set via --dart-define=API_BASE_URL=https://api.thynejewels.com/api/v1)
  static const bool isProduction = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  ) == 'production';

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
  
  // Debug settings - disable in production
  static bool get enableApiLogging => !isProduction;
  static bool get enableMockFallback => !isProduction;
}
