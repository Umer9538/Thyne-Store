import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Production Server URL
  static const String productionUrl = 'http://13.203.247.178:8080/api/v1';

  // Set to true to use production server, false for local development
  static const bool useProductionServer = true;

  // Backend API Configuration
  static String get baseUrl {
    // Check for environment override first
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Use production server if enabled
    if (useProductionServer) {
      return productionUrl;
    }

    // Auto-detect platform for development
    if (kIsWeb) {
      // Web uses localhost
      return 'http://localhost:8080/api/v1';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine
      return 'http://10.0.2.2:8080/api/v1';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:8080/api/v1';
    } else {
      // Default fallback
      return 'http://localhost:8080/api/v1';
    }
  }

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
