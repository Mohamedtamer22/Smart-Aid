import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  const AppConfig._();

  static const String _defaultEnvUrl = String.fromEnvironment('API_BASE_URL');
  static const String _prefKey = 'smartaid_api_base_url';

  static ValueChanged<String>? onBaseUrlChanged;

  static String get defaultBaseUrl {
    if (_defaultEnvUrl.isNotEmpty) return _defaultEnvUrl;
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://192.168.100.181:8080';
  }

  static String _currentBaseUrl = defaultBaseUrl;

  static String get apiBaseUrl => _currentBaseUrl;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        final trimmed = saved.trim();
        final uri = Uri.tryParse(trimmed);
        final isValid = uri != null &&
            (uri.isScheme('http') || uri.isScheme('https')) &&
            uri.host.isNotEmpty &&
            (uri.host.contains('.') || uri.host == 'localhost') &&
            !trimmed.contains('10.0.2.2');
        if (!isValid) {
          _currentBaseUrl = defaultBaseUrl;
          await prefs.remove(_prefKey);
        } else {
          _currentBaseUrl = trimmed;
        }
      } else {
        _currentBaseUrl = defaultBaseUrl;
      }
    } catch (_) {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    final clean = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _currentBaseUrl = clean;
    onBaseUrlChanged?.call(_currentBaseUrl);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _currentBaseUrl);
    } catch (_) {}
  }
}
