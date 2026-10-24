import 'package:flutter/foundation.dart';

/// Build-time configuration.
///
/// Values come from `--dart-define` or, more conveniently, from a `.env` file:
///
/// ```bash
/// cp .env.example .env      # fill in your URL and keys
/// flutter run --dart-define-from-file=.env
/// ```
///
/// `API_BASE_URL` points at the Node battle server. `SUPABASE_URL` and
/// `SUPABASE_ANON_KEY` enable trainer cards and friend battles; the anon key is
/// public by design (row-level security protects the tables) — never put a
/// service-role key in the app.
abstract final class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _trimSlash(_apiBaseUrl);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // The Android emulator reaches the host machine through 10.0.2.2.
      return 'http://10.0.2.2:8787';
    }
    return 'http://127.0.0.1:8787';
  }

  static String get supabaseUrl => _trimSlash(_supabaseUrl);

  static String get supabaseAnonKey => _supabaseAnonKey.trim();

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project') &&
      !supabaseAnonKey.startsWith('your-');

  static String _trimSlash(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
