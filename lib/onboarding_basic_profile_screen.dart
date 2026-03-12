import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import the next onboarding screen.
import 'package:ai_food_app/onboarding_dietary_needs_screen.dart';
import 'package:ai_food_app/login_screen.dart';
import 'package:ai_food_app/config.dart';

// OnboardingBasicProfileScreen collects basic user profile information.
class OnboardingBasicProfileScreen extends StatefulWidget {
  /// The name of the user, passed from the previous screen.
  final String? userName;

  const OnboardingBasicProfileScreen({super.key, this.userName});

  @override
  State<OnboardingBasicProfileScreen> createState() =>
      _OnboardingBasicProfileScreenState();
}

class _OnboardingBasicProfileScreenState
    extends State<OnboardingBasicProfileScreen> {
  // GlobalKey to uniquely identify the Form and allow validation.
  final _formKey = GlobalKey<FormState>();

  // Controllers for text input fields.
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  // State variables for dropdown and radio buttons.
  String? _selectedGender;
  String? _selectedActivityLevel;
  // State variable to track loading state for API calls.
  bool _isLoading = false;

  // Options for Gender Dropdown
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Prefer not to say'
  ];

  // Options for Activity Level Radio Buttons
  final List<Map<String, String>> _activityLevelOptions = [
    {'id': 'sedentary', 'title': 'Sedentary', 'subtitle': 'Little to no exercise'},
    {'id': 'lightly_active', 'title': 'Lightly Active', 'subtitle': 'Light exercise 1-3 days/week'},
    {'id': 'moderately_active', 'title': 'Moderately Active', 'subtitle': 'Moderate exercise 3-5 days/week'},
    {'id': 'very_active', 'title': 'Very Active', 'subtitle': 'Intense exercise 6-7 days/week'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers.
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources.
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Helper method for consistent InputDecoration.
  InputDecoration _m3FilledInputDecoration({
    required String labelText,
    String? hintText,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
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

  // Handles form submission.
  Future<void> _submitForm() async {
    bool isFormValid = _formKey.currentState!.validate();
    bool isActivityLevelSelected = _selectedActivityLevel != null;

    if (!isActivityLevelSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your activity level.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (!isFormValid || !isActivityLevelSelected) {
      return;
    }

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
      
      // Basic parsing for height and weight. A more robust solution would use separate fields.
      // final heightParts = _heightController.text.split(' ');
      final weightParts = _weightController.text.split(' ');

      final requestBody = {
        'age': int.tryParse(_ageController.text),
        'gender': _selectedGender,
        'height': null, // Was: double.tryParse(heightParts.first),
        'heightUnit': null, // Was: heightParts.length > 1 ? heightParts.last : null,
        'weight': double.tryParse(weightParts.first),
        'weightUnit': weightParts.length > 1 ? weightParts.last : null,
        'activityLevel': _selectedActivityLevel,
      };

      // Remove null values from the map before encoding
      // requestBody.removeWhere((key, value) => value == null); // Comment this out so explicit nulls are sent

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
          MaterialPageRoute(builder: (context) => const OnboardingDietaryNeedsScreen()),
        );
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
          SnackBar(content: Text('Failed to save profile. Error: ${response.body}'), backgroundColor: Colors.redAccent),
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Correctly access userName via widget.userName
    print("OnboardingBasicProfileScreen received userName: ${widget.userName}");     final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'About You',
          style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    "This helps us understand your general needs.",
                    style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    controller: _ageController,
                    decoration: _m3FilledInputDecoration(
                      labelText: 'Age',
                      hintText: 'e.g., 30',
                      colorScheme: colorScheme,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your age.';
                      final age = int.tryParse(value);
                      if (age == null) return 'Please enter a valid number.';
                      if (age <= 0) return 'Age must be positive.';
                      if (age > 120) return 'Please enter a realistic age.'; // Arbitrary upper limit
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>( // Removed Align wrapper
                    decoration: _m3FilledInputDecoration(
                      labelText: 'Gender',
                      colorScheme: colorScheme,
                    ),
                    value: _selectedGender,
                    items: _genderOptions.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() { _selectedGender = newValue; });
                    },
                    validator: (value) => value == null ? 'Please select your gender.' : null,
                    borderRadius: BorderRadius.circular(4.0),
                    dropdownColor: colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 16.0),
                  Visibility(
                    visible: false,
                    child: TextFormField(
                      controller: _heightController,
                      decoration: _m3FilledInputDecoration(
                        labelText: 'Height',
                        hintText: 'e.g., 175 cm',
                        colorScheme: colorScheme,
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter your height.' : null,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _weightController,
                    decoration: _m3FilledInputDecoration(
                      labelText: 'Current Weight',
                      hintText: 'e.g., 70 kg',
                      colorScheme: colorScheme,
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter your current weight.' : null,
                  ),
                  const SizedBox(height: 24.0), // Keep spacing before the dropdown
                  // const SizedBox(height: 8.0), // No longer needed for direct DropdownButtonFormField
                  DropdownButtonFormField<String>(
                    decoration: _m3FilledInputDecoration( // Existing decoration
                      labelText: 'Select Activity Level', // Changed label
                      colorScheme: colorScheme,
                    ).copyWith( // Add specific content padding to increase height
                      contentPadding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 12.0),
                      // Default vertical padding is often around 16.0, so 22.0 will make it taller.
                    ),
                    value: _selectedActivityLevel,
                    isExpanded: true, // Allows the rich text in items to be properly laid out
                    itemHeight: 72.0, // Explicitly set item height to accommodate multi-line content
                    selectedItemBuilder: (BuildContext context) { // Custom builder for the selected item
                      return _activityLevelOptions.map<Widget>((Map<String, String> option) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(option['title']!, overflow: TextOverflow.ellipsis),
                        );
                      }).toList();
                    },
                    items: _activityLevelOptions.map((Map<String, String> option) {
                      return DropdownMenuItem<String>(
                        value: option['id']!,
                        child: Column( // Use a Column for title and subtitle
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Ensure Column takes minimum vertical space
                          // mainAxisAlignment: MainAxisAlignment.center, // Removed for potentially simpler layout
                          children: <Widget>[
                            Text(
                              option['title']!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                // Ensure text color is appropriate if not default
                                // color: colorScheme.onSurface,
                              )
                            ),
                            Text(
                              option['subtitle']!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() { _selectedActivityLevel = newValue; });
                    },
                    validator: (value) => value == null ? 'Please select your activity level.' : null,
                    borderRadius: BorderRadius.circular(4.0),
                    dropdownColor: colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 24.0),
                  FilledButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    "Step 1 of 4 (Profile Input)",
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
