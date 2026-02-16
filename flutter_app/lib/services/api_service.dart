import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html'; // Conditional import
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/lost_found_item.dart';
import '../models/item_match.dart';
import '../models/notification.dart';
import 'tflite_classifier.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _sessionCookie;
  final TFLiteClassifier _tfliteClassifier = TFLiteClassifier();

  // Get headers with session cookie
  Future<Map<String, String>> get _headers async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Load cookie from SharedPreferences if not in memory
    if (_sessionCookie == null) {
      await _loadCookie();
    }

    // Use session cookie for authentication
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }

    return headers;
  }

  // Load session cookie from SharedPreferences
  Future<void> _loadCookie() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
  }

  // Save session cookie (for legacy auth)
  Future<void> _saveCookie(http.Response response) async {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      _sessionCookie = cookies.split(';')[0];
      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_cookie', _sessionCookie!);
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
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed'
        };
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

  Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
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
      await prefs.remove('session_cookie');
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

      // Check for empty response body
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server returned empty response. Is the backend running?'
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'item': LostFoundItem.fromJson(data['item'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create item'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateItem(
      String itemId, LostFoundItem item) async {
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
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update item'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateItemDescription(
      String itemId, String description) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.itemDescriptionEndpoint(itemId)),
        headers: await _headers,
        body: jsonEncode({'description': description}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'item': LostFoundItem.fromJson(data['item'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update description'
        };
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
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete item'
        };
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

      // Handle mobile/desktop upload (File from dart:io, but we used conditional import)
      // If we are here, kIsWeb is false, so dart:io should be available?
      // But conditional import imports dart:html on web.
      // On mobile, it imports dart:io.
      // We should treat imageFile as dynamic and assume it has path if not on web.
      request.files.add(
        await http.MultipartFile.fromPath('file', (imageFile as dynamic).path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'imageUrl': data['imageUrl']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload image'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> addComment(
      String itemId, String commentText) async {
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
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add comment'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ============ ML Classification API ============

  /// Classify an image using TensorFlow Lite (on-device)
  /// Returns predicted class, confidence, and suggested backend category
  Future<Map<String, dynamic>> classifyImage(dynamic imageFile) async {
    try {
      // Use TFLite for on-device inference
      final result = await _tfliteClassifier.classifyImage(imageFile);

      if (result != null) {
        return {
          'success': true,
          'predictedClass': result['predictedClass'],
          'confidence': result['confidence'],
          'backendCategory': result['backendCategory'],
          'allProbabilities': result['allProbabilities'],
        };
      } else {
        return {'success': false, 'message': 'Failed to classify image'};
      }
    } catch (e) {
      print('TFLite Classification error: $e');
      return {'success': false, 'message': 'Classification failed: $e'};
    }
  }

  /// Initialize TFLite model (call during app startup)
  Future<bool> initializeTFLite() async {
    return await _tfliteClassifier.initialize();
  }

  // ============ Matching APIs ============

  /// Find matches for a specific item
  Future<Map<String, dynamic>> findMatchesForItem(String itemId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/items/$itemId/find-matches'),
        headers: await _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        List<ItemMatch> matches = [];
        if (data['matches'] != null) {
          matches = (data['matches'] as List)
              .map((m) => ItemMatch.fromJson(m))
              .toList();
        }
        return {
          'success': true,
          'matchCount': data['matchCount'] ?? 0,
          'matches': matches,
          'message': data['message'] ?? 'Matches found',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to find matches'
        };
      }
    } catch (e) {
      print('Error finding matches: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get pending matches for current user
  Future<List<ItemMatch>> getPendingMatches() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/matches'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['matches'] != null) {
          return (data['matches'] as List)
              .map((m) => ItemMatch.fromJson(m))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching pending matches: $e');
      return [];
    }
  }

  /// Get all matches for current user
  Future<List<ItemMatch>> getAllMatches() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/matches/all'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['matches'] != null) {
          return (data['matches'] as List)
              .map((m) => ItemMatch.fromJson(m))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching all matches: $e');
      return [];
    }
  }

  /// Get match by ID
  Future<ItemMatch?> getMatchById(String matchId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/matches/$matchId'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['match'] != null) {
          return ItemMatch.fromJson(data['match']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching match: $e');
      return null;
    }
  }

  /// Confirm a match
  Future<Map<String, dynamic>> confirmMatch(String matchId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/matches/$matchId/confirm'),
        headers: await _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'match':
              data['match'] != null ? ItemMatch.fromJson(data['match']) : null,
          'message': data['message'] ?? 'Match confirmed!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to confirm match'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Dismiss a match
  Future<Map<String, dynamic>> dismissMatch(String matchId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/matches/$matchId/dismiss'),
        headers: await _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Match dismissed'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to dismiss match'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get pending match count
  Future<int> getPendingMatchCount() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/matches/count'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching match count: $e');
      return 0;
    }
  }

  // ============ Notification APIs ============

  /// Get all notifications for current user
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['notifications'] != null) {
          return (data['notifications'] as List)
              .map((n) => AppNotification.fromJson(n))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notifications
  Future<Map<String, dynamic>> getUnreadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/unread'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<AppNotification> notifications = [];
        if (data['notifications'] != null) {
          notifications = (data['notifications'] as List)
              .map((n) => AppNotification.fromJson(n))
              .toList();
        }
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'notifications': notifications,
        };
      }
      return {'success': false, 'count': 0, 'notifications': []};
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return {'success': false, 'count': 0, 'notifications': []};
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/count'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching notification count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications/$notificationId/read'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/read-all'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$notificationId'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // ============ Claim APIs ============

  /// Generate verification questions from ML service
  Future<List<Map<String, dynamic>>> generateQuestions({
    required String itemId,
    int numQuestions = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.claimQuestionsEndpoint(itemId,
            numQuestions: numQuestions)),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['questions'] != null) {
          return (data['questions'] as List)
              .map((q) => Map<String, dynamic>.from(q))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error generating questions: $e');
      return [];
    }
  }

  /// Submit a claim for an item
  Future<Map<String, dynamic>> submitClaim(
      String itemId, String questionsAndAnswers) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.claimsEndpoint),
        headers: await _headers,
        body: jsonEncode({
          'itemId': itemId,
          'questionsAndAnswers': questionsAndAnswers,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get current user's claims
  Future<List<Map<String, dynamic>>> getMyClaims() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myClaimsEndpoint),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['claims'] != null) {
          return (data['claims'] as List)
              .map((c) => Map<String, dynamic>.from(c))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching my claims: $e');
      return [];
    }
  }

  /// Get all claims (admin only)
  Future<List<Map<String, dynamic>>> getAllClaimsAdmin() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminAllClaimsEndpoint),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['claims'] != null) {
          return (data['claims'] as List)
              .map((c) => Map<String, dynamic>.from(c))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching all claims: $e');
      return [];
    }
  }

  /// Get claims for a specific item
  Future<List<Map<String, dynamic>>> getClaimsForItem(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.claimsByItemEndpoint(itemId)),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['claims'] != null) {
          return (data['claims'] as List)
              .map((c) => Map<String, dynamic>.from(c))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching claims for item: $e');
      return [];
    }
  }

  /// Review a claim (admin only)
  Future<Map<String, dynamic>> reviewClaim(
      String claimId, String status, String adminNotes) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.reviewClaimEndpoint(claimId)),
        headers: await _headers,
        body: jsonEncode({
          'status': status,
          'adminNotes': adminNotes,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Check if current user has already claimed an item
  Future<bool> hasUserClaimedItem(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.checkClaimEndpoint(itemId)),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasClaimed'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking claim status: $e');
      return false;
    }
  }
}
