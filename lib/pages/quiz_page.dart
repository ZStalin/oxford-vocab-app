import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme.dart';
import '../models/word.dart';
import '../widgets/common.dart';
import 'result_page.dart';

/// P4 四选一考核：看英文选中文
class QuizPage extends StatefulWidget {
  final List<Word> words;
  final Set<int> newIds;

  const QuizPage({super.key, required this.words, required this.newIds});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _index = 0;
  String? _picked;
  bool _answered = false;
  bool _locked = false;
  final List<Word> _wrongWords = [];
  int _correct = 0;
  late DateTime _startAt;
  Timer? _timer;

  Word get _current => widget.words[_index];

  // 选项在需要时生成：同一题的 4 个选项在一次作答内保持不变
  List<String>? _optionsCache;

  List<String> _optionsOf(BuildContext context) =>
      _optionsCache ??= EnvScope.of(context).bank.buildOptions(_current);

  @override
  void initState() {
    super.initState();
    _startAt = DateTime.now();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _choose(String option) async {
    if (_answered || _locked) return;
    final env = EnvScope.of(context);
    final ok = option == _current.cn;
    setState(() {
      _picked = option;
      _answered = true;
      _locked = true;
      if (ok) _correct++;
    });
    if (!ok) _wrongWords.add(_current);

    await env.recordAnswer(_current, ok, isNew: widget.newIds.contains(_current.id));

    // 答对自动过，答错停下来看正确答案
    _timer = Timer(Duration(milliseconds: ok ? 620 : 1400), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    if (_index >= widget.words.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _picked = null;
      _answered = false;
      _locked = false;
      _optionsCache = null;
    });
  }

  Future<void> _finish() async {
    final env = EnvScope.of(context);
    final total = widget.words.length;
    await env.finishSession(
      newCount: widget.newIds.length,
      reviewCount: total - widget.newIds.length,
      correct: _correct,
      wrong: total - _correct,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultPage(
          total: total,
          correct: _correct,
          wrongWords: _wrongWords,
          seconds: DateTime.now().difference(_startAt).inSeconds,
          newCount: widget.newIds.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = _current;
    final progress = (_index + 1) / widget.words.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text('${_index + 1}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(' / ${widget.words.length}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.muted)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFEDEAE2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('正确 $_correct',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('选出正确的中文释义',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            word.w,
                            style: const TextStyle(
                              fontSize: 40,
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
                    Text(word.ipaText,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.muted)),
                    const SizedBox(height: 30),
                    ..._optionsOf(context).map(_buildOption),
                    const SizedBox(height: 18),
                    if (_answered && _picked != word.cn)
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        color: const Color(0xFFFBF2EF),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                size: 18, color: AppColors.bad),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${word.w} = ${word.cn}',
                                style: const TextStyle(
                                    fontSize: 13.5, height: 1.5),
                              ),
                            ),
                            TextButton(
                              onPressed: _goNext,
                              child: const Text('继续',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String option) {
    final isTarget = option == _current.cn;
    final isPicked = option == _picked;

    Color bg = AppColors.surface;
    Color border = AppColors.line;
    Color text = AppColors.ink;
    IconData? icon;

    if (_answered) {
      if (isTarget) {
        bg = const Color(0xFFEDF6F0);
        border = AppColors.ok;
        text = AppColors.ok;
        icon = Icons.check_circle;
      } else if (isPicked) {
        bg = const Color(0xFFFBEFEC);
        border = AppColors.bad;
        text = AppColors.bad;
        icon = Icons.cancel;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _answered ? null : () => _choose(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: _answered && (isTarget || isPicked) ? 1.2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                      fontSize: 15.5, height: 1.4, color: text),
                ),
              ),
              if (icon != null) Icon(icon, size: 18, color: text),
            ],
          ),
        ),
      ),
    );
  }
}
