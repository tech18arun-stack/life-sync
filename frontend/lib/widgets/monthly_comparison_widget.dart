import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class MonthlyComparisonWidget extends StatelessWidget {
  final Map<String, dynamic> comparisonData;

  const MonthlyComparisonWidget({super.key, required this.comparisonData});

  @override
  Widget build(BuildContext context) {
    if (comparisonData.isEmpty) return const SizedBox.shrink();

    final current = comparisonData['current'] as double;
    final previous = comparisonData['previous'] as double;
    final diff = comparisonData['difference'] as double;
    final percent = comparisonData['percentChange'] as double;
    final isDesktop = Responsive.isDesktop(context);

    final isIncrease = diff > 0;
    final isGood = !isIncrease;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Comparison',
                style: GoogleFonts.inter(
                  fontSize: Responsive.getFontSize(context, FontSizeType.title),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 12,
                  vertical: isDesktop ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: (isGood ? AppTheme.successColor : AppTheme.errorColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: isGood
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                    SizedBox(width: isDesktop ? 6 : 4),
                    Text(
                      '${percent.abs().toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        color: isGood
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.getFontSize(context, FontSizeType.small),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 40 : 32),
          Row(
            children: [
              Expanded(
                child: _buildMonthColumn(
                  context,
                  'Last Month',
                  previous,
                  Colors.grey,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: _buildMonthColumn(
                  context,
                  'This Month',
                  current,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 32 : 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: previous > 0 ? (current / (current + previous)) : 0.5,
              backgroundColor: Theme.of(
                context,
              ).dividerColor.withValues(alpha: 0.3),
              color: AppTheme.primaryColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthColumn(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: Responsive.getFontSize(context, FontSizeType.small),
          ),
        ),
        SizedBox(height: Responsive.isDesktop(context) ? 12 : 8),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            color: color,
            fontSize: Responsive.isDesktop(context) ? 28 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
