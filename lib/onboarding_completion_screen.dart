import 'package:flutter/material.dart';
import 'package:ai_food_app/home_screen.dart'; // Import the HomeScreen
import 'package:ai_food_app/tutorial_screen.dart'; // Import the TutorialScreen
import 'package:ai_food_app/services/recommendation_service.dart';


class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({super.key});

  @override
  State<OnboardingCompletionScreen> createState() => _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen> {
  // State variables
  bool _dataProcessingConsentGiven = false;
  bool _isGeneratingRecommendations = false;
  final _recommendationService = RecommendationService();

  // Function to navigate to the tutorial screen.
  void _completeOnboardingFunction() {
    // Navigate to TutorialScreen and remove all previous routes.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TutorialScreen()),
      (Route<dynamic> route) => false,
    );
  }

  /// Handle "Explore Recommendations" button tap
  Future<void> _handleExploreRecommendations() async {
    setState(() {
      _isGeneratingRecommendations = true;
    });

    try {
      // Trigger async recommendation generation in the backend
      await _recommendationService.completeOnboarding();

      if (!mounted) return;

      // Don't wait for recommendations - navigate to Tutorial immediately!
      // Backend is now generating recommendations in the background
      // Tutorial will explain what's happening
      // Home screen will handle status polling and button states
      _completeOnboardingFunction();
    } catch (e) {
      setState(() {
        _isGeneratingRecommendations = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "You're All Set!",
          style:
              theme.textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
        automaticallyImplyLeading: false, // No back button on completion
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16.0),
              Text(
                "Your profile is complete. We're ready to find amazing food recommendations for you.",
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              Container(
                height: 250.0, // Decreased height for a smaller GIF display
                width: double.infinity, // Ensure container takes full width for better image display
                decoration: BoxDecoration(
                  // color: colorScheme.primaryContainer, // Removed background color
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ClipRRect( // To respect the border radius of the container
                  borderRadius: BorderRadius.circular(12.0),
                   child: Image.asset(
                     'assets/images/onboard_complete.png', // Reverted to PNG
                     fit: BoxFit.cover,
                   ),
                ),
              ),
              const Spacer(), // Pushes elements below to the bottom
              CheckboxListTile(
                title: const Text(
                  "I consent to the processing of my personal data (including dietary and health information) to provide AI-powered food recommendations as described in the Privacy Policy.",
                ),
                value: _dataProcessingConsentGiven,
                onChanged: (bool? value) {
                  setState(() {
                    _dataProcessingConsentGiven = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16.0),
              FilledButton(
                // Button is disabled until consent is given or while generating
                onPressed: (_dataProcessingConsentGiven && !_isGeneratingRecommendations)
                    ? _handleExploreRecommendations
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Pill shape
                  ),
                ),
                child: _isGeneratingRecommendations
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Explore Recommendations'),
              ),
              const SizedBox(height: 12.0),
              Text(
                "Step 4 of 4 (Completed)",
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0), // For bottom padding
            ],
          ),
        ),
      ),
    );
  }
}