import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/lost_found_item.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  List<LostFoundItem> _items = [];
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  List<LostFoundItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Load user from SharedPreferences
  Future<void> loadUserFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _currentUser = User.fromJson(userData);
        notifyListeners();
        // Fetch items after loading user
        await fetchItems();
      }
    } catch (e) {
      print('Error loading user from prefs: $e');
    }
  }

  // Initialize app state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _apiService.getCurrentUser();

    if (_currentUser != null) {
      await fetchItems();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Authentication methods
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.login(username, password);

    if (result['success']) {
      _currentUser = result['user'];
      await fetchItems();
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.register(userData);

    if (result['success']) {
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    _currentUser = null;
    _items = [];
    notifyListeners();
  }

  // Item methods
  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    _items = await _apiService.getAllItems();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserItems() async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    _items = await _apiService.getItemsByUserId(_currentUser!.id);

    _isLoading = false;
    notifyListeners();
  }

  Future<LostFoundItem?> getItemById(String itemId) async {
    return await _apiService.getItemById(itemId);
  }

  Future<Map<String, dynamic>> createItem(LostFoundItem item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.createItem(item);

    if (result['success']) {
      await fetchItems();
      _isLoading = false;
      notifyListeners();
      final createdItem = result['item'] as LostFoundItem?;
      return {
        'success': true,
        'itemId': createdItem?.id,
      };
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': result['message'],
      };
    }
  }

  Future<bool> updateItem(String itemId, LostFoundItem item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.updateItem(itemId, item);

    if (result['success']) {
      await fetchItems();
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.deleteItem(itemId);

    if (result['success']) {
      await fetchItems();
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadImage(dynamic imageFile) async {
    final result = await _apiService.uploadImage(imageFile);

    if (result['success']) {
      return result['imageUrl'];
    } else {
      _error = result['message'];
      notifyListeners();
      return null;
    }
  }

  Future<bool> addComment(String itemId, String commentText) async {
    final result = await _apiService.addComment(itemId, commentText);

    if (result['success']) {
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  /// Classify an image using ML service
  /// Returns a map with predictedClass, confidence, and backendCategory
  Future<Map<String, dynamic>?> classifyImage(dynamic imageFile) async {
    final result = await _apiService.classifyImage(imageFile);

    if (result['success']) {
      return {
        'predictedClass': result['predictedClass'],
        'confidence': result['confidence'],
        'backendCategory': result['backendCategory'],
        'allProbabilities': result['allProbabilities'],
      };
    } else {
      _error = result['message'];
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
