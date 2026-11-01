import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../models/word.dart';
import 'progress_store.dart';
import 'word_bank.dart';

/// 记忆曲线间隔（天）：答对一次进一档，答错归零
const List<int> kSrsIntervals = [1, 2, 4, 7, 15, 30];

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayKey() => dateKey(DateTime.now());

DateTime parseDateKey(String k) {
  final parts = k.split('-');
  return DateTime(
      int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// 一次学习任务：新词 + 复习词
class StudySession {
  final List<Word> newWords;
  final List<Word> reviewWords;
  const StudySession({required this.newWords, required this.reviewWords});

  List<Word> get queue => [...newWords, ...reviewWords];
  bool get isEmpty => queue.isEmpty;
  int get total => queue.length;

  /// 某个词是不是本次的「复习词」（用于卡片上打标签）
  bool isReview(Word w) => reviewWords.any((e) => e.id == w.id);
}

/// 全局应用状态：词库 + 进度 + 设置
/// 用内置 ChangeNotifier 实现，不引入第三方状态库，减少打包风险
class AppEnv extends ChangeNotifier {
  final WordBank bank;
  final ProgressStore store;

  Settings settings;
  Map<int, CardState> cards = {};
  DailyStat today = DailyStat(date: todayKey());
  int streakDays = 0;
  Map<String, bool> doneDays = {};
  bool _busy = false;

  AppEnv({
    required this.bank,
    required this.store,
    required this.settings,
  });

  bool get busy => _busy;
  int get totalWords => bank.all.length;

  static Future<AppEnv> bootstrap() async {
    final store = ProgressStore();
    await store.init();
    final bank = await WordBank.load();
    final settings = await store.loadSettings();
    final env = AppEnv(bank: bank, store: store, settings: settings);
    await env.refresh();
    return env;
  }

  Future<void> refresh() async {
    cards = await store.loadCards();
    today = await store.statOf(todayKey()) ?? DailyStat(date: todayKey());
    streakDays = await store.streak();
    final recent = await store.recentDays(400);
    doneDays = {
      for (final d in recent)
        if (d.done) d.date: true,
    };
    notifyListeners();
  }

  CardState cardOf(int wordId) =>
      cards[wordId] ?? (cards[wordId] = CardState(wordId: wordId));

  // ---------------- 今日任务 ----------------
  /// 今天还能学几个新词（考虑当天已完成量）
  int get newQuotaLeft {
    final left = settings.dailyNew - today.newCnt;
    return left < 0 ? 0 : left;
  }

  List<Word> pickNewWords({int? limit}) {
    final cap = limit ?? newQuotaLeft;
    if (cap <= 0) return const [];
    final scope = bank.byLevel(settings.level);
    final result = <Word>[];
    for (final w in scope) {
      if (result.length >= cap) break;
      final c = cards[w.id];
      if (c == null || c.status == 0) result.add(w);
    }
    return result;
  }

  /// 到期待复习的词（是否启用由 settings.repeat 决定，调用方控制）
  List<Word> pickReviewWords({int? limit}) {
    final cap = limit ?? (settings.dailyNew * 2);
    final now = todayKey();
    final due = <CardState>[];
    for (final c in cards.values) {
      if (c.status != 1) continue;
      if (c.due == null || c.due!.compareTo(now) <= 0) due.add(c);
    }
    due.sort((a, b) => (a.due ?? '').compareTo(b.due ?? ''));
    final result = <Word>[];
    for (final c in due) {
      if (result.length >= cap) break;
      final w = bank[c.wordId];
      if (w != null) result.add(w);
    }
    return result;
  }

  /// 构建今天的任务；forceNewOnly = 首页「只背新词」入口
  StudySession buildSession({bool? repeatOverride}) {
    final repeat = repeatOverride ?? settings.repeat;
    final nw = pickNewWords();
    final rv = repeat ? pickReviewWords() : <Word>[];
    return StudySession(newWords: nw, reviewWords: rv);
  }

  // ---------------- 答题记录 ----------------
  /// 返回该词更新后的状态，供结果页展示
  Future<void> recordAnswer(Word w, bool correct, {bool isNew = false}) async {
    final c = cardOf(w.id);
    c.seen += 1;
    c.lastSeen = todayKey();
    if (correct) {
      c.correct += 1;
      c.stage = (c.stage + 1).clamp(0, kSrsIntervals.length);
      final days = kSrsIntervals[(c.stage - 1).clamp(0, kSrsIntervals.length - 1)];
      c.due = dateKey(DateTime.now().add(Duration(days: days)));
      c.status = c.stage >= 4 ? 2 : 1;
    } else {
      c.wrong += 1;
      c.stage = 0;
      c.due = todayKey();
      c.status = 1; // 仍算「学习中」，下次作为复习词出现
    }
    if (isNew && c.status == 0) c.status = 1;
    await store.upsertCard(c);
  }

  /// 一次考核结束：写入当天统计
  Future<void> finishSession({
    required int newCount,
    required int reviewCount,
    required int correct,
    required int wrong,
  }) async {
    await store.bumpDaily(
      date: todayKey(),
      newCnt: newCount,
      reviewCnt: reviewCount,
      correct: correct,
      wrong: wrong,
    );
    await store.markDone(todayKey());
    await refresh();
  }

  // ---------------- 收藏 / 掌握 ----------------
  Future<void> toggleFavorite(int wordId) async {
    final c = cardOf(wordId);
    c.favorite = !c.favorite;
    await store.upsertCard(c);
    notifyListeners();
  }

  Future<void> setMastered(int wordId, bool v) async {
    final c = cardOf(wordId);
    c.status = v ? 2 : 1;
    c.stage = v ? 5 : 1;
    c.due = dateKey(DateTime.now().add(Duration(days: v ? 30 : 1)));
    await store.upsertCard(c);
    notifyListeners();
  }

  Future<void> updateSettings(Settings s) async {
    settings = s;
    await store.saveSettings(s);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await store.resetProgress();
    cards = {};
    await refresh();
  }

  // ---------------- 统计 ----------------
  int get learnedCount => cards.values.where((c) => c.seen > 0).length;
  int get masteredCount => cards.values.where((c) => c.mastered).length;
  int get wrongCount => cards.values.where((c) => c.isWrong).length;
  int get favoriteCount => cards.values.where((c) => c.favorite).length;

  double get overallAccuracy {
    final total = cards.values.fold<int>(0, (s, c) => s + c.correct + c.wrong);
    if (total == 0) return 0;
    final ok = cards.values.fold<int>(0, (s, c) => s + c.correct);
    return ok / total;
  }

  List<Word> get wrongWords {
    final list = cards.values.where((c) => c.isWrong).toList()
      ..sort((a, b) => b.wrong.compareTo(a.wrong));
    return list.map((c) => bank[c.wordId]).whereType<Word>().toList();
  }

  List<Word> get favoriteWords {
    final list = cards.values.where((c) => c.favorite).toList();
    return list.map((c) => bank[c.wordId]).whereType<Word>().toList();
  }
}
