import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:ai_food_app/recommendation_detail_screen.dart'; // Import the detail screen
import 'package:ai_food_app/profile_settings_screen.dart'; // Import ProfileSettingsScreen
import 'package:ai_food_app/home_screen.dart'; // Import HomeScreen
import 'package:ai_food_app/recommendation_history_screen.dart';
import 'package:ai_food_app/ai_recommendation.dart';
import 'package:ai_food_app/widgets/compact_fsa_score_bar.dart';
import 'package:ai_food_app/services/notification_service.dart';
import 'package:ai_food_app/widgets/countdown_button.dart';

/// Displays a list of food recommendations.
class RecommendationResultsScreen extends StatefulWidget {
  final List<AiRecommendation> recommendations;
  final int currentCycleNumber;                    // PHASE D: Current cycle (1-20)
  final int totalRecommendationsGenerated;         // PHASE D: Total recommendations (0-100)

  const RecommendationResultsScreen({
    super.key,
    required this.recommendations,
    this.currentCycleNumber = 0,                   // PHASE D: Default to 0
    this.totalRecommendationsGenerated = 0,        // PHASE D: Default to 0
  });

  @override
  State<RecommendationResultsScreen> createState() =>
      _RecommendationResultsScreenState();
}

class _RecommendationResultsScreenState
    extends State<RecommendationResultsScreen> {
  late List<AiRecommendation> _localRecommendations;
  int? _waitingMinutes;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the recommendations to allow for removal.
    _localRecommendations = List.from(widget.recommendations);
    _loadWaitingMinutes();
    
    // Check if auto-trigger was just set (5th feedback submitted)
    _checkAndHandleAutoTrigger();
  }
  
  /// Check if auto-trigger is in progress (5th feedback was just submitted)
  /// If so, navigate to HomeScreen to wait for next batch
  Future<void> _checkAndHandleAutoTrigger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoTrigger = prefs.getBool('autoTriggerInProgress') ?? false;
      
      if (autoTrigger && mounted) {
        print('[AUTO_TRIGGER] 5th feedback detected on RecommendationResultsScreen - navigating to HomeScreen');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('[AUTO_TRIGGER] Error checking auto-trigger: $e');
    }
  }

  /// Load waitingMinutes from SharedPreferences
  Future<void> _loadWaitingMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final minutes = prefs.getInt('waitingMinutes');
      if (minutes != null) {
        setState(() {
          _waitingMinutes = minutes;
        });
      }
    } catch (e) {
      print('Error loading waitingMinutes: $e');
    }
  }

  Future<void> _updateCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_localRecommendations.isEmpty) {
        // If the list is empty, delete the cache key
        await prefs.remove('cached_recommendations');
      } else {
        // Update the cache with the remaining recommendations
        final jsonList = _localRecommendations.map((rec) => rec.toJson()).toList();
        await prefs.setString('cached_recommendations', jsonEncode(jsonList));
      }
    } catch (e) {
      print('Error updating cached recommendations: $e');
    }
  }

  /// Build the "Get More Meals" button
  /// Phase B Step 9: Countdown timer moved to Home Screen only
  Widget _buildGetMoreMealsButton(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    // Always show "Get More Meals" button - countdown is now handled on Home Screen
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          // Navigate back to HomeScreen where countdown timer is displayed
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
        child: const Text('✨ Get More Meals'),
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
          'Your Recommendations',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: colorScheme.onSurface),
            onPressed: () {
              print('Filter button tapped');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PHASE D: Cycle counter and progress display
            if (widget.currentCycleNumber > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Cycle counter
                    Text(
                      'Cycle ${widget.currentCycleNumber}/20',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Progress counter
                    Text(
                      'You\'ve rated ${widget.totalRecommendationsGenerated}/100 recommendations so far',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListView.builder(
                  itemCount: _localRecommendations.length,
                  itemBuilder: (BuildContext context, int index) {
                    final recommendation = _localRecommendations[index];
                    return RecommendationCard(
                      recommendation: recommendation,
                      showTransparencyFeatures: recommendation.healthScore > 0.0,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecommendationDetailScreen(
                              recommendation: recommendation,
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          // Remove the item from the list first.
                          _localRecommendations.remove(recommendation);

                          // Update the cache
                          await _updateCachedRecommendations();

                          // Reload the waitingMinutes from SharedPreferences
                          await _loadWaitingMinutes();

                          // Check if the list is now empty.
                          if (_localRecommendations.isEmpty) {
                            // Schedule notification for batch complete (Tomorrow at 6 PM)
                            await NotificationService().scheduleBatchCompleteNotification();

                            // If waitingMinutes is set, stay on this screen
                            // Otherwise, navigate to HomeScreen
                            if (_waitingMinutes == null || _waitingMinutes! <= 0) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const HomeScreen()),
                                (Route<dynamic> route) => false,
                              );
                            } else {
                              // Rebuilding with empty list to show the "Get More Meals" button
                              setState(() {});
                            }
                          } else {
                            // Otherwise, just rebuild the screen to show the updated list.
                            setState(() {});
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            // Footer with "Get More Meals" button
            if (_localRecommendations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildGetMoreMealsButton(context, colorScheme, theme),
              ),
          ],
        ),
      ),
      // Placeholder for the main bottom navigation bar
      bottomNavigationBar: SafeArea(
        top: false, // We only want to apply padding to the bottom
        child: _buildBottomNavigationBarPlaceholder(context, colorScheme, theme),
      ),
    );
  }

  /// Builds a placeholder for the bottom navigation bar.
  Widget _buildBottomNavigationBarPlaceholder(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    // This can be replaced with your actual BottomNavigationBar implementation
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border:
            Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(Icons.home_outlined, 'Home', false, colorScheme, () {
            print('Home (Nav) tapped - from Recommendations. Navigating to HomeScreen.');
            // Navigate to HomeScreen and remove all routes above it.
            Navigator.pushAndRemoveUntil(
              context, // Pass userName if available/needed
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          }),
          _buildNavItem(Icons.history, 'History', false, colorScheme, () {
            print('History (Nav) tapped from Home');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const RecommendationHistoryScreen()),
              (Route<dynamic> route) => false,
            );
          }),
          _buildNavItem(Icons.person_outline, 'Profile', false, colorScheme, () {
            print('Profile (Nav) tapped');
            Navigator.push(
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

  Widget _buildNavItem(IconData icon, String label, bool isActive,
      ColorScheme colorScheme, VoidCallback onPressed) {
    final Color itemColor =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
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

/// A card widget to display a single food recommendation.
class RecommendationCard extends StatelessWidget {
  final AiRecommendation recommendation;
  final bool showTransparencyFeatures;
  final VoidCallback onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.showTransparencyFeatures,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card.outlined(
      // Using Material 3 Outlined Card
      margin: const EdgeInsets.only(bottom: 25.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        // The side is handled by Card.outlined constructor
      ),
      clipBehavior: Clip.antiAlias, // Ensures content respects card's shape
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: recommendation.imageUrl,
              height: 160.0,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 160.0,
                color: colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 160.0,
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                    child: Icon(Icons.broken_image,
                        size: 48.0, color: colorScheme.onSurfaceVariant)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    recommendation.name,
                    style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  if (showTransparencyFeatures) ...[
                    const SizedBox(height: 12.0),
                    CompactFsaScoreBar(healthScore: recommendation.healthScore),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}