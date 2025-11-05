import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Placeholder text for the privacy policy content
  static const String _policyContent = """

**1. Introduction & Data Controller**
This Privacy Policy describes how personal information is collected, used, and processed by the "Nutri Recom" mobile application (the "App"). This App is a research project conducted by the University of Oulu.

The data controller for the personal data collected through this App is:
University of Oulu
Pentti Kaiteran katu 1
90570 Oulu, FINLAND

**2. Purpose of Data Collection**
The primary purpose for collecting and processing your data is for academic research. The data you provide will be used to study the effectiveness of AI-generated explanations on food choices. The anonymized and aggregated results of this research may be used in academic publications.

Your data is also used to:
- Provide, maintain, and improve the App's services.
- Personalize your food recommendations based on your unique profile.

**3. Information We Collect**
We collect information you provide directly to us when you create an account and build your profile. This includes:
- Account Information: Email address.
- Profile Data: Age, gender, height, weight, activity level.
- Dietary & Taste Data: Dietary restrictions, food allergies, health conditions, liked/disliked ingredients, and favorite cuisines.
- Feedback Data: Your ratings (liked/disliked, scores for healthiness, tastiness, and intent-to-try) for the recommendations you receive.

**4. Data Sharing and Anonymization**
The personal data collected will be processed by the researchers at the University of Oulu. For the purpose of academic publication, all data will be anonymized and aggregated to ensure that individual users cannot be identified.

We will not share your identifiable personal information with third parties except as required by law.

**5. Your Rights Under GDPR**
As a user within the European Union, you have the following rights regarding your personal data:
- The right to access your data.
- The right to correct any inaccurate data.
- The right to have your data erased.
- The right to restrict the processing of your data.

You can exercise most of these rights directly within the App's profile editing screens. For full data erasure or other inquiries, please contact the research team.

**6. Contact Us**
If you have any questions about this Privacy Policy or our data practices, please contact us at:
amir.mollazadeh@oulu.fi
mehrdad.rostami@oulu.fi
""";

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // i. Last Updated Date
                Text(
                  "Last Updated: May 23, 2025",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16.0),

                // iii. Main Policy Content with Headings
                _buildStyledText(_policyContent, context),

                const SizedBox(height: 24.0),

                // vi. Back to Settings Button
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: const Text('← Back to Settings'),
                ),
                const SizedBox(height: 16.0), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // A helper method to parse text with simple markdown-like bolding (**text**).
  Widget _buildStyledText(String rawText, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Style for regular text
    final defaultStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface,
      height: 1.5, // Improves readability of long paragraphs
    );
    // Style for headings (bolded text)
    final boldStyle = theme.textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );

    final List<TextSpan> children = [];
    // This regex finds text enclosed in double asterisks.
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');

    int lastMatchEnd = 0;
    for (final Match match in regExp.allMatches(rawText)) {
      // Add text before the match with default style
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(
          text: rawText.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      // Add the matched (bold) text, using group 1 to get text inside asterisks
      children.add(TextSpan(
        text: match.group(1),
        style: boldStyle,
      ));

      lastMatchEnd = match.end;
    }

    // Add any remaining text after the last match
    if (lastMatchEnd < rawText.length) {
      children.add(TextSpan(
        text: rawText.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: children),
    );
  }
}