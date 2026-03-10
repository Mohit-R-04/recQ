import 'package:flutter/foundation.dart';

class ApiConfig {
  // Local URLs for development
  static const String localhostUrl = 'http://localhost:8080';
  static const String emulatorUrl = 'http://10.0.2.2:8080';
  static const String deviceUrl = 'http://192.168.68.102:8080';

  // Pass in Railway backend URL at build time:
  // flutter build apk --release --dart-define=PROD_API_URL=https://your-app.up.railway.app
  static const String productionUrl = String.fromEnvironment(
    'PROD_API_URL',
    defaultValue: 'https://your-app.up.railway.app',
  );

  // Set to true when testing on physical device, false for emulator
  static const bool usePhysicalDevice = true;

  /// Automatically choose correct base URL
  static String get baseUrl {
    if (kReleaseMode) {
      // Use production URL in release builds (deployed app)
      return productionUrl;
    }
    if (kIsWeb) {
      return localhostUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Use deviceUrl for physical device, emulatorUrl for emulator
      return usePhysicalDevice ? deviceUrl : emulatorUrl;
    }
    // iOS Simulator / macOS / others
    return localhostUrl;
  }

  // API base
  static String get apiUrl => '$baseUrl/api';

  // Auth endpoints
  static String get loginEndpoint => '$apiUrl/auth/login';
  static String get registerEndpoint => '$apiUrl/auth/register';
  static String get logoutEndpoint => '$apiUrl/auth/logout';
  static String get currentUserEndpoint => '$apiUrl/auth/me';

  // Item endpoints
  static String get itemsEndpoint => '$apiUrl/items';
  static String get uploadEndpoint => '$apiUrl/items/upload';

  // Claim endpoints
  static String get claimsEndpoint => '$apiUrl/claims';
  static String get myClaimsEndpoint => '$apiUrl/claims/my';
  static String get adminAllClaimsEndpoint => '$apiUrl/claims/admin/all';
  static String claimsByItemEndpoint(String itemId) =>
      '$apiUrl/claims/item/$itemId';
  static String reviewClaimEndpoint(String claimId) =>
      '$apiUrl/claims/$claimId/review';
  static String checkClaimEndpoint(String itemId) =>
      '$apiUrl/claims/check/$itemId';
  static String claimByIdEndpoint(String claimId) => '$apiUrl/claims/$claimId';
  static String claimQuestionsEndpoint(String itemId, {int numQuestions = 5}) =>
      '$apiUrl/claims/questions/$itemId?numQuestions=$numQuestions';

  // Optional ML service URL override
  static const String mlServiceUrl = String.fromEnvironment(
    'ML_SERVICE_URL',
    defaultValue: '',
  );
  static String get generateQuestionsEndpoint =>
      '$mlServiceUrl/generate-questions';

  // Helper methods
  static String itemByIdEndpoint(String itemId) => '$itemsEndpoint/$itemId';
  static String itemDescriptionEndpoint(String itemId) =>
      '$itemsEndpoint/$itemId/description';

  static String itemsByUserEndpoint(int userId) =>
      '$itemsEndpoint/user/$userId';

  static String addCommentEndpoint(String itemId) =>
      '$itemsEndpoint/$itemId/comments';

  static String imageUrl(String path) => '$baseUrl$path';
}
