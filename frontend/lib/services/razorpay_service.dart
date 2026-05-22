import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'auth_service.dart';
import '../services/config_service.dart';

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  late Razorpay _razorpay;
  final AuthService _authService = AuthService();
  final ConfigService _configService = ConfigService();

  VoidCallback? onSuccess;
  Function(String)? onError;
  int _pendingDurationDays = 30;
  String? _pendingPlanType;

  String get _razorpayKeyId => _configService.razorpayKey;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void openPaymentSheet({
    required double amount, // In INR
    required String name,
    required String description,
    required String email,
    required String contact,
    int durationDays = 30, // Default to standard monthly
    String planType = 'premium',
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
    _pendingDurationDays = durationDays;
    _pendingPlanType = planType;

    var options = {
      'key': _razorpayKeyId,
      'amount': (amount * 100).toInt(), // amount in the smallest currency unit (paise)
      'name': 'LifeSync Premium',
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success: ${response.paymentId}');

    // Unlock premium features for the user with the correct plan type
    final success = await _authService.upgradeToPremium(
      days: _pendingDurationDays,
      planType: _pendingPlanType ?? 'premium',
    );

    if (success['success']) {
      debugPrint('✅ Premium upgraded successfully for user: ${_authService.currentUser?.email}');
      debugPrint('✅ Plan: ${_pendingPlanType ?? 'premium'}');
      
      if (onSuccess != null) {
        onSuccess!();
      }
    } else {
      debugPrint('❌ Premium upgrade failed: ${success['error']}');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error: ${response.code.toString()} - ${response.message}');
    if (onError != null) {
      onError!(response.message ?? 'Unknown error');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }
}
