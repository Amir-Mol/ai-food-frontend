import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import screens for navigation
import 'package:ai_food_app/onboarding_dietary_needs_screen.dart';
import 'package:ai_food_app/onboarding_taste_profile_screen.dart';
import 'package:ai_food_app/login_screen.dart'; // For logout
import 'package:ai_food_app/edit_profile_screen.dart'; // Import EditProfileScreen
import 'package:ai_food_app/home_screen.dart'; // Import HomeScreen
import 'package:ai_food_app/edit_dietary_needs_screen.dart'; // Import EditDietaryNeedsScreen
import 'package:ai_food_app/edit_taste_profile_screen.dart'; // Import EditTasteProfileScreen 
import 'package:ai_food_app/recommendation_history_screen.dart'; // Import HistoryScreen
import 'package:ai_food_app/privacy_policy_screen.dart'; // Import PrivacyPolicyScreen 
import 'package:ai_food_app/terms_of_service_screen.dart'; // Import TermsOfServiceScreen
import 'package:ai_food_app/about_screen.dart'; // Import AboutScreen
import 'package:ai_food_app/tutorial_screen.dart'; // Import TutorialScreen
import 'package:ai_food_app/config.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoadingLogout = false;
  bool _isLoadingProfile = true;
  String _userName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
        final String? serverName = data['name'];
        final String serverEmail = data['email'] ?? '';

        setState(() {
          _userEmail = serverEmail;
          _userName = (serverName != null && serverName.isNotEmpty)
              ? serverName
              : serverEmail.split('@').first;
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
        // Handle error, maybe show a snackbar or a retry button
        print('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      print('Could not connect to server: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
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
          'Profile & Settings',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
        automaticallyImplyLeading: false, // Assuming this is a main tab screen
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _fetchProfile,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // i. Main Profile Section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: <Widget>[
                            Text(
                              _userName,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(color: colorScheme.onSurface),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              _userEmail,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12.0),
                            TextButton(
                              onPressed: () {
                                print('Edit Profile tapped');
                                // Navigate to the EditProfileScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                ).then((_) {
                                  _fetchProfile(); // Refetch profile after returning from edit screen
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Edit Profile', style: TextStyle(color: colorScheme.primary)),
                                  const SizedBox(width: 4.0),
                                  Icon(Icons.arrow_forward_ios, size: 16.0, color: colorScheme.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ii. Dietary Needs
                      ListTile(
                        title: Text('Dietary Needs', style: theme.textTheme.titleMedium),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          print('Dietary Needs tapped');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditDietaryNeedsScreen(), // Navigate to the new edit screen
                              // settings: RouteSettings(arguments: {'editMode': true, 'userData': currentUserData}), // Example
                            ),
                          );
                        },
                      ),

                      // iii. Your Taste Profile
                      ListTile(
                        title: Text('Your Taste Profile', style: theme.textTheme.titleMedium),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          print('Your Taste Profile tapped');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditTasteProfileScreen(), // Navigate to the new edit screen
                              // settings: RouteSettings(arguments: {'editMode': true, 'userData': currentUserData}), // Example
                            ),
                          );
                        },
                      ),

                      // iv. View Tutorial
                      ListTile(
                        title: Text('View Tutorial', style: theme.textTheme.titleMedium),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          print('View Tutorial tapped');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TutorialScreen(),
                            ),
                          );
                        },
                      ),

                      // vi. Privacy Policy
                      ListTile(
                        title: Text('Privacy Policy', style: theme.textTheme.titleMedium),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          print('Privacy Policy tapped');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()), // Navigate to the PrivacyPolicyScreen
                          );
                        }
                      ),

                      // vii. Terms of Service
                      ListTile(
                        title: Text('Terms of Service', style: theme.textTheme.titleMedium),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          print('Terms of Service tapped');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()), // Navigate to TermsOfServiceScreen
                          );
                        }
                      ),

                      // viii. About
                      ListTile(
                        title: Text('About', style: theme.textTheme.titleMedium),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          print('About tapped');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AboutScreen()),
                          );
                        }
                      ),

                      // ix. SizedBox for spacing
                      const SizedBox(height: 24.0),

                      // x. Logout Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FilledButton(
                          onPressed: _isLoadingLogout ? null : _showLogoutConfirmationDialog,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.onErrorContainer,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Pill shape
                          ),
                          child: _isLoadingLogout
                              ? SizedBox(
                                  height: 24.0,
                                  width: 24.0,
                                  child: CircularProgressIndicator(
                                    color: colorScheme.onErrorContainer,
                                    strokeWidth: 3.0,
                                  ),
                                )
                              : const Text('Logout'),
                        ),
                      ),
                      const SizedBox(height: 24.0), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
      // Placeholder for the main bottom navigation bar
      bottomNavigationBar: SafeArea(
        top: false, // We only want to apply padding to the bottom
        child: _buildBottomNavigationBarPlaceholder(context, colorScheme, theme, 2),
      ), // 2 for Profile
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            FilledButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
                _performLogout(); // Proceed with logout
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    setState(() {
      _isLoadingLogout = true;
    });

    const storage = FlutterSecureStorage();

    try {
      // Attempt to invalidate token on the server, but don't block client logout
      final token = await storage.read(key: 'access_token');
      if (token != null) {
        final url = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/logout');
        // We don't need to await this or check the response, as client-side logout is primary.
        http.post(
          url,
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 5)); // Timeout to prevent long waits
      }
    } catch (e) {
      // Log the error but don't show a disruptive message to the user.
      // The user is logging out, so the most important thing is to clear local data.
      print('Could not reach server for logout, proceeding locally: $e');
    } finally {
      // Always perform client-side cleanup and navigation
      await storage.delete(key: 'access_token');
      await _googleSignIn.signOut(); // <-- ADD THIS LINE
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
        // No need to set isLoading to false, as the screen is being replaced.
      }
    }
  }

  // Helper methods for the bottom navigation bar placeholder
  // (Copied from home_screen.dart or recommendation_results_screen.dart for consistency)
  Widget _buildBottomNavigationBarPlaceholder(BuildContext context, ColorScheme colorScheme, ThemeData theme, int currentIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(Icons.home_outlined, 'Home', currentIndex == 0, colorScheme, theme, () {
            print('Home (Nav) tapped from Profile. Navigating to HomeScreen.');
            // Navigate to HomeScreen and remove all routes above it.
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          }),
          _buildNavItem(Icons.history_outlined, 'History', currentIndex == 1, colorScheme, theme, () {
            print('History (Nav) tapped from Home');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const RecommendationHistoryScreen()),
              (Route<dynamic> route) => false,
            );
          }),
          _buildNavItem(Icons.person_outline, 'Profile', currentIndex == 2, colorScheme, theme, () {
            print('Profile (Nav) tapped (already here)');
            // No action needed if already on the profile screen
            // if (currentIndex != 2) Navigator.of(context).pushReplacementNamed('/profile');
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, ColorScheme colorScheme, ThemeData theme, VoidCallback onPressed) {
    final Color itemColor = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: itemColor),
          const SizedBox(height: 4.0),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: itemColor)),
        ],
      ),
    );
  }
}