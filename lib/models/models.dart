/// 用户设置（存 DB settings 表，启动时一次性读入内存）
class Settings {
  final bool onboarded; // 是否完成首次引导
  final String level; // all / B2 / C1
  final int dailyNew; // 每天新词量
  final bool repeat; // 「重复」勾选：true=新词+复习旧词，false=只考新词
  final String accent; // US / UK 发音口音

  const Settings({
    this.onboarded = false,
    this.level = 'all',
    this.dailyNew = 20,
    this.repeat = true,
    this.accent = 'US',
  });

  Settings copyWith({
    bool? onboarded,
    String? level,
    int? dailyNew,
    bool? repeat,
    String? accent,
  }) =>
      Settings(
        onboarded: onboarded ?? this.onboarded,
        level: level ?? this.level,
        dailyNew: dailyNew ?? this.dailyNew,
        repeat: repeat ?? this.repeat,
        accent: accent ?? this.accent,
      );

  String get levelText => switch (level) {
        'B2' => 'B2 基础',
        'C1' => 'C1 进阶',
        _ => '全部词库',
      };
}

/// 单个单词的学习状态
class CardState {
  final int wordId;
  int status; // 0=未学/待学 1=学习中 2=已掌握（随学习进度变化）
  int seen;
  int correct;
  int wrong;
  int stage; // 记忆阶段，决定下次复习间隔
  String? due; // 下次复习日期 yyyy-MM-dd
  String? lastSeen;
  bool favorite;

  CardState({
    required this.wordId,
    this.status = 0,
    this.seen = 0,
    this.correct = 0,
    this.wrong = 0,
    this.stage = 0,
    this.due,
    this.lastSeen,
    this.favorite = false,
  });

  bool get isNew => status == 0;
  bool get mastered => status == 2;
  bool get isWrong => wrong > 0;

  factory CardState.fromMap(Map<String, Object?> m) => CardState(
        wordId: m['word_id'] as int,
        status: (m['status'] as int?) ?? 0,
        seen: (m['seen'] as int?) ?? 0,
        correct: (m['correct'] as int?) ?? 0,
        wrong: (m['wrong'] as int?) ?? 0,
        stage: (m['stage'] as int?) ?? 0,
        due: m['due'] as String?,
        lastSeen: m['last_seen'] as String?,
        favorite: ((m['favorite'] as int?) ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        'word_id': wordId,
        'status': status,
        'seen': seen,
        'correct': correct,
        'wrong': wrong,
        'stage': stage,
        'due': due,
        'last_seen': lastSeen,
        'favorite': favorite ? 1 : 0,
      };
}

/// 每日记录
class DailyStat {
  final String date; // yyyy-MM-dd
  final int newCnt;
  final int reviewCnt;
  final int correct;
  final int wrong;
  final bool done; // 是否已打卡

  const DailyStat({
    required this.date,
    this.newCnt = 0,
    this.reviewCnt = 0,
    this.correct = 0,
    this.wrong = 0,
    this.done = false,
  });

  factory DailyStat.fromMap(Map<String, Object?> m) => DailyStat(
        date: m['date'] as String,
        newCnt: (m['new_cnt'] as int?) ?? 0,
        reviewCnt: (m['review_cnt'] as int?) ?? 0,
        correct: (m['correct'] as int?) ?? 0,
        wrong: (m['wrong'] as int?) ?? 0,
        done: ((m['done'] as int?) ?? 0) == 1,
      );
}
