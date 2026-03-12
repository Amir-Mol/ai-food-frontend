import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ai_food_app/config.dart';import 'package:ai_food_app/login_screen.dart';
class EditTasteProfileScreen extends StatefulWidget {
  const EditTasteProfileScreen({super.key});

  @override
  State<EditTasteProfileScreen> createState() => _EditTasteProfileScreenState();
}

class _EditTasteProfileScreenState extends State<EditTasteProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for text fields
  late TextEditingController _likedIngredientsController;
  late TextEditingController _dislikedIngredientsController;
  late TextEditingController _otherCuisineController;

  // State variable for selected cuisines
  late Set<String> _selectedFavoriteCuisines;

  // Define options for cuisines (similar to onboarding)
  final List<String> _cuisineOptions = [
    'Italian', 'Mexican', 'Chinese', 'Indian', 'Thai', 'Japanese',
    'Mediterranean', 'American', 'French', 'Spanish', 'Korean',
    'Vietnamese', 'Brazilian', 'Ethiopian',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize empty and then fetch data
    _likedIngredientsController = TextEditingController();
    _dislikedIngredientsController = TextEditingController();
    _otherCuisineController = TextEditingController();
    _selectedFavoriteCuisines = {};
    _fetchTasteProfile();
  }

  Future<void> _fetchTasteProfile() async {
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
        setState(() {
          // The backend sends lists of strings, join them for the text fields
          _likedIngredientsController.text = (data['likedIngredients'] as List<dynamic>?)?.join(', ') ?? '';
          _dislikedIngredientsController.text = (data['dislikedIngredients'] as List<dynamic>?)?.join(', ') ?? '';
          _selectedFavoriteCuisines = Set<String>.from(data['favoriteCuisines'] ?? []);
          _otherCuisineController.text = data['otherCuisine'] ?? '';
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
          SnackBar(content: Text('Failed to load taste profile: ${response.body}'), backgroundColor: Colors.redAccent),
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
    _likedIngredientsController.dispose();
    _dislikedIngredientsController.dispose();
    _otherCuisineController.dispose();
    super.dispose();
  }

  // Helper method for consistent InputDecoration (copied from onboarding screens)
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

  // Helper method for building CheckboxListTile for cuisines (copied from onboarding)
  Widget _buildCuisineCheckboxListTile(
      String cuisine, Set<String> selectedSet, ColorScheme colorScheme) {
    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        title: Text(cuisine, overflow: TextOverflow.ellipsis),
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
        visualDensity: VisualDensity.compact,
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
        'likedIngredients': _likedIngredientsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'dislikedIngredients': _dislikedIngredientsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'favoriteCuisines': _selectedFavoriteCuisines.toList(),
        'otherCuisine': _otherCuisineController.text,
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
          const SnackBar(content: Text('Taste profile updated successfully!'), backgroundColor: Colors.green),
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
          SnackBar(content: Text('Failed to save taste profile: ${response.body}'), backgroundColor: Colors.redAccent),
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

  Widget _buildDottedSection({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
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
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Your Taste Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Edit Your Taste Profile',
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
                  "Update your preferences to help us find the best food for you.",
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),

                _buildDottedSection(
                  context: context,
                  title: 'I Like these Ingredients/Foods:',
                  child: TextFormField(
                    controller: _likedIngredientsController,
                    decoration: _m3FilledInputDecoration(
                      labelText: 'Liked (comma-separated)',
                      hintText: 'e.g., chicken, tomatoes, pasta',
                      colorScheme: colorScheme,
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 16.0),

                _buildDottedSection(
                  context: context,
                  title: "I Don't Like these Ingredients/Foods:",
                  child: TextFormField(
                    controller: _dislikedIngredientsController,
                    decoration: _m3FilledInputDecoration(
                      labelText: 'Disliked (comma-separated)',
                      hintText: 'e.g., mushrooms, olives, cilantro',
                      colorScheme: colorScheme,
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 16.0),

                _buildDottedSection(
                  context: context,
                  title: 'Favorite Cuisines:',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                const SizedBox(height: 32.0),

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