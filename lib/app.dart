import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/app_env.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/notebook_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/profile_page.dart';
import 'services/tts_service.dart';

/// 把 AppEnv 注入到整棵组件树，页面里用 EnvScope.of(context) 取
class EnvScope extends InheritedNotifier<AppEnv> {
  EnvScope({super.key, required AppEnv env, required super.child})
      : super(notifier: env);

  static AppEnv of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EnvScope>();
    assert(scope != null, 'EnvScope 未找到，检查 main.dart 是否包裹');
    return scope!.notifier!;
  }
}

class OxfordApp extends StatelessWidget {
  final AppEnv env;

  const OxfordApp({super.key, required this.env});

  @override
  Widget build(BuildContext context) {
    globalTts.accent = env.settings.accent;
    return EnvScope(
      env: env,
      child: MaterialApp(
        title: '牛津 5000',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: ListenableBuilder(
          listenable: env,
          builder: (context, _) {
            globalTts.accent = env.settings.accent;
            return env.settings.onboarded
                ? const RootShell()
                : const OnboardingPage();
          },
        ),
      ),
    );
  }
}

/// 四个底部 Tab 的容器
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      HomePage(),
      LibraryPage(),
      NotebookPage(),
      ProfilePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: const Color(0x1A1F4B43), // primary 10% 透明
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '词库',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: '生词本',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
