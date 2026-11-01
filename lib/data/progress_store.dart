import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// 本地进度库（SQLite）
/// 只存「用户数据」：每个词的学习状态、每日记录、设置
/// 词条本体在 assets 里，不重复入库
class ProgressStore {
  late final Database db;

  static const _dbName = 'oxford_vocab.db';

  Future<void> init() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cards(
            word_id INTEGER PRIMARY KEY,
            status INTEGER NOT NULL DEFAULT 0,
            seen INTEGER NOT NULL DEFAULT 0,
            correct INTEGER NOT NULL DEFAULT 0,
            wrong INTEGER NOT NULL DEFAULT 0,
            stage INTEGER NOT NULL DEFAULT 0,
            due TEXT,
            last_seen TEXT,
            favorite INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE daily(
            date TEXT PRIMARY KEY,
            new_cnt INTEGER NOT NULL DEFAULT 0,
            review_cnt INTEGER NOT NULL DEFAULT 0,
            correct INTEGER NOT NULL DEFAULT 0,
            wrong INTEGER NOT NULL DEFAULT 0,
            done INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE settings(
            k TEXT PRIMARY KEY,
            v TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------- 设置 ----------------
  Future<Settings> loadSettings() async {
    final rows = await db.query('settings');
    final map = {for (final r in rows) r['k'] as String: r['v'] as String};
    return Settings(
      onboarded: map['onboarded'] == '1',
      level: map['level'] ?? 'all',
      dailyNew: int.tryParse(map['daily_new'] ?? '') ?? 20,
      repeat: (map['repeat'] ?? '1') == '1',
      accent: map['accent'] ?? 'US',
    );
  }

  Future<void> saveSettings(Settings s) async {
    final batch = db.batch();
    void put(String k, String v) {
      batch.insert('settings', {'k': k, 'v': v},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    put('onboarded', s.onboarded ? '1' : '0');
    put('level', s.level);
    put('daily_new', s.dailyNew.toString());
    put('repeat', s.repeat ? '1' : '0');
    put('accent', s.accent);
    await batch.commit(noResult: true);
  }

  // ---------------- 学习卡状态 ----------------
  Future<Map<int, CardState>> loadCards() async {
    final rows = await db.query('cards');
    return {
      for (final r in rows) (r['word_id'] as int): CardState.fromMap(r),
    };
  }

  Future<void> upsertCard(CardState c) async {
    await db.insert('cards', c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------------- 每日记录 ----------------
  Future<DailyStat?> statOf(String date) async {
    final rows =
        await db.query('daily', where: 'date = ?', whereArgs: [date], limit: 1);
    if (rows.isEmpty) return null;
    return DailyStat.fromMap(rows.first);
  }

  Future<void> bumpDaily({
    required String date,
    int newCnt = 0,
    int reviewCnt = 0,
    int correct = 0,
    int wrong = 0,
  }) async {
    final cur = await statOf(date);
    final next = DailyStat(
      date: date,
      newCnt: (cur?.newCnt ?? 0) + newCnt,
      reviewCnt: (cur?.reviewCnt ?? 0) + reviewCnt,
      correct: (cur?.correct ?? 0) + correct,
      wrong: (cur?.wrong ?? 0) + wrong,
      done: cur?.done ?? false,
    );
    await db.insert('daily', {
      'date': next.date,
      'new_cnt': next.newCnt,
      'review_cnt': next.reviewCnt,
      'correct': next.correct,
      'wrong': next.wrong,
      'done': next.done ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markDone(String date) async {
    final cur = await statOf(date);
    await db.insert('daily', {
      'date': date,
      'new_cnt': cur?.newCnt ?? 0,
      'review_cnt': cur?.reviewCnt ?? 0,
      'correct': cur?.correct ?? 0,
      'wrong': cur?.wrong ?? 0,
      'done': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DailyStat>> recentDays(int days) async {
    final rows = await db.query('daily', orderBy: 'date DESC', limit: days);
    return rows.map(DailyStat.fromMap).toList();
  }

  /// 连续打卡天数（从今天往回数）
  Future<int> streak() async {
    final rows = await db.query('daily',
        where: 'done = 1', orderBy: 'date DESC', limit: 400);
    if (rows.isEmpty) return 0;
    final dates = rows.map((r) => r['date'] as String).toSet();
    var streak = 0;
    var cursor = DateTime.now();
    // 今天没打卡不算断，从昨天开始数
    if (!dates.contains(_fmt(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (dates.contains(_fmt(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---------------- 维护 ----------------
  Future<void> resetProgress() async {
    await db.delete('cards');
    await db.delete('daily');
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
