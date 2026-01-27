import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Updated content based on "Privacy Notice for Scientific Research Participants"
  static const String _policyContent = """
**1. Information for Research Participants**
You are taking part in a scientific study organized by the University of Oulu. This notice describes how your personal data will be processed in the study. Participation in the study is voluntary. There will be no negative consequences for you if you choose not to participate in the study or if you withdraw from the study.

**2. Data Controller**
University of Oulu
Address: PL 8000, 90014 Oulun yliopisto (Pentti Kaiteran katu 1, Linnanmaa)

**Contact person in matters concerning the project:**
Name: Amir Mollazadeh & Merdad Rostami
Faculty: Faculty of Information Technology and Electrical Engineering (ITEE)
E-mail: amir.mollazadeh@oulu.fi & mehrdad.rostami@oulu.fi

**3. Description of the study and the purposes of processing personal data**
The "NutriRecom" project investigates the effectiveness of Artificial Intelligence (AI) in providing personalized food and recipe recommendations. The purpose of processing your personal data is to:
- Generate personalized food recommendations based on your preferences.
- Analyze user interaction with AI explanations to improve nutritional guidance systems.
- Conduct academic research.

**First-Stage User Testing:**
Users participating in these first-stage tests are explicitly informed about the experimental nature of the application. Please note:
- The system is under development, and recommendations may be approximate.
- The primary purpose of this test phase is to evaluate the application’s technical performance, usability, and transparency.
- **The recommendations provided by the application do not constitute medical or nutritional advice and should not be interpreted as such.**

**4. Principal investigator or responsible research group**
**Principal Investigator / Supervisor:**
Name: Prof. Mourad Oussalah
Faculty: ITEE, University of Oulu
E-mail: mourad.oussalah@oulu.fi

**Researcher:**
Name: Amir Mollazadeh & Mehrdad Rostami
E-mail: amir.mollazadeh@oulu.fi & mehrdad.rostami@oulu.fi

**5. Contact details of the Data Protection Officer**
You can contact the Data Protection Officer of the University at **dpo@oulu.fi**.

**6. Persons processing personal data in the study**
The personal data will be processed by:
- The designated researchers in the Faculty of Information Technology and Electrical Engineering (ITEE).

**7. Duration of the study**
Your personal data will be processed until the completion of the research project (estimated **December 31, 2026**). After the project concludes, direct identifiers will be removed, and the anonymized data will be stored for verification purposes.

**8. Lawful basis of processing**
Personal data is processed on the following basis (Article 6(1) of the GDPR):
- **Performance of a task carried out in the public interest:** Scientific research.

Note: Sensitive personal data (health data) is not collected in this phase of the study.

**9. Personal data included in the research materials**
We collect the following data:
- **Direct Identifiers:** Email address.
- **Basic Profile:** Age, Gender, Current Weight, Activity Level.
- **Dietary Preferences:** General restrictions (e.g., Vegan, Vegetarian, No Pork), food dislikes, and cuisine preferences.
- **Usage Data:** Ratings and feedback on recommendations provided by the app.
- **Technical Logs:** Server logs may temporarily record IP addresses for security and technical troubleshooting purposes.

**10. Sources of personal data**
All data is collected directly from you (the participant) through your interaction with the NutriRecom mobile application.

**11. Transfer and disclosure of personal data**
We use the following third-party service providers (processors) to support the app's functionality. Data processing agreements are in place to ensure compliance with GDPR.
- **Microsoft Azure OpenAI (Sweden/EU):** Used to generate AI recommendations. Your profile data is processed within the EU.
- **CSC - IT Center for Science (Finland):** Provides secure hosting for the application backend (Rahti), database (Pukki), and email services.

**12. Transfer or disclosure of personal data to countries outside the EU/EEA**
Personal data **is not transferred** outside the European Union (EU) or the European Economic Area (EEA).

**13. Automated decisions**
The app uses AI to generate recommendations, but no automated decisions which produce legal effects or similarly significant effects concerning the participant are made.

**14. Safeguards to protect the personal data**
The following measures are implemented:
- **Encryption:** Data is encrypted in transit (HTTPS) and at rest in the database.
- **Access Control:** Access to the database is restricted to authorized researchers via secure credentials.
- **Separation of Data:** Your email address is stored separately from your research data where possible, linked only by a unique user ID.

**15. Your rights as a data subject, and exceptions to these rights**
The contact person in matters concerning the rights of the participant is the person mentioned in section 2 of this notice.

**Withdrawing consent (GDPR Article 7)**
You have the right to withdraw your consent, provided that the processing of the personal data is based on consent. The withdrawal of consent will not affect the lawfulness of processing based on consent before its withdrawal.

**Right of access (GDPR Article 15)**
You have the right to obtain information on whether or not personal data concerning you are being processed in the project, as well as the data being processed. You can also request a copy of the personal data undergoing processing.

**Right to rectification (GDPR Article 16)**
If there are inaccuracies or errors in your personal data undergoing processing, you have the right to request their rectification or supplementation.

**Right to erasure (GDPR Article 17)**
You have the right to request the erasure of your personal data on the following grounds:
- The personal data are no longer necessary for the purposes for which they were collected or otherwise processed.
- You withdraw the consent on which the processing was based, and there are no other legal grounds for the processing.
- You object to the processing (the right to object is described below), and there are no justified grounds for the processing.
- The personal data have been unlawfully processed, or
- The personal data must be erased to comply with a legal obligation in Union or Member State law to which the controller is subject.

The right to erasure does not apply if the erasure of data renders impossible or seriously impairs the achievement of the objectives of the processing in scientific research.

**Right to restriction of processing (GDPR Article 18)**
You have the right to restrict the processing of your personal data on the following grounds:
- You contest the accuracy of the personal data, whereupon the processing will be restricted for a period enabling the University to verify their accuracy.
- The processing is unlawful and you oppose the erasure of the personal data, requesting the restriction of their use instead.
- The University no longer needs the personal data for the purposes of the processing, but you need them for the establishment, exercise or defence of legal claims.
- You have objected to processing (see details below) pending verification of whether the legitimate grounds of the controller override those of the data subject.

**Right to data portability (GDPR Article 20)**
You have the right to request to receive the personal data you have submitted to the University in a structured, commonly used and machine-readable format and have the right to transmit these data to another controller without hindrance from the University, provided that the processing is based on consent or a contract, and the processing is carried out by automated means.
When exercising your right to data portability, you have the right to have your personal data transmitted from one controller to another, where technically feasible.

**Right to object (GDPR Article 21)**
You have the right to object to processing your personal data, provided that the processing is based on the public interest or legitimate interests. The University will no longer have the right to process your personal data unless it can demonstrate compelling legitimate grounds for the processing that override the interests, rights and freedoms of the data subject, or unless it is necessary for the establishment, exercise or defence of legal claims.
The University can continue processing your personal data also when necessary for the performance of a task carried out for reasons of the public interest.

**Derogating from rights**
In certain individual cases, derogations from the rights described above in this section “Your rights as a data subject”, and exceptions to these rights may be made on the basis of the GDPR and the Finnish Data Protection Act, insofar as the rights render impossible or seriously impair the achievement of scientific or historical research purposes or statistical purposes.
The need for derogations will always be assessed on a case-by-case basis.

**16. Right to lodge a complaint**
You have the right to lodge a complaint with the Data Protection Ombudsman’s Office if you think your personal data has been processed in violation of applicable data protection laws.
**Email:** tietosuoja@om.fi
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
                  "Date: December 16, 2025",
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