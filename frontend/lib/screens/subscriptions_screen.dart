import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import '../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Subscriptions',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: subProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildSummaryCard(context, subProvider, isDark),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final sub = subProvider.subscriptions[index];
                      return _buildSubscriptionCard(
                            context,
                            sub,
                            subProvider,
                            isDark,
                          )
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.1, curve: Curves.easeOutQuad);
                    }, childCount: subProvider.subscriptions.length),
                  ),
                ),
                if (subProvider.subscriptions.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No subscriptions found.',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubscriptionDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    SubscriptionProvider provider,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppTheme.glowShadow],
      ),
      child: Column(
        children: [
          Text(
            'Total Monthly Spend',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${provider.totalMonthlyCost.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBubble('Active: ${provider.subscriptions.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    Subscription sub,
    SubscriptionProvider provider,
    bool isDark,
  ) {
    final daysLeft = sub.nextBillingDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(sub.category),
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Next: ${DateFormat('MMM dd').format(sub.nextBillingDate)} ($daysLeft days left)',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${sub.amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                sub.billingCycle,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () => provider.deleteSubscription(sub.id),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'entertainment':
        return Icons.play_circle_outline;
      case 'music':
        return Icons.music_note;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'software':
        return Icons.computer;
      default:
        return Icons.subscriptions_outlined;
    }
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Entertainment';
    String cycle = 'Monthly';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add Subscription',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(),
                      decoration: InputDecoration(
                        labelText: 'Service Name',
                        hintText: 'e.g. Netflix, Spotify',
                        prefixIcon: const Icon(Icons.subscriptions_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(),
                      decoration: InputDecoration(
                        labelText: 'Price',
                        hintText: '0.00',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        suffixText: 'INR',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            items:
                                [
                                      'Entertainment',
                                      'Music',
                                      'Shopping',
                                      'Software',
                                      'Other',
                                    ]
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => category = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: cycle,
                            decoration: InputDecoration(
                              labelText: 'Cycle',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            items: ['Monthly', 'Yearly']
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: GoogleFonts.inter(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => cycle = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 10),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.fromSeed(
                                  seedColor: AppTheme.primaryColor,
                                  brightness: isDark
                                      ? Brightness.dark
                                      : Brightness.light,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next Billing Date',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(selectedDate),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              amountController.text.isNotEmpty) {
                            final sub = Subscription(
                              id: '', // Will be set by Appwrite
                              name: nameController.text,
                              amount: double.parse(amountController.text),
                              nextBillingDate: selectedDate,
                              category: category,
                              billingCycle: cycle,
                            );
                            Provider.of<SubscriptionProvider>(
                              context,
                              listen: false,
                            ).addSubscription(sub);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save Subscription',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
