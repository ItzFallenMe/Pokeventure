import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'social_config.dart';
import 'social_repository.dart';
import 'supabase_social_repository.dart';

bool _initialized = false;

/// Builds the social repository once at startup. Without credentials the app
/// keeps working and the Social tab explains what to configure.
Future<SocialRepository> createSocialRepository() async {
  final config = SupabaseConfig.fromEnvironment();
  if (!config.isConfigured) return const UnavailableSocialRepository();

  try {
    if (!_initialized) {
      await Supabase.initialize(
        url: config.url,
        publishableKey: config.anonKey,
      );
      _initialized = true;
    }
    return SupabaseSocialRepository(Supabase.instance.client);
  } catch (error) {
    debugPrint('Supabase init failed: $error');
    return const UnavailableSocialRepository(
      'Social could not start. Check the Supabase URL and anon key.',
    );
  }
}
