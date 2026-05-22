import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpcomingPaymentCard extends StatelessWidget {
  final String title;
  final double amount;
  final String timeLeft;
  final IconData icon;
  final Color color;

  const UpcomingPaymentCard({
    super.key,
    required this.title,
    required this.amount,
    required this.timeLeft,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}/month',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeLeft,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
