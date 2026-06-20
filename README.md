<p align="center">
  <h1 align="center">文渡 LangFerry</h1>
  <p align="center">以文字为舟，渡语言之河</p>
</p>

当你浏览外文网页、查阅海外资料时，陌生的语言常常像一条横亘的河流——内容就在对岸，你却难以顺畅抵达。

文渡（LangFerry）是一款专为安卓用户打造的 AI 页面翻译工具。我们不做生硬的词句替换，也无意颠覆原生的阅读体验，而是愿做一艘按需启程的渡船：在你需要时启动 AI 能力，将整页外文内容转化为通顺自然的中文，平稳送你抵达信息的彼岸；无需翻译时，便静默退居一旁，不打扰你浏览页面的节奏。

---

## ✨ 核心特性

- 🤖 **AI 智能整页翻译** — 基于大语言模型（DeepSeek / OpenAI / 通义千问 等兼容 API），兼顾语义准确性与中文阅读流畅度，并发生成译文，平均 5-20 秒完成整页翻译
- 📱 **内置浏览器** — 多标签页管理、前进后退刷新、页内查找、桌面版模式、广告拦截，一站式浏览体验
- 📖 **三种阅读模式** — 仅译文 / 原文对照 / 还原原文，按需切换，不强制替换
- ⚡ **自动翻译** — 可选开启，每次加载外文页面自动翻译，无需手动点击
- ⬇️ **下载管理** — 浏览中点击 PDF、图片等文件自动下载，支持自定义保存目录
- 🔍 **划词翻译** — 长按选中网页中任意文字，底部弹出翻译面板
- ⭐ **收藏与历史** — 自动记录浏览历史，支持收藏夹分类管理
- 🌙 **深色模式** — 支持浅色 / 深色 / 跟随系统
- 🔤 **多搜索引擎** — Google / 百度 / 必应 / 搜狗 / 秘塔 / 夸克 … 共 10 个可选

## 🚀 快速开始

### 安装

从 [Releases](https://github.com/XY0L6X/langferry-ai-browser/releases) 下载最新 APK，传到手机上安装即可。

> 如提示"未知来源"，在设置中允许"安装未知应用"。

### 配置 API Key（必须操作）

翻译需要调用 AI 大模型，你需要先获取一个 API Key：

1. 注册 AI 平台账号（推荐 [DeepSeek](https://platform.deepseek.com/)，国内可直接访问，新用户送额度）
2. 在控制台创建 API Key（以 `sk-` 开头的一串字符）
3. 打开应用 → 设置 → API 配置 → 添加 → 粘贴 Key → 测试连接 → 保存

> 💰 费用极低：DeepSeek V4 Flash 翻译一个网页约 0.001-0.01 元，新用户赠送 10 元额度。

详细图文教程见 [使用指南](RUN_GUIDE.md)。

### 从源码构建

```bash
# 需要 Flutter 3.22+ / Dart 3.2+
git clone https://github.com/XY0L6X/langferry-ai-browser.git
cd langferry
flutter pub get
flutter run                # 连接设备运行
flutter build apk --debug  # 构建调试版 APK
```

## 🛠 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.22+ |
| 语言 | Dart 3.2+ |
| 状态管理 | Riverpod 2.x |
| WebView | flutter_inappwebview 6.x |
| 本地存储 | Hive (配置/缓存) + flutter_secure_storage (API Key, 计划中) |
| 网络 | Dio 5.x (HTTP + SSE 流式) |
| JS 桥接 | 注入 extract_text.js / replace_text.js 实现 DOM 文本提取与替换 |

## 📂 项目结构

```
lib/
├── main.dart              # 入口
├── app.dart               # MaterialApp 配置
├── core/
│   ├── services/          # 翻译/API/下载/JS注入/日志
│   ├── constants/         # 字符串/尺寸常量
│   └── theme/             # Material 3 主题
├── models/                # Hive 数据模型
├── providers/             # Riverpod 状态管理
├── pages/                 # 页面 (浏览器/历史/收藏/下载/设置/调试)
└── widgets/               # 通用组件
assets/js/
├── extract_text.js        # 网页文本提取脚本
└── replace_text.js        # 译文注入与模式切换脚本
```

## 📄 许可证

MIT License · 详见 [LICENSE](LICENSE)

---

<p align="center">我们愿做你浏览外文世界的摆渡人，让语言不再是阅读的阻碍。</p>
