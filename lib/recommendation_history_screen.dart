import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ai_food_app/config.dart';import 'package:ai_food_app/login_screen.dart';
// Import other necessary screens for bottom navigation
import 'package:ai_food_app/home_screen.dart';
import 'package:ai_food_app/profile_settings_screen.dart';

/// Data class for a single history item.
/// Data class for a single history item.
class HistoryItem {
  final String foodName;
  final DateTime recommendedOn;
  final String feedbackStatus; // 'liked', 'disliked', 'none'
  final int? healthinessScore;
  final int? tastinessScore;
  final int? intentToTryScore;

  HistoryItem({
    required this.foodName,
    required this.recommendedOn,
    required this.feedbackStatus,
    this.healthinessScore,
    this.tastinessScore,
    this.intentToTryScore,
  });

  // Factory constructor to parse from the backend's JSON structure.
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    // Derive feedbackStatus from the 'liked' boolean.
    String status;
    final bool? liked = json['liked'] as bool?;
    if (liked == true) {
      status = 'liked';
    } else if (liked == false) {
      status = 'disliked';
    } else {
      status = 'none';
    }

    return HistoryItem(
      // CORRECTED: Use the aliased field names from the backend's Pydantic model
      foodName: json['foodName'] ?? 'Unknown Food',
      recommendedOn: DateTime.parse(json['recommendedOn']),
      feedbackStatus: status,
      healthinessScore: json['healthinessScore'] as int?,
      tastinessScore: json['tastinessScore'] as int?,
      intentToTryScore: json['intentToTryScore'] as int?,
    );
  }
}

class RecommendationHistoryScreen extends StatefulWidget {
  const RecommendationHistoryScreen({super.key});

  @override
  State<RecommendationHistoryScreen> createState() =>
      _RecommendationHistoryScreenState();
}

class _RecommendationHistoryScreenState
    extends State<RecommendationHistoryScreen> {
  List<HistoryItem> _historyItems = [];
  bool _isInitialLoading = true;
  bool _isPaginating = false;
  bool _hasMorePages = true;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory(); // Fetch the first page on initial load.
  }

  // Fetches recommendation history from the backend, handling pagination.
  Future<void> _fetchHistory({bool isRetry = false}) async {
    // Prevent multiple simultaneous requests.
    if (_isPaginating) return;

    setState(() {
      if (_currentPage == 1) {
        _isInitialLoading = true;
      } else {
        _isPaginating = true;
      }
      _errorMessage = null; // Clear previous errors on a new fetch attempt.
    });

    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Authentication error. Please log in again.';
          _isInitialLoading = false;
        });
        return;
      }

      // CORRECTED: Use the new, correct endpoint URL from history.py
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/history/?page=$_currentPage');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );


      if (!mounted) return;

      final List<HistoryItem> fetchedItems;
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> historyJson = responseData['history'];

        fetchedItems = historyJson
            .map((json) => HistoryItem.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          if (fetchedItems.isNotEmpty) {
            _historyItems.addAll(fetchedItems);
            _currentPage++;
          } else {
            // This was the last page.
            _hasMorePages = false;
          }
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
        setState(() {
          _errorMessage = 'Failed to load history: ${response.body}';
        });
      }
    } catch (e, stacktrace) {
      print('Error fetching history: $e\n$stacktrace');
      setState(() {
        _errorMessage = 'Could not connect to the server. Please check your connection.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isPaginating = false;
        });
      }
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
          'Recommendation History',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
        automaticallyImplyLeading: false, // Assuming this is a main tab screen
      ),
      body: SafeArea(
        child: Column(
          children: [
            // i. Placeholder for filter controls
            Container(
              padding: const EdgeInsets.all(16.0),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by: Date / Meal / Liked', // Placeholder text
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Icon(Icons.filter_list, color: colorScheme.primary),
                ],
              ),
            ),
            // ii. Expanded ListView.builder
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      // d. Bottom navigation bar
      bottomNavigationBar: SafeArea(
        top: false, // We only want to apply padding to the bottom
        child: _buildBottomNavigationBarPlaceholder(context, colorScheme, theme, 1),
      ), // 1 for History
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    if (_historyItems.isEmpty && !_isInitialLoading) {
      return const Center(child: Text('No history found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      // Add 1 to the item count for the "Load More" button or indicator.
      itemCount: _historyItems.length + 1,
      itemBuilder: (context, index) {
        // If it's the last item in the list, decide what to show.
        if (index == _historyItems.length) {
          if (_isPaginating) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ));
          }
          if (_errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: () => _fetchHistory(isRetry: true), child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          if (_hasMorePages) {
            return Center(
              child: OutlinedButton(onPressed: _fetchHistory, child: const Text('Load More')),
            );
          }
          // If no more pages and no errors, show an "end of list" message.
          return const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Center(child: Text("You've reached the end of your history.")));
        }
        // Otherwise, show the history item card.
        return HistoryListItemCard(historyItem: _historyItems[index]);
      },
    );
  }

  // Helper methods for the bottom navigation bar placeholder (copied for consistency)
  Widget _buildBottomNavigationBarPlaceholder(BuildContext context, ColorScheme colorScheme, ThemeData theme, int currentIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, // Using a Material 3 surface color
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(Icons.home_outlined, 'Home', currentIndex == 0, colorScheme, theme, () {
            if (currentIndex != 0) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
          }),
          _buildNavItem(Icons.history_outlined, 'History', currentIndex == 1, colorScheme, theme, () {
            // Already on History screen
          }),
          _buildNavItem(Icons.person_outline, 'Profile', currentIndex == 2, colorScheme, theme, () {
             if (currentIndex != 2) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()), (route) => false);
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

/// Card widget to display a single history item.
class HistoryListItemCard extends StatelessWidget {
  final HistoryItem historyItem;

  const HistoryListItemCard({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final DateFormat dateFormat = DateFormat('MMM d, yyyy \'at\' h:mm a');

    Widget feedbackWidget;
    switch (historyItem.feedbackStatus) {
      case 'liked':
        feedbackWidget = Row(children: [Icon(Icons.thumb_up, color: Colors.green.shade700, size: 18), const SizedBox(width: 4), Text('(Liked)', style: TextStyle(color: Colors.green.shade700, fontSize: theme.textTheme.bodySmall?.fontSize))]);
        break;
      case 'disliked':
        feedbackWidget = Row(children: [Icon(Icons.thumb_down, color: colorScheme.error, size: 18), const SizedBox(width: 4), Text('(Disliked)', style: TextStyle(color: colorScheme.error, fontSize: theme.textTheme.bodySmall?.fontSize))]);
        break;
      default: // 'none'
        // This case will no longer be shown due to backend filtering, but kept as a fallback.
        feedbackWidget = Text('(No feedback)', style: TextStyle(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic, fontSize: theme.textTheme.bodySmall?.fontSize));
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(historyItem.foodName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                feedbackWidget,
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Recommended on ${dateFormat.format(historyItem.recommendedOn)}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            // REMOVED: The section for Healthiness, Tastiness, and Intent to Try scores.
            // REMOVED: The 'View Original Recommendation' button.
          ],
        ),
      ),
    );
  }

  // REMOVED: The _buildScoreIndicator method is no longer needed.
} 