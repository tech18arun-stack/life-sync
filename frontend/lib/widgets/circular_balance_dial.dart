import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';

class CircularBalanceDial extends StatefulWidget {
  final double balance;
  final double income;
  final double expenses;
  final String? avatarUrl;
  final String userName;
  final VoidCallback onProfileTap;

  final double size;
  final String label;

  const CircularBalanceDial({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    this.avatarUrl,
    required this.userName,
    required this.onProfileTap,
    this.size = 240,
    this.label = 'Total Balance',
  });

  @override
  State<CircularBalanceDial> createState() => _CircularBalanceDialState();
}

class _CircularBalanceDialState extends State<CircularBalanceDial> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(CircularBalanceDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance ||
        oldWidget.income != widget.income ||
        oldWidget.expenses != widget.expenses) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final total = widget.income > 0 ? widget.income : 1.0;
    // Calculate fraction (clamp between 0 an 1)
    final expenseFraction = (widget.expenses / total).clamp(0.0, 1.0);
    // If net is negative, it's largely red. If positive, largely green/primary.
    final bool isPositive = widget.balance >= 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorPrimary = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;

    return Center(
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (context, child) {
          final dialSize = widget.size;
          final titleFontSize = (dialSize / 15).clamp(10.0, 14.0);
          final balanceFontSize = (dialSize / 6.5).clamp(18.0, 36.0);
          
          return SizedBox(
            height: dialSize,
            width: dialSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular Progress Ring
                CustomPaint(
                  size: Size(dialSize, dialSize),
                  painter: _BalanceDialPainter(
                    progress: _progressAnim.value,
                    expenseFraction: expenseFraction,
                    isPositive: isPositive,
                    isDark: isDark,
                  ),
                ),

                // Center Text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: titleFontSize,
                        color: textColorSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(widget.balance * _progressAnim.value),
                      style: GoogleFonts.inter(
                        fontSize: balanceFontSize,
                        fontWeight: FontWeight.w800,
                        color: textColorPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (dialSize >= 180) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPositive ? '+ Net Positive' : '- Net Negative',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceDialPainter extends CustomPainter {
  final double progress;
  final double expenseFraction;
  final bool isPositive;
  final bool isDark;

  _BalanceDialPainter({
    required this.progress,
    required this.expenseFraction,
    required this.isPositive,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    final strokeWidth = 14.0;

    // Background track
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Dynamic Foreground arc
    final gradientColors = isPositive 
      ? [const Color(0xFF00F5A0), const Color(0xFF00D9F5)] // Vibrant Emerald / Neon Blue
      : [const Color(0xFFFF416C), const Color(0xFFFF4B2B)]; // Deep Pink / Orange
    
    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the main active arc (scaled by progress)
    final sweepAngle = 2 * math.pi * progress * (isPositive ? (1.0 - expenseFraction) : expenseFraction);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      sweepAngle,
      false,
      fgPaint,
    );

    // Draw little floating glow dots
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * progress)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    for (int i = 0; i < 3; i++) {
        final angle = -math.pi / 2 + sweepAngle + (i * 0.4);
        final dotX = center.dx + (radius + 18) * math.cos(angle);
        final dotY = center.dy + (radius + 18) * math.sin(angle);
        if (progress > 0.5) {
          canvas.drawCircle(Offset(dotX, dotY), 3.0 * (progress), dotPaint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceDialPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.expenseFraction != expenseFraction ||
           oldDelegate.isPositive != isPositive;
  }
}
