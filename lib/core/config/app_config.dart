import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum AppEnvironment { development, staging, production }

abstract final class AppConfig {
  static const String _rawEnv = String.fromEnvironment('ENV', defaultValue: 'development');

  static AppEnvironment get environment {
    switch (_rawEnv) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.development;
    }
  }

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://127.0.0.1:3000/api/v1';
  }

  static Duration get connectTimeout => const Duration(seconds: 15);
  static Duration get receiveTimeout => const Duration(seconds: 20);

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get enableNetworkLogging => !isProduction;
}
