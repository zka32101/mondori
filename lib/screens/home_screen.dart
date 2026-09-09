import 'package:flutter/material.dart';
import 'package:mondori/screens/game_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // タイトル
              Text(
                '紋取り',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'もんどり',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // ルール説明
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ゲーム説明',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '駒は「本体」と「刻印（能力）」の2層構造で、敵駒を奪取すると刻印を奪い自駒に上書きする。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '毎ターン「移動」「奪取」「教化」の3アクションから1つ選び、敵王刻印を奪取したプレイヤーが勝ちだ。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '先手有利を抑制するためパイルール（後手が初手を見てから陣営交換可）を採用している。',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 開始ボタン
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GameModeScreen(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('ゲーム開始'),
              ),
              const SizedBox(height: 16),

              // ルール表示ボタン
              OutlinedButton(
                onPressed: () => _showRulesDialog(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('詳細ルール'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームルール'),
        content: const SingleChildScrollView(
          child: Text(
            '''【刻印の種類と移動】

進（しん）：前方1マスのみ
早（そう）：縦横1～2マス
対（たい）：斜め1マス
王（おう）：全8方向1マス

【手番でできること】

1. 移動：刻印のパターンに従い移動
2. 奪取：隣接する敵駒の刻印を奪う（移動を伴わない）
3. 教化：隣接する無印駒に刻印をコピーで付与（移動を伴わない）

【勝利条件】

相手の王刻印を奪取したら勝ち

【パイルール】

後手は初手を見てから陣営交換できる
''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
