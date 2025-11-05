import 'package:flutter/material.dart';
import 'package:ai_food_app/login_screen.dart'; // To potentially navigate back
import 'package:ai_food_app/set_new_password_screen.dart'; // Import SetNewPasswordScreen
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ai_food_app/config.dart';

// ForgotPasswordScreen allows users to request a password reset code.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

// _ForgotPasswordScreenState manages the state for the ForgotPasswordScreen.
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // GlobalKey to uniquely identify the Form and allow validation.
  final _formKey = GlobalKey<FormState>();
  // Controller for the email input field.
  late TextEditingController _emailController;
  // State variable to track loading state for API calls.
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the email controller when the widget is created.
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose the email controller when the widget is removed from the widget tree.
    _emailController.dispose();
    super.dispose();
  }

  // Handles the action of sending a password reset code.
  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/forgot-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset code sent to your email.'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to the SetNewPasswordScreen, passing the email.
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SetNewPasswordScreen(email: _emailController.text.trim())),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper method to create a consistent Material 3 Filled InputDecoration style.
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Scaffold provides the basic visual structure for the screen.
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: SingleChildScrollView(
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
                  // Instructional text for the user.
                  'Enter your email address to receive a password reset code.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                TextFormField(
                  // Email input field.
                  controller: _emailController,
                  decoration: _m3FilledInputDecoration(
                    labelText: 'Email Address',
                    colorScheme: colorScheme,
                  ),
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
                const SizedBox(height: 24.0),
                FilledButton(
                  // Button to trigger sending the reset code.
                  onPressed: _isLoading ? null : _sendResetCode,
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
                      : const Text('Send Reset Code'),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  // Button to navigate back to the Login screen.
                  onPressed: () {
                    // Navigate back to the LoginScreen
                    // This assumes ForgotPasswordScreen was pushed from LoginScreen.
                    // If LoginScreen might not be the previous screen,
                    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    // might be more robust to ensure the user lands on LoginScreen.
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}