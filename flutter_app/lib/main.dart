import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_item_screen.dart';
import 'providers/app_provider.dart';
import 'models/user.dart';
import 'services/tflite_classifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize TFLite classifier in background
  TFLiteClassifier().initialize();

  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString('user');
  final isLoggedIn = userJson != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = AppProvider();
            // Load user data immediately
            provider.loadUserFromPreferences();
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Lost & Found',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C47FF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C47FF), width: 2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C47FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        initialRoute: isLoggedIn ? '/home' : '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/create-item': (context) => const CreateItemScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/item-detail') {
            final itemId = settings.arguments as String?;
            if (itemId == null || itemId.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
                settings: settings,
              );
            }

            return MaterialPageRoute(
              builder: (_) => ItemDetailScreen(itemId: itemId),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}
