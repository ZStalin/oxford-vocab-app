import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme.dart';
import '../models/word.dart';
import '../widgets/common.dart';
import 'quiz_page.dart';
import 'word_detail_page.dart';

/// P8 生词本：收藏 + 错词
class NotebookPage extends StatelessWidget {
  const NotebookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final env = EnvScope.of(context);
    final favs = env.favoriteWords;
    final wrongs = env.wrongWords;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('生词本'),
          bottom: TabBar(
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            tabs: [
              Tab(text: '收藏 ${favs.length}'),
              Tab(text: '错词 ${wrongs.length}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _List(
              words: favs,
              emptyTitle: '还没有收藏的词',
              emptyHint: '在词库里点书签图标，把想再看的词收进来',
            ),
            _List(
              words: wrongs,
              emptyTitle: '还没有错词',
              emptyHint: '答错的词会自动进这里，随时回来重刷',
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  final List<Word> words;
  final String emptyTitle;
  final String emptyHint;

  const _List({
    required this.words,
    required this.emptyTitle,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    final env = EnvScope.of(context);
    if (words.isEmpty) {
      return EmptyHint(
        icon: Icons.bookmark_border,
        title: emptyTitle,
        subtitle: emptyHint,
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizPage(
                    words: List<Word>.from(words),
                    newIds: const {},
                  ),
                ),
              );
            },
            child: Text('开始复习这 ${words.length} 个词'),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: words.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.line),
            itemBuilder: (context, i) {
              final w = words[i];
              return WordRow(
                word: w,
                state: env.cards[w.id],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => WordDetailPage(word: w)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
