import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme.dart';
import '../data/app_env.dart';
import '../models/word.dart';
import '../services/tts_service.dart';
import '../widgets/common.dart';
import 'quiz_page.dart';

/// P3 新词卡：逐张看词 → 认识/不认识 → 全部看完进考核
class StudyPage extends StatefulWidget {
  final StudySession session;

  const StudyPage({super.key, required this.session});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  int _index = 0;
  bool _showMeaning = true;

  List<Word> get _items => widget.session.queue;
  Word get _current => _items[_index];

  Future<void> _next({required bool known}) async {
    final env = EnvScope.of(context);
    final word = _current;
    if (!known) {
      // 卡片阶段就标「不认识」：直接进错词池，下次复习优先出现
      await env.recordAnswer(word, false, isNew: widget.session.newWords.contains(word));
    }
    if (_index >= _items.length - 1) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizPage(
            words: _items,
            newIds: widget.session.newWords.map((e) => e.id).toSet(),
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _showMeaning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = _current;
    final isReview = widget.session.isReview(word);
    final progress = (_index + 1) / _items.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部：进度 + 关闭
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Text(
                    '${_index + 1}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    ' / ${_items.length}',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFEDEAE2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: '退出（进度已保存）',
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Pill(word.level,
                            color: AppColors.primary,
                            bg: const Color(0xFFEAF0EE)),
                        const SizedBox(width: 6),
                        Pill(word.posText),
                        if (isReview) ...[
                          const SizedBox(width: 6),
                          Pill('复习',
                              color: AppColors.accent,
                              bg: const Color(0xFFFAEEE7)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 单词 + 音标 + 发音
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            word.w,
                            style: const TextStyle(
                              fontSize: 38,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        SpeakerButton(word.w, size: 24),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      word.ipaText,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.muted, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 26),

                    // 释义
                    GestureDetector(
                      onTap: () => setState(() => _showMeaning = !_showMeaning),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F6F1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('释义',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                        letterSpacing: 1)),
                                const Spacer(),
                                Icon(
                                  _showMeaning
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 15,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showMeaning ? word.cn : '点一下看释义',
                              style: TextStyle(
                                fontSize: 19,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                                color: _showMeaning
                                    ? AppColors.ink
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 例句
                    if (word.ex.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const Text('例句',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(
                        word.ex,
                        style: const TextStyle(fontSize: 15, height: 1.7),
                      ),
                      if (word.exCn.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          word.exCn,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted, height: 1.6),
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => globalTts.speak(word.ex),
                        icon: const Icon(Icons.graphic_eq, size: 16),
                        label: const Text('朗读例句',
                            style: TextStyle(fontSize: 12.5)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _next(known: false),
                      child: const Text('不认识'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _next(known: true),
                      child: const Text('认识'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
