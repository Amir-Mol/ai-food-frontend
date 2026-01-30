import 'package:flutter/material.dart';
import 'package:ai_food_app/auth_check_screen.dart';
import 'package:ai_food_app/services/notification_service.dart';

// The main entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

// MyApp is the root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp is a convenience widget that wraps a number of widgets
    // that are commonly required for Material Design applications.
    return MaterialApp(
      title: 'Nutri Recom', // The title of the application, used by the OS.
      theme: ThemeData(
        useMaterial3: true, // Enables Material 3 design.
        colorScheme: const ColorScheme(
          brightness: Brightness.light, // Assuming a light theme based on provided colors
          primary: Color(0xFF26C6DA),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFB2EBF2),
          onPrimaryContainer: Color(0xFF006064),
          secondary: Color(0xFF8BC34A),
          onSecondary: Color(0xFF212121),
          secondaryContainer: Color(0xFFDCEDC8),
          onSecondaryContainer: Color(0xFF33691E),
          tertiary: Color(0xFFFFCC80),
          onTertiary: Color(0xFF4E342E),
          tertiaryContainer: Color(0xFFFFF3E0),
          onTertiaryContainer: Color(0xFFA1887F),
          error: Color(0xFFD32F2F),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFFFFCDD2),
          onErrorContainer: Color(0xFFB71C1C),
          surface: Color(0xFFFCFCFC), // Background color for Material surfaces.
          onSurface: Color(0xFF1A1C1E), // Text/icon color on surface.
          surfaceContainer: Color(0xFFF8F9FA), // A surface color for containers.
          surfaceContainerHighest: Color(0xFFE1E3E5), // Highest elevation surface container color.
          onSurfaceVariant: Color(0xFF44474A),
          outline: Color(0xFF74777A),
        ),
        // Set the default font family for the entire application.
        fontFamily: 'RobotoFlex',
      ),
      debugShowCheckedModeBanner: false, // Hides the debug banner.
      home: const AuthCheckScreen(), // Start with the auth check screen.
    );
  }
}
