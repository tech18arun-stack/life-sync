import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For ImageFilter

import '../providers/auth_provider.dart';
import '../providers/financial_data_manager.dart';
import '../providers/family_provider.dart';
import '../providers/family_number_provider.dart';
import '../providers/task_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import 'register_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      _navigateToHome();
    } else if (mounted) {
      _showError(authProvider.error ?? 'Login failed');
    }
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await _initializeProviders();
      if (mounted) {
        final user = authProvider.currentUser;
        if (user != null) {
          final isAdmin = user.isAdmin;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Welcome back, ${user.name}!${isAdmin ? ' (Admin)' : ''}',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to initialize app data: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showError(String errorMsg) {
    if (errorMsg.toLowerCase().contains('email') &&
        errorMsg.toLowerCase().contains('confirm')) {
      _showEmailNotVerifiedDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEmailNotVerifiedDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.cardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.mail_outline, color: AppTheme.warningColor),
            const SizedBox(width: 12),
            Text(
              'Email Not Verified',
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textPrimary : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Please check your email and click the verification link before logging in.',
          style: GoogleFonts.inter(
            color: isDark ? AppTheme.textSecondary : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.cardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(
              'Reset Password',
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textPrimary : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: GoogleFonts.inter(
                  color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  labelStyle: GoogleFonts.inter(),
                  hintStyle: GoogleFonts.inter(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.surfaceColor : Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textSecondary : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                try {
                  final authProvider = context.read<AuthProvider>();
                  final success = await authProvider.resetPassword(
                    emailController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Password reset email sent to ${emailController.text}'
                              : 'Failed to send reset email: ${authProvider.error}',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: success
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to send reset email: $e',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Send Reset Link',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeProviders() async {
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
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.backgroundColor, const Color(0xFF1E1E2C)]
                : [
                    const Color(0xFFE3F2FD),
                    const Color(0xFFF3E5F5),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.getHorizontalPadding(context),
                  vertical: Responsive.isDesktop(context) ? 40 : 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 500 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        [
                              SizedBox(height: isDesktop ? 60 : 32),
                              _buildHeader(isDark, context),
                              SizedBox(height: isDesktop ? 64 : 48),
                              _buildLoginForm(authProvider, isDark, context),
                              SizedBox(height: isDesktop ? 32 : 24),
                              _buildLoginButton(authProvider, context),
                              SizedBox(height: isDesktop ? 32 : 24),
                              _buildRegisterLink(isDark, context),
                              SizedBox(
                                height: Responsive.getHorizontalPadding(
                                  context,
                                ),
                              ),
                            ]
                            .animate(interval: 100.ms)
                            .fade(duration: 600.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOutQuad),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final logoSize = isDesktop ? 72.0 : (isTablet ? 60.0 : 48.0);
    final logoPadding = isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(logoPadding),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(isDesktop ? 32 : 28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: isDesktop ? 30 : 24,
                offset: Offset(0, isDesktop ? 15 : 12),
              ),
            ],
          ),
          child: FaIcon(
            FontAwesomeIcons.house,
            size: logoSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isDesktop ? 40 : (isTablet ? 32 : 28)),
        Text(
          'LifeSync',
          style:
              GoogleFonts.inter(
                fontSize: isDesktop
                    ? Responsive.getFontSize(context, FontSizeType.largeDisplay)
                    : Responsive.getFontSize(context, FontSizeType.display),
                fontWeight: FontWeight.bold,
              ).copyWith(
                foreground: Paint()
                  ..shader = AppTheme.primaryGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ),
              ),
        ),
        SizedBox(height: isDesktop ? 16 : (isTablet ? 12 : 8)),
        Text(
          'Plan • Track • Achieve',
          style: GoogleFonts.inter(
            fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
            color: isDark ? AppTheme.textSecondary : Colors.grey[600],
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
        SizedBox(
          width: isDesktop ? 400 : double.infinity,
          child: Text(
            'Welcome back! Please login to continue.',
            style: GoogleFonts.inter(
              fontSize: Responsive.getFontSize(context, FontSizeType.body),
              color: isDark ? AppTheme.textTertiary : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(
    AuthProvider authProvider,
    bool isDark,
    BuildContext context,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final cardRadius = isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0);
    final inputRadius = isDesktop ? 50.0 : (isTablet ? 48.0 : 44.0);
    final padding = isDesktop ? 40.0 : (isTablet ? 32.0 : 28.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.cardColor.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: isDesktop ? 30 : 25,
                offset: Offset(0, isDesktop ? 15 : 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(
                    color: isDark ? AppTheme.textPrimary : Colors.black,
                    fontSize: Responsive.getFontSize(
                      context,
                      FontSizeType.body,
                    ),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    labelStyle: GoogleFonts.inter(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: Responsive.getFontSize(
                        context,
                        FontSizeType.body,
                      ),
                    ),
                    hintStyle: GoogleFonts.inter(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.surfaceColor.withValues(alpha: 0.6)
                        : Colors.grey[50],
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(inputRadius),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isDesktop ? 28 : (isTablet ? 24 : 20)),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(
                    color: isDark ? AppTheme.textPrimary : Colors.black,
                    fontSize: Responsive.getFontSize(
                      context,
                      FontSizeType.body,
                    ),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    labelStyle: GoogleFonts.inter(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: Responsive.getFontSize(
                        context,
                        FontSizeType.body,
                      ),
                    ),
                    hintStyle: GoogleFonts.inter(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.surfaceColor.withValues(alpha: 0.6)
                        : Colors.grey[50],
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(inputRadius),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.getFontSize(
                          context,
                          FontSizeType.body,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AuthProvider authProvider, BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final buttonRadius = isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0);

    return Container(
      width: double.infinity,
      height: Responsive.getButtonHeight(context),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(buttonRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: isDesktop ? 20 : 16,
            offset: Offset(0, isDesktop ? 8 : 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          elevation: 0,
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.rightToBracket,
                    size: Responsive.getIconSize(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Login',
                    style: GoogleFonts.inter(
                      fontSize: Responsive.getFontSize(
                        context,
                        FontSizeType.subtitle,
                      ),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRegisterLink(bool isDark, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.inter(
            color: isDark ? AppTheme.textSecondary : Colors.grey[600],
            fontSize: Responsive.getFontSize(context, FontSizeType.body),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: Text(
            'Register',
            style: GoogleFonts.inter(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getFontSize(context, FontSizeType.body),
            ),
          ),
        ),
      ],
    );
  }
}
