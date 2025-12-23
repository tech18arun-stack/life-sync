import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

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

    final isIncrease = diff > 0;
    final isGood = !isIncrease; // For expenses, decrease is good

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Comparison',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isGood ? AppTheme.successColor : AppTheme.errorColor)
                      .withOpacity(0.1),
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
                    const SizedBox(width: 4),
                    Text(
                      '${percent.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isGood
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMonthColumn(
                  context,
                  'Last Month',
                  previous,
                  AppTheme.textSecondary,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.borderColor),
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
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: previous > 0 ? (current / (current + previous)) : 0.5,
              backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
