import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ai_food_app/login_screen.dart'; // Import the LoginScreen
import 'package:ai_food_app/onboarding_welcome_screen.dart'; // Import OnboardingWelcomeScreen
import 'package:ai_food_app/terms_of_service_screen.dart';
import 'package:ai_food_app/privacy_policy_screen.dart';
import 'package:ai_food_app/email_verification_screen.dart'; // Import the EmailVerificationScreen
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ai_food_app/config.dart';

// CreateAccountScreen is a StatefulWidget for user registration.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

// _CreateAccountScreenState manages the state for the CreateAccountScreen.
class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // GlobalKey to uniquely identify the Form and allow validation.
  final _formKey = GlobalKey<FormState>();
  // Controllers for email, password, and confirm password input fields.
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // State variables to toggle password visibility.
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  // State variable to track loading state for API calls.
  bool _isLoading = false;
  // State variable to track if the user has agreed to terms and conditions.
  bool _termsOfServiceAgreed = false;
  bool _privacyPolicyAgreed = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers when the widget is created.
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree to free up resources.
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Toggles the visibility of the password in the password field.
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  // Toggles the visibility of the password in the confirm password field.
  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
    });
  }

  // Handles the form submission for account creation.
  Future<void> _submitForm() async {
    if (!_termsOfServiceAgreed || !_privacyPolicyAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to both the Terms of Service and Privacy Policy.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validate the form before proceeding.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      // Check if the widget is still in the tree.
      if (!mounted) return;

      if (response.statusCode == 200) {
        // ALL OLD CODE THAT PARSED A TOKEN IS DELETED.
        // This is the ONLY code that should be left:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EmailVerificationScreen(email: _emailController.text.trim()),
          ),
        );
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email address is already registered.'), backgroundColor: Colors.redAccent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${response.body}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server. Please check your connection.'), backgroundColor: Colors.redAccent),
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
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Helper method to create a consistent Material 3 Filled InputDecoration style.
    InputDecoration M3FilledInputDecoration({
      required String labelText,
      String? helperText,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: labelText,
        helperText: helperText,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest, // M3 filled text field background
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: BorderSide.none, // No border in default state for this style
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)), // Subtle border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        // For a style with focused underline as per original detailed request:
        // border: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
        // enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.6))),
        // focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2.0)),
      );
    }

    // Scaffold provides the basic visual structure for the screen.
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface, // Uses theme default
        elevation: theme.appBarTheme.elevation ?? 0, // Uses theme default or 0
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Ensures the content is scrollable if it overflows the screen height.
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // Main column for all registration form elements.
                children: <Widget>[
                  TextFormField(
                    // Email input field.
                    controller: _emailController,
                    decoration: M3FilledInputDecoration(labelText: 'Email Address'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address.';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    // Password input field.
                    controller: _passwordController,
                    decoration: M3FilledInputDecoration(
                      labelText: 'Password',
                      helperText: 'Must be at least 8 characters and include a number.',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    obscureText: _isPasswordObscured,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password.';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters long.';
                      }
                      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).*$').hasMatch(value)) {
                        return 'Password must contain at least one letter and one number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    // Confirm password input field.
                    controller: _confirmPasswordController,
                    decoration: M3FilledInputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                    obscureText: _isConfirmPasswordObscured,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password.';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CheckboxListTile(
                    title: Text(
                      'I agree to the Terms of Service',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    value: _termsOfServiceAgreed,
                    onChanged: (bool? value) {
                      setState(() {
                        _termsOfServiceAgreed = value ?? false;
                      });
                    },
                    activeColor: colorScheme.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    secondary: IconButton(
                      icon: Icon(Icons.info_outline, color: colorScheme.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
                        );
                      },
                    ),
                  ),
                  CheckboxListTile(
                    title: Text(
                      'I agree to the Privacy Policy',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    value: _privacyPolicyAgreed,
                    onChanged: (bool? value) {
                      setState(() {
                        _privacyPolicyAgreed = value ?? false;
                      });
                    },
                    activeColor: colorScheme.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    secondary: IconButton(
                      icon: Icon(Icons.info_outline, color: colorScheme.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  FilledButton(
                    // Primary registration button.
                    onPressed: (_termsOfServiceAgreed && _privacyPolicyAgreed) ? _submitForm : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Pill shape
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
                        : const Text('Register'),
                  ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    // Link to navigate to the Login screen if the user already has an account.
                    onPressed: _isLoading ? null : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                    child: const Text('Already have an account? Login'),
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