import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme.dart';
import '../models/word.dart';
import '../services/tts_service.dart';
import '../widgets/common.dart';

/// P7 单词详情
class WordDetailPage extends StatelessWidget {
  final Word word;

  const WordDetailPage({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final env = EnvScope.of(context);
    final c = env.cards[word.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(word.level),
        actions: [
          IconButton(
            tooltip: c?.favorite == true ? '取消收藏' : '加入生词本',
            onPressed: () => env.toggleFavorite(word.id),
            icon: Icon(
              c?.favorite == true ? Icons.bookmark : Icons.bookmark_border,
              color: c?.favorite == true ? AppColors.accent : AppColors.ink,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  word.w,
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              SpeakerButton(word.w, size: 24),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(word.ipaText,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              const SizedBox(width: 10),
              Text(word.posText,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic)),
            ],
          ),
          if (word.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('词表原注：${word.note}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
          const SizedBox(height: 24),
          const SectionLabel('释义'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < word.senses.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (word.senses.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 8),
                            child: Text('${i + 1}.',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ),
                        Expanded(
                          child: Text(
                            word.senses[i],
                            style: const TextStyle(fontSize: 16, height: 1.55),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (word.ex.isNotEmpty) ...[
            const SizedBox(height: 22),
            const SectionLabel('例句'),
            Text(word.ex, style: const TextStyle(fontSize: 15, height: 1.7)),
            const SizedBox(height: 6),
            Text(word.exCn,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.muted, height: 1.6)),
            TextButton.icon(
              onPressed: () => globalTts.speak(word.ex),
              icon: const Icon(Icons.graphic_eq, size: 16),
              label: const Text('朗读', style: TextStyle(fontSize: 12.5)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
          const SizedBox(height: 22),
          const SectionLabel('学习记录'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    _KV(label: '学过', value: '${c?.seen ?? 0} 次'),
                    _KV(label: '答对', value: '${c?.correct ?? 0}'),
                    _KV(label: '答错', value: '${c?.wrong ?? 0}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('下次复习',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.muted)),
                    const Spacer(),
                    Text(c?.due ?? '按计划自动安排',
                        style: const TextStyle(fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => env.setMastered(word.id, !(c?.mastered ?? false)),
            icon: Icon(
              c?.mastered == true ? Icons.undo : Icons.check,
              size: 17,
            ),
            label: Text(c?.mastered == true ? '取消「已掌握」' : '标记为已掌握'),
          ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;

  const _KV({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}
