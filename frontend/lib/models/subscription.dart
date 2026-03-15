class Subscription {
  final String id;
  final String name;
  final double amount;
  final DateTime nextBillingDate;
  final String category;
  final String billingCycle; // monthly, yearly, etc.
  final String? icon;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.nextBillingDate,
    required this.category,
    required this.billingCycle,
    this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'next_billing_date': nextBillingDate.toIso8601String(),
      'category': category,
      'billing_cycle': billingCycle,
      'icon': icon,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? json[r'$id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      nextBillingDate: DateTime.parse(json['next_billing_date'] ?? DateTime.now().toIso8601String()),
      category: json['category'] ?? '',
      billingCycle: json['billing_cycle'] ?? '',
      icon: json['icon'],
    );
  }
}
