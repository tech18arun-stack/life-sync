import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // GitHub Raw JSON URL for Remote Config (Loaded from environment)
  static const String _configUrl = String.fromEnvironment(
    'APP_CONFIG_URL',
    defaultValue:
        'https://raw.githubusercontent.com/tech18arun-stack/lifeSync-remote-config/main/config.json',
  );

  Map<String, dynamic> _config = {};
  bool _isInitialized = false;

  /// Check if config service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Config Service - fetches remote config
  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) {
      debugPrint('✅ Config already initialized, skipping fetch');
      return;
    }

    debugPrint('🔄 Fetching remote config from GitHub...');

    if (forceRefresh) {
      debugPrint('⚠️ Force refresh requested, clearing cached config');
      await _clearCachedConfig();
    }

    await _loadCachedConfig();

    try {
      await _fetchRemoteConfig();
      _isInitialized = true;
      debugPrint('✅ Config initialization complete');
      debugPrint('💰 Premium Cost: ₹$premiumMonthlyCost');
      debugPrint('🔑 Razorpay Key: ${razorpayKey.substring(0, 15)}...');
      debugPrint('🌍 API Base URL: $apiBaseUrl');
      debugPrint('🔧 Environment: $environment');
    } catch (e) {
      debugPrint('⚠️ Error fetching remote config: $e');
      debugPrint('📋 Using cached config or defaults');
      debugPrint('💰 Premium Cost (fallback): ₹$premiumMonthlyCost');
      debugPrint('🌍 API Base URL (fallback): $apiBaseUrl');
      _isInitialized = true;
    }
    
    // 🔥 Validate critical configuration
    _validateCriticalConfig();
  }

  /// Validate that critical configuration is not empty or invalid
  void _validateCriticalConfig() {
    final apiUrl = apiBaseUrl;
    if (apiUrl.isEmpty) {
      debugPrint('🚨 CRITICAL: API Base URL is empty after initialization!');
      debugPrint('   This should never happen due to fallback logic.');
    } else {
      debugPrint('✅ Critical config validation passed: API URL = $apiUrl');
    }
  }

  Future<void> _loadCachedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('app_config');
    if (cachedData != null) {
      try {
        _config = jsonDecode(cachedData);
        debugPrint('📦 Loaded cached config');
        debugPrint('  - Premium Cost: ₹$premiumMonthlyCost');
      } catch (e) {
        debugPrint('❌ Error decoding cached config: $e');
      }
    } else {
      debugPrint('📭 No cached config found');
    }
  }

  Future<void> _clearCachedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_config');
    debugPrint('🗑️ Cached config cleared');
  }

  Future<void> _fetchRemoteConfig() async {
    // Append timestamp to bypass aggressive GitHub raw caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final urlWithCacheBuster = '$_configUrl?t=$timestamp';

    debugPrint('🌐 Fetching: $urlWithCacheBuster');

    final response = await http.get(Uri.parse(urlWithCacheBuster));
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      _config = jsonResponse;

      // Cache it locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config', response.body);
      
      debugPrint('✅ Remote config fetched successfully');
      debugPrint('  - Premium Cost: ₹$premiumMonthlyCost');
      debugPrint('  - Razorpay Key: $razorpayKey');
    } else {
      debugPrint('❌ Failed to fetch config: HTTP ${response.statusCode}');
      throw Exception('Failed to load config, status: ${response.statusCode}');
    }
  }

  /// Force refresh config from GitHub (call this when user pulls to refresh or on important actions)
  Future<void> refreshConfig() async {
    debugPrint('🔄 Manual config refresh triggered');
    await initialize(forceRefresh: true);
  }

  /// Get API Base URL with fallback safety
  /// 🔥 CRITICAL: Never return empty string - always fallback to production URL
  String get apiBaseUrl {
    final url = _config['server']?['api_base_url'];
    
    if (url != null && url is String && url.isNotEmpty) {
      return url;
    }
    
    // 🔥 Fallback safety URL (VERY IMPORTANT)
    // Prevents Appwrite initialization failures
    debugPrint('⚠️ API URL from config is empty/null, using fallback');
    return 'https://api.websitescorp.com/v1';
  }

  /// Get Backup API URL for failover
  String get backupApiUrl {
    final url = _config['server']?['backup_api_url'];
    
    if (url != null && url is String && url.isNotEmpty) {
      return url;
    }
    
    // Same as primary by default
    return 'https://api.websitescorp.com/v1';
  }

  // Getters for specific features
  bool get maintenanceMode => _config['features']?['maintenance_mode'] ?? false;
  String get latestVersion => _config['app']?['latest_version'] ?? '1.0.0';

  String get minSupportedVersion =>
      _config['app']?['min_supported_version'] ?? '1.0.0';
  bool get forceUpdate => _config['app']?['force_update'] ?? false;
  String get updateMessage => _config['app']?['update_message'] ?? '';
  String get downloadUrl => _config['app']?['download_url'] ?? '';
  String get indusStoreUrl => _config['app']?['indus_store_url'] ?? '';
  String get playStoreUrl => _config['app']?['play_store_url'] ?? '';

  bool get adsEnabled => _config['features']?['ads_enabled'] ?? false;
  bool get smsTrackingEnabled => _config['features']?['sms_tracking_enabled'] ?? false;
  bool get habitTrackerEnabled => _config['features']?['habit_tracker_enabled'] ?? false;
  bool get moodTrackerEnabled => _config['features']?['mood_tracker_enabled'] ?? false;
  bool get aiInsightsEnabled => _config['features']?['ai_insights_enabled'] ?? false;
  
  /// Feature flags for authentication methods
  bool get googleLoginEnabled => _config['features']?['google_login_enabled'] ?? true;
  bool get emailLoginEnabled => _config['features']?['email_login_enabled'] ?? true;
  
  /// Feature flag for registration
  bool get registrationEnabled => _config['features']?['registration_enabled'] ?? true;
  
  /// Environment detection
  String get environment => _config['env'] ?? 'production';
  bool get isDevelopmentEnv => environment == 'dev' || environment == 'development';
  bool get isStagingEnv => environment == 'staging';
  bool get isProductionEnv => environment == 'production';
  
  /// Premium Monthly Cost - fetched from GitHub config
  /// Fallback: ₹5.0 if not found in config
  double get premiumMonthlyCost {
    final cost = _config['features']?['premium_monthly_cost'];
    if (cost != null) {
      return (cost is int) ? cost.toDouble() : (cost as double);
    }
    return 5.0; // Fallback for backwards compatibility
  }

  double get premiumUltraMonthlyCost {
    final cost = _config['features']?['premium_ultra_monthly_cost'];
    if (cost != null) return (cost is int) ? cost.toDouble() : (cost as double);
    return 9.0;
  }

  double get premiumYearlyCost {
    final cost = _config['features']?['premium_yearly_cost'];
    if (cost != null) return (cost is int) ? cost.toDouble() : (cost as double);
    return 49.0;
  }
  
  /// Razorpay Key - fetched from GitHub config
  /// Fallback: rzp_live_SSlQnbynKOMOSg if not found
  String get razorpayKey => _config['features']?['razorpay_key'] ?? 'rzp_live_SSlQnbynKOMOSg';

  bool get startioEnabled => _config['ads']?['startio_enabled'] ?? false;
  String get startioAppId => _config['ads']?['startio_app_id'] ?? '';

  /// Get full config map (for debugging)
  Map<String, dynamic> get fullConfig => Map.unmodifiable(_config);

  /// Print current config values (for debugging)
  void debugPrintConfig() {
    debugPrint('════════════════════════════════════════');
    debugPrint('📋 LIFECONFIG CONFIGURATION');
    debugPrint('════════════════════════════════════════');
    debugPrint('🌍 Environment: $environment');
    debugPrint('🌍 API Base URL: $apiBaseUrl');
    debugPrint('🔄 Backup API URL: $backupApiUrl');
    debugPrint('💰 Premium Monthly Cost: ₹$premiumMonthlyCost');
    debugPrint('🔑 Razorpay Key: $razorpayKey');
    debugPrint('📢 Ads Enabled: $adsEnabled');
    debugPrint('🤖 AI Insights Enabled: $aiInsightsEnabled');
    debugPrint('📱 SMS Tracking Enabled: $smsTrackingEnabled');
    debugPrint('🔐 Google Login Enabled: $googleLoginEnabled');
    debugPrint('🔐 Email Login Enabled: $emailLoginEnabled');
    debugPrint('📝 Registration Enabled: $registrationEnabled');
    debugPrint('════════════════════════════════════════');
  }
}
