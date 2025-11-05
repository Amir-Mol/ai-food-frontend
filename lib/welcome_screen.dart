import 'package:flutter/material.dart';
import 'package:ai_food_app/create_account_screen.dart'; // Import the CreateAccountScreen
import 'package:ai_food_app/login_screen.dart'; // Import the LoginScreen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Using surface as the main background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Ensures children can expand horizontally
            children: <Widget>[
              const SizedBox(height: 30.0), // Added space to push "Welcome" text down
              Text(
                "Welcome",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              // Replaced placeholder Container with a Column for Logo and App Name
              Column(
                mainAxisSize: MainAxisSize.min, // So the column doesn't expand unnecessarily
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/app_logo1.png', // Make sure this path is correct
                    height: 100.0, // Increased height
                    fit: BoxFit.contain,
                    // You might want to add errorBuilder for Image.asset if the image might not load
                    // errorBuilder: (context, error, stackTrace) =>
                    //     const Icon(Icons.image_not_supported, size: 80.0),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    "Nutri Recom",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface, // Using onSurface as it's on the main background
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 30.0),
              Text(
                "AI-Powered Personalized Food Recommendations Just For You",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(), // Pushes buttons to the bottom
              SizedBox(
                width: double.infinity, // Makes button full-width
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateAccountScreen()),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0), // Makes button taller
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Pill shape
                    ),
                  ),
                  child: const Text("Register"),
                ),
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity, // Makes button full-width
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 16.0), // Makes button taller
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Pill shape
                    ),
                  ),
                  child: const Text("Login"),
                ),
              ),
              const SizedBox(height: 20.0), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}