import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../utils/app_theme.dart';
import '../models/budget.dart';

class BudgetGaugeChart extends StatelessWidget {
  final List<Budget> budgets;
  final double totalSpent;
  final double totalBudget;

  const BudgetGaugeChart({
    super.key,
    required this.budgets,
    required this.totalSpent,
    required this.totalBudget,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Title
          Text(
            'Monthly Budget',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Gauge
          SizedBox(
            height: 200,
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  startAngle: 180,
                  endAngle: 0,
                  radiusFactor: 0.9,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.15,
                    color: AppTheme.surfaceColor,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: [
                    RangePointer(
                      value: percentage,
                      width: 0.15,
                      sizeUnit: GaugeSizeUnit.factor,
                      gradient: SweepGradient(
                        colors: _getGradientColors(percentage),
                        stops: const [0.25, 0.5, 0.75, 1.0],
                      ),
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                  ],
                  annotations: [
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${totalSpent.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getColor(percentage),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'of ₹${totalBudget.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${percentage.toStringAsFixed(0)}% Used',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getColor(percentage),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      angle: 90,
                      positionFactor: 0.6,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category Breakdown
          if (budgets.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: budgets.take(5).map((budget) {
                final color = AppTheme.getCategoryColor(budget.category);
                final percent =
                    (budget.spentAmount / budget.allocatedAmount * 100);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        budget.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(double percentage) {
    if (percentage < 50) {
      return [
        AppTheme.successColor,
        AppTheme.accentColor,
        AppTheme.accentColor,
        AppTheme.accentColor,
      ];
    } else if (percentage < 80) {
      return [
        AppTheme.accentColor,
        AppTheme.warningColor,
        AppTheme.warningColor,
        AppTheme.warningColor,
      ];
    } else {
      return [
        AppTheme.warningColor,
        const Color(0xFFFF8C42),
        AppTheme.errorColor,
        AppTheme.errorColor,
      ];
    }
  }

  Color _getColor(double percentage) {
    if (percentage < 50) {
      return AppTheme.successColor;
    } else if (percentage < 80) {
      return AppTheme.warningColor;
    } else if (percentage < 100) {
      return const Color(0xFFFF8C42);
    } else {
      return AppTheme.errorColor;
    }
  }
}
