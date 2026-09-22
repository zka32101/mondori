import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/providers/online_game_provider.dart';
import 'package:mondori/screens/online_game_screen.dart';

/// マッチメイキング待機画面
class MatchmakingScreen extends ConsumerStatefulWidget {
  final String playerId;

  const MatchmakingScreen({Key? key, required this.playerId}) : super(key: key);

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onlineGameStateProvider.notifier).startMatchmaking(widget.playerId);
    });
  }

  // dispose() では leaveSession() を呼ばない。マッチが成立して
  // pushReplacement で OnlineGameScreen に遷移した場合も dispose() は
  // 呼ばれるため、ここで無条件に呼ぶとマッチ直後のセッションを
  // 即座に abandoned にしてしまう。ユーザーが自分で「戻る」を押した
  // ときにのみ明示的に呼ぶ（下記 onPressed）。

  @override
  Widget build(BuildContext context) {
    ref.listen<OnlineGameState>(onlineGameStateProvider, (previous, next) {
      if (next.connectionStatus == OnlineConnectionStatus.connected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OnlineGameScreen(playerId: widget.playerId),
          ),
        );
      }
    });

    final state = ref.watch(onlineGameStateProvider);

    // AppBar の戻るボタンだけでなく、Android の戻る操作/iOS のスワイプでも
    // 待機中のセッションを確実に abandoned にするため WillPopScope で拾う。
    return WillPopScope(
      onWillPop: () async {
        ref.read(onlineGameStateProvider.notifier).leaveSession();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('オンライン対戦'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: '戻る',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.connectionStatus == OnlineConnectionStatus.error) ...[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.errorMessage ?? '接続エラーが発生しました'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(onlineGameStateProvider.notifier)
                        .startMatchmaking(widget.playerId);
                  },
                  child: const Text('再試行'),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('対戦相手を探しています...'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
