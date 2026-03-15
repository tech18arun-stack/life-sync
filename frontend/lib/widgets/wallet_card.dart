import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class WalletCard extends StatelessWidget {
  final double balance;
  final double percentageChange;
  final VoidCallback onDeposit;
  final VoidCallback onSend;

  const WalletCard({
    super.key,
    required this.balance,
    required this.percentageChange,
    required this.onDeposit,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final bool isPositive = percentageChange >= 0;
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your balance',
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, FontSizeType.body),
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 8),
          Text(
            currencyFormat.format(balance),
            style: TextStyle(
              fontSize: isDesktop ? 44 : 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${isPositive ? "+" : ""}${percentageChange.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.getFontSize(context, FontSizeType.small),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Last month',
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: Responsive.getFontSize(context, FontSizeType.small),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 40 : 32),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  context,
                  'Deposit',
                  Icons.arrow_downward_rounded,
                  AppTheme.primaryColor,
                  onDeposit,
                ),
              ),
              SizedBox(width: isDesktop ? 20 : 16),
              Expanded(
                child: _buildButton(
                  context,
                  'Send',
                  Icons.arrow_upward_rounded,
                  Colors.black,
                  onSend,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : 12),
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: AppTheme.textPrimary,
                  size: Responsive.getIconSize(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isDesktop ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 6 : 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isDesktop ? 18 : 16,
              ),
            ),
            SizedBox(width: isDesktop ? 12 : 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
