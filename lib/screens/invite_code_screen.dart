import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/providers/online_game_provider.dart';
import 'package:mondori/screens/online_game_screen.dart';

/// 招待コードでのオンライン対戦画面（ホスト作成 / コード入力で参加）
///
/// ランダムマッチング（[MatchmakingScreen]）と異なり、知り合い同士で
/// セッションIDを直接共有して対戦する。
class InviteCodeScreen extends ConsumerStatefulWidget {
  final String playerId;

  const InviteCodeScreen({Key? key, required this.playerId}) : super(key: key);

  @override
  ConsumerState<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

enum _Mode { choose, hosting, joining }

class _InviteCodeScreenState extends ConsumerState<InviteCodeScreen> {
  _Mode _mode = _Mode.choose;
  String? _hostedCode;
  final _codeController = TextEditingController();

  // dispose() では leaveSession() を呼ばない。ホスト/参加が成立して
  // pushReplacement で OnlineGameScreen に遷移した場合も dispose() は
  // 呼ばれるため、無条件に呼ぶと接続直後のセッションを即座に
  // abandoned にしてしまう。実際の離脱は WillPopScope（下記）で拾う。
  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startHosting() async {
    setState(() => _mode = _Mode.hosting);
    final code = await ref.read(onlineGameStateProvider.notifier).hostGame(widget.playerId);
    if (mounted) setState(() => _hostedCode = code);
  }

  void _startJoining() {
    setState(() => _mode = _Mode.joining);
  }

  Future<void> _submitJoinCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    await ref.read(onlineGameStateProvider.notifier).joinByCode(code, widget.playerId);
  }

  @override
  Widget build(BuildContext context) {
    // ホスト側: 相手が参加してセッションが2人揃うまで待つ
    // （connectionStatus は購読開始時点で connected になるため、
    // isFull を見てはじめて「対戦相手が参加した」と判定できる）。
    // 参加側: joinSession は満員でない限り成功しないため、
    // connected になった時点で既にセッションは揃っている。
    ref.listen<OnlineGameState>(onlineGameStateProvider, (previous, next) {
      final ready = _mode == _Mode.hosting
          ? next.session?.isFull == true
          : next.connectionStatus == OnlineConnectionStatus.connected;

      if (ready) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OnlineGameScreen(playerId: widget.playerId),
          ),
        );
      }
    });

    final state = ref.watch(onlineGameStateProvider);

    return WillPopScope(
      onWillPop: () async {
        ref.read(onlineGameStateProvider.notifier).leaveSession();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('招待コード対戦'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: '戻る',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: _buildBody(state)),
        ),
      ),
    );
  }

  Widget _buildBody(OnlineGameState state) {
    if (state.connectionStatus == OnlineConnectionStatus.error) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(state.errorMessage ?? '接続エラーが発生しました', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => setState(() {
              _mode = _Mode.choose;
              _hostedCode = null;
            }),
            child: const Text('やり直す'),
          ),
        ],
      );
    }

    switch (_mode) {
      case _Mode.choose:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '知り合いと対戦するには、コードを作成して共有するか、\n'
              '相手から受け取ったコードを入力してください。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.add_link),
              label: const Text('コードを作成してホストする'),
              onPressed: _startHosting,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('コードを入力して参加する'),
              onPressed: _startJoining,
            ),
          ],
        );

      case _Mode.hosting:
        if (_hostedCode == null) {
          return const CircularProgressIndicator();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('このコードを相手に伝えてください'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SelectableText(
                  _hostedCode!,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('コピー'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _hostedCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('コードをコピーしました')),
                );
              },
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('対戦相手の参加を待っています...'),
          ],
        );

      case _Mode.joining:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('相手から受け取ったコードを入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '招待コード',
              ),
              onSubmitted: (_) => _submitJoinCode(),
            ),
            const SizedBox(height: 16),
            if (state.connectionStatus == OnlineConnectionStatus.matchmaking)
              const CircularProgressIndicator()
            else
              FilledButton(
                onPressed: _submitJoinCode,
                child: const Text('参加する'),
              ),
          ],
        );
    }
  }
}
