import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/lost_found_item.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _sessionCookie;

  // Get headers with session cookie
  Future<Map<String, String>> get _headers async {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    // Use session cookie for authentication
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    
    return headers;
  }

  // Save session cookie (for legacy auth)
  void _saveCookie(http.Response response) {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      _sessionCookie = cookies.split(';')[0];
    }
  }

  // ============ Authentication APIs ============

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        _saveCookie(response);
        
        // Save user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('Registering user with data: $userData');
      print('Endpoint: ${ApiConfig.registerEndpoint}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Registration error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // OTP Authentication
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        _saveCookie(response);
        
        // Save user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        
        return data;
      } else {
        return data;
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse(ApiConfig.logoutEndpoint),
        headers: await _headers,
      );
    } catch (e) {
      // Ignore errors on logout
    } finally {
      _sessionCookie = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  // ============ Lost/Found Item APIs ============

  Future<List<LostFoundItem>> getAllItems() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.itemsEndpoint),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => LostFoundItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching items: $e');
      return [];
    }
  }

  Future<List<LostFoundItem>> getItemsByUserId(int userId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.itemsByUserEndpoint(userId)),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => LostFoundItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching user items: $e');
      return [];
    }
  }

  Future<LostFoundItem?> getItemById(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.itemByIdEndpoint(itemId)),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return LostFoundItem.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching item: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createItem(LostFoundItem item) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.itemsEndpoint),
        headers: await _headers,
        body: jsonEncode(item.toJson()),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'item': LostFoundItem.fromJson(data['item'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create item'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateItem(String itemId, LostFoundItem item) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.itemByIdEndpoint(itemId)),
        headers: await _headers,
        body: jsonEncode(item.toJson()),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'item': LostFoundItem.fromJson(data['item'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update item'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteItem(String itemId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.itemByIdEndpoint(itemId)),
        headers: await _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete item'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.uploadEndpoint),
      );
      
      // Add headers (session cookie or JWT token)
      final headers = await _headers;
      request.headers.addAll(headers);
      
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'imageUrl': data['imageUrl']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to upload image'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> addComment(String itemId, String commentText) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.addCommentEndpoint(itemId)),
        headers: await _headers,
        body: jsonEncode({'commentText': commentText}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to add comment'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
