import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_food_app/home_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Tutorial slide data
  final List<TutorialSlide> _slides = [
    TutorialSlide(
      image: 'assets/images/app_logo1.png',
      title: 'Welcome to NutriRecom',
      subtitle:
          'This app is part of a University of Oulu research project exploring AI-based food recommender systems. Our goal is to understand how AI can help people make healthier, personalized food choices.',
    ),
    TutorialSlide(
      image: 'assets/images/tutorial_1.png',
      title: 'Your Daily Recommendations',
      subtitle:
          'By tapping "Find a Meal," our system crafts a personalized batch of 5 meal recommendations tailored to your unique taste and dietary profile.',
    ),
    TutorialSlide(
      image: 'assets/images/tutorial_2.png',
      title: 'Rate Your Meals',
      subtitle:
          'Let us know what you think! Give each meal a thumbs up or down, rate it using the stars, and submit your feedback. Be sure to do this for all 5 items in your batch.',
    ),
    TutorialSlide(
      image: 'assets/images/tutorial_3.png',
      title: 'Reach Your Goal',
      subtitle:
          'Help us complete this research pilot by rating a total of 100 meals. Track your progress right on the home screen and build your perfect diet profile!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Mark tutorial as seen immediately — handles any exit path including back button
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('has_seen_tutorial', true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Marks the tutorial as seen and navigates to HomeScreen
  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  /// Skips the tutorial
  Future<void> _skipTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  /// Navigate to next page or complete if on last page
  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skipTutorial,
            child: Text(
              'Skip',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 16.0,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PageView for slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index], theme, colorScheme);
                },
              ),
            ),
            // Bottom section with indicators and buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: _currentPage == index ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: _currentPage == _slides.length - 1
                        ? FilledButton(
                            onPressed: _completeTutorial,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(fontSize: 16.0),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single tutorial slide
  Widget _buildSlide(TutorialSlide slide, ThemeData theme,
      ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.80,
                heightFactor: 0.80,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32.0),
                    border: !slide.image.contains('app_logo1')
                        ? Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: !slide.image.contains('app_logo1')
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16.0,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8.0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32.0),
                    child: Image.asset(
                      slide.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainer,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 64.0,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32.0),
          // Title
          Text(
            slide.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          // Subtitle
          Text(
            slide.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Model class for tutorial slides
class TutorialSlide {
  final String image;
  final String title;
  final String subtitle;

  TutorialSlide({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
