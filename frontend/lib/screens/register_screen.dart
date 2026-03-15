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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );

    if (success && mounted) {
      if (authProvider.error != null &&
          authProvider.error!.contains('Please check your email')) {
        _showEmailVerificationDialog();
      } else {
        try {
          await _initializeProviders();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? 'Registration failed',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEmailVerificationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppTheme.cardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.successColor,
                      AppTheme.successColor.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const FaIcon(
                  FontAwesomeIcons.envelopeCircleCheck,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimary : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _emailController.text.trim(),
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification link to your email address. Please check your inbox and click the link to activate your admin account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.lightbulb,
                      color: AppTheme.warningColor,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your spam folder if you don\'t see the email.',
                        style: GoogleFonts.inter(
                          color: isDark
                              ? AppTheme.textSecondary
                              : Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go to Login',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeProviders() async {
    // Same as LoginScreen
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
                    const Color(0xFFE0F7FA),
                    const Color(0xFFE8EAF6),
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 550 : double.infinity,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isDesktop ? 60 : 32),
                          _buildHeader(isDark, context),
                          SizedBox(height: isDesktop ? 48 : 32),
                          _buildRegisterForm(authProvider, isDark, context),
                          SizedBox(height: isDesktop ? 32 : 24),
                          _buildRegisterButton(authProvider, context),
                          SizedBox(height: isDesktop ? 32 : 24),
                          _buildLoginLink(isDark, context),
                          SizedBox(height: Responsive.getHorizontalPadding(context)),
                        ],
                      ),
                    ),
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
            gradient: AppTheme.oceanGradient,
            borderRadius: BorderRadius.circular(isDesktop ? 32 : 28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentBlue.withValues(alpha: 0.4),
                blurRadius: isDesktop ? 30 : 24,
                offset: Offset(0, isDesktop ? 15 : 12),
              ),
            ],
          ),
          child: FaIcon(
            FontAwesomeIcons.userPlus,
            size: logoSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isDesktop ? 40 : (isTablet ? 32 : 28)),
        Text(
          'Create Admin Account',
          style: GoogleFonts.inter(
            fontSize: isDesktop
                ? Responsive.getFontSize(context, FontSizeType.largeDisplay)
                : Responsive.getFontSize(context, FontSizeType.headline),
            fontWeight: FontWeight.bold,
          ).copyWith(
            foreground: Paint()
              ..shader = AppTheme.oceanGradient.createShader(
                const Rect.fromLTWH(0, 0, 200, 70),
              ),
          ),
        ),
        SizedBox(height: isDesktop ? 16 : (isTablet ? 12 : 8)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 16,
            vertical: isDesktop ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.accentBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.crown,
                size: isDesktop ? 20 : 16,
                color: AppTheme.accentBlue,
              ),
              SizedBox(width: isDesktop ? 10 : 8),
              Text(
                'Administrator Account',
                style: GoogleFonts.inter(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.getFontSize(context, FontSizeType.small),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 20 : (isTablet ? 16 : 12)),
        SizedBox(
          width: isDesktop ? 400 : double.infinity,
          child: Text(
            'Create your admin account to manage family members',
            style: GoogleFonts.inter(
              color: isDark ? AppTheme.textSecondary : Colors.grey[600],
              fontSize: Responsive.getFontSize(context, FontSizeType.body),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(AuthProvider authProvider, bool isDark, BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final cardRadius = isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0);
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
                _buildTextField(
                  context,
                  isDark,
                  _nameController,
                  'Full Name',
                  Icons.person_outlined,
                ),
                SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
                _buildTextField(
                  context,
                  isDark,
                  _emailController,
                  'Email',
                  Icons.email_outlined,
                ),
                SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
                _buildTextField(
                  context,
                  isDark,
                  _phoneController,
                  'Phone (Optional)',
                  Icons.phone_outlined,
                  isOptional: true,
                ),
                SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
                _buildPasswordField(
                  context,
                  isDark,
                  _passwordController,
                  'Password',
                  _obscurePassword,
                  () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
                _buildPasswordField(
                  context,
                  isDark,
                  _confirmPasswordController,
                  'Confirm Password',
                  _obscureConfirmPassword,
                  () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    bool isDark,
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isOptional = false,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final inputRadius = isDesktop ? 50.0 : (isTablet ? 48.0 : 44.0);

    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(
        color: isDark ? AppTheme.textPrimary : Colors.black,
        fontSize: Responsive.getFontSize(context, FontSizeType.body),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: Responsive.getFontSize(context, FontSizeType.body),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: Responsive.getIconSize(context),
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
          borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
        ),
      ),
      validator: (value) {
        if (isOptional && (value == null || value.isEmpty)) {
          return null;
        }
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Required';
        }
        if (label == 'Email' &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
          return 'Invalid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(
    BuildContext context,
    bool isDark,
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback toggle,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final inputRadius = isDesktop ? 50.0 : (isTablet ? 48.0 : 44.0);

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(
        color: isDark ? AppTheme.textPrimary : Colors.black,
        fontSize: Responsive.getFontSize(context, FontSizeType.body),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: Responsive.getFontSize(context, FontSizeType.body),
        ),
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: toggle,
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
          borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (value.length < 6) {
          return 'Min 6 chars';
        }
        if (label == 'Confirm Password' && value != _passwordController.text) {
          return 'Mismatch';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton(AuthProvider authProvider, BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final buttonRadius = isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0);

    return Container(
      width: double.infinity,
      height: Responsive.getButtonHeight(context),
      decoration: BoxDecoration(
        gradient: AppTheme.oceanGradient,
        borderRadius: BorderRadius.circular(buttonRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withValues(alpha: 0.4),
            blurRadius: isDesktop ? 20 : 16,
            offset: Offset(0, isDesktop ? 8 : 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleRegister,
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
                    FontAwesomeIcons.userPlus,
                    size: Responsive.getIconSize(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Register',
                    style: GoogleFonts.inter(
                      fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink(bool isDark, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: GoogleFonts.inter(
            color: isDark ? AppTheme.textSecondary : Colors.grey[600],
            fontSize: Responsive.getFontSize(context, FontSizeType.body),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Login',
            style: GoogleFonts.inter(
              color: AppTheme.accentBlue,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getFontSize(context, FontSizeType.body),
            ),
          ),
        ),
      ],
    );
  }
}
