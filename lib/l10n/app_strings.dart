import 'package:flutter/material.dart';

/// アプリ独自の多言語対応（日本語・English・中文・한국어）
///
/// `flutter gen-l10n` によるコード生成は使わず、シンプルな Map ベースの
/// 手書き実装とする。生成ステップに依存すると、コード生成が実行されない
/// 環境ではビルドが壊れる（本プロジェクトで実際に fonts/assets の宣言だけが
/// 存在してファイル本体が無い、という問題が起きたのと同種の罠）。
class AppStrings {
  final Locale locale;

  const AppStrings(this.locale);

  static const supportedLocales = [
    Locale('ja'),
    Locale('en'),
    Locale('zh'),
    Locale('ko'),
  ];

  static const _localeNames = {
    'ja': '日本語',
    'en': 'English',
    'zh': '中文',
    'ko': '한국어',
  };

  static String localeName(String code) => _localeNames[code] ?? code;

  static const Map<String, Map<String, String>> _values = {
    'appTitle': {
      'ja': '紋取り（もんどり）',
      'en': 'Mondori',
      'zh': '纹取',
      'ko': '몬도리',
    },
    'startGame': {
      'ja': 'ゲーム開始',
      'en': 'Start Game',
      'zh': '开始游戏',
      'ko': '게임 시작',
    },
    'detailedRules': {
      'ja': '詳細ルール',
      'en': 'Detailed Rules',
      'zh': '详细规则',
      'ko': '상세 규칙',
    },
    'statisticsHistory': {
      'ja': '統計・履歴',
      'en': 'Statistics & History',
      'zh': '统计与历史',
      'ko': '통계 및 기록',
    },
    'settings': {
      'ja': '設定',
      'en': 'Settings',
      'zh': '设置',
      'ko': '설정',
    },
    'gameModeSelection': {
      'ja': 'ゲームモード選択',
      'en': 'Select Game Mode',
      'zh': '选择游戏模式',
      'ko': '게임 모드 선택',
    },
    'hotSeatPlay': {
      'ja': 'ホットシートプレイ',
      'en': 'Hot-Seat Play',
      'zh': '面对面对战',
      'ko': '핫시트 플레이',
    },
    'hotSeatDescription': {
      'ja': '1台のデバイスで2人が交代でプレイします',
      'en': 'Two players take turns on one device',
      'zh': '两名玩家轮流使用同一台设备',
      'ko': '두 플레이어가 한 기기에서 번갈아 플레이합니다',
    },
    'aiBattle': {
      'ja': 'AI対戦',
      'en': 'AI Battle',
      'zh': 'AI对战',
      'ko': 'AI 대전',
    },
    'aiBattleDescription': {
      'ja': 'コンピュータ相手にプレイします',
      'en': 'Play against the computer',
      'zh': '与电脑对战',
      'ko': '컴퓨터와 대결합니다',
    },
    'onlineBattle': {
      'ja': 'オンライン対戦',
      'en': 'Online Battle',
      'zh': '在线对战',
      'ko': '온라인 대전',
    },
    'onlineBattleDescription': {
      'ja': 'インターネット経由で他のプレイヤーと対戦します',
      'en': 'Play against other players over the internet',
      'zh': '通过互联网与其他玩家对战',
      'ko': '인터넷을 통해 다른 플레이어와 대전합니다',
    },
    'comingSoon': {
      'ja': '準備中',
      'en': 'Coming Soon',
      'zh': '即将推出',
      'ko': '준비 중',
    },
    'difficultySelection': {
      'ja': '難度選択',
      'en': 'Select Difficulty',
      'zh': '选择难度',
      'ko': '난이도 선택',
    },
    'resetGame': {
      'ja': 'ゲームをリセット',
      'en': 'Reset Game',
      'zh': '重置游戏',
      'ko': '게임 재설정',
    },
    'playAgain': {
      'ja': 'もう一度プレイ',
      'en': 'Play Again',
      'zh': '再玩一次',
      'ko': '다시 플레이',
    },
    'yourTurn': {
      'ja': 'あなたのターン',
      'en': 'Your Turn',
      'zh': '轮到你了',
      'ko': '당신의 차례',
    },
    'aiTurn': {
      'ja': 'AI のターン',
      'en': "AI's Turn",
      'zh': 'AI回合',
      'ko': 'AI 차례',
    },
    'aiThinking': {
      'ja': 'AI 考え中...',
      'en': 'AI is thinking...',
      'zh': 'AI思考中...',
      'ko': 'AI 생각 중...',
    },
    'youWin': {
      'ja': 'あなたの勝利！',
      'en': 'You Win!',
      'zh': '你赢了！',
      'ko': '승리했습니다!',
    },
    'aiWins': {
      'ja': 'AI の勝利',
      'en': 'AI Wins',
      'zh': 'AI获胜',
      'ko': 'AI 승리',
    },
    'language': {
      'ja': '言語',
      'en': 'Language',
      'zh': '语言',
      'ko': '언어',
    },
    'theme': {
      'ja': 'テーマ',
      'en': 'Theme',
      'zh': '主题',
      'ko': '테마',
    },
    'themeSystem': {
      'ja': '端末の設定に従う',
      'en': 'Follow System',
      'zh': '跟随系统',
      'ko': '시스템 설정 따르기',
    },
    'themeLight': {
      'ja': 'ライト',
      'en': 'Light',
      'zh': '浅色',
      'ko': '라이트',
    },
    'themeDark': {
      'ja': 'ダーク',
      'en': 'Dark',
      'zh': '深色',
      'ko': '다크',
    },
    'soundEffects': {
      'ja': '効果音',
      'en': 'Sound Effects',
      'zh': '音效',
      'ko': '효과음',
    },
    'backgroundMusic': {
      'ja': 'BGM',
      'en': 'Background Music',
      'zh': '背景音乐',
      'ko': '배경 음악',
    },
    'volume': {
      'ja': '音量',
      'en': 'Volume',
      'zh': '音量',
      'ko': '음량',
    },
  };

  String get(String key) {
    final entry = _values[key];
    if (entry == null) return key;
    return entry[locale.languageCode] ?? entry['en'] ?? key;
  }

  // よく使うキーのショートカット
  String get appTitle => get('appTitle');
  String get startGame => get('startGame');
  String get detailedRules => get('detailedRules');
  String get statisticsHistory => get('statisticsHistory');
  String get settings => get('settings');
  String get gameModeSelection => get('gameModeSelection');
  String get hotSeatPlay => get('hotSeatPlay');
  String get hotSeatDescription => get('hotSeatDescription');
  String get aiBattle => get('aiBattle');
  String get aiBattleDescription => get('aiBattleDescription');
  String get onlineBattle => get('onlineBattle');
  String get onlineBattleDescription => get('onlineBattleDescription');
  String get comingSoon => get('comingSoon');
  String get difficultySelection => get('difficultySelection');
  String get resetGame => get('resetGame');
  String get playAgain => get('playAgain');
  String get yourTurn => get('yourTurn');
  String get aiTurn => get('aiTurn');
  String get aiThinking => get('aiThinking');
  String get youWin => get('youWin');
  String get aiWins => get('aiWins');
  String get language => get('language');
  String get theme => get('theme');
  String get themeSystem => get('themeSystem');
  String get themeLight => get('themeLight');
  String get themeDark => get('themeDark');
  String get soundEffects => get('soundEffects');
  String get backgroundMusic => get('backgroundMusic');
  String get volume => get('volume');
}

/// `context.strings` で現在のロケールに応じた文字列にアクセスするための拡張
extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings(Localizations.localeOf(this));
}

