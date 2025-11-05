import 'package:flutter/material.dart';
import 'package:ai_food_app/home_screen.dart'; // Import the HomeScreen


class OnboardingCompletionScreen extends StatelessWidget {
  const OnboardingCompletionScreen({super.key});

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
              const Spacer(), // Pushes elements below to the bottom.
              FilledButton(
                onPressed: () {
                  print('Explore Recommendations tapped. Navigate to HomeScreen.');
                  // Navigate to HomeScreen and remove all previous routes.
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
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