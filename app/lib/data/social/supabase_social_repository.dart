import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'social_models.dart';
import 'social_repository.dart';

class SupabaseSocialRepository implements SocialRepository {
  SupabaseSocialRepository(this._client);

  final SupabaseClient _client;
  Future<TrainerProfile>? _profile;

  @override
  bool get isAvailable => true;

  Future<String> _userId() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const SocialException('Could not sign in. Try again.');
    }
    return id;
  }

  Future<TrainerProfile> _ensureProfile() async {
    try {
      return await (_profile ??= _loadOrCreateProfile());
    } catch (error) {
      _profile = null;
      if (error is SocialException) rethrow;
      throw SocialException(_describe(error));
    }
  }

  String _describe(Object error) {
    if (error is AuthException) {
      return 'Could not sign in to social (${error.message}).';
    }
    if (error is PostgrestException) return _friendly(error);
    return 'Social is unavailable right now.';
  }

  Future<TrainerProfile> _loadOrCreateProfile() async {
    final id = await _userId();
    final existing = await _client
        .from('players')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (existing != null) return TrainerProfile.fromRow(existing);

    final random = Random();
    final name = 'Trainer ${1000 + random.nextInt(9000)}';
    try {
      final inserted = await _client
          .from('players')
          .insert({'id': id, 'trainer_name': name})
          .select()
          .single();
      return TrainerProfile.fromRow(inserted);
    } on PostgrestException catch (error) {
      // Another request created the row first; read it instead.
      if (error.code == '23505') {
        final again = await _client
            .from('players')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (again != null) return TrainerProfile.fromRow(again);
      }
      throw SocialException(error.message);
    }
  }

  @override
  Future<SocialSnapshot> load() async {
    try {
      final me = await _ensureProfile();
      final now = DateTime.now().toUtc();

      await _client
          .from('players')
          .update({'last_seen': now.toIso8601String()})
          .eq('id', me.id);

      final rows = await _client
          .from('friendships')
          .select()
          .or('requester_id.eq.${me.id},addressee_id.eq.${me.id}');

      final otherIds = <String>{
        for (final row in rows)
          row['requester_id'] == me.id
              ? row['addressee_id'] as String
              : row['requester_id'] as String,
      }.toList();

      final profiles = otherIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client.from('players').select().inFilter('id', otherIds);

      final byId = {
        for (final profile in profiles)
          profile['id'] as String: TrainerProfile.fromRow(profile),
      };

      final friends = <Friendship>[];
      final incoming = <Friendship>[];
      final outgoing = <Friendship>[];

      for (final row in rows) {
        final outgoingRow = row['requester_id'] == me.id;
        final otherId =
            (outgoingRow ? row['addressee_id'] : row['requester_id']) as String;
        final friend =
            byId[otherId] ??
            TrainerProfile(
              id: otherId,
              name: 'Trainer',
              friendCode: '—',
              lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
            );
        final friendship = Friendship.fromRow(
          row,
          friend: friend,
          outgoing: outgoingRow,
        );

        switch (friendship.status) {
          case FriendshipStatus.accepted:
            friends.add(friendship);
          case FriendshipStatus.pending:
            (outgoingRow ? outgoing : incoming).add(friendship);
          case FriendshipStatus.declined:
            break;
        }
      }

      friends.sort((a, b) {
        final aOnline = a.friend.isOnline(now: now) ? 1 : 0;
        final bOnline = b.friend.isOnline(now: now) ? 1 : 0;
        if (aOnline != bOnline) return bOnline - aOnline;
        return a.friend.name.toLowerCase().compareTo(
          b.friend.name.toLowerCase(),
        );
      });

      return SocialSnapshot(
        me: me.copyWith(lastSeen: now.toLocal()),
        friends: friends,
        incoming: incoming,
        outgoing: outgoing,
      );
    } on PostgrestException catch (error) {
      throw SocialException(_friendly(error));
    } on AuthException catch (error) {
      throw SocialException(_describe(error));
    }
  }

  @override
  Future<TrainerProfile> rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.length < 3 || trimmed.length > 20) {
      throw const SocialException('Trainer names are 3–20 characters long.');
    }

    try {
      final me = await _ensureProfile();
      final row = await _client
          .from('players')
          .update({'trainer_name': trimmed})
          .eq('id', me.id)
          .select()
          .single();
      final updated = TrainerProfile.fromRow(row);
      _profile = Future.value(updated);
      return updated;
    } on PostgrestException catch (error) {
      throw SocialException(_friendly(error));
    } on AuthException catch (error) {
      throw SocialException(_describe(error));
    }
  }

  @override
  Future<void> sendRequest(String friendCode) async {
    final code = friendCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw const SocialException('Enter a friend code.');
    }

    try {
      final me = await _ensureProfile();
      final target = await _client
          .from('players')
          .select()
          .eq('friend_code', code)
          .maybeSingle();

      if (target == null) {
        throw const SocialException('No trainer uses that code.');
      }
      if (target['id'] == me.id) {
        throw const SocialException('That is your own friend code.');
      }

      await _client.from('friendships').insert({
        'requester_id': me.id,
        'addressee_id': target['id'],
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const SocialException(
          'You already have a request or friendship with that trainer.',
        );
      }
      throw SocialException(_friendly(error));
    } on AuthException catch (error) {
      throw SocialException(_describe(error));
    }
  }

  @override
  Future<void> accept(String friendshipId) => _answer(friendshipId, true);

  @override
  Future<void> decline(String friendshipId) => _answer(friendshipId, false);

  Future<void> _answer(String friendshipId, bool accept) async {
    try {
      if (accept) {
        await _client
            .from('friendships')
            .update({
              'status': 'accepted',
              'responded_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', friendshipId);
      } else {
        // Delete instead of storing "declined" so either side can ask again.
        await _client.from('friendships').delete().eq('id', friendshipId);
      }
    } on PostgrestException catch (error) {
      throw SocialException(_friendly(error));
    } on AuthException catch (error) {
      throw SocialException(_describe(error));
    }
  }

  @override
  Future<void> remove(String friendshipId) async {
    try {
      await _client.from('friendships').delete().eq('id', friendshipId);
    } on PostgrestException catch (error) {
      throw SocialException(_friendly(error));
    } on AuthException catch (error) {
      throw SocialException(_describe(error));
    }
  }

  String _friendly(PostgrestException error) {
    if (error.code == '42501') {
      return 'That action is not allowed for this account.';
    }
    if (error.code == '23514') {
      return 'That value is not valid.';
    }
    return error.message;
  }
}
