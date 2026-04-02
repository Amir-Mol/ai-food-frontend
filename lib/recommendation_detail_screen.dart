import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_food_app/ai_recommendation.dart';
import 'package:ai_food_app/widgets/compact_fsa_score_bar.dart';
import 'package:ai_food_app/config.dart';import 'package:ai_food_app/login_screen.dart';
class RecommendationDetailScreen extends StatefulWidget {
  final AiRecommendation recommendation;

  const RecommendationDetailScreen({
    super.key,
    required this.recommendation,
  });

  @override
  State<RecommendationDetailScreen> createState() =>
      _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState
    extends State<RecommendationDetailScreen> {
  bool _isSubmittingFeedback = false;
  bool _isIngredientsExpanded = false;

  // State for the new two-stage feedback system
  bool? _likedStatus; // null = no selection, true = liked, false = disliked
  int _healthScore = 0;
  int _tastinessScore = 0;
  int _intentScore = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Increments the global progress counter for total feedbacks submitted.
  Future<void> _incrementProgressCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTotal = prefs.getInt('total_feedbacks_submitted') ?? 0;
      await prefs.setInt('total_feedbacks_submitted', currentTotal + 1);
    } catch (e) {
      print('Error incrementing progress counter: $e');
    }
  }

  /// Launches the provided URL string.
  ///
  /// Shows a SnackBar if the URL can't be launched or is empty.
  Future<void> _launchURL(String urlString) async {
    final cleanUrlString = urlString.trim();
    if (cleanUrlString.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipe link available.')),
      );
      return;
    }
    final Uri url = Uri.parse(cleanUrlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $cleanUrlString')),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Part C: Update the validation
    if (_likedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select "Like" or "Dislike" before submitting.', style: TextStyle(color: colorScheme.onErrorContainer)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
      return; // Stop further processing
    } else if (_healthScore == 0 || _tastinessScore == 0 || _intentScore == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a rating for all three questions.', style: TextStyle(color: colorScheme.onErrorContainer)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
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

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/recommendations/${widget.recommendation.recipeId}/feedback');

      // Part C: Update the requestBody map
      final requestBody = {
        'liked': _likedStatus!,
        'healthinessScore': _healthScore,
        'tastinessScore': _tastinessScore,
        'intentToTryScore': _intentScore,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you for your feedback!', style: TextStyle(color: colorScheme.onSecondaryContainer)),
            backgroundColor: colorScheme.secondaryContainer,
          ),
        );
        // Increment the global progress counter
        await _incrementProgressCounter();
        // After showing feedback, pop back to the previous screen.
        Navigator.pop(context, true);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired - force logout
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'access_token');
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please log in again.'), backgroundColor: Colors.redAccent),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: ${response.body}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to the server. Please check your connection.'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingFeedback = false;
        });
      }
    }
  }

  /// Helper widget for building a 1-5 star rating row.
  Widget _buildStarRating({
    required String question,
    required int currentScore,
    required void Function(int) onScoreChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(5, (index) {
            final score = index + 1;
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                score <= currentScore ? Icons.star_rounded : Icons.star_border_rounded,
                color: score <= currentScore ? Colors.amber.shade600 : Colors.grey,
                size: 32,
              ),
              onPressed: () {
                setState(() => onScoreChanged(score));
              },
            );
          }),
        ),
      ],
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
          widget.recommendation.name,
          style: theme.textTheme.titleLarge
              ?.copyWith(color: colorScheme.onSurface),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // i. Hero Image
              CachedNetworkImage(
                imageUrl: widget.recommendation.imageUrl,
                height: 250.0,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250.0,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250.0,
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                      child: Icon(Icons.broken_image,
                          size: 60.0, color: colorScheme.onSurfaceVariant)),
                ),
              ),

              // ii. Food Name
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text(
                  widget.recommendation.name,
                  style: theme.textTheme.displaySmall
                      ?.copyWith(color: colorScheme.onSurface),
                ),
              ),

              // iv. Conditional Transparency Block
              // Use healthScore as the definitive check for the transparency group
              if (widget.recommendation.healthScore > 0.0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Why this was recommended:",
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          widget.recommendation.explanation,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 16.0),
                        CompactFsaScoreBar(
                            healthScore: widget.recommendation.healthScore),
                      ],
                    ),
                  ),
                ),

              // v. Nutritional Information
              ListTile(
                leading: Icon(Icons.assessment_outlined, color: colorScheme.primary),
                title: Text("Nutritional Information (per 100g)", style: theme.textTheme.titleMedium),
                subtitle: Text(
                  'Calories: ${widget.recommendation.nutritionalInfo.calories?.toStringAsFixed(0) ?? 'N/A'}kcal • '
                  'Protein: ${widget.recommendation.nutritionalInfo.protein?.toStringAsFixed(1) ?? 'N/A'}g • '
                  'Carbs: ${widget.recommendation.nutritionalInfo.carbs?.toStringAsFixed(1) ?? 'N/A'}g • '
                  'Fat: ${widget.recommendation.nutritionalInfo.fat?.toStringAsFixed(1) ?? 'N/A'}g',
                  maxLines: 2, // Allow wrapping if the line is too long
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),

              // vi. Ingredients (expandable) & Recipe Link
              ListTile(
                leading: Icon(Icons.list_alt_outlined, color: colorScheme.primary),
                title: Text("Ingredients & Recipe", style: theme.textTheme.titleMedium),
                subtitle: Text(() {
                  final ingredients = widget.recommendation.ingredients;
                  if (ingredients.isEmpty) {
                    return 'No ingredients listed. Tap to expand or view recipe.';
                  }
                  if (_isIngredientsExpanded || ingredients.length <= 2) {
                    return ingredients.join(', ');
                  } else {
                    return '${ingredients.take(2).join(', ')}...';
                  }
                }()),
                trailing: IconButton(
                  icon: const Icon(Icons.launch),
                  onPressed: () => _launchURL(widget.recommendation.recipeUrl),
                  tooltip: 'Open Recipe',
                ),
                onTap: () => setState(() {
                  _isIngredientsExpanded = !_isIngredientsExpanded;
                }),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              const Divider(indent: 16, endIndent: 16),

              // vii. Feedback Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Enjoy this recommendation?",
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.thumb_up_outlined, color: _likedStatus == true ? colorScheme.primary : colorScheme.onSurfaceVariant),
                            label: Text("Like", style: TextStyle(color: _likedStatus == true ? colorScheme.primary : colorScheme.onSurfaceVariant)),
                            onPressed: () => setState(() => _likedStatus = true),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: _likedStatus == true ? colorScheme.primary : colorScheme.outline, width: _likedStatus == true ? 2 : 1),
                              backgroundColor: _likedStatus == true ? colorScheme.primaryContainer.withOpacity(0.3) : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.thumb_down_outlined, color: _likedStatus == false ? colorScheme.error : colorScheme.onSurfaceVariant),
                            label: Text("Dislike", style: TextStyle(color: _likedStatus == false ? colorScheme.error : colorScheme.onSurfaceVariant)),
                            onPressed: () => setState(() => _likedStatus = false),
                             style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: _likedStatus == false ? colorScheme.error : colorScheme.outline, width: _likedStatus == false ? 2 : 1),
                              backgroundColor: _likedStatus == false ? colorScheme.errorContainer.withOpacity(0.3) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Part B: Conditionally show the detailed rating section
                    Visibility(
                      visible: _likedStatus != null,
                      child: Column(
                        children: [
                          const Divider(height: 24),
                          _buildStarRating(
                            question: "How healthy did this seem?",
                            currentScore: _healthScore,
                            onScoreChanged: (score) => _healthScore = score,
                          ),
                          const SizedBox(height: 16),
                          _buildStarRating(
                            question: "How tasty did this seem?",
                            currentScore: _tastinessScore,
                            onScoreChanged: (score) => _tastinessScore = score,
                          ),
                          const SizedBox(height: 16),
                          _buildStarRating(
                            question: "How likely are you to try this?",
                            currentScore: _intentScore,
                            onScoreChanged: (score) => _intentScore = score,
                          ),
                          const SizedBox(height: 24.0),
                          FilledButton(
                            onPressed: _isSubmittingFeedback ? null : _submitFeedback,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48), // Full width
                            ),
                            child: _isSubmittingFeedback
                                ? const SizedBox(
                                    height: 24.0,
                                    width: 24.0,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0),
                                  )
                                : const Text('Submit Feedback'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}