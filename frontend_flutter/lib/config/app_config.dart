import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String _globalBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _webBaseUrl = String.fromEnvironment(
    'API_WEB_BASE_URL',
    defaultValue: '',
  );

  static const String _mobileBaseUrl = String.fromEnvironment(
    'API_MOBILE_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_globalBaseUrl.isNotEmpty) return _normalize(_globalBaseUrl);

    if (kIsWeb) {
      if (_webBaseUrl.isNotEmpty) return _normalize(_webBaseUrl);
      return 'http://localhost:5000';
    }

    if (_mobileBaseUrl.isNotEmpty) return _normalize(_mobileBaseUrl);
    return 'http://10.0.2.2:5000';
  }

  static String _normalize(String raw) {
    if (raw.endsWith('/')) {
      return raw.substring(0, raw.length - 1);
    }
    return raw;
  }
}
