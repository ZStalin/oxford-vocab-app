import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/word.dart';

/// 词库：启动时把 assets/data/words.json 全部读进内存
/// 1995 个词条约 400KB，内存占用可忽略，换来筛选/搜索/取干扰项毫秒级响应
class WordBank {
  final List<Word> all;
  final Map<int, Word> byId;

  WordBank._(this.all, this.byId);

  static Future<WordBank> load() async {
    final raw = await rootBundle.loadString('assets/data/words.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final list = (data['words'] as List)
        .map((e) => Word.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return WordBank._(list, {for (final w in list) w.id: w});
  }

  Word? operator [](int id) => byId[id];

  int countOf(String level) {
    if (level == 'all') return all.length;
    return all.where((w) => w.level == level).length;
  }

  List<Word> byLevel(String level) =>
      level == 'all' ? all : all.where((w) => w.level == level).toList();

  /// 按关键词搜索（英文前缀优先，其次中文释义包含）
  List<Word> search(String keyword, String level) {
    final kw = keyword.trim().toLowerCase();
    final scope = byLevel(level);
    if (kw.isEmpty) return scope;
    final starts = <Word>[];
    final contains = <Word>[];
    for (final w in scope) {
      if (w.w.startsWith(kw)) {
        starts.add(w);
      } else if (w.w.contains(kw) || w.cn.contains(kw)) {
        contains.add(w);
      }
    }
    return [...starts, ...contains];
  }

  /// 给四选一生成干扰项：优先同级、词性接近、释义不重复的词
  List<String> buildOptions(Word target, {int total = 4}) {
    final sameLevel = all
        .where((w) => w.id != target.id && w.level == target.level)
        .toList()
      ..shuffle();
    final options = <String>[target.cn];
    for (final w in sameLevel) {
      if (options.length >= total) break;
      if (w.cn.isEmpty || options.contains(w.cn)) continue;
      // 避免释义高度重合（如「废除；取消」与「废除」）
      final dup = options.any((o) =>
          o.contains(w.cn) || w.cn.contains(o) || _shareSense(o, w.cn));
      if (!dup) options.add(w.cn);
    }
    options.shuffle();
    return options;
  }

  bool _shareSense(String a, String b) {
    final sa = a.split('；').map((e) => e.trim()).toSet();
    final sb = b.split('；').map((e) => e.trim()).toSet();
    return sa.intersection(sb).isNotEmpty;
  }
}
