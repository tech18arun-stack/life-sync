import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/financial_data_manager.dart';
import '../providers/family_provider.dart';
import '../providers/family_number_provider.dart';
import '../providers/task_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/savings_goal_provider.dart';
import '../services/config_service.dart';
import '../widgets/app_updater_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _iconSlide1;
  late Animation<double> _iconSlide2;
  late Animation<double> _iconSlide3;
  late Animation<double> _textFade;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();

    // Listen for auth state changes that might happen when user confirms email
    _listenForAuthChanges();
  }

  void _listenForAuthChanges() {
    // Listen for auth state changes to handle email confirmation
    // This will help navigate to home screen when user confirms email
  }

  void _initializeAnimations() {
    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Icon animations
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _iconSlide1 = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _iconSlide2 = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _iconSlide3 = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Particle animation (continuous)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100)); // Quick startup
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _progressController.forward();

    // Check auth status and navigate quickly
    await Future.delayed(
      const Duration(milliseconds: 1000),
    ); // Reduced from 2000ms
    if (mounted) {
      await _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    // Check for updates
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final config = ConfigService();

      if (currentVersion != config.latestVersion) {
        if (config.forceUpdate) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AppUpdaterDialog(
              downloadUrl: config.downloadUrl,
              latestVersion: config.latestVersion,
              releaseNotes: config.updateMessage,
              forceUpdate: true,
            ),
          );
          return; // Stop execution, forcing them to update
        } else {
          // Optional update
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => AppUpdaterDialog(
                downloadUrl: config.downloadUrl,
                latestVersion: config.latestVersion,
                releaseNotes: config.updateMessage,
                forceUpdate: false,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking version: $e');
    }

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initialize auth
    final isLoggedIn = await authProvider.initialize();

    if (!mounted) return;

    if (isLoggedIn) {
      // User is logged in, initialize all providers
      await _initializeProviders();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // User is not logged in, check if they've seen onboarding
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (mounted) {
        if (!hasSeenOnboarding) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    }
  }

  Future<void> _initializeProviders() async {
    // Initialize all data providers after successful login
    final financialManager = Provider.of<FinancialDataManager>(
      context,
      listen: false,
    );
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final familyNumberProvider = Provider.of<FamilyNumberProvider>(
      context,
      listen: false,
    );
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final savingsProvider = Provider.of<SavingsGoalProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      financialManager.initialize(),
      familyProvider.initialize(),
      familyNumberProvider.initialize(),
      taskProvider.initialize(),
      savingsProvider.initialize(),
    ]);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _iconController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Stack(
          children: [
            // Animated particles background
            _buildParticles(),

            // Main content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated Logo
                  _buildAnimatedLogo(),

                  const SizedBox(height: 40),

                  // Feature Icons
                  _buildFeatureIcons(),

                  const SizedBox(height: 40),

                  // App Name and Tagline
                  _buildTextContent(),

                  const Spacer(flex: 2),

                  // Loading Progress
                  _buildLoadingProgress(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value * 0.1,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureIcons() {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, _iconSlide1.value),
              child: _buildFeatureIcon(
                FontAwesomeIcons.chartLine,
                'Analytics',
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 40),
            Transform.translate(
              offset: Offset(0, _iconSlide2.value),
              child: _buildFeatureIcon(
                FontAwesomeIcons.wallet,
                'Finance',
                AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 40),
            Transform.translate(
              offset: Offset(0, _iconSlide3.value),
              child: _buildFeatureIcon(
                FontAwesomeIcons.heartPulse,
                'Health',
                AppTheme.errorColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: FaIcon(icon, color: color, size: 24)),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent() {
    return FadeTransition(
      opacity: _textFade,
      child: Column(
        children: [
          Text(
            'LifeSync',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Family Finance & Wellness',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingProgress() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 200,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressValue.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Syncing your family data...',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            // Show config status at the bottom
            FutureBuilder<String>(
              future: _getVersionString(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Checking version...',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _getVersionString() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final config = ConfigService();

      // Ensure config is loaded or fallback is used
      return 'v$currentVersion  |  Remote: v${config.latestVersion}';
    } catch (e) {
      return '';
    }
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 15; i++) {
      final x = (size.width / 15) * i;
      final y = (size.height * ((i * 0.15 + animationValue) % 1.0));
      final radius = 2.0 + (i % 3) * 2.0;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw subtle currency symbols
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final symbols = ['₹', '\$', '€', '£', '¥'];
    for (int i = 0; i < symbols.length; i++) {
      final x = (size.width / 5) * i + 40;
      final y = (size.height * ((i * 0.2 + animationValue * 0.7) % 1.0));

      textPainter.text = TextSpan(
        text: symbols[i],
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.1),
          fontSize: 32,
          fontWeight: FontWeight.w100,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
