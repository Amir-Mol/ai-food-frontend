import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ai_food_app/config.dart';import 'package:ai_food_app/login_screen.dart';
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for text input fields
  late TextEditingController _nameController;
  late TextEditingController _emailController; // Read-only
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  // State variables for dropdown and radio buttons
  String? _selectedGender;
  String? _selectedActivityLevel;

  // Options for Gender Dropdown (same as onboarding)
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Prefer not to say'
  ];

  // Options for Activity Level Radio Buttons (same as onboarding)
  final List<Map<String, String>> _activityLevelOptions = [
    {'id': 'sedentary', 'title': 'Sedentary', 'subtitle': 'Little to no exercise'},
    {'id': 'lightly_active', 'title': 'Lightly Active', 'subtitle': 'Light exercise 1-3 days/week'},
    {'id': 'moderately_active', 'title': 'Moderately Active', 'subtitle': 'Moderate exercise 3-5 days/week'},
    {'id': 'very_active', 'title': 'Very Active', 'subtitle': 'Intense exercise 6-7 days/week'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers, they will be populated by the fetch method.
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        // Handle not being logged in
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
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          
          final height = data['height']?.toString() ?? '';
          final heightUnit = data['heightUnit'] ?? '';
          _heightController.text = height.isNotEmpty ? '$height $heightUnit'.trim() : '';

          final weight = data['weight']?.toString() ?? '';
          final weightUnit = data['weightUnit'] ?? '';
          _weightController.text = weight.isNotEmpty ? '$weight $weightUnit'.trim() : '';

          _selectedGender = data['gender'];
          _selectedActivityLevel = data['activityLevel'];
        });
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
          SnackBar(content: Text('Failed to load profile: ${response.body}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Helper method for consistent InputDecoration (copied from onboarding screens)
  InputDecoration _m3FilledInputDecoration({
    required String labelText,
    String? hintText,
    required ColorScheme colorScheme,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: enabled ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: enabled ? colorScheme.outline.withOpacity(0.5) : colorScheme.outline.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: enabled ? colorScheme.primary : colorScheme.outline.withOpacity(0.2), width: enabled ? 2.0 : 1.0),
      ),
      disabledBorder: OutlineInputBorder( // Style for disabled field
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
    );
  }

  Future<void> _saveChanges() async {
    bool isFormValid = _formKey.currentState!.validate();
    if (!isFormValid) return;

    setState(() => _isSaving = true);

    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // final heightParts = _heightController.text.split(' ');
      final weightParts = _weightController.text.split(' ');

      final requestBody = {
        'name': _nameController.text,
        'age': int.tryParse(_ageController.text),
        'gender': _selectedGender,
        'height': null,
        'heightUnit': null,
        'weight': double.tryParse(weightParts.first),
        'weightUnit': weightParts.length > 1 ? weightParts.last : null,
        'activityLevel': _selectedActivityLevel,
      };

      // Remove null values from the map before encoding
      // requestBody.removeWhere((key, value) => value == null);

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
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
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
          SnackBar(content: Text('Failed to save profile: ${response.body}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
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
                  // The CircleAvatar and "Tap to change" button have been hidden for now.
                  // They can be re-enabled when the feature is implemented in the future.
                  const SizedBox(height: 24.0), // Top padding
                  TextFormField(
                    controller: _nameController,
                    decoration: _m3FilledInputDecoration(labelText: 'Name', colorScheme: colorScheme),
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name.' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _emailController,
                    decoration: _m3FilledInputDecoration(labelText: 'Email Address (cannot be changed)', colorScheme: colorScheme, enabled: false),
                    enabled: false, // Make it read-only
                    style: TextStyle(color: colorScheme.onSurfaceVariant), // Indicate disabled state
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _ageController,
                    decoration: _m3FilledInputDecoration(labelText: 'Age', hintText: 'e.g., 30', colorScheme: colorScheme),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your age.';
                      final age = int.tryParse(value);
                      if (age == null) return 'Please enter a valid number.';
                      if (age <= 0 || age > 120) return 'Please enter a realistic age.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: _m3FilledInputDecoration(labelText: 'Gender', colorScheme: colorScheme),
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
                      decoration: _m3FilledInputDecoration(labelText: 'Height', hintText: 'e.g., 175 cm', colorScheme: colorScheme),
                      keyboardType: TextInputType.text, // Can be number with unit or just text
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter your height.' : null,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _weightController,
                    decoration: _m3FilledInputDecoration(labelText: 'Current Weight', hintText: 'e.g., 70 kg', colorScheme: colorScheme),
                    keyboardType: TextInputType.text, // Can be number with unit or just text
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter your current weight.' : null,
                  ),
                  const SizedBox(height: 24.0),
                  Text('Activity Level:', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: 8.0),
                  Column(
                    children: _activityLevelOptions.map((option) {
                      return RadioListTile<String>(
                        title: Text(option['title']!),
                        subtitle: Text(option['subtitle']!),
                        value: option['id']!,
                        groupValue: _selectedActivityLevel,
                        onChanged: (String? value) {
                          setState(() { _selectedActivityLevel = value; });
                        },
                        activeColor: colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32.0),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      ),
    );
  }
}