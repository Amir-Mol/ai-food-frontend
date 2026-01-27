import 'package:flutter/material.dart';
import 'package:ai_food_app/create_account_screen.dart'; // For navigation
import 'package:ai_food_app/forgot_password_screen.dart'; // Import ForgotPasswordScreen
import 'package:ai_food_app/onboarding_welcome_screen.dart'; // Placeholder for HomeScreen
import 'package:ai_food_app/home_screen.dart'; // Import the main HomeScreen
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ai_food_app/config.dart';

// LoginScreen is a StatefulWidget to manage the state of the login form.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// _LoginScreenState holds the mutable state for the LoginScreen.
class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey to uniquely identify the Form and allow validation.
  final _formKey = GlobalKey<FormState>();
  // Google Sign-In instance.
final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: AppConfig.googleWebClientId,
);

  // Controllers to manage the text input for email and password fields.
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  // State variable to toggle password visibility.
  bool _isPasswordObscured = true;
  // State variable to track loading state for API calls.
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers when the widget is created.
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree to free up resources.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Toggles the visibility of the password in the password field.
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  // Handles the form submission for login.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/login');
      // The backend expects form data, so we pass the map directly to the body.
      // The http package automatically sets the 'Content-Type' to 'application/x-www-form-urlencoded'.
      final response = await http.post(
        url,
        body: {
          'username': _emailController.text,
          'password': _passwordController.text,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final accessToken = responseData['access_token'];
        final bool onboardingCompleted = responseData['onboardingCompleted'] ?? false;
        final String? serverName = responseData['name'];
        final String serverEmail = responseData['email'] ?? _emailController.text;

        // Store the token securely on the device.
        const storage = FlutterSecureStorage();
        await storage.write(key: 'access_token', value: accessToken);

        // Use the name from the server if it exists and is not empty, otherwise derive it from the email.
        final String finalUserName = (serverName != null && serverName.isNotEmpty)
            ? serverName
            : serverEmail.split('@').first;

        // Navigate to the correct screen based on onboarding status.
        if (onboardingCompleted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => OnboardingWelcomeScreen(userName: finalUserName)),
            (Route<dynamic> route) => false,
          );
        }

      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password.'), backgroundColor: Colors.redAccent),
        );
      } else {
        final errorBody = response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: Status ${response.statusCode}, Body: $errorBody'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      // Log the error for debugging and show a more accurate message.
      print('An error occurred during login process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during login. Please try again.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handles the Google Sign-in process.
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in.
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google Sign-In did not return an ID token.');
      }

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/google-login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final accessToken = responseData['access_token'];
        final bool onboardingCompleted = responseData['onboardingCompleted'] ?? false;
        final String? serverName = responseData['name'];
        final String serverEmail = responseData['email'] ?? googleUser.email;

        const storage = FlutterSecureStorage();
        await storage.write(key: 'access_token', value: accessToken);

        final String finalUserName = (serverName != null && serverName.isNotEmpty)
            ? serverName
            : serverEmail.split('@').first;

        if (onboardingCompleted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
        } else {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => OnboardingWelcomeScreen(userName: finalUserName)), (route) => false);
        }
      } else {
        final errorBody = response.body;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In failed: Status ${response.statusCode}, Body: $errorBody'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      print('An error occurred during Google Sign-In: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred during Google Sign-In. Please try again.'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      fillColor: colorScheme.surfaceContainerHighest, // M3 filled text field background
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

    // Scaffold provides the basic structure of the visual interface.
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Login',
          style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
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
                // Main column for all login form elements.
                children: <Widget>[
                  Container(
                    child: Column(
                      // Section for App Logo and Name.
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          'assets/images/app_logo1.png', // Ensure this path is correct
                          height: 60.0, // Adjusted height for LoginScreen
                          fit: BoxFit.contain,
                          // errorBuilder: (context, error, stackTrace) =>
                          //     const Icon(Icons.image_not_supported, size: 60.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          "Nutri Recom",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                  const SizedBox(height: 16.0),
                  TextFormField(
                    // Password input field.
                    controller: _passwordController,
                    decoration: _m3FilledInputDecoration(
                      labelText: 'Password',
                      colorScheme: colorScheme,
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
                        return 'Please enter your password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8.0),
                  Align(
                    // "Forgot Password?" link.
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  FilledButton(
                    // Primary login button.
                    onPressed: _isLoading ? null : _submitForm,
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
                        : const Text('Login'),
                  ),
                  // const SizedBox(height: 24.0),
                  // Row(
                  //   // "OR" divider for alternative login methods.
                  //   children: <Widget>[
                  //     const Expanded(child: Divider()),
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  //       child: Text('OR', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  //     ),
                  //     const Expanded(child: Divider()),
                  //   ],
                  // ),
                  // const SizedBox(height: 24.0),
                  // OutlinedButton.icon(
                  //   // "Sign in with Google" button.
                  //   icon: Image.asset(
                  //     'assets/images/google_logo.png', // Path to your Google logo
                  //     height: 24.0, // Adjust height as needed
                  //   ),
                  //   label: const Text('Continue with Google'),
                  //   onPressed: _isLoading ? null : _handleGoogleSignIn,
                  //   style: OutlinedButton.styleFrom(
                  //     foregroundColor: colorScheme.primary,
                  //     padding: const EdgeInsets.symmetric(vertical: 12.0),
                  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Pill shape
                  //     side: BorderSide(color: colorScheme.outline),
                  //   ),
                  // ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    // Link to navigate to the Create Account screen.
                    onPressed: _isLoading ? null : () {
                      Navigator.pushReplacement( 
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CreateAccountScreen()),
                      );
                    },
                    child: const Text("Don't have an account? Register"),
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