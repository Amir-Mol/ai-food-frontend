import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ai_food_app/ai_recommendation.dart';
import 'package:ai_food_app/recommendation_results_screen.dart';
import 'package:ai_food_app/profile_settings_screen.dart';
import 'package:ai_food_app/recommendation_history_screen.dart'; // Import HistoryScreen
import 'package:ai_food_app/login_screen.dart'; // For potential re-login on auth error
import 'package:ai_food_app/config.dart';

/// HomeScreen is the main dashboard screen displayed after a user logs in.
///
/// It welcomes the user and provides access to primary features like
/// getting daily recommendations. It also includes a placeholder for
/// bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingRecommendations = false;
  bool _isLoadingProfile = true;
  String _userName = 'User';
  bool _isExperimentComplete = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/profile');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? serverName = data['name'];
        final String serverEmail = data['email'] ?? '';

        setState(() {
          _userName = (serverName != null && serverName.isNotEmpty)
              ? serverName
              : serverEmail.split('@').first;
        });
      }
    } catch (e) {
      // Silently fail on home screen, as the default name is acceptable.
      print('Could not connect to server on home screen: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _getTodaysRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });

    // Show a loading dialog that is not dismissible.
    showDialog(
      context: context,
      barrierDismissible: false, // User must wait for the process to complete.
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Expanded(
                // Use Expanded to prevent overflow if text is long
                child: Text(
                  "Our AI is crafting your personalized recommendations...",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication error. Please log in again.'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/generate-recommendations');
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200) {
        // First, pop the loading dialog
        Navigator.of(context).pop();

        final List<dynamic> recsJson =
            jsonDecode(response.body)['recommendations'];

        // Parse the new AI recommendation format
        final List<AiRecommendation> aiRecommendations = recsJson
            .map((json) => AiRecommendation.fromJson(json))
            .toList();


        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecommendationResultsScreen(
                recommendations: aiRecommendations, // Pass the full AiRecommendation list
                // The showTransparencyFeatures flag can be determined by another logic if needed
              ),
            ),
          );
      } else if (response.statusCode == 404) {
        Navigator.of(context).pop(); // Pop dialog for this case as well.
        // The backend sends a specific message for 404, which is more of an info than an error.
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseBody['detail'] ?? 'No new recommendations available at this time.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
        setState(() {
          _isExperimentComplete = true;
        });
      } else {
        Navigator.of(context).pop(); // Pop dialog on failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to get recommendations: ${response.body}'),
              backgroundColor: Colors.redAccent),
        );
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop dialog on timeout
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The request timed out. Please try again.'), backgroundColor: Colors.orangeAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop dialog on other errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to the server. Please check your connection.'), backgroundColor: Colors.redAccent),
        );
        print('Error getting recommendations: $e');
      }
    } finally {
      // The pop is now handled in each success/error path above.
      // We only need to reset the loading state here.
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Home',
          style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
        automaticallyImplyLeading: false, // No back button on the main home screen
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Make children like buttons stretch
                  children: <Widget>[
                    const SizedBox(height: 16.0), // Top spacing
                    Text(
                      "Hello, $_userName!",
                      style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50.0),
                    FilledButton(
                      onPressed: _isLoadingRecommendations || _isExperimentComplete ? null : _getTodaysRecommendations,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: const StadiumBorder(), // Ensures a pill shape
                        padding: const EdgeInsets.symmetric(vertical: 25.0),
                      ),
                      child: const Text('Find a Meal'),
                    ),
                    Visibility(
                      visible: _isExperimentComplete,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          "Thank you for completing all recommendations for this phase of our research!",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    const Spacer(), // Pushes the bottom navigation bar placeholder to the bottom
                    _buildBottomNavigationBarPlaceholder(context, colorScheme, theme),
                  ],
                ),
              ),
            ),
    );
  }

  /// Builds a placeholder for the bottom navigation bar.
  Widget _buildBottomNavigationBarPlaceholder(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, // Using a Material 3 surface color
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(Icons.home, 'Home', true, colorScheme, () {
            print('Home (Nav) tapped');
          }),
          _buildNavItem(Icons.history, 'History', false, colorScheme, () {
            print('History (Nav) tapped from Home');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const RecommendationHistoryScreen()), // No need to pass data
              (Route<dynamic> route) => false,
            );
          }),
          _buildNavItem(Icons.person_outline, 'Profile', false, colorScheme, () {
            print('Profile (Nav) tapped');
            Navigator.push( // Push, so the back button works correctly
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen(),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Helper to build individual navigation items for the placeholder bar.
  Widget _buildNavItem(IconData icon, String label, bool isActive, ColorScheme colorScheme, VoidCallback onPressed) {
    final Color itemColor = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return TextButton(
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: itemColor),
          const SizedBox(height: 4.0),
          Text(label, style: TextStyle(color: itemColor, fontSize: 12)),
        ],
      ),
    );
  }
}