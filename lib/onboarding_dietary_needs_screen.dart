import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart'; // Import for dashed border
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ai_food_app/config.dart';
// TODO: Import the next onboarding screen when it's created
// Import the next onboarding screen.
import 'package:ai_food_app/onboarding_taste_profile_screen.dart';
class OnboardingDietaryNeedsScreen extends StatefulWidget {
  const OnboardingDietaryNeedsScreen({super.key});

  @override
  State<OnboardingDietaryNeedsScreen> createState() =>
      _OnboardingDietaryNeedsScreenState();
}

class _OnboardingDietaryNeedsScreenState
    extends State<OnboardingDietaryNeedsScreen> {
  // State variables for selected options
  final Set<String> _selectedDietaryRestrictions = <String>{};
  final Set<String> _selectedFoodAllergies = <String>{};
  final Set<String> _selectedHealthConditions = <String>{};

  // Controllers for "Other" text fields
  late TextEditingController _otherRestrictionController;
  late TextEditingController _otherAllergyController;
  late TextEditingController _otherConditionController;
  // State variable to track loading state for API calls.
  bool _isLoading = false;

  // Define options for checkboxes to avoid magic strings
  static const String vegan = 'Vegan';
  static const String vegetarian = 'Vegetarian';
  static const String noPork = 'No Pork';

  static const String peanuts = 'Peanuts';
  static const String treeNuts = 'Tree Nuts (e.g., almonds, walnuts)';
  static const String shellfish = 'Shellfish (Crustacean/Molluscan)';
  static const String eggs = 'Eggs';

  static const String diabetes = 'Diabetes (General)';
  static const String hypertension = 'Hypertension (High Blood Pressure)';

  @override
  void initState() {
    super.initState();
    _otherRestrictionController = TextEditingController();
    _otherAllergyController = TextEditingController();
    _otherConditionController = TextEditingController();
  }

  @override
  void dispose() {
    _otherRestrictionController.dispose();
    _otherAllergyController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }

  // Helper method for consistent InputDecoration
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

  Widget _buildCheckboxListTile(
      String title, Set<String> selectedSet, ColorScheme colorScheme) {
    return CheckboxListTile(
      title: Text(title),
      value: selectedSet.contains(title),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            selectedSet.add(title);
          } else {
            selectedSet.remove(title);
          }
        });
      },
      activeColor: colorScheme.primary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact, // Decrease vertical spacing
    );
  }

  Future<void> _submitForm() async {
    // Ensure hidden data is cleared before submission
    setState(() {
      _selectedFoodAllergies.clear();
      _otherAllergyController.clear();
      // Also clear health conditions as that section is also hidden
      _selectedHealthConditions.clear();
      _otherConditionController.clear();
    });

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
        return; // Exit if no token
      }

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/profile');

      final requestBody = {
        'dietaryProfile': {
          'dietaryRestrictions': {
            'selected': _selectedDietaryRestrictions.toList(),
            'other': _otherRestrictionController.text,
          },
          'foodAllergies': {
            'selected': _selectedFoodAllergies.toList(),
            'other': _otherAllergyController.text,
          },
          'healthConditions': {
            'selected': _selectedHealthConditions.toList(),
            'other': _otherConditionController.text,
          }
        }
      };

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
          MaterialPageRoute(builder: (context) => const OnboardingTasteProfileScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save dietary needs. Error: ${response.body}'), backgroundColor: Colors.redAccent),
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
          'Dietary Needs',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "Please select any relevant items. This helps us tailor recommendations.",
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),

                // Dietary Restrictions Section
                DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(8), // Small corner radius
                  dashPattern: const [6, 3], // Dash pattern (length of dash, space between dashes)
                  color: colorScheme.outline.withOpacity(0.6), // Color of the dashed border
                  strokeWidth: 1, // Thickness of the border
                  padding: const EdgeInsets.all(12), // Padding inside the border
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Dietary Restrictions:',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold // Make title bold
                          )),
                      const SizedBox(height: 8.0), // Keep some space below title
                      _buildCheckboxListTile(vegan, _selectedDietaryRestrictions, colorScheme),
                      _buildCheckboxListTile(vegetarian, _selectedDietaryRestrictions, colorScheme),
                      _buildCheckboxListTile(noPork, _selectedDietaryRestrictions, colorScheme),
                      _buildCheckboxListTile('No Peanuts', _selectedDietaryRestrictions, colorScheme),
                      _buildCheckboxListTile('No Tree Nuts', _selectedDietaryRestrictions, colorScheme),
                      const SizedBox(height: 8.0), // Reduced space before "Other" field
                      TextFormField(
                        controller: _otherRestrictionController,
                        decoration: _m3FilledInputDecoration(
                          labelText: 'Other restriction...',
                          colorScheme: colorScheme,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0), // Reduced space between sections

                // Food Allergies Section
                Visibility(
                  visible: false,
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(8),
                    dashPattern: const [6, 3],
                    color: colorScheme.outline.withOpacity(0.6),
                    strokeWidth: 1,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Food Allergies:',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold // Make title bold
                            )),
                        const SizedBox(height: 8.0), // Keep some space below title
                        _buildCheckboxListTile(peanuts, _selectedFoodAllergies, colorScheme),
                        _buildCheckboxListTile(treeNuts, _selectedFoodAllergies, colorScheme),
                        _buildCheckboxListTile(shellfish, _selectedFoodAllergies, colorScheme),
                        _buildCheckboxListTile(eggs, _selectedFoodAllergies, colorScheme),
                        const SizedBox(height: 8.0), // Reduced space before "Other" field
                        TextFormField(
                          controller: _otherAllergyController,
                          decoration: _m3FilledInputDecoration(
                            labelText: 'Other allergy...',
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0), // Reduced space between sections

                // Health Conditions Section
                Visibility(
                  visible: false,
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(8),
                    dashPattern: const [6, 3],
                    color: colorScheme.outline.withOpacity(0.6),
                    strokeWidth: 1,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Health Conditions Affecting Diet:',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold // Make title bold
                            )),
                        const SizedBox(height: 8.0), // Keep some space below title
                        _buildCheckboxListTile(diabetes, _selectedHealthConditions, colorScheme),
                        _buildCheckboxListTile(hypertension, _selectedHealthConditions, colorScheme),
                        const SizedBox(height: 8.0), // Reduced space before "Other" field
                        TextFormField(
                          controller: _otherConditionController,
                          decoration: _m3FilledInputDecoration(
                            labelText: 'Other condition...',
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Space before the button and progress text
                const SizedBox(height: 8.0), // Reduced space before button

                FilledButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)), // Pill shape
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
                      : const Text('Next'),
                ),
                const SizedBox(height: 12.0),
                Text(
                  "Step 2 of 4 (Dietary Needs)",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}