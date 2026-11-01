import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme.dart';
import '../data/app_env.dart';
import '../models/word.dart';
import '../widgets/common.dart';
import 'study_page.dart';

/// P2 首页：今日任务 + 进度环 + 打卡状态
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _start(BuildContext context, {bool? repeatOverride}) async {
    final env = EnvScope.of(context);
    final session = env.buildSession(repeatOverride: repeatOverride);
    if (session.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('今天没有待学的词了，去词库翻翻吧'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StudyPage(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = EnvScope.of(context);
    final daily = env.settings.dailyNew;
    final done = env.today.newCnt.clamp(0, daily);
    final progress = daily == 0 ? 0.0 : done / daily;

    final newWords = env.pickNewWords();
    final reviewWords = env.settings.repeat ? env.pickReviewWords() : <Word>[];
    final quotaLeft = env.newQuotaLeft;

    final now = DateTime.now();
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: env.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              // 顶部：日期 + 连续打卡
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '今天',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w600, height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${now.month} 月 ${now.day} 日 · 周${weekdays[now.weekday - 1]}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          '${env.streakDays} 天',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 进度环 + 开始学习
              AppCard(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                child: Column(
                  children: [
                    SizedBox(
                      width: 148,
                      height: 148,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 148,
                            height: 148,
                            child: CircularProgressIndicator(
                              value: progress.toDouble(),
                              strokeWidth: 9,
                              backgroundColor: const Color(0xFFEDEAE2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$done',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '今日新词 / $daily',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MiniStat(label: '新词', value: '${newWords.length}'),
                        Container(
                            width: 1,
                            height: 22,
                            color: AppColors.line,
                            margin: const EdgeInsets.symmetric(horizontal: 22)),
                        _MiniStat(
                          label: env.settings.repeat ? '复习' : '复习（已关闭）',
                          value: env.settings.repeat ? '${reviewWords.length}' : '—',
                        ),
                        Container(
                            width: 1,
                            height: 22,
                            color: AppColors.line,
                            margin: const EdgeInsets.symmetric(horizontal: 22)),
                        _MiniStat(label: '连续', value: '${env.streakDays}'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: () => _start(context),
                      child: Text(
                        newWords.isEmpty && reviewWords.isEmpty
                            ? '今天已完成'
                            : '开始学习',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed:
                              quotaLeft > 0 ? () => _start(context, repeatOverride: false) : null,
                          child: const Text('只背新词',
                              style: TextStyle(fontSize: 13)),
                        ),
                        Text(
                          env.settings.repeat ? '· 当前开启重复' : '· 当前仅新词',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              const SectionLabel('学习节奏'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      title: '词库',
                      value: env.settings.levelText,
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.repeat,
                      title: '重复',
                      value: env.settings.repeat ? '已开启 · 新旧混排' : '已关闭 · 只考新词',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.check_circle_outline,
                      title: '累计学过',
                      value: '${env.learnedCount} / ${env.bank.all.length}',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.insights_outlined,
                      title: '总正确率',
                      value: env.overallAccuracy == 0
                          ? '—'
                          : '${(env.overallAccuracy * 100).round()}%',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (env.today.correct + env.today.wrong > 0)
                Center(
                  child: Text(
                    '今天已答 ${env.today.correct + env.today.wrong} 题 · 正确 ${env.today.correct} · 错误 ${env.today.wrong}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.muted),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 13.5)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      ],
    );
  }
}
