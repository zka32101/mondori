import 'dart:convert';

import 'package:mondori/models/game_statistics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ゲーム統計・履歴の永続化サービス（端末ローカル保存）
class StatisticsService {
  static const String _historyKey = 'mondori_game_history';

  /// 保持する履歴の最大件数（無制限の肥大化を防止）
  static const int maxHistorySize = 200;

  /// ゲーム結果を記録（履歴の先頭に追加）
  Future<void> recordGameResult(GameStatistics stats) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGameHistory();

    final updated = [stats, ...history];
    final trimmed = updated.length > maxHistorySize
        ? updated.sublist(0, maxHistorySize)
        : updated;

    await prefs.setString(
      _historyKey,
      jsonEncode(trimmed.map((g) => g.toJson()).toList()),
    );
  }

  /// 保存されているゲーム履歴を取得（新しい順）
  Future<List<GameStatistics>> getGameHistory({GameMode? filterMode}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final history = decoded
        .map((e) => GameStatistics.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (filterMode == null) {
      return history;
    }
    return history.where((g) => g.mode == filterMode).toList();
  }

  /// 履歴を全削除
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
