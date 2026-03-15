import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'login_screen.dart';
import '../utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingPages = [
    OnboardingData(
      title: 'Master Finances Through\nEasy Budget Planning',
      description:
          'Track every expense, save spare change, and boost your budget effortlessly',
      icon: FontAwesomeIcons.piggyBank,
      color: const Color(0xFF8A56FF),
      featureCard: FeatureCardData(
        title: 'Your budget this month',
        subtitle: 'Good job! You have ₹2000 left.',
        progress: 0.7,
        items: [
          FeatureItemData(
            'Food & Dining',
            '₹1580 of ₹2000',
            FontAwesomeIcons.utensils,
          ),
          FeatureItemData(
            'Entertainment',
            '₹990 of ₹1500',
            FontAwesomeIcons.play,
          ),
        ],
      ),
    ),
    OnboardingData(
      title: 'Family Sync & Connectivity',
      description:
          'Manage family expenses and track collective financial goals in real-time',
      icon: FontAwesomeIcons.users,
      color: const Color(0xFF2196F3),
      featureCard: FeatureCardData(
        title: 'Family Goal: Vacation',
        subtitle: '₹45,000 / ₹50,000 saved',
        progress: 0.9,
        items: [
          FeatureItemData('John contributed', '₹5,000', FontAwesomeIcons.user),
          FeatureItemData('Sarah contributed', '₹3,000', FontAwesomeIcons.user),
        ],
      ),
    ),
    OnboardingData(
      title: 'AI-Powered Insights',
      description:
          'Receive smart recommendations to optimize your spending and saving habits',
      icon: FontAwesomeIcons.robot,
      color: const Color(0xFF00C853),
      featureCard: FeatureCardData(
        title: 'Smart Spending Tip',
        subtitle:
            'You could save ₹1,200 by switching to a weekly grocery plan.',
        progress: 1.0,
        items: [
          FeatureItemData(
            'Dining trend',
            'Down 12%',
            FontAwesomeIcons.chartLine,
          ),
          FeatureItemData(
            'Savings potential',
            'High',
            FontAwesomeIcons.lightbulb,
          ),
        ],
      ),
    ),
  ];

  Future<void> _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    final bottomPadding = isDesktop ? 60.0 : (isTablet ? 50.0 : 40.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isDesktop ? 16 : 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    )
                  else
                    const SizedBox(width: 48),

                  // Progress Bar
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 20,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / _onboardingPages.length,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _onboardingPages[_currentPage].color,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: _onFinish,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        color: _onboardingPages[_currentPage].color,
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.getFontSize(context, FontSizeType.body),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingPages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _buildPage(_onboardingPages[index]);
                },
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: EdgeInsets.all(bottomPadding),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _onboardingPages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: _onboardingPages[_currentPage].color,
                      dotColor: Colors.grey[200]!,
                      dotHeight: isDesktop ? 10 : 8,
                      dotWidth: isDesktop ? 10 : 8,
                      expansionFactor: 4,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 48 : 40),
                  SizedBox(
                    width: double.infinity,
                    height: Responsive.getButtonHeight(context),
                    child: ElevatedButton(
                      onPressed: _currentPage == _onboardingPages.length - 1
                          ? _onFinish
                          : () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _onboardingPages[_currentPage].color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _onboardingPages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildPage(OnboardingData data) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final horizontalPadding = Responsive.getHorizontalPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: isDesktop ? 40 : 20),
          // Illustration / Feature Card
          _buildIllustration(data),

          SizedBox(height: isDesktop ? 60 : (isTablet ? 50 : 40)),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isDesktop
                  ? Responsive.getFontSize(context, FontSizeType.display)
                  : Responsive.getFontSize(context, FontSizeType.headline),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),

          SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),

          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: Responsive.getFontSize(context, FontSizeType.body),
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),

          SizedBox(height: isDesktop ? 40 : (isTablet ? 30 : 20)),
        ],
      ),
    );
  }

  Widget _buildIllustration(OnboardingData data) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    final illustrationWidth = isDesktop ? 340.0 : (isTablet ? 300.0 : 280.0);
    final illustrationHeight = isDesktop ? 450.0 : (isTablet ? 380.0 : 380.0);
    final phoneWidth = isDesktop ? 280.0 : (isTablet ? 240.0 : 220.0);
    final phoneHeight = isDesktop ? 400.0 : (isTablet ? 340.0 : 320.0);
    final featureCardTop = isDesktop ? 100.0 : (isTablet ? 90.0 : 80.0);
    final featureCardWidth = isDesktop ? 320.0 : (isTablet ? 280.0 : 260.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Glow/Shape
        Container(
          width: illustrationWidth,
          height: illustrationHeight,
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isDesktop ? 48 : 40),
          ),
        ),

        // Pseudo-phone frame
        Container(
          width: phoneWidth,
          height: phoneHeight,
          decoration: BoxDecoration(
            border: Border.all(color: data.color.withOpacity(0.1), width: isDesktop ? 6 : 4),
            borderRadius: BorderRadius.circular(isDesktop ? 36 : 30),
          ),
        ),

        // Feature Card
        Positioned(
          top: featureCardTop,
          child: SizedBox(
            width: featureCardWidth,
            child: _buildFeatureCard(data, isDesktop),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(OnboardingData data, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 28 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isDesktop ? 30 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 12 : 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: isDesktop ? 24 : 20,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.featureCard.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop
                            ? Responsive.getFontSize(context, FontSizeType.subtitle)
                            : Responsive.getFontSize(context, FontSizeType.body),
                      ),
                    ),
                    Text(
                      data.featureCard.subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: Responsive.getFontSize(context, FontSizeType.small),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: data.featureCard.progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(data.color),
              minHeight: 6,
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          ...data.featureCard.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: isDesktop ? 10 : 8),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: isDesktop ? 16 : 14,
                    color: Colors.grey[400],
                  ),
                  SizedBox(width: isDesktop ? 10 : 8),
                  Flexible(
                    child: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: Responsive.getFontSize(context, FontSizeType.small),
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      item.value,
                      style: GoogleFonts.inter(
                        fontSize: Responsive.getFontSize(context, FontSizeType.small),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final FeatureCardData featureCard;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.featureCard,
  });
}

class FeatureCardData {
  final String title;
  final String subtitle;
  final double progress;
  final List<FeatureItemData> items;

  FeatureCardData({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.items,
  });
}

class FeatureItemData {
  final String label;
  final String value;
  final IconData icon;

  FeatureItemData(this.label, this.value, this.icon);
}
