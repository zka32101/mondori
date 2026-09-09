import 'package:flutter/material.dart';

/// パイルール選択ダイアログ
///
/// 先手有利を抑制するため、後手（プレイヤーB）が初手を見てから
/// 陣営を交換できるルール。
///
/// 流れ:
/// 1. プレイヤーA が初手を実施
/// 2. ダイアログ表示: 「陣営を交換しますか？」
/// 3. プレイヤーB が選択
///    - Yes: 盤面回転、B がプレイヤーA の駒を担当
///    - No:  通常通り続行
class PieRuleDialog extends StatefulWidget {
  /// パイルール適用後のコールバック
  /// switchSides: true = 陸営交換, false = 交換なし
  final Function(bool switchSides) onPieRuleResolved;

  const PieRuleDialog({
    Key? key,
    required this.onPieRuleResolved,
  }) : super(key: key);

  @override
  State<PieRuleDialog> createState() => _PieRuleDialogState();
}

class _PieRuleDialogState extends State<PieRuleDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleChoice(bool switchSides) {
    Navigator.pop(context);
    widget.onPieRuleResolved(switchSides);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        title: const Text('🍰 パイルール'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ルール説明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '後手（プレイヤーB）が初手を見てから、\n陸営を交換できます。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '先手有利を抑制するため、後手に選択権があります。',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 選択肢
              Text(
                '陸営を交換しますか？',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          // 交換しない
          TextButton(
            onPressed: () => _handleChoice(false),
            child: const Text('いいえ'),
          ),

          // 交換する
          FilledButton(
            onPressed: () => _handleChoice(true),
            child: const Text('はい、交換する'),
          ),
        ],
      ),
    );
  }
}

/// パイルール確認ダイアログを表示するユーティリティ関数
Future<bool> showPieRuleDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PieRuleDialog(
      onPieRuleResolved: (switchSides) {
        Navigator.pop(context, switchSides);
      },
    ),
  );

  return result ?? false;
}
