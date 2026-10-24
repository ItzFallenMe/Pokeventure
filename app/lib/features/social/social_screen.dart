import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/battle_api.dart';
import '../../data/friend_battle_api.dart';
import '../../data/social/social_models.dart';
import '../../data/social/social_repository.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';
import '../battle/battle_arena_screen.dart';
import 'friend_battle_lobby.dart';
import 'qr_payload.dart';
import 'qr_sheets.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  SocialSnapshot? _data;
  bool _loading = true;
  bool _working = false;
  String? _error;

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  @override
  void initState() {
    super.initState();
    if (_repo.isAvailable) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load({bool quiet = false}) async {
    final repo = _repo;
    if (!repo.isAvailable) return;

    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await repo.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
    } on SocialException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Social is unavailable right now.';
      });
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
      if (!mounted) return;
      if (success != null) _snack(success);
      await _load(quiet: true);
    } on SocialException catch (error) {
      if (mounted) _snack(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String?> _askCode({
    required String title,
    required String body,
    required String hint,
    required String action,
  }) async {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final code = controller.text.trim();
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 12,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: hint,
                        counterText: '',
                        hintText: 'ABC123',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final payload = await Navigator.of(dialogContext)
                              .push<QrPayload>(
                                MaterialPageRoute(
                                  builder: (_) => const QrScanScreen(),
                                ),
                              );
                          if (payload == null || !context.mounted) return;
                          controller.text = payload.code;
                          setDialogState(() {});
                        },
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                        ),
                        label: const Text('Scan QR'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: code.length < 4
                      ? null
                      : () =>
                            Navigator.of(dialogContext).pop(code.toUpperCase()),
                  child: Text(action),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> _addFriend() async {
    final code = await _askCode(
      title: 'Add a friend',
      body: 'Enter their 6-character trainer code, or scan their QR.',
      hint: 'Friend code',
      action: 'Send request',
    );
    if (code == null || !mounted) return;
    await _run(() => _repo.sendRequest(code), success: 'Friend request sent');
  }

  Future<void> _editName() async {
    final data = _data;
    if (data == null) return;

    final controller = TextEditingController(text: data.me.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trainer name'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            decoration: const InputDecoration(labelText: 'Visible to friends'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name == data.me.name || !mounted) return;
    await _run(() => _repo.rename(name), success: 'Name updated');
  }

  Future<void> _showMyQr() async {
    final data = _data;
    if (data == null) return;
    await showQrSheet(
      context,
      title: 'Your trainer code',
      subtitle: 'A friend scans this to send you a request.',
      code: data.me.friendCode,
      payload: friendQrPayload(data.me.friendCode),
      footer: 'The code is a lookup key, not a password.',
    );
  }

  Future<void> _inviteFriend() async {
    final data = _data;
    if (data == null || _working) return;

    setState(() => _working = true);
    try {
      final api = ref.read(friendBattleApiProvider);
      final invite = await api.create(name: data.me.name);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FriendBattleLobbyScreen(invite: invite, api: api),
        ),
      );
    } on BattleApiException catch (error) {
      if (mounted) _snack(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _joinBattle() async {
    final code = await _askCode(
      title: 'Join a battle',
      body:
          'Enter the invite code your friend shared, or scan their battle QR.',
      hint: 'Battle code',
      action: 'Join',
    );
    if (code == null || !mounted) return;

    setState(() => _working = true);
    try {
      final api = ref.read(friendBattleApiProvider);
      final update = await api.join(
        code: code,
        name: _data?.me.name ?? 'Trainer',
      );
      final snapshot = update.snapshot;
      final id = update.id;
      if (!mounted) return;
      if (snapshot == null || id == null || update.token == null) {
        _snack('That battle is not ready.');
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BattleArenaScreen(
            initial: snapshot,
            friend: FriendBattleConnection(
              api: api,
              id: id,
              token: update.token!,
            ),
          ),
        ),
      );
    } on BattleApiException catch (error) {
      if (mounted) _snack(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _remove(Friendship friendship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${friendship.friend.name}?'),
        content: const Text(
          'They stay in your battle history, but are no longer in your friends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _repo.remove(friendship.id), success: 'Friend removed');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final repo = ref.watch(socialRepositoryProvider);
    final data = _data;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => _load(quiet: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            StaggeredEntrance(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Social', style: theme.textTheme.displaySmall),
                  Text(
                    'Friends, codes and battles between the two of you.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_working) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (!repo.isAvailable)
              _SetupCard(
                reason: repo is UnavailableSocialRepository
                    ? repo.reason
                    : 'Social is not connected in this build.',
              )
            else if (_loading && data == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (data == null)
              _ErrorCard(
                message: _error ?? 'Could not load your social feed.',
                onRetry: () => _load(),
              )
            else ...[
              _TrainerCard(
                profile: data.me,
                onQr: _showMyQr,
                onEdit: _editName,
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Friends',
                trailingLabel: 'Add friend',
                onTrailing: _addFriend,
              ),
              if (data.incoming.isNotEmpty) ...[
                _RequestList(
                  title: 'Requests for you',
                  requests: data.incoming,
                  onAccept: (friendship) => _run(
                    () => _repo.accept(friendship.id),
                    success: 'You are now friends',
                  ),
                  onDecline: (friendship) =>
                      _run(() => _repo.decline(friendship.id)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (data.outgoing.isNotEmpty) ...[
                _OutgoingList(
                  requests: data.outgoing,
                  onCancel: (friendship) =>
                      _run(() => _repo.decline(friendship.id)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (data.friends.isEmpty)
                _EmptyFriends(onAdd: _addFriend)
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < data.friends.length; i++) ...[
                        _FriendTile(
                          friendship: data.friends[i],
                          onBattle: _inviteFriend,
                          onRemove: () => _remove(data.friends[i]),
                        ),
                        if (i != data.friends.length - 1)
                          Divider(
                            height: 1,
                            indent: 68,
                            color: scheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Battle a friend'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A real Showdown battle, one move at a time. '
                        'Share an invite code or join theirs.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _inviteFriend,
                              icon: const Icon(
                                Icons.add_link_rounded,
                                size: 18,
                              ),
                              label: const Text('Create invite'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _joinBattle,
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: const Text('Join code'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Guild'),
              Card(
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  title: const Text(
                    'Guilds · M5',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Guild halls, raids and shared quests are not built yet.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  const _TrainerCard({
    required this.profile,
    required this.onQr,
    required this.onEdit,
  });

  final TrainerProfile profile;
  final VoidCallback onQr;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onCard = scheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.tertiary.withValues(alpha: 0.3),
              scheme.primaryContainer,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.surface.withValues(alpha: 0.7),
                child: Text(
                  profile.initial,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: onCard,
                      ),
                    ),
                    Text(
                      'Trainer code · ${profile.friendCode}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: onCard.withValues(alpha: 0.78),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit name',
                onPressed: onEdit,
                color: onCard,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onQr,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.surface.withValues(alpha: 0.82),
                    foregroundColor: scheme.primary,
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Show my QR'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Copy trainer code',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: profile.friendCode),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Trainer code copied')),
                    );
                },
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surface.withValues(alpha: 0.55),
                  foregroundColor: scheme.primary,
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friendship,
    required this.onBattle,
    required this.onRemove,
  });

  final Friendship friendship;
  final VoidCallback onBattle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final friend = friendship.friend;
    final online = friend.isOnline();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  friend.initial,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online
                        ? const Color(0xFF35C46A)
                        : scheme.outlineVariant,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${online ? 'Online now' : _lastSeen(friend.lastSeen)} · '
                  '${friend.friendCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Battle',
            onPressed: onBattle,
            icon: const Icon(Icons.sports_mma_rounded, size: 20),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: scheme.primary,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'remove') onRemove();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'remove', child: Text('Remove friend')),
            ],
          ),
        ],
      ),
    );
  }

  String _lastSeen(DateTime lastSeen) {
    final difference = DateTime.now().difference(lastSeen);
    if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes.clamp(1, 59)}m ago';
    }
    if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    }
    return 'Last seen ${difference.inDays}d ago';
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.title,
    required this.requests,
    required this.onAccept,
    required this.onDecline,
  });

  final String title;
  final List<Friendship> requests;
  final ValueChanged<Friendship> onAccept;
  final ValueChanged<Friendship> onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ),
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: scheme.secondaryContainer,
                      child: Text(
                        request.friend.initial,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        request.friend.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Decline',
                      onPressed: () => onDecline(request),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                    FilledButton.tonal(
                      onPressed: () => onAccept(request),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingList extends StatelessWidget {
  const _OutgoingList({required this.requests, required this.onCancel});

  final List<Friendship> requests;
  final ValueChanged<Friendship> onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                'WAITING FOR THEM',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ),
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        request.friend.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onCancel(request),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 32,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No friends yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Share your trainer code or scan a friend’s to send a request.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add by code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Connect Supabase', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Social runs on Supabase Postgres with anonymous sign-in. '
              'Create a free project, run the migration in '
              'supabase/migrations, then build with:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'flutter build apk --release \\\n'
                '  --dart-define=SUPABASE_URL=… \\\n'
                '  --dart-define=SUPABASE_ANON_KEY=…',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Setup guide: docs/SUPABASE.md. Everything else in the app keeps '
              'working without it.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not load social', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
