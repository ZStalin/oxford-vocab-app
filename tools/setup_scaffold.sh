#!/usr/bin/env bash
# 一键生成 Android / iOS 平台脚手架
# 用法：双击或在项目根目录执行  bash tools/setup_scaffold.sh
set -e

APP_NAME="oxford_vocab"
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "✗ 没检测到 flutter 命令。"
  echo "  请先安装 Flutter SDK 并把 flutter/bin 加入 PATH：https://docs.flutter.dev/get-started/install"
  exit 1
fi

echo "→ Flutter 版本："
flutter --version | head -2

echo "→ 生成平台目录（android / ios）..."
rm -rf .scaffold
flutter create --org com.example --project-name "$APP_NAME" --platforms=android,ios .scaffold

# 只取平台目录，lib/ 和 pubspec.yaml 保留我们自己写的
cp -r .scaffold/android .
cp -r .scaffold/ios .
[ -f .scaffold/.metadata ] && cp .scaffold/.metadata .
[ -f .scaffold/analysis_options.yaml ] && [ ! -f analysis_options.yaml ] && cp .scaffold/analysis_options.yaml .
rm -rf .scaffold

# 顺手把桌面显示名改成中文（失败也不影响构建）
if [ -f android/app/src/main/AndroidManifest.xml ]; then
  sed -i.bak 's/android:label="[^"]*"/android:label="牛津 5000"/' android/app/src/main/AndroidManifest.xml && rm -f android/app/src/main/AndroidManifest.xml.bak
fi
if [ -f ios/Runner/Info.plist ]; then
  /usr/bin/plutil -replace CFBundleDisplayName -string "牛津 5000" ios/Runner/Info.plist 2>/dev/null || true
fi

echo "→ 拉取依赖..."
flutter pub get

echo ""
echo "✓ 完成。接下来："
echo "  flutter devices        # 看有没有连上手机 / 模拟器"
echo "  flutter run            # 调试运行"
echo "  flutter build apk --release   # 打安卓包"
