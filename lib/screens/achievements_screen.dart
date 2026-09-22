import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/models/achievement.dart';
import 'package:mondori/providers/statistics_provider.dart';

/// 実績一覧画面
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('実績'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '戻る',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '$unlockedCount / ${achievements.length} 達成',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: achievements.isEmpty ? 0 : unlockedCount / achievements.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: achievements.length,
              itemBuilder: (context, index) => _AchievementTile(item: achievements[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementProgress item;

  const _AchievementTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final achievement = item.achievement;
    final unlocked = item.unlocked;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: unlocked
            ? Colors.amber.withOpacity(0.2)
            : Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(
          achievement.icon,
          color: unlocked ? Colors.amber.shade800 : Colors.grey,
        ),
      ),
      title: Text(
        achievement.title,
        style: TextStyle(
          fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
          color: unlocked ? null : Colors.grey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            achievement.description,
            style: TextStyle(color: unlocked ? null : Colors.grey),
          ),
          if (!unlocked && item.progress > 0) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: item.progress, minHeight: 4),
          ],
        ],
      ),
      trailing: unlocked
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.lock_outline, color: Colors.grey),
      isThreeLine: !unlocked && item.progress > 0,
    );
  }
}
