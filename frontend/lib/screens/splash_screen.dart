import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/financial_data_manager.dart';
import '../providers/family_provider.dart';
import '../providers/family_number_provider.dart';
import '../providers/task_provider.dart';
import '../providers/savings_goal_provider.dart';

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
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _progressController.forward();

    // Check auth status and navigate
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      await _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
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
      // User is not logged in, go to login screen
      Navigator.of(context).pushReplacementNamed('/login');
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
              AppTheme.accentColor,
            ],
          ),
        ),
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
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Center(child: FaIcon(icon, color: Colors.white, size: 28)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
          const Text(
            'LifeSync',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plan • Track • Achieve',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
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
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressValue.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your financial insights...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20) * i;
      final y = (size.height * ((i * 0.1 + animationValue) % 1.0));
      final radius = 2 + (i % 3) * 2.0;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw currency symbols
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final symbols = ['₹', '\$', '€', '£', '¥'];
    for (int i = 0; i < symbols.length; i++) {
      final x = (size.width / 5) * i + 40;
      final y = (size.height * ((i * 0.15 + animationValue * 0.5) % 1.0));

      textPainter.text = TextSpan(
        text: symbols[i],
        style: TextStyle(
          color: Colors.white.withOpacity(0.05),
          fontSize: 40,
          fontWeight: FontWeight.bold,
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
