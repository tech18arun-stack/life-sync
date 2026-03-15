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

  Future<void> initialize() async {
    await _loadCachedConfig();
    try {
      await _fetchRemoteConfig();
    } catch (e) {
      debugPrint('Error fetching remote config, using cache/defaults: $e');
    }
  }

  Future<void> _loadCachedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('app_config');
    if (cachedData != null) {
      try {
        _config = jsonDecode(cachedData);
      } catch (e) {
        debugPrint('Error decoding cached config: $e');
      }
    }
  }

  Future<void> _fetchRemoteConfig() async {
    // Append timestamp to bypass aggressive GitHub raw caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final urlWithCacheBuster = '$_configUrl?t=$timestamp';

    final response = await http.get(Uri.parse(urlWithCacheBuster));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      _config = jsonResponse;

      // Cache it locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config', response.body);
      debugPrint('✅ Remote config fetched and cached successfully.');
    } else {
      throw Exception('Failed to load config, status: ${response.statusCode}');
    }
  }

  // Getters for specific features
  String get apiBaseUrl => _config['server']?['api_base_url'] ?? '';
  bool get maintenanceMode => _config['features']?['maintenance_mode'] ?? false;
  String get latestVersion => _config['app']?['latest_version'] ?? '1.0.0';

  String get minSupportedVersion =>
      _config['app']?['min_supported_version'] ?? '1.0.0';
  bool get forceUpdate => _config['app']?['force_update'] ?? false;
  String get updateMessage => _config['app']?['update_message'] ?? '';
  String get downloadUrl => _config['app']?['download_url'] ?? '';

  bool get adsEnabled => _config['features']?['ads_enabled'] ?? false;
  bool get startioEnabled => _config['ads']?['startio_enabled'] ?? false;
  String get startioAppId => _config['ads']?['startio_app_id'] ?? '';
}
