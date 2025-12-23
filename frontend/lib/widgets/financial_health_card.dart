import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/financial_data_manager.dart';

class FinancialHealthCard extends StatelessWidget {
  const FinancialHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialDataManager>(
      builder: (context, financialManager, child) {
        final healthScore = financialManager.getFinancialHealthScore();
        final savingsPercentage = financialManager.getSavingsPercentage();
        final monthlyIncome = financialManager.getMonthlyIncome();
        final monthlyExpenses = financialManager
            .getExpensesByDateRange(
              DateTime(DateTime.now().year, DateTime.now().month, 1),
              DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
            )
            .fold(0.0, (sum, expense) => sum + expense.amount);
        final monthlySavings = monthlyIncome - monthlyExpenses;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getHealthColor(healthScore),
                _getHealthColor(healthScore).withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getHealthColor(healthScore).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FaIcon(
                            _getHealthIcon(healthScore),
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Financial Health',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${healthScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Text(
                        _getHealthStatus(healthScore),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: healthScore / 100,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          healthScore.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Income',
                      '₹${monthlyIncome.toStringAsFixed(0)}',
                      FontAwesomeIcons.arrowTrendUp,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: _buildStatItem(
                      'Expenses',
                      '₹${monthlyExpenses.toStringAsFixed(0)}',
                      FontAwesomeIcons.arrowTrendDown,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: _buildStatItem(
                      'Savings',
                      '${savingsPercentage.toStringAsFixed(0)}%',
                      FontAwesomeIcons.piggyBank,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      monthlySavings >= 0
                          ? FontAwesomeIcons.circleCheck
                          : FontAwesomeIcons.circleExclamation,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        monthlySavings >= 0
                            ? 'You saved ₹${monthlySavings.toStringAsFixed(0)} this month!'
                            : 'Overspent by ₹${(-monthlySavings).toStringAsFixed(0)} this month',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        FaIcon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return const Color(0xFF00D9A3); // Excellent
    if (score >= 60) return const Color(0xFF64B5F6); // Good
    if (score >= 40) return const Color(0xFFFFC107); // Fair
    return const Color(0xFFFF5252); // Needs Attention
  }

  IconData _getHealthIcon(double score) {
    if (score >= 80) return FontAwesomeIcons.faceSmile;
    if (score >= 60) return FontAwesomeIcons.faceMeh;
    if (score >= 40) return FontAwesomeIcons.faceGrimace;
    return FontAwesomeIcons.faceFrown;
  }

  String _getHealthStatus(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }
}
