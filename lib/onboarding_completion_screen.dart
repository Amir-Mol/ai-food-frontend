import 'package:flutter/material.dart';
import 'package:ai_food_app/home_screen.dart'; // Import the HomeScreen


class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({super.key});

  @override
  State<OnboardingCompletionScreen> createState() => _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen> {
  // State variable for the mandatory consent checkbox.
  bool _dataProcessingConsentGiven = false;

  // Function to navigate to the home screen.
  void _completeOnboardingFunction() {
    // Navigate to HomeScreen and remove all previous routes.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
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
                // Button is disabled until consent is given.
                onPressed: _dataProcessingConsentGiven ? _completeOnboardingFunction : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Pill shape
                  ),
                ),
                child: const Text('Explore Recommendations'),
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