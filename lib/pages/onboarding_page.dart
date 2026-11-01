import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';

/// P1 首次引导：选词库、定每天词量、决定是否「重复」
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String _level = 'all';
  int _daily = 20;
  bool _repeat = true;

  @override
  Widget build(BuildContext context) {
    final env = EnvScope.of(context);
    final options = [
      ('all', '全部词库', env.bank.countOf('all'), 'B2 + C1 一次打通'),
      ('B2', 'B2 基础', env.bank.countOf('B2'), '先啃常见学术词'),
      ('C1', 'C1 进阶', env.bank.countOf('C1'), '冲高分必备'),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            const Text(
              '你好，\n从今天开始。',
              style: TextStyle(
                fontSize: 30,
                height: 1.35,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '牛津 5000 · 共 ${env.bank.all.length} 词\n每天定量背，答错的词自动进复习池',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            const SectionLabel('选择词库'),
            ...options.map((o) {
              final selected = _level == o.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _level = o.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF0F4F2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.line,
                        width: selected ? 1.2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    o.$2,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  Pill('${o.$3} 词'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o.$4,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: selected ? AppColors.primary : AppColors.line,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 22),
            const SectionLabel('每天背多少新词', trailing: '可随时修改'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [10, 20, 30, 50].map((n) {
                final selected = _daily == n;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _daily = n),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected ? AppColors.primary : AppColors.line),
                    ),
                    child: Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            const SectionLabel('复习模式'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('重复',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          _repeat
                              ? '每天混入背过的词一起考，记得更牢'
                              : '每天只考没学过的新词',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _repeat,
                    onChanged: (v) => setState(() => _repeat = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await env.updateSettings(Settings(
                  onboarded: true,
                  level: _level,
                  dailyNew: _daily,
                  repeat: _repeat,
                  accent: 'US',
                ));
              },
              child: const Text('开始背单词'),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '词表来源：Oxford University Press · The Oxford 5000™',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
