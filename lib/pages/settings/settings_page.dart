import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/theme_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/api_config.dart';
import '../../models/search_engine.dart';
import '../../core/services/log_service.dart';
import '../debug/debug_console_page.dart';
import 'widgets/api_config_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apiConfigs = ref.watch(apiConfigsProvider);
    final fontSizeDisplay = ref.watch(fontSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        children: [
          // API配置
          _SettingsCard(
            title: AppStrings.apiConfig,
            icon: Icons.key,
            children: [
              if (apiConfigs.isEmpty)
                ListTile(
                  leading: Icon(
                    Icons.warning_amber,
                    color: theme.colorScheme.error,
                  ),
                  title: const Text(AppStrings.noApiConfig),
                  subtitle: const Text(AppStrings.noApiConfigHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _navigateToApiConfig(),
                )
              else ...[
                ...apiConfigs.map((config) => _ApiConfigTile(
                  config: config,
                  onTap: () => _navigateToApiConfig(config: config),
                  onSetActive: () async {
                    await ref.read(apiConfigsProvider.notifier).setActive(config.name);
                  },
                )),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text(AppStrings.addApiConfig),
                  onTap: () => _navigateToApiConfig(),
                ),
              ],
            ],
          ),
          
          // 外观设置
          _SettingsCard(
            title: AppStrings.appearanceSettings,
            icon: Icons.palette,
            children: [
              ListTile(
                leading: Icon(ref.read(themeModeIconProvider)),
                title: const Text(AppStrings.themeMode),
                subtitle: Text(ref.read(themeModeDisplayNameProvider)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showThemeModeDialog,
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text(AppStrings.fontSize),
                subtitle: Text(_getFontSizeDisplayName(fontSizeDisplay)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showFontSizeDialog,
              ),
            ],
          ),
          
          // 搜索引擎
          _SettingsCard(
            title: '搜索引擎',
            icon: Icons.search,
            children: [
              ListTile(
                leading: Text(
                  SearchEngine.findById(ref.watch(searchEngineProvider)).icon,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(SearchEngine.findById(ref.watch(searchEngineProvider)).name),
                subtitle: const Text('点击切换默认搜索引擎'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showSearchEngineDialog,
              ),
            ],
          ),
          
          // 数据管理
          _SettingsCard(
            title: AppStrings.dataManagement,
            icon: Icons.storage,
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('历史记录管理'),
                subtitle: const Text('查看和清理历史记录'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _clearHistory,
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('收藏管理'),
                subtitle: const Text('查看和管理收藏夹'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _manageFavorites,
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  AppStrings.clearCache,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text(AppStrings.clearCacheHint),
                onTap: _clearCache,
              ),
              ListTile(
                leading: Icon(
                  Icons.bug_report,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  '清理日志',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text('删除所有调试日志文件'),
                onTap: _clearLogs,
              ),
            ],
          ),
          
          // 关于
          _SettingsCard(
            title: AppStrings.about,
            icon: Icons.info_outline,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text(AppStrings.version),
                subtitle: const Text(AppStrings.appVersion),
                onLongPress: () {
                  LogService.instance.setDebugMode(!LogService.instance.debugMode);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LogService.instance.debugMode ? '调试模式已开启' : '调试模式已关闭'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('调试控制台'),
                subtitle: const Text('查看日志、执行JS、状态监控'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openDebugConsole,
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('导出日志'),
                subtitle: const Text('分享调试日志文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => LogService.instance.exportLogs(),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text(AppStrings.usageGuide),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showUsageGuide,
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text(AppStrings.openSource),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showOpenSource,
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text(AppStrings.feedback),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showFeedback,
              ),
            ],
          ),
          
          const SizedBox(height: AppDimens.spacing32),
        ],
      ),
    );
  }

  void _navigateToApiConfig({ApiConfig? config}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApiConfigPage(initialConfig: config),
      ),
    );
  }

  String _getFontSizeDisplayName(String size) {
    switch (size) {
      case 'xsmall':
        return '超小 (80%)';
      case 'small':
        return '小 (90%)';
      case 'large':
        return '大 (110%)';
      case 'xlarge':
        return '超大 (120%)';
      default:
        return '正常 (100%)';
    }
  }

  void _showThemeModeDialog() {
    final currentMode = ref.read(themeModeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.themeMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeModeOption>(
              title: const Text('浅色模式'),
              value: ThemeModeOption.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeModeOption>(
              title: const Text('深色模式'),
              value: ThemeModeOption.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeModeOption>(
              title: const Text('跟随系统'),
              value: ThemeModeOption.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeModeOption mode) {
    switch (mode) {
      case ThemeModeOption.light:
        return AppStrings.lightMode;
      case ThemeModeOption.dark:
        return AppStrings.darkMode;
      case ThemeModeOption.system:
        return AppStrings.systemMode;
    }
  }

  void _showFontSizeDialog() {
    final currentSize = ref.read(fontSizeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.fontSize),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('超小 (80%)'),
              value: 'xsmall',
              groupValue: currentSize,
              onChanged: (value) {
                if (value != null) {
                  ref.read(fontSizeProvider.notifier).setFontSize(value);
                }
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('小 (90%)'),
              value: 'small',
              groupValue: currentSize,
              onChanged: (value) {
                if (value != null) {
                  ref.read(fontSizeProvider.notifier).setFontSize(value);
                }
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('正常 (100%)'),
              value: 'normal',
              groupValue: currentSize,
              onChanged: (value) {
                if (value != null) {
                  ref.read(fontSizeProvider.notifier).setFontSize(value);
                }
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('大 (110%)'),
              value: 'large',
              groupValue: currentSize,
              onChanged: (value) {
                if (value != null) {
                  ref.read(fontSizeProvider.notifier).setFontSize(value);
                }
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('超大 (120%)'),
              value: 'xlarge',
              groupValue: currentSize,
              onChanged: (value) {
                if (value != null) {
                  ref.read(fontSizeProvider.notifier).setFontSize(value);
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchEngineDialog() {
    final currentId = ref.read(searchEngineProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择搜索引擎'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: SearchEngine.presets.map((engine) {
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Text(engine.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(engine.name),
                  ],
                ),
                subtitle: Text(
                  engine.searchUrl.replaceAll('{query}', '...'),
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                value: engine.id,
                groupValue: currentId,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(searchEngineProvider.notifier).setEngine(value);
                  }
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有历史记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(historyProvider.notifier).clearAll();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _manageFavorites() {
    // 跳转到收藏页面
    // 这里可以导航到收藏页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请在底部导航栏查看收藏')),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearCache),
        content: const Text(AppStrings.clearCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(translationCacheProvider).clearCache();
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.clearCacheSuccess)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('清除失败: $e'),
                      backgroundColor: Theme.of(this.context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理日志'),
        content: const Text('确定要删除所有调试日志吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await LogService.instance.clearLogs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日志已清理')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showUsageGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _UsageGuidePage(),
      ),
    );
  }

  void _openDebugConsole() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugConsolePage(),
      ),
    );
  }

  void _showOpenSource() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开源地址'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('项目名称: WebLingo'),
            SizedBox(height: AppDimens.spacing8),
            Text('开源协议: MIT License'),
            SizedBox(height: AppDimens.spacing8),
            Text('技术栈: Flutter + Riverpod + Hive'),
            SizedBox(height: AppDimens.spacing8),
            Text('感谢使用本应用！'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('反馈渠道'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('如有问题或建议，请通过以下方式联系我们：'),
            SizedBox(height: AppDimens.spacing16),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('邮箱'),
              subtitle: Text('109762976@qq.com'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(AppDimens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.spacing16,
              AppDimens.spacing16,
              AppDimens.spacing16,
              AppDimens.spacing8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppDimens.iconSizeMedium,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppDimens.spacing8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ApiConfigTile extends StatelessWidget {
  final ApiConfig config;
  final VoidCallback onTap;
  final VoidCallback onSetActive;

  const _ApiConfigTile({
    required this.config,
    required this.onTap,
    required this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: config.isActive
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
        ),
        child: Center(
          child: Text(
            config.name.isNotEmpty ? config.name.substring(0, 1).toUpperCase() : '?',
            style: TextStyle(
              color: config.isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      title: Text(config.name),
      subtitle: Text(
        config.model,
        style: theme.textTheme.bodySmall,
      ),
      trailing: config.isActive
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : TextButton(
              onPressed: onSetActive,
              child: const Text('启用'),
            ),
      onTap: onTap,
    );
  }
}

/// 使用说明全屏页面
class _UsageGuidePage extends StatelessWidget {
  const _UsageGuidePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('使用说明')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, '🔑 最重要的第一步：配置 API 密钥'),
            _body(theme, '翻译功能需要调用 AI 大模型，所以你必须先获取一个 API 密钥（也叫 API Key）。'
                '这就像一把"钥匙"，让应用能使用 AI 翻译服务。'),
            const SizedBox(height: 12),
            _subsectionTitle(theme, '什么是 API Key？'),
            _body(theme, '可以理解为 AI 服务的"密码"。你在 AI 平台注册后获得一串字符，'
                '填入应用就能使用了。放心，费用极低——翻译几十个网页通常只要几分钱。'),
            const SizedBox(height: 12),
            _subsectionTitle(theme, '怎么获取？（推荐 DeepSeek）'),
            _numberedItem(theme, '1', '打开浏览器访问 platform.deepseek.com'),
            _numberedItem(theme, '2', '点击右上角"注册"，用手机号或邮箱注册'),
            _numberedItem(theme, '3', '登录后进入控制台，点击左侧"API Keys"'),
            _numberedItem(theme, '4', '点击"创建 API Key"，随便起个名字（如 WebLingo），点确定'),
            _numberedItem(theme, '5', '复制生成的那串以 sk- 开头的字符，这就是你的 Key'),
            _tip(theme, '新用户通常赠送 10 元额度，够用很久。也可以使用阿里云通义千问：dashscope.console.aliyun.com'),
            const SizedBox(height: 12),
            _subsectionTitle(theme, '怎么填入应用？'),
            _numberedItem(theme, '1', '回到 WebLingo，点击底部"设置"'),
            _numberedItem(theme, '2', '点击"API 配置" → "添加 API 配置"'),
            _numberedItem(theme, '3', '在"选择预设模板"中选你注册的平台（如 DeepSeek V4 Flash）'),
            _numberedItem(theme, '4', '在"API Key"一栏粘贴刚才复制的 Key'),
            _numberedItem(theme, '5', '点击"测试连接"，看到 ✅ 连接成功 就对了'),
            _numberedItem(theme, '6', '点击右上角"保存"'),
            _tip(theme, '如果测试失败：检查 Key 是否复制完整、网络是否正常。API Key 就像银行卡密码，不要随意分享给他人。'),

            const SizedBox(height: 28),
            _sectionTitle(theme, '🌐 浏览器功能'),
            _body(theme, '在顶部地址栏输入网址（如 www.google.com）或关键词即可搜索。'
                '底部导航栏提供前进、后退、刷新按钮。'),
            _body(theme, '点击地址栏右侧的数字图标可管理多个标签页，支持新建和关闭。'),

            const SizedBox(height: 28),
            _sectionTitle(theme, '📖 翻译网页'),
            _subsectionTitle(theme, '全页翻译'),
            _numberedItem(theme, '1', '打开一个外文网页'),
            _numberedItem(theme, '2', '点击底部中间的"翻译"按钮'),
            _numberedItem(theme, '3', '等待翻译完成（页面会逐块变成中文）'),
            _subsectionTitle(theme, '切换显示模式'),
            _body(theme, '翻译完成后再次点击翻译按钮，可选择：'),
            _bullet(theme, '仅译文 — 只显示中文'),
            _bullet(theme, '原文译文对照 — 同时显示原文和译文'),
            _bullet(theme, '显示原文 — 恢复原始页面'),
            _bullet(theme, '重新翻译 — 重新提取页面文本再翻译（适合点开"展开"加载更多内容后使用）'),
            _subsectionTitle(theme, '划词翻译'),
            _body(theme, '长按网页中任意外文文字并选中，底部会自动弹出翻译结果，支持复制和收藏。'),

            const SizedBox(height: 28),
            _sectionTitle(theme, '⬇️ 下载管理'),
            _body(theme, '浏览网页时点击 PDF、图片等可下载链接，会自动开始下载。'
                '在底部"下载"tab 查看和管理已下载文件。'),
            _bullet(theme, '点击下载项右侧菜单可"打开文件"或"删除"'),
            _bullet(theme, '删除时可选择"仅删记录"（保留文件）或"同时删除文件"'),
            _bullet(theme, '点击"更改"可自定义文件保存目录'),

            const SizedBox(height: 28),
            _sectionTitle(theme, '⭐ 收藏与历史'),
            _body(theme, '点击地址栏右侧心形图标可收藏当前网页。'
                '浏览和翻译过的网页会自动记录在"历史"tab 中。'
                '两个页面都支持搜索和批量管理。'),

            const SizedBox(height: 28),
            _sectionTitle(theme, '❓ 常见问题'),
            _faq(theme, '翻译按钮点了没反应？',
                '① 是否已配置 API Key？（设置→API配置→添加→测试连接→保存）\n'
                '② 是否有网络连接？\n'
                '③ 页面是否加载完成？'),
            _faq(theme, '提示"翻译失败"？',
                '① 进入设置→API配置，点击"测试连接"验证 Key 是否有效\n'
                '② Key 可能已过期或额度用完，需重新获取\n'
                '③ 检查网络是否正常'),
            _faq(theme, '翻译后页面有些地方没翻译？',
                '① 点击翻译按钮→选择"重新翻译"可覆盖新加载的内容\n'
                '② 部分网页的动态评论区可能无法翻译\n'
                '③ 点开"展开"按钮后需要重新翻译'),
            _faq(theme, '翻译速度慢？',
                '已优化为并发翻译，常规页面约需 5-30 秒。页面越复杂耗时越长。'
                '第二次翻译同一页面会更快（有缓存）。'),
            _faq(theme, '需要一直联网吗？',
                '浏览网页和翻译都需要网络。翻译过的内容会缓存，同一段文字再次翻译不需联网。'),
            _faq(theme, '费用会不会很贵？',
                '不会。按实际翻译量计费，常用模型价格极低。正常使用每月不到 1 元。'
                '只有点"翻译"按钮时才计费，浏览网页不产生费用。'),
            _faq(theme, 'API Key 安全吗？',
                'Key 保存在手机本地，不会上传到任何第三方。但仍建议不要分享给他人。'),
            _faq(theme, '能翻译成其他语言吗？',
                '当前默认翻译为中文。后续版本将支持选择目标语言。'),

            const SizedBox(height: 32),
            Center(
              child: Text('更多帮助请查看 RUN_GUIDE.md',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _subsectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _body(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: theme.textTheme.bodyMedium),
    );
  }

  Widget _numberedItem(ThemeData theme, String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$num. ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _bullet(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _tip(ThemeData theme, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _faq(ThemeData theme, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q: $question', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(answer, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}