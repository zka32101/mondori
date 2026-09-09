import 'package:flutter/material.dart';
import 'package:mondori/screens/game_screen.dart';

/// ゲームモード選択画面
class GameModeScreen extends StatelessWidget {
  const GameModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('紋取り'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ゲームモード選択',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 48),

              // ホットシートプレイ
              _GameModeCard(
                icon: Icons.people,
                title: 'ホットシートプレイ',
                description: '1台のデバイスで2人が交代でプレイします',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GameScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // AI対戦（将来版）
              _GameModeCard(
                icon: Icons.android,
                title: 'AI対戦',
                description: 'コンピュータ相手にプレイします',
                isComingSoon: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI対戦は今後のバージョンで実装予定です'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // オンライン対戦（将来版）
              _GameModeCard(
                icon: Icons.cloud,
                title: 'オンライン対戦',
                description: 'インターネット経由で他のプレイヤーと対戦します',
                isComingSoon: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('オンライン対戦は今後のバージョンで実装予定です'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ゲームモード選択カード
class _GameModeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isComingSoon;

  const _GameModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  State<_GameModeCard> createState() => _GameModeCardState();
}

class _GameModeCardState extends State<_GameModeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevation = Tween<double>(begin: 2, end: 8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _elevation,
        builder: (context, child) {
          return Card(
            elevation: _elevation.value,
            child: InkWell(
              onTap: widget.isComingSoon ? null : widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      widget.icon,
                      size: 48,
                      color: widget.isComingSoon
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: widget.isComingSoon ? Colors.grey : null,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.isComingSoon) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '準備中',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.amber.shade900,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
