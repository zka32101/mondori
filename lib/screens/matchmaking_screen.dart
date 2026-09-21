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

  @override
  void dispose() {
    ref.read(onlineGameStateProvider.notifier).leaveSession();
    super.dispose();
  }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('オンライン対戦'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
    );
  }
}
