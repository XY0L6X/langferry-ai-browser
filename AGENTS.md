# 文渡 LangFerry — AI翻译浏览器

基于 Flutter 的安卓翻译浏览器，通过 WebView 加载网页并使用 DeepSeek/Mimo/OpenAI 兼容 API 进行全文翻译。

## Project

- **技术栈**: Flutter 3.22+, Dart 3.2+, Material 3, Riverpod 2.x, Hive, flutter_inappwebview 6.x, Dio 5.x
- **入口**: `lib/main.dart` → `ProviderScope` → `文渡 LangFerryApp` → `MainPage`
- **目标平台**: Android (minSdk 31 / Android 12), 理论上支持 iOS/Desktop
- **版本**: 1.0.0+1 (MIT License)

## Commands

```bash
flutter pub get                    # 安装依赖
flutter run                        # 在连接的设备上运行
flutter run -d <device_id>         # 指定设备运行
flutter build apk --debug          # 构建调试版 APK
flutter build apk --release        # 构建发布版 APK
flutter analyze                    # 静态分析
flutter test                       # 运行测试 (test/widget_test.dart)
dart run build_runner build        # 生成 Hive/Riverpod/JSON 代码
```

## Architecture

三层流水线架构，WebView 是核心宿主，翻译流程通过 JS 桥接实现：

```
lib/
├── main.dart                        # 入口：初始化 DB + SystemChrome + runApp
├── app.dart                         # MaterialApp 配置（主题/字体缩放/路由）
├── core/
│   ├── services/
│   │   ├── database_service.dart    # Hive 本地持久化（API配置/历史/收藏/缓存）
│   │   ├── api_client.dart          # Dio 客户端（OpenAI 兼容 API，SSE 流式）
│   │   ├── translation_service.dart # 翻译业务：分段/缓存/批量翻译
│   │   ├── translation_coordinator.dart # 全页翻译协调器：提取→翻译→注入
│   │   ├── js_injection_service.dart    # JS 桥接层：注入/提取/替换/模式切换
│   │   └── download_service.dart    # 下载服务
│   ├── constants/                   # app_dimens / app_strings
│   ├── theme/                       # 主题（暂空，实际在 lib/theme/）
│   └── utils/platform_utils.dart    # 平台适配工具
├── models/                          # Hive 数据模型 + .g.dart 生成文件
│   ├── api_config.dart              # API 配置 (typeId:0)
│   ├── translation_record.dart      # 翻译历史 (typeId:1?)
│   └── favorite_item.dart           # 收藏项
├── providers/                       # Riverpod 状态管理
│   ├── theme_provider.dart          # 主题模式 + 字体大小
│   ├── database_provider.dart       # API配置/历史/收藏 CRUD + 缓存服务
│   └── translation_provider.dart    # 翻译状态 (idle/loading/success/failed)
├── pages/                           # 页面
│   ├── main_page.dart               # 底部导航壳（浏览器/历史/收藏/设置）
│   ├── browser/                     # 浏览器 + WebView 容器 + URL 栏 + 标签栏
│   ├── history/                     # 翻译历史页
│   ├── favorite/                    # 收藏页
│   ├── settings/                    # 设置页 + API配置子页
│   └── download/                    # 下载管理页
├── widgets/                         # 共享组件
│   ├── common/                      # 底部导航/列表项/错误占位/翻译按钮
│   └── translate/                   # 划词翻译底部弹窗
└── theme/
    ├── app_colors.dart              # Material 3 色板
    └── app_theme.dart               # Light/Dark ThemeData
```

**翻译流水线**: `TranslationCoordinator` 协调三步：① `JsInjectionService.extractText()` 通过注入的 `extract_text.js` 提取 DOM 文本节点 → ② `TranslationService` 调用 `ApiClient` 逐段翻译（支持 OpenAI 兼容 + SSE 流式 + 缓存） → ③ `JsInjectionService.replaceText()` 通过 `replace_text.js` 替换 DOM 并支持原文/译文/对照三种显示模式。

**JS 脚本**: `assets/js/extract_text.js` 遍历 DOM 提取 `<p>/<h1>-<h6>/<span>/<div>/<li>/<a>` 等文本节点并标记 `data-wl-*` 属性；`assets/js/replace_text.js` 负责替换和三种模式切换。

**状态管理**: Riverpod `StateNotifierProvider`，每个聚合根（API配置/历史/收藏/翻译）一个 Notifier。数据库通过 `databaseServiceProvider` 单例注入。

## Conventions

- **命名**: Dart 标准 — 文件名 `snake_case`，类/Widget `UpperCamelCase`，变量 `lowerCamelCase`。Widget 文件以描述命名（如 `url_bar.dart`、`web_view_container.dart`）。
- **状态管理**: 所有可变状态通过 Riverpod `StateNotifierProvider` 暴露；页面通过 `ConsumerWidget` / `ref.watch()` 订阅。不要创建额外的全局单例。
- **数据库**: Hive 数据模型使用 `@HiveType`/`@HiveField` 注解 + `build_runner` 生成序列化代码。新增模型需指定唯一 `typeId` 并重新运行 `build_runner`。
- **主题**: 使用 `ThemeModeOption` 枚举 + `ThemeModeNotifier` 管理；颜色定义在 `app_colors.dart`，完整主题在 `app_theme.dart`。Material 3 设计，8dp 网格系统。
- **API**: 所有 API 调用走 `ApiClient`（Dio），支持非流式和 SSE 流式两种模式。翻译 prompt 在 `_buildRequest()` 中拼接。
- **错误处理**: try-catch + print 日志（无结构化日志框架）。翻译失败保留原文。
- **测试**: 仅一个基础 `widget_test.dart`；无 mock/集成测试。
- **分析选项**: 使用 `flutter_lints` 默认规则集 + `analysis_options.yaml`。

## Notes

- `README.md` 中提到的 `app_constants.dart` 实际不存在，常量在 `app_dimens.dart` + `app_strings.dart` 中。
- 安卓端 `android/` 目录包含 .gradle 和 AndroidManifest 等原生配置。
- API Key 为明文 Hive 存储，建议迁移到 flutter_secure_storage。
- 项目根目录 `.reasonix/` 已加入 .gitignore。
- 提交前请确保 `android/local.properties` 未被跟踪（含本地 SDK 路径）。
