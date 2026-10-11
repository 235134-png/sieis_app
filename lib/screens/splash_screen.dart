import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      title: 'Monitor Indoor Air Quality',
      subtitle:
          'Track real-time CO₂, VOCs, temperature, and humidity from your ESP32 sensors anytime, anywhere.',
      icon: Icons.air_rounded,
      badgeText: 'Live Sensor Telemetry',
      accentColor: Color(0xFF0F766E),
      previewMetrics: [
        ('CO₂', '920 ppm', Icons.co2_rounded),
        ('VOCs', '310 ppb', Icons.air_rounded),
        ('Temp', '27.2 °C', Icons.thermostat_rounded),
        ('Humidity', '64 %', Icons.water_drop_rounded),
      ],
    ),
    OnboardingSlide(
      title: 'AI Predictions & Forecasts',
      subtitle:
          'Get early insights on air quality trends before they happen, powered by machine learning algorithms.',
      icon: Icons.insights_rounded,
      badgeText: 'Machine Learning AI',
      accentColor: Color(0xFF2563EB),
      previewMetrics: [
        ('Prediction', '+1h Forecast', Icons.auto_graph_rounded),
        ('Confidence', '86% Accuracy', Icons.psychology_rounded),
        ('Trend', 'Stable', Icons.trending_up_rounded),
        ('Alert', 'Low Risk', Icons.check_circle_rounded),
      ],
    ),
    OnboardingSlide(
      title: 'Stay Informed with Actionable Guidance',
      subtitle:
          'Receive instant notifications and clear step-by-step recommendations whenever indoor air needs attention.',
      icon: Icons.tips_and_updates_rounded,
      badgeText: 'Smart Guidance',
      accentColor: Color(0xFFE05D2D),
      previewMetrics: [
        ('Ventilate', 'Open windows 10m', Icons.wb_sunny_rounded),
        ('Occupancy', 'Reduce crowd', Icons.groups_rounded),
        ('Checklist', '4 steps ready', Icons.task_alt_rounded),
        ('Status', 'Healthy Room', Icons.verified_rounded),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onGetStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Brand & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.air_rounded,
                          color: Color(0xFF0F766E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'SIEIS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF162033),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: widget.onGetStarted,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF687386),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Card Illustration Preview
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: slide.accentColor.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  slide.accentColor.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: slide.accentColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        slide.badgeText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: slide.accentColor,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      slide.icon,
                                      color: slide.accentColor,
                                      size: 28,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Metrics Preview Grid
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 2.2,
                                  children: slide.previewMetrics.map((item) {
                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(item.$3,
                                              size: 20, color: slide.accentColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item.$1,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF6B7280),
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  item.$2,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF111827),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Title & Subtitle
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF162033),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF687386),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls Section (Dots + Get Started Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  // Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF0F766E)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Get Started / Next Button
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE05D2D), // Branded orange button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
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
}

class OnboardingSlide {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final Color accentColor;
  final List<(String, String, IconData)> previewMetrics;

  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    required this.accentColor,
    required this.previewMetrics,
  });
}
