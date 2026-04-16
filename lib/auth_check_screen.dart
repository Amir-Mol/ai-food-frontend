import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_food_app/home_screen.dart';
import 'package:ai_food_app/welcome_screen.dart';
import 'package:ai_food_app/tutorial_screen.dart';
import 'package:ai_food_app/survey_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ai_food_app/config.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool('has_seen_tutorial') ?? false;

      if (!hasSeen) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorialScreen()),
        );
        return;
      }

      // Check if survey is pending (locally flagged OR confirmed from server)
      final surveyPendingLocal = prefs.getBool('surveyPending') ?? false;
      if (surveyPendingLocal) {
        // Verify with server and get group info to show correct questions
        try {
          final surveyStatusResponse = await http.get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/survey/status'),
            headers: {'Authorization': 'Bearer $token'},
          ).timeout(const Duration(seconds: 8));

          if (surveyStatusResponse.statusCode == 200) {
            final body = jsonDecode(surveyStatusResponse.body);
            final surveyPending = body['surveyPending'] == true;
            final surveyComplete = body['surveyComplete'] == true;

            if (surveyComplete) {
              // Survey was actually already submitted (e.g. on another device)
              await prefs.setBool('surveyPending', false);
            } else if (surveyPending) {
              // Get group from profile
              bool isTransparency = true;
              try {
                final profileResponse = await http.get(
                  Uri.parse('${AppConfig.apiBaseUrl}/api/user/profile'),
                  headers: {'Authorization': 'Bearer $token'},
                ).timeout(const Duration(seconds: 8));
                if (profileResponse.statusCode == 200) {
                  final profileBody = jsonDecode(profileResponse.body);
                  isTransparency = (profileBody['group'] ?? 'transparency') == 'transparency';
                }
              } catch (_) {}

              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SurveyScreen(isTransparencyGroup: isTransparency),
                ),
              );
              return;
            }
          }
        } catch (_) {
          // Network error — still show survey (local flag is reliable enough)
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SurveyScreen(isTransparencyGroup: true),
            ),
          );
          return;
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
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