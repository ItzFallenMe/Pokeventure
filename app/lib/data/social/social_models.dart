class TrainerProfile {
  const TrainerProfile({
    required this.id,
    required this.name,
    required this.friendCode,
    required this.lastSeen,
  });

  factory TrainerProfile.fromRow(Map<String, dynamic> row) {
    return TrainerProfile(
      id: row['id'] as String,
      name: row['trainer_name'] as String,
      friendCode: row['friend_code'] as String,
      lastSeen:
          DateTime.tryParse(row['last_seen']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String friendCode;
  final DateTime lastSeen;

  bool isOnline({DateTime? now, Duration window = const Duration(minutes: 4)}) {
    final moment = now ?? DateTime.now();
    return moment.difference(lastSeen) < window;
  }

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  TrainerProfile copyWith({String? name, DateTime? lastSeen}) {
    return TrainerProfile(
      id: id,
      name: name ?? this.name,
      friendCode: friendCode,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

enum FriendshipStatus { pending, accepted, declined }

class Friendship {
  const Friendship({
    required this.id,
    required this.friend,
    required this.status,
    required this.outgoing,
    this.createdAt,
  });

  factory Friendship.fromRow(
    Map<String, dynamic> row, {
    required TrainerProfile friend,
    required bool outgoing,
  }) {
    return Friendship(
      id: row['id'] as String,
      friend: friend,
      status: FriendshipStatus.values.firstWhere(
        (value) => value.name == row['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      outgoing: outgoing,
      createdAt: DateTime.tryParse(
        row['created_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  final String id;
  final TrainerProfile friend;
  final FriendshipStatus status;

  /// True when this player sent the request.
  final bool outgoing;
  final DateTime? createdAt;

  bool get isPending => status == FriendshipStatus.pending;
}

class SocialSnapshot {
  const SocialSnapshot({
    required this.me,
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
  });

  final TrainerProfile me;
  final List<Friendship> friends;
  final List<Friendship> incoming;
  final List<Friendship> outgoing;
}
