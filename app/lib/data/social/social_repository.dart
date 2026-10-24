import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'social_models.dart';

class SocialException implements Exception {
  const SocialException(this.message);

  final String message;

  @override
  String toString() => 'SocialException: $message';
}

abstract interface class SocialRepository {
  bool get isAvailable;

  Future<SocialSnapshot> load();

  Future<TrainerProfile> rename(String name);

  Future<void> sendRequest(String friendCode);

  Future<void> accept(String friendshipId);

  Future<void> decline(String friendshipId);

  Future<void> remove(String friendshipId);
}

/// Used when the build has no Supabase credentials. The Social tab shows the
/// setup card instead of inventing friends.
class UnavailableSocialRepository implements SocialRepository {
  const UnavailableSocialRepository([
    this.reason = 'This build has no Supabase project configured.',
  ]);

  final String reason;

  @override
  bool get isAvailable => false;

  @override
  Future<SocialSnapshot> load() => _fail();

  @override
  Future<TrainerProfile> rename(String name) => _fail();

  @override
  Future<void> sendRequest(String friendCode) => _fail();

  @override
  Future<void> accept(String friendshipId) => _fail();

  @override
  Future<void> decline(String friendshipId) => _fail();

  @override
  Future<void> remove(String friendshipId) => _fail();

  Never _fail() {
    throw const SocialException(
      'Social is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY.',
    );
  }
}

/// Replaced in `main()` with the Supabase-backed repository when configured.
final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => const UnavailableSocialRepository(),
);
