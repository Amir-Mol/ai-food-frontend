import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:ai_food_app/recommendation_detail_screen.dart'; // Import the detail screen
import 'package:ai_food_app/profile_settings_screen.dart'; // Import ProfileSettingsScreen
import 'package:ai_food_app/home_screen.dart'; // Import HomeScreen
import 'package:ai_food_app/recommendation_history_screen.dart';
import 'package:ai_food_app/ai_recommendation.dart';
import 'package:ai_food_app/widgets/compact_fsa_score_bar.dart';

/// Displays a list of food recommendations.
class RecommendationResultsScreen extends StatefulWidget {
  final List<AiRecommendation> recommendations;

  const RecommendationResultsScreen({
    super.key,
    required this.recommendations,
  });

  @override
  State<RecommendationResultsScreen> createState() =>
      _RecommendationResultsScreenState();
}

class _RecommendationResultsScreenState
    extends State<RecommendationResultsScreen> {
  late List<AiRecommendation> _localRecommendations;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the recommendations to allow for removal.
    _localRecommendations = List.from(widget.recommendations);
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

                    // Check if the list is now empty.
                    if (_localRecommendations.isEmpty) {
                      // If it's the last recommendation, navigate to the HomeScreen
                      // and clear the navigation stack.
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (Route<dynamic> route) => false,
                      );
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