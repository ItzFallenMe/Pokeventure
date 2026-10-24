import '../../app/app_config.dart';

/// Supabase credentials, provided through `--dart-define` or `.env`.
///
/// ```
/// cp .env.example .env
/// flutter run --dart-define-from-file=.env
/// ```
///
/// The anon key is public by design; row-level security protects the tables.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  factory SupabaseConfig.fromEnvironment() {
    return SupabaseConfig(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  final String url;
  final String anonKey;

  bool get isConfigured => AppConfig.hasSupabase;
}
