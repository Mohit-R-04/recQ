class ApiConfig {
  // Update this to your backend URL
  static const String baseUrl = 'http://localhost:8080';
  static const String apiUrl = '$baseUrl/api';
  
  // API Endpoints
  static const String loginEndpoint = '$apiUrl/auth/login';
  static const String registerEndpoint = '$apiUrl/auth/register';
  static const String logoutEndpoint = '$apiUrl/auth/logout';
  static const String currentUserEndpoint = '$apiUrl/auth/me';
  
  static const String itemsEndpoint = '$apiUrl/items';
  static const String uploadEndpoint = '$apiUrl/items/upload';
  
  // Helper methods
  static String itemByIdEndpoint(String itemId) => '$itemsEndpoint/$itemId';
  static String itemsByUserEndpoint(int userId) => '$itemsEndpoint/user/$userId';
  static String addCommentEndpoint(String itemId) => '$itemsEndpoint/$itemId/comments';
  static String imageUrl(String path) => '$baseUrl$path';
}
