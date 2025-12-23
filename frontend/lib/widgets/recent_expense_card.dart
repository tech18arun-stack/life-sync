import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../utils/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecentExpenseCard extends StatelessWidget {
  final Expense expense;

  const RecentExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      expense.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(' • ', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      DateFormat('MMM d, h:mm a').format(expense.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${expense.amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return FontAwesomeIcons.utensils;
      case 'transport':
        return FontAwesomeIcons.car;
      case 'health':
      case 'healthcare':
        return FontAwesomeIcons.heartPulse;
      case 'education':
        return FontAwesomeIcons.graduationCap;
      case 'entertainment':
        return FontAwesomeIcons.film;
      case 'utilities':
        return FontAwesomeIcons.bolt;
      case 'shopping':
        return FontAwesomeIcons.bagShopping;
      default:
        return FontAwesomeIcons.ellipsis;
    }
  }
}
