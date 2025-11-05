import 'package:flutter/material.dart';
import 'package:ai_food_app/onboarding_basic_profile_screen.dart'; // Import the new screen

// OnboardingWelcomeScreen welcomes the user to the onboarding process.
class OnboardingWelcomeScreen extends StatefulWidget {
  // Optional user name, defaults to "User".
  final String? userName;

  const OnboardingWelcomeScreen({super.key, this.userName});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showWelcomeSnackBar();
      }
    });
  }

  void _showWelcomeSnackBar() {
    // Ensure context is still valid if the widget was disposed quickly
    if (!mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use the userName passed to the widget for the welcome message.
    final String displayedUserName = (widget.userName == null || widget.userName!.isEmpty) ? "User" : widget.userName!;
    // final String snackBarMessage = "Login successful!\nLet's get you set up."; // Replaced by RichText

    final snackBar = SnackBar(
      content: RichText(
        textAlign: TextAlign.center, // Center the entire RichText content
        text: TextSpan(
          style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 14), // Default style for SnackBar text
          children: <TextSpan>[
            const TextSpan(text: "Login successful!\n"),
            TextSpan(
                text: "Let's get you set up.",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer, // Ensure color consistency
                )),
          ],
        ),
      ),
      backgroundColor: colorScheme.secondaryContainer,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 100.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      duration: const Duration(milliseconds: 3000), // SnackBar visible for 3 seconds
    );
    ScaffoldMessenger.of(context).clearSnackBars(); // Clear any previous SnackBars
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    // This displayedUserName is for the AppBar title, SnackBar uses its own local version
    // or can directly use widget.userName.
    final String displayedUserName = (widget.userName == null || widget.userName!.isEmpty) ? "User" : widget.userName!;

    // Scaffold provides the basic visual structure for the screen.
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Welcome, $displayedUserName!',
          style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
        automaticallyImplyLeading: false, // No back button for the first onboarding screen
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Main column for all onboarding welcome elements.
            children: <Widget>[
              const SizedBox(height: 16.0),
              Text(
                "Let's personalize your experience. We'll ask a few questions to tailor food recommendations for you.",
                style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              Container(
                // Placeholder for an illustration or graphic.
                height: 170.0,
                decoration: BoxDecoration(
                  // color: colorScheme.primaryContainer, // Removed to make it transparent
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ClipRRect( // Ensures the image respects the container's border radius
                  borderRadius: BorderRadius.circular(12.0),
                  child: Opacity(
                    opacity: 0.5, // Adjust this value (0.0 to 1.0) for desired fade level
                    child: Image.asset(
                      'assets/images/onboard_welcome.PNG', // Your image path
                      fit: BoxFit.cover, // Adjust fit as needed (e.g., BoxFit.contain, BoxFit.fill)
                    ),
                  ),
                ),
              ),
              const Spacer(), // Pushes elements below to the bottom.
              FilledButton(
                // "Get Started" button to proceed with onboarding.
                onPressed: () {
                  // Navigate to the OnboardingBasicProfileScreen.
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OnboardingBasicProfileScreen(userName: widget.userName)), // Pass the userName
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
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 16.0), // For bottom padding
            ],
          ),
        ),
      ),
    );
  }
}