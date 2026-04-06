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
import 'package:ai_food_app/services/recommendation_service.dart';
import 'package:ai_food_app/models/recommendation_status.dart';
import 'package:ai_food_app/widgets/countdown_button.dart';

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
  
  // UI state for displaying status information
  RecommendationStatus? _currentStatus;
  
  // Phase B: Status polling
  Timer? _statusPollingTimer;
  final _recommendationService = RecommendationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 1. ASK FOR PERMISSION IMMEDIATELY (wait for it to complete)
    _requestNotificationPermission();
    
    _fetchProfile();
    _loadCachedRecommendations();
    
    // Phase B: Start status polling to track recommendation generation
    _startStatusPolling();
    
    // 2. CANCEL NOTIFICATIONS (Since user is now looking at the app)
    NotificationService().cancelAllNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Phase B: Stop status polling when leaving screen
    _stopStatusPolling();
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
  
  /// Phase B Step 6: Start polling for recommendation status
  /// Polls every 2 seconds to check if recommendations are ready or if generation is complete
  void _startStatusPolling() {
    // Don't start polling if already running
    if (_statusPollingTimer != null) {
      return;
    }
    
    print('[STATUS_POLLING] Starting status polling...');
    
    // First poll immediately
    _pollStatus();
    
    // Then start recurring polls every 2 seconds
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollStatus();
    });
  }
  
  /// Phase B Step 6: Stop status polling
  void _stopStatusPolling() {
    if (_statusPollingTimer != null) {
      print('[STATUS_POLLING] Stopping status polling...');
      _statusPollingTimer!.cancel();
      _statusPollingTimer = null;
    }
  }
  
  /// Phase B Step 6: Poll status from backend
  Future<void> _pollStatus() async {
    if (!mounted) return;
    
    try {
      final status = await _recommendationService.checkStatus();
      
      if (!mounted) return;
      
      print('[STATUS_POLLING] Status: ${status.status}, canGenerate: ${status.canGenerateNow}');
      
      // Update UI with new status
      setState(() {
        _currentStatus = status;
      });
      
      // Phase B Step 7: Auto-navigate to recommendations when ready
      // Only fetch if user CAN generate (not rate-limited)
      if (status.isReady && !_isLoadingRecommendations && _cachedRecommendations == null && status.canGenerateNow) {
        print('[STATUS_POLLING] Recommendations ready! Fetching...');
        await _getTodaysRecommendations();
      }
      
    } catch (e) {
      print('[STATUS_POLLING] Error checking status: $e');
      // Continue polling even if this check fails
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
    print('[RECOMMENDATIONS] User tapped "Find a Meal"');
    
    setState(() {
      _isLoadingRecommendations = true;
    });

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

      // Send recommendation request (backend takes ~17-25 seconds to generate)
      print('[RECOMMENDATIONS] Sending POST to /api/generate-recommendations...');
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/generate-recommendations');
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 40)); // Allow full backend processing time

      if (!mounted) return;

      if (response.statusCode == 200) {
        print('[RECOMMENDATIONS] ✅ Recommendations generated successfully!');
        
        try {
          final jsonResponse = jsonDecode(response.body);
          
          // Extract recommendations array
          final recsList = jsonResponse['recommendations'] as List?;
          if (recsList == null || recsList.isEmpty) {
            throw Exception('No recommendations in response');
          }
          
          print('[RECOMMENDATIONS] Parsing ${recsList.length} recommendations...');
          
          // Convert to AiRecommendation objects
          final recommendations = recsList
              .map((rec) => AiRecommendation.fromJson(rec as Map<String, dynamic>))
              .toList();
          
          print('[RECOMMENDATIONS] ✅ Converted ${recommendations.length} recommendations to objects');
          
          // Extract and save timer
          final nextAllowedAt = jsonResponse['nextAllowedGenerationAt'];
          if (nextAllowedAt != null) {
            print('[RECOMMENDATIONS] Next generation allowed at: $nextAllowedAt');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('nextAllowedGenerationAt', nextAllowedAt);
            print('[RECOMMENDATIONS] ✅ Saved timer to SharedPreferences');
          }
          
          // Cache the recommendations
          await _cacheRecommendations(recommendations);
          print('[RECOMMENDATIONS] ✅ Cached recommendations');
          
          if (!mounted) return;
          
          // Stop polling before navigating away (prevents auto-refetch while on recommendations screen)
          _stopStatusPolling();
          
          // Navigate to recommendations screen
          print('[RECOMMENDATIONS] 🚀 Navigating to RecommendationResultsScreen...');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecommendationResultsScreen(
                recommendations: recommendations,
              ),
            ),
          ).then((_) {
            // Restart polling when user returns from recommendations screen
            print('[STATUS_POLLING] User returned from recommendations screen, restarting polling...');
            _startStatusPolling();
          });
          
        } catch (parseError) {
          print('[RECOMMENDATIONS] ❌ Error parsing response: $parseError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error processing recommendations: $parseError'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('[RECOMMENDATIONS] ❌ Unauthorized (401/403)');
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'access_token');
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please log in again.'), backgroundColor: Colors.redAccent),
          );
        }
      } else if (response.statusCode == 429) {
        print('[RECOMMENDATIONS] ❌ Rate limited (429) - Countdown timer shown on button');
        // Don't show popup - the countdown timer on the button already shows the wait time
        // This prevents repeated popups every 2 seconds from polling
      } else {
        print('[RECOMMENDATIONS] ❌ Failed with status ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to get recommendations: ${response.body}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } on TimeoutException catch (_) {
      print('[RECOMMENDATIONS] ❌ Request timed out');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The request timed out. Please try again.'), backgroundColor: Colors.orangeAccent),
        );
      }
    } catch (e) {
      print('[RECOMMENDATIONS] ❌ Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to the server. Please check your connection.'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }



  // DEPRECATED: Polling is no longer used. Countdown button shows timer instead.
  // This code is kept for reference only.

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
                    // Status indicator (if generation is in progress)
                    if (_currentStatus?.isGenerating == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.primary),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Text(
                                  _currentStatus?.status == 'summarizing'
                                      ? 'Summarizing your feedback...'
                                      : 'AI is crafting your meals...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Main button (Find a Meal / Continue / Countdown / etc.)
                    // PRIORITY: Show "Continue Rating" if there are unsubmitted feedbacks, regardless of timer
                    if (_cachedRecommendations != null &&
                        _cachedRecommendations!.isNotEmpty)
                      // Show "Continue Rating" button (highest priority - unsubmitted feedback)
                      FilledButton(
                        onPressed: _isLoadingRecommendations ||
                                _isExperimentComplete ||
                                (_currentStatus?.isGenerating == true)
                            ? null
                            : _continueCachedSession,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: const StadiumBorder(),
                          padding:
                              const EdgeInsets.symmetric(vertical: 25.0),
                        ),
                        child: Text(
                          'Continue Rating (${_cachedRecommendations!.length} left)',
                        ),
                      )
                    else if (_currentStatus?.nextAllowedGenerationAt != null &&
                        !_currentStatus!.canGenerateNow)
                      // Show countdown timer if generation is blocked (and no pending feedback)
                      CountdownButton(
                        nextAvailableAt:
                            _currentStatus!.nextAllowedGenerationAt!,
                        onReady: () {
                          // When countdown expires, update status
                          setState(() {
                            _currentStatus = RecommendationStatus(
                              status: 'ready',
                              recommendationsReadyAt:
                                  _currentStatus?.recommendationsReadyAt,
                              nextAllowedGenerationAt: null,
                            );
                          });
                        },
                      )
                    else
                      // Show "Find a Meal" button
                      FilledButton(
                        onPressed: _isLoadingRecommendations ||
                                _isExperimentComplete ||
                                (_currentStatus?.isGenerating == true)
                            ? null
                            : _getTodaysRecommendations,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: const StadiumBorder(),
                          padding:
                              const EdgeInsets.symmetric(vertical: 25.0),
                        ),
                        child: const Text('✨ Find a Meal'),
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