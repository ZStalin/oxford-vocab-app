import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme.dart';
import '../data/app_env.dart';
import '../widgets/common.dart';

/// P9 我的：统计、打卡日历、设置
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _pickDaily(BuildContext context, int current) async {
    final env = EnvScope.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('每天背多少新词',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            for (final n in [10, 20, 30, 50, 80])
              ListTile(
                title: Text('$n 个',
                    style: const TextStyle(fontSize: 14.5)),
                trailing: n == current
                    ? const Icon(Icons.check, size: 18, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(n),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await env.updateSettings(env.settings.copyWith(dailyNew: picked));
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final env = EnvScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空学习数据？'),
        content: const Text('会删除所有学习记录、错词和打卡，词库本身不受影响。此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认清空', style: TextStyle(color: AppColors.bad)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await env.resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('已清空学习数据'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = EnvScope.of(context);
    final s = env.settings;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const Text('我的',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),

            // 四个统计
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        value: '${env.learnedCount}', label: '累计学过')),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        _StatCard(value: '${env.masteredCount}', label: '已掌握')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        value: '${env.streakDays}',
                        label: '连续打卡',
                        accent: true)),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: env.overallAccuracy == 0
                        ? '—'
                        : '${(env.overallAccuracy * 100).round()}%',
                    label: '总正确率',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const SectionLabel('最近 5 周'),
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: _Calendar(doneDays: env.doneDays),
            ),
            const SizedBox(height: 24),

            const SectionLabel('设置'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('每天新词量',
                        style: TextStyle(fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${s.dailyNew} 个',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.muted)),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.muted),
                      ],
                    ),
                    onTap: () => _pickDaily(context, s.dailyNew),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('重复', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      s.repeat ? '新词 + 待复习旧词混排' : '每天只考没学过的新词',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.muted),
                    ),
                    value: s.repeat,
                    onChanged: (v) =>
                        env.updateSettings(s.copyWith(repeat: v)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('词库范围',
                        style: TextStyle(fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.levelText,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.muted)),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.muted),
                      ],
                    ),
                    onTap: () async {
                      final picked = await showModalBottomSheet<String>(
                        context: context,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final o in [
                                ('all', '全部词库', env.bank.countOf('all')),
                                ('B2', 'B2 基础', env.bank.countOf('B2')),
                                ('C1', 'C1 进阶', env.bank.countOf('C1')),
                              ])
                                ListTile(
                                  title: Text(o.$2,
                                      style: const TextStyle(fontSize: 14.5)),
                                  subtitle: Text('${o.$3} 词',
                                      style: const TextStyle(fontSize: 11.5)),
                                  trailing: s.level == o.$1
                                      ? const Icon(Icons.check,
                                          size: 18, color: AppColors.primary)
                                      : null,
                                  onTap: () =>
                                      Navigator.of(context).pop(o.$1),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                      if (picked != null) {
                        await env.updateSettings(s.copyWith(level: picked));
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('发音口音',
                        style: TextStyle(fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final a in ['US', 'UK'])
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: GestureDetector(
                              onTap: () => env
                                  .updateSettings(s.copyWith(accent: a)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: s.accent == a
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: s.accent == a
                                          ? AppColors.primary
                                          : AppColors.line),
                                ),
                                child: Text(
                                  a == 'US' ? '美音' : '英音',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: s.accent == a
                                        ? Colors.white
                                        : AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SectionLabel('数据'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('清空学习数据',
                    style: TextStyle(fontSize: 14, color: AppColors.bad)),
                onTap: () => _confirmReset(context),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text('牛津 5000 背单词 · v1.0',
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(
                    '词表：Oxford University Press\nThe Oxford 5000™ by CEFR level（B2 / C1）',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10.5, color: AppColors.muted, height: 1.6),
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;

  const _StatCard({required this.value, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: accent ? AppColors.accent : AppColors.ink,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// 打卡日历：最近 35 天，学过的日子填色
class _Calendar extends StatelessWidget {
  final Map<String, bool> doneDays;

  const _Calendar({required this.doneDays});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 34));
    const week = ['一', '二', '三', '四', '五', '六', '日'];

    return Column(
      children: [
        Row(
          children: week
              .map((w) => Expanded(
                    child: Center(
                      child: Text(w,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.muted)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: List.generate(35, (i) {
            final d = start.add(Duration(days: i));
            final done = doneDays[dateKey(d)] ?? false;
            final isToday = dateKey(d) == dateKey(today);
            return Container(
              decoration: BoxDecoration(
                color: done
                    ? AppColors.primary
                    : const Color(0xFFF3F1EA),
                borderRadius: BorderRadius.circular(7),
                border: isToday
                    ? Border.all(color: AppColors.accent, width: 1.2)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${d.day}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: done ? Colors.white : AppColors.muted,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
