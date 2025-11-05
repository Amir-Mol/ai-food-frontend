import 'package:flutter/material.dart';
import 'package:ai_food_app/login_screen.dart'; // For navigation after successful reset
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ai_food_app/config.dart';

// SetNewPasswordScreen allows users to set a new password after verifying a reset code.
class SetNewPasswordScreen extends StatefulWidget {
  // The email address of the user resetting their password.
  final String email;

  const SetNewPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

// _SetNewPasswordScreenState manages the state for the SetNewPasswordScreen.
class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  // GlobalKey to uniquely identify the Form and allow validation.
  final _formKey = GlobalKey<FormState>();
  // Controllers for the new password and confirm password input fields.
  late TextEditingController _codeController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // State variables to toggle password visibility for each field.
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  // State variable to track loading state for API calls.
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers when the widget is created.
    _codeController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree to free up resources.
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Toggles the visibility of the new password field.
  void _toggleNewPasswordVisibility() {
    setState(() {
      _isNewPasswordObscured = !_isNewPasswordObscured;
    });
  }

  // Toggles the visibility of the confirm password field.
  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
    });
  }

  // Handles the form submission to reset the password.
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/reset-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': _codeController.text,
          'newPassword': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to LoginScreen and remove all previous routes from the stack.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['detail'] ?? 'An unknown error occurred.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMessage'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to the server.'), backgroundColor: Colors.redAccent),
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

  // Helper method to create a consistent Material 3 Filled InputDecoration style.
  InputDecoration _m3FilledInputDecoration({
    required String labelText,
    required ColorScheme colorScheme,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      suffixIcon: suffixIcon,
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Scaffold provides the basic visual structure for the screen.
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Set New Password',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Allows the content to be scrollable if it exceeds screen height.
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // Main column for form elements.
                children: <Widget>[
                  Text(
                    'Enter the code sent to ${widget.email} and set a new password.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    controller: _codeController,
                    decoration: _m3FilledInputDecoration(
                      labelText: 'Verification Code',
                      colorScheme: colorScheme,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter the code.' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    // Input field for the new password.
                    controller: _passwordController,
                    decoration: _m3FilledInputDecoration(
                      labelText: 'New Password',
                      colorScheme: colorScheme,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _toggleNewPasswordVisibility,
                      ),
                    ),
                    obscureText: _isNewPasswordObscured,
                    // Validates the new password field.
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password.';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters long.';
                      }
                      // Add other password strength rules if needed
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    // Input field to confirm the new password.
                    controller: _confirmPasswordController,
                    decoration: _m3FilledInputDecoration(
                      labelText: 'Confirm New Password',
                      colorScheme: colorScheme,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                    obscureText: _isConfirmPasswordObscured,
                    // Validates the confirm password field, ensuring it matches the new password.
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password.';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  FilledButton(
                    // Button to submit the new password.
                    onPressed: _isLoading ? null : _resetPassword,
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
                        : const Text('Set New Password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}