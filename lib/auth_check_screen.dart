import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_food_app/home_screen.dart';
import 'package:ai_food_app/welcome_screen.dart';
import 'package:ai_food_app/tutorial_screen.dart';

/// A screen that checks the user's authentication status on app startup.
///
/// It checks for a stored access token and navigates to the [HomeScreen]
/// if a token is found, or to the [WelcomeScreen] if not.
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the build is complete before navigating.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  /// Checks for a stored access token and navigates accordingly.
  Future<void> _checkAuthStatus() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    // Ensure the widget is still mounted before attempting to navigate.
    if (!mounted) return;

    if (token != null) {
      // If a token exists, the user is considered logged in.
      // Check if the user has already seen the tutorial.
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool('has_seen_tutorial') ?? false;

      if (hasSeen) {
        // User has seen the tutorial, go to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // User is new or hasn't seen the tutorial, go to TutorialScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorialScreen()),
        );
      }
    } else {
      // If no token, the user needs to log in or register.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading indicator while the authentication check is in progress.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}