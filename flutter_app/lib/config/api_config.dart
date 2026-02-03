import 'package:flutter/foundation.dart';

class ApiConfig {
  // URLs - Update deviceUrl with your computer's local IP
  static const String localhostUrl = 'http://localhost:8080';
  static const String emulatorUrl = 'http://10.0.2.2:8080';
  static const String deviceUrl = 'http://192.168.68.101:8080';

  // TODO: Replace this with your deployed backend URL (from Render/Railway)
  static const String productionUrl = 'https://your-app-name.onrender.com';

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

  // Helper methods
  static String itemByIdEndpoint(String itemId) => '$itemsEndpoint/$itemId';

  static String itemsByUserEndpoint(int userId) =>
      '$itemsEndpoint/user/$userId';

  static String addCommentEndpoint(String itemId) =>
      '$itemsEndpoint/$itemId/comments';

  static String imageUrl(String path) => '$baseUrl$path';
}
