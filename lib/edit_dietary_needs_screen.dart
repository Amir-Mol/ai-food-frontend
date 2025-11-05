import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ai_food_app/config.dart';

class EditDietaryNeedsScreen extends StatefulWidget {
  const EditDietaryNeedsScreen({super.key});

  @override
  State<EditDietaryNeedsScreen> createState() => _EditDietaryNeedsScreenState();
}

class _EditDietaryNeedsScreenState extends State<EditDietaryNeedsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // State variables for selected options
  late Set<String> _selectedDietaryRestrictions;
  late Set<String> _selectedFoodAllergies;
  late Set<String> _selectedHealthConditions;

  // Controllers for "Other" text fields
  late TextEditingController _otherRestrictionController;
  late TextEditingController _otherAllergyController;
  late TextEditingController _otherConditionController;

  // --- Options for Checkboxes (similar to onboarding) ---
  // Dietary Restrictions
  final List<String> _dietaryRestrictionOptions = [
    'Vegan', 'Vegetarian', 'Pescatarian', 'Gluten-Free', 'Lactose-Free', 'No Pork'
  ];
  // Food Allergies
  final List<String> _foodAllergyOptions = [
    'Peanuts', 'Tree Nuts (e.g., almonds, walnuts)', 'Shellfish (Crustacean/Molluscan)', 'Eggs'
  ];
  // Health Conditions
  final List<String> _healthConditionOptions = [
    'Diabetes (General)', 'Hypertension (High Blood Pressure)'
  ];
  // --- End of Options ---

  @override
  void initState() {
    super.initState();
    // Initialize with empty data, will be populated by fetch
    _selectedDietaryRestrictions = {};
    _otherRestrictionController = TextEditingController();
    _selectedFoodAllergies = {};
    _otherAllergyController = TextEditingController();
    _selectedHealthConditions = {};
    _otherConditionController = TextEditingController();
    _fetchDietaryProfile();
  }

  Future<void> _fetchDietaryProfile() async {
    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/profile');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dietaryProfile = data['dietaryProfile'];

        if (dietaryProfile != null) {
          setState(() {
            _selectedDietaryRestrictions = Set<String>.from(dietaryProfile['dietaryRestrictions']['selected'] ?? []);
            _otherRestrictionController.text = dietaryProfile['dietaryRestrictions']['other'] ?? '';

            _selectedFoodAllergies = Set<String>.from(dietaryProfile['foodAllergies']['selected'] ?? []);
            _otherAllergyController.text = dietaryProfile['foodAllergies']['other'] ?? '';

            _selectedHealthConditions = Set<String>.from(dietaryProfile['healthConditions']['selected'] ?? []);
            _otherConditionController.text = dietaryProfile['healthConditions']['other'] ?? '';
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dietary profile: ${response.body}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _otherRestrictionController.dispose();
    _otherAllergyController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }

  // Helper method for consistent InputDecoration (copied from onboarding screens)
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
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<String> options,
    required Set<String> selectedSet,
    required TextEditingController otherController,
    required String otherLabel,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(8),
      dashPattern: const [6, 3],
      color: colorScheme.outline.withOpacity(0.6),
      strokeWidth: 1,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          ...options.map((option) =>
              _buildCheckboxListTile(option, selectedSet, colorScheme)),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: otherController,
            decoration: _m3FilledInputDecoration(
              labelText: otherLabel,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

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

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/profile');
      final response = await http.patch(
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
          const SnackBar(content: Text('Dietary needs updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save dietary needs: ${response.body}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Dietary Needs')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Edit Dietary Needs',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: colorScheme.onSurface),
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
                  "Update your dietary information. This helps us refine recommendations.",
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),

                _buildSection(
                  context: context,
                  title: 'Dietary Restrictions:',
                  options: _dietaryRestrictionOptions,
                  selectedSet: _selectedDietaryRestrictions,
                  otherController: _otherRestrictionController,
                  otherLabel: 'Other restriction...',
                ),
                const SizedBox(height: 16.0),

                _buildSection(
                  context: context,
                  title: 'Food Allergies:',
                  options: _foodAllergyOptions,
                  selectedSet: _selectedFoodAllergies,
                  otherController: _otherAllergyController,
                  otherLabel: 'Other allergy...',
                ),
                const SizedBox(height: 16.0),

                // _buildSection(
                //   context: context,
                //   title: 'Health Conditions Affecting Diet:',
                //   options: _healthConditionOptions,
                //   selectedSet: _selectedHealthConditions,
                //   otherController: _otherConditionController,
                //   otherLabel: 'Other condition...',
                // ),
                const SizedBox(height: 16.0),

                FilledButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 24.0,
                          width: 24.0,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 3.0,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
                const SizedBox(height: 12.0),
                OutlinedButton(
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
                  child: const Text('Back to Profile'),
                ),
                const SizedBox(height: 24.0), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}