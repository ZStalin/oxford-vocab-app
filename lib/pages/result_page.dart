import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/word.dart';
import '../widgets/common.dart';
import 'quiz_page.dart';

/// P5 结算页
class ResultPage extends StatelessWidget {
  final int total;
  final int correct;
  final List<Word> wrongWords;
  final int seconds;
  final int newCount;

  const ResultPage({
    super.key,
    required this.total,
    required this.correct,
    required this.wrongWords,
    required this.seconds,
    required this.newCount,
  });

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0.0 : correct / total;
    final m = seconds ~/ 60;
    final s = seconds % 60;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
          children: [
            const Text('今天完成',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 8),
            Text(
              '${(rate * 100).round()}%',
              style: const TextStyle(
                  fontSize: 56, fontWeight: FontWeight.w600, height: 1.0),
            ),
            const SizedBox(height: 6),
            Text(
              '共 $total 词 · 答对 $correct · 用时 $m 分 $s 秒',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 26),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(child: _Stat(label: '新词', value: '$newCount')),
                  Container(width: 1, height: 30, color: AppColors.line),
                  Expanded(child: _Stat(label: '复习', value: '${total - newCount}')),
                  Container(width: 1, height: 30, color: AppColors.line),
                  Expanded(
                      child: _Stat(label: '错词', value: '${wrongWords.length}')),
                ],
              ),
            ),
            const SizedBox(height: 26),
            if (wrongWords.isNotEmpty) ...[
              SectionLabel('这批错的词', trailing: '${wrongWords.length} 个'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: wrongWords
                      .take(6)
                      .map((w) => WordRow(word: w, onTap: () {}))
                      .toList(),
                ),
              ),
            ] else
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: AppColors.ok),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '全对，这一批词可以放心了',
                        style: TextStyle(fontSize: 13.5, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
            if (wrongWords.isNotEmpty)
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          QuizPage(words: wrongWords, newIds: const {}),
                    ),
                  );
                },
                child: Text('再练这 ${wrongWords.length} 个错词'),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('完成打卡'),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '连续打卡已记录，明天继续',
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}
