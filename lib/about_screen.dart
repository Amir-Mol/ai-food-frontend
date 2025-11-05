import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // For fetching app version

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchAppVersion();
  }

  Future<void> _fetchAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = "Version ${packageInfo.version}";
        });
      }
    } catch (e) {
      print("Error fetching package info: $e");
      if (mounted) {
        setState(() {
          _appVersion = "Version N/A"; // Fallback version
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'About',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // As requested
            children: <Widget>[
              const SizedBox(height: 24.0),
              Center(
                child: Image.asset(
                  'assets/images/app_logo1.png', // Ensure this path is correct
                  height: 80.0,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12.0),
              Center(
                child: Text(
                  "NutriRecom", // App Name
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              Center(
                child: Text(
                  _appVersion,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 32.0),
              Text(
                "About This App",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                "This AI-Powered Food Recommendation App is designed to provide personalized and healthy food choices based on your unique profile and preferences. Our goal is to make healthy eating easy, enjoyable, and perfectly suited to your lifestyle.",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface),
              ),
              const Spacer(), // Pushes the button to the bottom
              SizedBox( // To make the button full width
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: const Text('← Back to Settings'),
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