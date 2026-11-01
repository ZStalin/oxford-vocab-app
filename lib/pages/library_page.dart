import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme.dart';
import '../data/app_env.dart';
import '../models/word.dart';
import '../widgets/common.dart';
import 'word_detail_page.dart';

/// P6 词库：搜索 + 级别筛选 + 学习状态筛选
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _controller = TextEditingController();
  String _level = 'all';
  String _status = 'all'; // all / new / learning / wrong / fav

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Word> _filter(AppEnv env) {
    var list = env.bank.search(_controller.text, _level);
    if (_status == 'all') return list;
    return list.where((w) {
      final c = env.cards[w.id];
      switch (_status) {
        case 'new':
          return c == null || c.status == 0;
        case 'learning':
          return c != null && c.status == 1;
        case 'wrong':
          return c != null && c.isWrong;
        case 'fav':
          return c?.favorite == true;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final env = EnvScope.of(context);
    final list = _filter(env);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('词库',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('${env.bank.all.length} 词',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '搜索单词或中文释义',
                      hintStyle: const TextStyle(
                          fontSize: 13.5, color: AppColors.muted),
                      prefixIcon: const Icon(Icons.search, size: 19),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('全部级别', _level == 'all',
                            () => setState(() => _level = 'all')),
                        _chip('B2', _level == 'B2',
                            () => setState(() => _level = 'B2')),
                        _chip('C1', _level == 'C1',
                            () => setState(() => _level = 'C1')),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 16, color: AppColors.line),
                        const SizedBox(width: 10),
                        _chip('全部', _status == 'all',
                            () => setState(() => _status = 'all')),
                        _chip('未学', _status == 'new',
                            () => setState(() => _status = 'new')),
                        _chip('学习中', _status == 'learning',
                            () => setState(() => _status = 'learning')),
                        _chip('错词', _status == 'wrong',
                            () => setState(() => _status = 'wrong')),
                        _chip('收藏', _status == 'fav',
                            () => setState(() => _status = 'fav')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? const EmptyHint(
                      icon: Icons.search_off,
                      title: '没有找到匹配的词',
                      subtitle: '换个关键词，或把筛选条件放宽一点',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.line),
                      itemBuilder: (context, i) {
                        final w = list[i];
                        return WordRow(
                          word: w,
                          state: env.cards[w.id],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => WordDetailPage(word: w)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: active ? Colors.white : AppColors.muted,
              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
