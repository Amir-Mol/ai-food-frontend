import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_food_app/config.dart';
import 'package:ai_food_app/home_screen.dart';

/// Post-study questionnaire shown after user completes all 100 recommendations.
/// Transparency group sees 15 questions (Q1–Q13 Likert + Q14–Q15 open-ended).
/// Control group sees 12 questions (Q1–Q10 Likert + Q14–Q15 open-ended).
class SurveyScreen extends StatefulWidget {
  final bool isTransparencyGroup;

  const SurveyScreen({super.key, required this.isTransparencyGroup});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  late DateTime _screenEnteredAt;
  bool _isSubmitting = false;

  // Likert answers (0 = unanswered)
  final Map<String, int> _scores = {
    'q1': 0, 'q2': 0, 'q3': 0, 'q4': 0, 'q5': 0,
    'q6': 0, 'q7': 0, 'q8': 0, 'q9': 0, 'q10': 0,
    'q11': 0, 'q12': 0, 'q13': 0,
  };

  // Open-ended answers
  final TextEditingController _q14Controller = TextEditingController();
  final TextEditingController _q15Controller = TextEditingController();
  static const int _maxChars = 200;

  @override
  void initState() {
    super.initState();
    _screenEnteredAt = DateTime.now();
  }

  @override
  void dispose() {
    _q14Controller.dispose();
    _q15Controller.dispose();
    super.dispose();
  }

  List<String> get _requiredKeys {
    final keys = ['q1','q2','q3','q4','q5','q6','q7','q8','q9','q10'];
    if (widget.isTransparencyGroup) keys.addAll(['q11','q12','q13']);
    return keys;
  }

  bool get _allAnswered => _requiredKeys.every((k) => _scores[k]! > 0);

  Future<void> _submit() async {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please answer all required questions before submitting.'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      if (token == null) return;

      final timeSpent = DateTime.now().difference(_screenEnteredAt).inSeconds;

      // Build answers map — omit q11-13 for control group (send as null)
      final Map<String, dynamic> answers = {};
      for (final k in ['q1','q2','q3','q4','q5','q6','q7','q8','q9','q10']) {
        answers[k] = _scores[k];
      }
      if (widget.isTransparencyGroup) {
        answers['q11'] = _scores['q11'];
        answers['q12'] = _scores['q12'];
        answers['q13'] = _scores['q13'];
      }
      answers['q14'] = _q14Controller.text.trim();
      answers['q15'] = _q15Controller.text.trim();

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/survey/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'answers': answers, 'timeSpentSeconds': timeSpent}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Clear the pending flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('surveyPending', false);

        // Navigate to HomeScreen (experiment-complete state)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit survey. Please try again. (${response.statusCode})'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not connect to server. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Builders ──────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: theme.colorScheme.outlineVariant, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildLikertRow(String key, String question, ThemeData theme) {
    final score = _scores[key]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final val = i + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  val <= score ? Icons.star_rounded : Icons.star_border_rounded,
                  color: val <= score ? Colors.amber.shade600 : Colors.grey,
                  size: 32,
                ),
                onPressed: () => setState(() => _scores[key] = val),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenEndedQuestion(
    String question,
    TextEditingController controller,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(question, style: theme.textTheme.bodyMedium)),
              Text(
                'Optional',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              final remaining = _maxChars - value.text.length;
              return TextField(
                controller: controller,
                maxLength: _maxChars,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  border: const OutlineInputBorder(),
                  counterText: '$remaining characters remaining',
                  counterStyle: TextStyle(
                    color: remaining < 20
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      // Prevent accidental back navigation — data would be lost
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Leave survey?'),
              content: const Text(
                  'Your answers will not be saved. You can come back to the survey anytime from the app.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Final Survey'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Intro ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎉 You\'ve completed all recommendations!',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please take a few minutes to complete this short survey. '
                        'Your feedback is important for our research.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.amber.shade600, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '1 = Strongly Disagree   ·   5 = Strongly Agree',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Section 1: App Usability ───────────────────────────────
                _buildSectionHeader('App Usability', theme),
                _buildLikertRow('q1', '1. The mobile application was easy to use and navigate.', theme),
                _buildLikertRow('q2', '2. The app functioned reliably without major issues.', theme),
                _buildLikertRow('q3', '3. I am satisfied with my overall experience using the app.', theme),

                // ── Section 2: Recommendations & Health Impact ─────────────
                _buildSectionHeader('Recommendations & Health Impact', theme),
                _buildLikertRow('q4', '4. The recommended food items matched my preferences and needs.', theme),
                _buildLikertRow('q5', '5. The recommendations helped me make better food choices.', theme),
                _buildLikertRow('q6', '6. Using this app increased my awareness of healthy food choices.', theme),
                _buildLikertRow('q7', '7. During the study, I chose healthier food options more often than usual.', theme),
                _buildLikertRow('q8', '8. The app motivated me to adopt a healthier lifestyle.', theme),
                _buildLikertRow('q9', '9. I would like to see similar healthy recommendation features in other food-related apps.', theme),
                _buildLikertRow('q10', '10. I would prefer using apps that suggest healthier options based on my preferences.', theme),

                // ── Section 3: Explanations (Transparency group only) ──────
                if (widget.isTransparencyGroup) ...[
                  _buildSectionHeader('About Explanations', theme),
                  _buildLikertRow('q11', '11. The explanations helped me understand why items were recommended.', theme),
                  _buildLikertRow('q12', '12. The explanations increased my trust in the recommendations.', theme),
                  _buildLikertRow('q13', '13. The explanations encouraged me to pay more attention to healthier food options.', theme),
                ],

                // ── Section 4: Open-ended ──────────────────────────────────
                _buildSectionHeader('Your Feedback', theme),
                _buildOpenEndedQuestion(
                  '14. What did you like most about the app?',
                  _q14Controller,
                  theme,
                ),
                _buildOpenEndedQuestion(
                  '15. What improvements would you suggest for the app?',
                  _q15Controller,
                  theme,
                ),

                // ── Submit button ──────────────────────────────────────────
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Survey', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
