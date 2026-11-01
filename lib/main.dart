import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 竖屏 + 状态栏透明，卡片式 App 不需要横屏
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 启动前把词库、进度、设置全部准备好，页面里就不必处理 loading 态
  final env = await AppEnv.bootstrap();

  runApp(OxfordApp(env: env));
}
