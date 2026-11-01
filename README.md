# 牛津 5000 背单词

基于你导入的 **《The Oxford 5000 by CEFR level》** 词表做的离线背单词 App，交互逻辑仿百词斩：
每天定量学新词 → 逐张看词卡 → 四选一考核 → 答错自动进错词池 → 打卡。

Flutter 一套代码，同时出 Android APK 与 iOS IPA。

---

## 一、这个版本做了什么

| 项 | 内容 |
|---|---|
| 词库 | **1995 词**（B2 699 / C1 1296），从你给的 PDF 逐条解析，15 组跨级同词已合并词性 |
| 数据字段 | 单词、词性、CEFR 级别、美音音标、中文释义（雅思托福常考义）、英文例句 + 中文翻译 |
| 考核 | 英→中 四选一，答错立刻高亮正确答案并提示 |
| 「重复」 | 开启＝今天的新词 + 到期的旧词混排；关闭＝只考没学过的新词。首页另有「只背新词」快捷入口 |
| 复习算法 | 答对进一档，间隔 1 / 2 / 4 / 7 / 15 / 30 天；答错归零并回到今天 |
| 页面 | 引导、首页、新词卡、考核、结算、词库、单词详情、生词本、我的（共 9 屏） |
| 离线 | 全离线可用，无登录、无后端；发音调用系统 TTS |
| 权限 | 仅本地存储。不要相机、相册、定位、麦克风、网络 |

## 二、目录结构

```
oxford_vocab_app/
├── pubspec.yaml                    # 依赖：sqflite / path / flutter_tts
├── analysis_options.yaml
├── assets/data/words.json          # ★ 词库（1995 条，350KB，已含释义/音标/例句）
├── lib/
│   ├── main.dart                   # 入口：启动前加载词库与进度
│   ├── app.dart                    # EnvScope 状态注入 + 底部 4 Tab 容器
│   ├── core/theme.dart             # 配色与全局主题（米白 + 墨绿）
│   ├── models/
│   │   ├── word.dart               # 词条模型
│   │   └── models.dart             # 设置 / 学习卡状态 / 每日记录
│   ├── data/
│   │   ├── word_bank.dart          # 词库加载、搜索、四选一干扰项生成
│   │   ├── progress_store.dart     # SQLite：进度、打卡、设置
│   │   └── app_env.dart            # 全局状态：抽词、记分、统计
│   ├── services/tts_service.dart   # 系统 TTS 发音（英美音可切）
│   ├── widgets/common.dart         # 卡片 / 标签 / 发音按钮 / 列表行
│   └── pages/
│       ├── onboarding_page.dart    # P1 首次引导
│       ├── home_page.dart          # P2 首页
│       ├── study_page.dart         # P3 新词卡
│       ├── quiz_page.dart          # P4 四选一
│       ├── result_page.dart        # P5 结算
│       ├── library_page.dart       # P6 词库
│       ├── word_detail_page.dart   # P7 单词详情
│       ├── notebook_page.dart      # P8 生词本 / 错词本
│       └── profile_page.dart       # P9 统计 + 设置
└── tools/
    ├── parse_pdf.py                # PDF → base.json（单词/词性/级别）
    ├── build_words.py              # 合并释义 + 音标 + 例句 → words.json
    ├── setup_scaffold.sh           # 一键生成 android / ios 平台目录
    └── cn_*.txt / ex_*.txt         # 释义、例句的中间数据（可改后重跑）
```

## 三、跑起来（3 步）

### 1. 装 Flutter

- 下载 SDK：https://docs.flutter.dev/get-started/install
- 装好后终端执行 `flutter doctor`，确保没有红叉
- 安卓要装 Android Studio（含 SDK + 一台模拟器，或一部开了「USB 调试」的手机）
- iOS 只能在 macOS 上打包，需要 Xcode

### 2. 生成平台目录

```bash
cd oxford_vocab_app
bash tools/setup_scaffold.sh
```

脚本会调 `flutter create` 生成 `android/` `ios/`（你的 `lib/`、`pubspec.yaml` 不会被覆盖），然后自动 `flutter pub get`。

### 3. 运行

```bash
flutter devices      # 确认设备已连接
flutter run          # 调试运行
```

> 首次启动会读 `assets/data/words.json`（1995 条）建本地库，约 1 秒。

## 四、打包安卓 APK

### 4.1 直接出测试包（最快）

```bash
flutter build apk --release
```

产物：`build/app/outputs/flutter-apk/app-release.apk`，拷到手机安装即可（需允许「安装未知来源应用」）。

> 不配签名也能出包，用的是 Flutter 自带 debug 签名，能装能跑，但不能上架、也不能覆盖升级。

### 4.2 正式签名包（推荐）

**① 生成密钥库**（只做一次，密码务必记住）

```bash
keytool -genkey -v -keystore ~/oxford-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias oxford
```

**② 项目根目录新建 `android/key.properties`**

```properties
storePassword=你的密码
keyPassword=你的密码
keyAlias=oxford
storeFile=C:/Users/你/oxford-key.jks
```

**③ 改 `android/app/build.gradle`**（新版是 `build.gradle.kts`）

```gradle
// 文件顶部
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**④ 打包**

```bash
flutter build apk --release
# 或按 CPU 架构分包，体积更小
flutter build apk --split-per-abi
```

### 4.3 装到手机

- USB 连电脑：`flutter install`
- 或把 APK 传到手机，文件管理器点开安装

## 五、打包 iOS IPA

> 必须有 macOS + Xcode + 苹果开发者账号（免费账号只能装 7 天，付费 99 美元/年可上 TestFlight）。

```bash
cd oxford_vocab_app
flutter build ios --release          # 生成 Xcode 工程产物
open ios/Runner.xcworkspace          # 用 Xcode 打开
```

Xcode 里：

1. 左侧选中 `Runner` → `Signing & Capabilities`
2. `Team` 选你的开发者账号，`Bundle Identifier` 改成唯一的（如 `com.你的名字.oxfordvocab`）
3. 顶部设备选 `Any iOS Device (arm64)`
4. 菜单 `Product → Archive`
5. 归档完成后在 Organizer 里点 `Distribute App` → `Ad Hoc`（装指定设备）或 `App Store Connect`（走 TestFlight 分发）

命令行直出 IPA（已配好签名时）：

```bash
flutter build ipa --release
# 产物：build/ios/ipa/*.ipa
```

## 六、常见报错对照表

| 报错 | 原因与处理 |
|---|---|
| `cmdline-tools component is missing` | Android Studio → SDK Manager → SDK Tools 勾选 **Android SDK Command-line Tools** 安装 |
| `CocoaPods not installed` | macOS 执行 `sudo gem install cocoapods`，再 `cd ios && pod install` |
| `Gradle build failed` / 各种红字 | `flutter clean` → `flutter pub get` → 重新 `flutter run`；仍失败看 `android/` 下 gradle 版本是否与 Android Studio 匹配 |
| `Execution failed for task ':app:...'` 关于 minSdk | 打开 `android/app/build.gradle`，把 `minSdkVersion` 提到 **21** 以上（sqflite 要求） |
| `Keystore was tampered with, or password was incorrect` | `key.properties` 里密码写错，或路径反斜杠没转义（Windows 用 `/` 或双反斜杠） |
| `No provisioning profile found`（iOS） | Xcode 里重选 Team，`Bundle Identifier` 与证书不匹配就换一个唯一值 |
| 真机装不上 / 闪退 | 检查手机系统版本 ≥ Android 5.0 / iOS 12；用 `flutter run` 看日志 |
| 没声音 | 手机静音键、媒体音量为 0，或系统未安装英文 TTS 语音包（设置 → 无障碍 → 文字转语音） |
| 中文显示成方框 | 极少见，属于系统字体缺失；换真机或改用系统默认字体 |

## 七、想改什么，改哪里

| 想改 | 位置 |
|---|---|
| 每天默认词量、默认是否重复 | `lib/models/models.dart` 里 `Settings` 的默认值 |
| 复习间隔天数 | `lib/data/app_env.dart` 顶部 `kSrsIntervals` |
| 配色 | `lib/core/theme.dart` 的 `AppColors` |
| 某个词的中文/例句 | `assets/data/cn_*.txt`、`assets/data/ex_*.txt`，改完重跑 `python tools/build_words.py` |
| 换整份词表 | 改 `tools/parse_pdf.py` 里的 PDF 路径，依次跑 `parse_pdf.py` → `build_words.py` |
| 加「看图选词」 | V2 计划，需要为每个词配一张图（`image_key` 字段已预留位置） |

## 八、已知限制

1. **音标**由离线发音词典自动转换（cmudict），个别同形异读词可能取到动词读音（如 `abstract` 标成动词重音），以 App 内 TTS 朗读为准。
2. **中文释义**是按雅思/托福常考义补写的，多义词只列常见 1–3 个义项，专业义可能缺失。
3. **例句**由 AI 生成，语法与用词已校对，但不是牛津官方例句，不能当作语料引用。
4. V1 不含：看图选词、拼写测试、听音选词、推送提醒、云同步（都在 V2/V3 规划里）。
5. 词表版权属 Oxford University Press，本 App 仅供个人学习使用，不要商用或公开分发词表数据。
