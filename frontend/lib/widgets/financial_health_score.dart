import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../utils/app_theme.dart';

class FinancialHealthScore extends StatelessWidget {
  final int score;
  final String rating;
  final String message;

  const FinancialHealthScore({
    super.key,
    required this.score,
    required this.rating,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getScoreColor().withOpacity(0.15),
            _getScoreColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getScoreColor().withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Financial Health',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Circular gauge
          SizedBox(
            height: 180,
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  radiusFactor: 0.8,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.2,
                    color: AppTheme.surfaceColor,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: [
                    RangePointer(
                      value: score.toDouble(),
                      width: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                      gradient: SweepGradient(
                        colors: _getGradientColors(),
                        stops: const [0.0, 0.5, 1.0],
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
                            score.toString(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(),
                            ),
                          ),
                          Text(
                            rating,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _getScoreColor(),
                            ),
                          ),
                        ],
                      ),
                      angle: 90,
                      positionFactor: 0.1,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor() {
    if (score >= 80) {
      return AppTheme.successColor;
    } else if (score >= 60) {
      return AppTheme.accentColor;
    } else if (score >= 40) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }

  List<Color> _getGradientColors() {
    if (score >= 80) {
      return [
        AppTheme.accentColor,
        AppTheme.successColor,
        AppTheme.successColor,
      ];
    } else if (score >= 60) {
      return [
        AppTheme.primaryColor,
        AppTheme.accentColor,
        AppTheme.accentColor,
      ];
    } else if (score >= 40) {
      return [
        AppTheme.warningColor,
        AppTheme.warningColor,
        const Color(0xFFFF8C42),
      ];
    } else {
      return [
        const Color(0xFFFF8C42),
        AppTheme.errorColor,
        AppTheme.errorColor,
      ];
    }
  }
}
