import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ai_food_app/onboarding_completion_screen.dart'; // Import the completion screen
import 'package:ai_food_app/config.dart';

class OnboardingTasteProfileScreen extends StatefulWidget {
  const OnboardingTasteProfileScreen({super.key});

  @override
  State<OnboardingTasteProfileScreen> createState() =>
      _OnboardingTasteProfileScreenState();
}

class _OnboardingTasteProfileScreenState
    extends State<OnboardingTasteProfileScreen> {
  // Controllers for TextFieldTags
  late TextEditingController _likedIngredientsController; // Changed to TextEditingController
  late TextEditingController _dislikedIngredientsController; // Changed to TextEditingController

  // State variable for selected cuisines
  final Set<String> _selectedFavoriteCuisines = <String>{};

  // Controller for "Other cuisine" text field
  late TextEditingController _otherCuisineController;

  // State variable to track loading state for API calls.
  bool _isLoading = false;

  // Define options for cuisines
  final List<String> _cuisineOptions = [
    'Italian',
    'Mexican',
    'Chinese',
    'Indian',
    'Thai',
    'Japanese',
    'Mediterranean',
    'American',
    'French',
    'Spanish',
    'Korean',
    'Vietnamese',
    'Brazilian',
    'Ethiopian',
  ];

  @override
  void initState() {
    super.initState();
    _likedIngredientsController = TextEditingController();
    _dislikedIngredientsController = TextEditingController();
    _otherCuisineController = TextEditingController();
  }

  @override
  void dispose() {
    _likedIngredientsController.dispose();
    _dislikedIngredientsController.dispose();
    _otherCuisineController.dispose();
    super.dispose();
  }

  // Helper method for consistent InputDecoration for TextFormFields
  InputDecoration _m3FilledInputDecoration({
    required String labelText,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
    );
  }


  // Helper method for building CheckboxListTile for cuisines
  Widget _buildCuisineCheckboxListTile(
      String cuisine, Set<String> selectedSet, ColorScheme colorScheme) {
    return SizedBox( // Wrap in SizedBox to control width in Wrap
      width: 150, // Adjust width as needed for your layout
      child: CheckboxListTile(
        title: Text(cuisine, overflow: TextOverflow.ellipsis), // Add overflow handling
        value: selectedSet.contains(cuisine),
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedSet.add(cuisine);
            } else {
              selectedSet.remove(cuisine);
            }
          });
        },
        activeColor: colorScheme.primary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact, // Decrease vertical spacing
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
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

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/profile');

      final requestBody = {
        'likedIngredients': _likedIngredientsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'dislikedIngredients': _dislikedIngredientsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'favoriteCuisines': _selectedFavoriteCuisines.toList(),
        'otherCuisine': _otherCuisineController.text,
        'onboardingCompleted': true, // Mark onboarding as complete
      };

      // Remove empty fields to avoid sending them
      if (_otherCuisineController.text.trim().isEmpty) {
        requestBody.remove('otherCuisine');
      }

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingCompletionScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save taste profile. Error: ${response.body}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to the server. Please check your connection.'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Your Taste Profile',
          style:
              theme.textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form( // Form key can be added if explicit validation on TextFieldTags's internal field is needed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    "Help us understand your preferences better!",
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),

                  // Liked Ingredients Section
                  DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    dashPattern: const [6, 3],
                    color: colorScheme.outline.withOpacity(0.6),
                    strokeWidth: 1,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('I Like these Ingredients/Foods:',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _likedIngredientsController,
                          decoration: _m3FilledInputDecoration(
                            labelText: 'Liked Ingredients (comma-separated)',
                            colorScheme: colorScheme,
                          ).copyWith(
                            hintText: 'e.g., chicken, tomatoes, pasta',
                          ),
                          // You can add a validator if needed
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Disliked Ingredients Section
                  DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    dashPattern: const [6, 3],
                    color: colorScheme.outline.withOpacity(0.6),
                    strokeWidth: 1,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('I Don\'t Like these Ingredients/Foods:',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _dislikedIngredientsController,
                          decoration: _m3FilledInputDecoration(
                            labelText: 'Disliked Ingredients (comma-separated)',
                            colorScheme: colorScheme,
                          ).copyWith(
                            hintText: 'e.g., mushrooms, olives, cilantro',
                          ),
                          // You can add a validator if needed
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Favorite Cuisines Section
                  DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    dashPattern: const [6, 3],
                    color: colorScheme.outline.withOpacity(0.6),
                    strokeWidth: 1,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Favorite Cuisines:',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 4.0,
                          runSpacing: 0.0,
                          children: _cuisineOptions.map((cuisine) {
                            return _buildCuisineCheckboxListTile(
                                cuisine, _selectedFavoriteCuisines, colorScheme);
                          }).toList(),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _otherCuisineController,
                          decoration: _m3FilledInputDecoration(
                            labelText: 'Other cuisine...',
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),

                   FilledButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24.0,
                            width: 24.0,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 3.0,
                            ),
                          )
                        : const Text('Finish'),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    "Step 3 of 4 (Taste Profile)",
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
