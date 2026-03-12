import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_food_app/ai_recommendation.dart';
import 'package:ai_food_app/recommendation_results_screen.dart';
import 'package:ai_food_app/profile_settings_screen.dart';
import 'package:ai_food_app/recommendation_history_screen.dart'; // Import HistoryScreen
import 'package:ai_food_app/login_screen.dart'; // For potential re-login on auth error
import 'package:ai_food_app/config.dart';
import 'package:ai_food_app/services/notification_service.dart';

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoadingRecommendations = false;
  bool _isLoadingProfile = true;
  String _userName = 'User';
  bool _isExperimentComplete = false;
  List<AiRecommendation>? _cachedRecommendations;
  int _totalFeedbacksSubmitted = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 1. ASK FOR PERMISSION IMMEDIATELY (wait for it to complete)
    _requestNotificationPermission();
    
    _fetchProfile();
    _loadCachedRecommendations();
    
    // 2. CANCEL NOTIFICATIONS (Since user is now looking at the app)
    NotificationService().cancelAllNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // User minimized the app -> SCHEDULE
      print("App paused - Scheduling notification...");
      _handleAppPaused(); 
    } 
    else if (state == AppLifecycleState.resumed) {
      // User came back -> CANCEL
      print("App resumed - Cancelling notifications...");
      NotificationService().cancelAllNotifications();
    }
  }

  /// Request notification permissions asynchronously
  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationService().requestPermissions();
      print('Notification permission requested successfully');
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  /// Handle app paused state by scheduling notifications
  Future<void> _handleAppPaused() async {
    try {
      await _checkAndScheduleNotification();
    } catch (e) {
      print('Error in _handleAppPaused: $e');
    }
  }

  /// Check if there are cached recommendations and schedule notification
  Future<void> _checkAndScheduleNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_recommendations');
      
      // Only schedule notification if there are cached recommendations
      if (cachedJson != null && cachedJson.isNotEmpty) {
        print('Scheduling notification for unfinished batch...');
        await NotificationService().scheduleUnfinishedBatchNotification();
      } else {
        print('No cached recommendations, skipping notification scheduling');
      }
    } catch (e) {
      print('Error in _checkAndScheduleNotification: $e');
    }
  }
  
  /// Deprecated: Progress counter now loaded from API via _fetchProfile()
  // Future<void> _loadProgressCounter() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final total = prefs.getInt('total_feedbacks_submitted') ?? 0;
  //     
  //     if (mounted) {
  //       setState(() {
  //         _totalFeedbacksSubmitted = total;
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading progress counter: $e');
  //   }
  // }

  Future<void> _loadCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_recommendations');
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(cachedJson);
        final recommendations = jsonList
            .map((json) => AiRecommendation.fromJson(json))
            .toList();
        
        if (mounted) {
          setState(() {
            _cachedRecommendations = recommendations;
          });
        }
      }
    } catch (e) {
      print('Error loading cached recommendations: $e');
    }
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
        final int totalFeedbacks = data['total_feedbacks_submitted'] ?? 0;

        setState(() {
          _userName = (serverName != null && serverName.isNotEmpty)
              ? serverName
              : serverEmail.split('@').first;
          _totalFeedbacksSubmitted = totalFeedbacks;
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

        // Cache the recommendations
        await _cacheRecommendations(aiRecommendations);

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecommendationResultsScreen(
                recommendations: aiRecommendations, // Pass the full AiRecommendation list
                // The showTransparencyFeatures flag can be determined by another logic if needed
              ),
            ),
          );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        Navigator.of(context).pop();
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'access_token');
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please log in again.'), backgroundColor: Colors.redAccent),
          );
        }
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

  Future<void> _cacheRecommendations(List<AiRecommendation> recommendations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = recommendations.map((rec) => rec.toJson()).toList();
      await prefs.setString('cached_recommendations', jsonEncode(jsonList));
    } catch (e) {
      print('Error caching recommendations: $e');
    }
  }

  Future<void> _continueCachedSession() async {
    if (_cachedRecommendations == null || _cachedRecommendations!.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationResultsScreen(
          recommendations: _cachedRecommendations!,
        ),
      ),
    );
  }

  Widget _buildProgressCounterWidget(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final progressPercentage = (_totalFeedbacksSubmitted / 100 * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: colorScheme.primary, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Total Rated',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '$_totalFeedbacksSubmitted / 100',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12.0),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: _totalFeedbacksSubmitted / 100,
              minHeight: 8.0,
              backgroundColor: colorScheme.primary.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '$progressPercentage% Complete',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
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
                    const SizedBox(height: 40.0),
                    // Progress Counter Widget
                    _buildProgressCounterWidget(context, colorScheme, theme),
                    const SizedBox(height: 50.0),
                    FilledButton(
                      onPressed: _isLoadingRecommendations || _isExperimentComplete
                          ? null
                          : (_cachedRecommendations != null && _cachedRecommendations!.isNotEmpty)
                              ? _continueCachedSession
                              : _getTodaysRecommendations,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: const StadiumBorder(), // Ensures a pill shape
                        padding: const EdgeInsets.symmetric(vertical: 25.0),
                      ),
                      child: Text(
                        (_cachedRecommendations != null && _cachedRecommendations!.isNotEmpty)
                            ? 'Continue Rating (${_cachedRecommendations!.length} left)'
                            : 'Find a Meal',
                      ),
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