import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/battle_api.dart';
import '../../data/friend_battle_api.dart';
import '../../ui/tokens/layout.dart';
import '../battle/battle_arena_screen.dart';
import 'qr_payload.dart';

class FriendBattleLobbyScreen extends StatefulWidget {
  const FriendBattleLobbyScreen({
    super.key,
    required this.invite,
    required this.api,
  });

  final FriendBattleInvite invite;
  final FriendBattleApi api;

  @override
  State<FriendBattleLobbyScreen> createState() =>
      _FriendBattleLobbyScreenState();
}

class _FriendBattleLobbyScreenState extends State<FriendBattleLobbyScreen> {
  Timer? _timer;
  bool _joined = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_joined || !mounted) return;
    try {
      final update = await widget.api.poll(
        id: widget.invite.id,
        token: widget.invite.token,
      );
      final snapshot = update.snapshot;
      if (snapshot == null || !mounted) return;

      _joined = true;
      _timer?.cancel();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BattleArenaScreen(
            initial: snapshot,
            friend: FriendBattleConnection(
              api: widget.api,
              id: widget.invite.id,
              token: widget.invite.token,
            ),
          ),
        ),
      );
    } on BattleApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final code = widget.invite.code;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend battle'),
        leading: IconButton(
          tooltip: 'Cancel',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Waiting for your friend',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'They join with this code, or by scanning the QR. '
              'The battle starts by itself.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: QrImageView(
                      data: battleQrPayload(code),
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF16131C),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF16131C),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    code,
                    style: theme.textTheme.displaySmall?.copyWith(
                      letterSpacing: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Invite code copied')),
                        );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy invite code'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _error ?? 'Listening for a challenger…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _error == null
                          ? scheme.onSurfaceVariant
                          : scheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Keep this screen open. If you leave, the invite expires in '
              '30 minutes and no battle is recorded.',
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
