import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/js_injection_service.dart';
import '../../core/services/translation_coordinator.dart';
import '../../providers/translation_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/search_engine.dart';
import '../../widgets/common/translate_button.dart';
import '../../widgets/translate/selection_translate_sheet.dart';
import 'widgets/url_bar.dart';
import 'widgets/tab_bar_widget.dart' show TabBarWidget, TabItem;
import 'widgets/web_view_container.dart';
import 'widgets/home_page.dart';
import '../../models/translation_record.dart';
import '../../models/favorite_item.dart';

enum BrowserPageState { home, loading, loaded, error }

class BrowserPage extends ConsumerStatefulWidget {
  final Function(Function(String))? onUrlLoaded;
  
  const BrowserPage({super.key, this.onUrlLoaded});

  @override
  ConsumerState<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends ConsumerState<BrowserPage> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  BrowserPageState _pageState = BrowserPageState.home;
  TranslateButtonState _translateState = TranslateButtonState.idle;
  String? _translatingUrl; // 正在翻译的URL，用于防止旧翻译回调覆盖新页面状态

  String _currentUrl = '';
  String _currentTitle = '';
  double _loadProgress = 0;

  final List<TabItem> _tabs = [];
  int _currentTabIndex = 0;

  InAppWebViewController? _webViewController;
  TranslationCoordinator? _coordinator;
  TranslationMode _translationMode = TranslationMode.translated;
  JsInjectionService? _jsService;
  bool _jsReady = false;  // JS 注入完成标志
  
  // 页内查找
  bool _showFindBar = false;
  final TextEditingController _findController = TextEditingController();
  int _findMatchCount = 0;
  int _findCurrentMatch = 0;
  
  // 桌面模式
  bool _desktopMode = false;
  
  // 无痕模式
  bool _incognitoMode = false;

  @override
  void initState() {
    super.initState();
    _addNewTab();
    // 注册URL加载回调
    widget.onUrlLoaded?.call(_onUrlSubmitted);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _onJsServiceReady(JsInjectionService jsService) {
    _jsService = jsService;
    _jsReady = true;
    final translationService = ref.read(translationServiceProvider);
    _coordinator = TranslationCoordinator(
      jsService: jsService,
      translationService: translationService,
    );
  }

  void _addNewTab() {
    setState(() {
      _tabs.add(TabItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: '',
        title: AppStrings.newTab,
      ));
      _currentTabIndex = _tabs.length - 1;
      _pageState = BrowserPageState.home;
      _currentUrl = '';
      _currentTitle = '';
      _urlController.clear();
    });
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) {
      _goToHomePage();
      return;
    }
    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
      _loadTabContent(_currentTabIndex);
    });
  }

  void _switchTab(int index) {
    setState(() {
      _currentTabIndex = index;
      _loadTabContent(index);
    });
  }

  void _loadTabContent(int index) {
    final tab = _tabs[index];
    setState(() {
      _currentUrl = tab.url;
      _currentTitle = tab.title;
      _urlController.text = tab.url;
      _pageState = tab.url.isEmpty
          ? BrowserPageState.home
          : BrowserPageState.loaded;
    });
  }

  /// 公共方法：加载URL（可从外部调用）
  void loadUrl(String url) {
    _onUrlSubmitted(url);
  }

  void _goToHomePage() {
    setState(() {
      _currentUrl = '';
      _currentTitle = '';
      _urlController.clear();
      _pageState = BrowserPageState.home;
      if (_currentTabIndex < _tabs.length) {
        _tabs[_currentTabIndex] = _tabs[_currentTabIndex].copyWith(
          url: '',
          title: AppStrings.newTab,
        );
      }
    });
  }

  void _onUrlSubmitted(String url) {
    if (url.isEmpty) return;
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // 使用 Uri 解析检测危险 scheme
      final uri = Uri.tryParse(url);
      if (uri != null && uri.scheme.isNotEmpty && uri.scheme != 'http' && uri.scheme != 'https') {
        // 拒绝危险 scheme: javascript, file, intent, data 等
        return;
      }
      if (url.contains('.') && !url.contains(' ')) {
        formattedUrl = 'https://$url';
      } else {
        final engineId = ref.read(searchEngineProvider);
        final engine = SearchEngine.findById(engineId);
        formattedUrl = engine.buildUrl(url);
      }
    }
    setState(() {
      _currentUrl = formattedUrl;
      _currentTitle = '';
      _urlController.text = formattedUrl;
      _pageState = BrowserPageState.loading;
      if (_currentTabIndex < _tabs.length) {
        _tabs[_currentTabIndex] =
            _tabs[_currentTabIndex].copyWith(url: formattedUrl);
      }
    });
    _urlFocusNode.unfocus();
    
    // 主动加载 URL（不再依赖 didUpdateWidget）
    if (_webViewController != null) {
      _webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(formattedUrl)),
      );
    }
  }

  void _onPageStarted(String url) {
    // 先更新 URL（旧翻译的 onDone 检查 _translatingUrl != _currentUrl 会安全跳过）
    _currentUrl = url;
    _translatingUrl = null; // 废弃旧翻译回调
    _coordinator?.cancel(); // 取消正在进行的翻译
    setState(() {
      _pageState = BrowserPageState.loading;
      _urlController.text = url;
      // 新页面加载时重置翻译状态
      _translateState = TranslateButtonState.idle;
      _translationMode = TranslationMode.translated;
      _jsReady = false;
    });
  }

  void _onPageFinished(String url, String title) {
    setState(() {
      _pageState = BrowserPageState.loaded;
      _currentUrl = url;
      _currentTitle = title;
      _loadProgress = 0;
      if (_currentTabIndex < _tabs.length) {
        _tabs[_currentTabIndex] = _tabs[_currentTabIndex].copyWith(
          url: url,
          title: title,
        );
      }
    });
    _saveToHistory(url, title);
    
    // 自动翻译：JS 注入完成 + 页面加载完成后自动触发
    final autoTranslate = ref.read(autoTranslateProvider);
    if (autoTranslate && _jsReady && _translateState == TranslateButtonState.idle) {
      // 短延迟确保 DOM 完全稳定
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _jsReady && _translateState == TranslateButtonState.idle) {
          _startTranslation();
        }
      });
    }
  }

  void _saveToHistory(String url, String title) {
    if (_incognitoMode) return; // 无痕模式不记录
    if (url.isEmpty || url == 'about:blank') return;
    final record = TranslationRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}_${url.hashCode}',
      url: url,
      title: title.isNotEmpty ? title : url,
      originalText: '',
      translatedText: '',
    );
    ref.read(historyProvider.notifier).addRecord(record);
  }

  void _onProgressChanged(double progress) {
    setState(() {
      _loadProgress = progress;
    });
  }

  void _onError(String error) {
    setState(() {
      _pageState = BrowserPageState.error;
    });
  }

  void _onTextSelected(String text) {
    if (text.isEmpty || text.length < 2) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SelectionTranslateSheet(originalText: text),
    );
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _webViewController = controller;
  }

  // 导航功能
  void _goBack() async {
    if (_webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();
      if (canGoBack) {
        // 回退前重置翻译状态（belt-and-suspenders）
        _translatingUrl = null;
        _coordinator?.cancel();
        setState(() {
          _translateState = TranslateButtonState.idle;
          _translationMode = TranslationMode.translated;
          _jsReady = false;
          _loadProgress = 0;
        });
        await _webViewController!.goBack();
      }
    }
  }

  void _goForward() async {
    if (_webViewController != null) {
      final canGoForward = await _webViewController!.canGoForward();
      if (canGoForward) {
        _translatingUrl = null;
        _coordinator?.cancel();
        setState(() {
          _translateState = TranslateButtonState.idle;
          _translationMode = TranslationMode.translated;
          _jsReady = false;
          _loadProgress = 0;
        });
        await _webViewController!.goForward();
      }
    }
  }

  void _refresh() {
    _translatingUrl = null;
    _coordinator?.cancel();
    setState(() {
      _translateState = TranslateButtonState.idle;
      _translationMode = TranslationMode.translated;
      _jsReady = false;
      _loadProgress = 0;
    });
    if (_webViewController != null) {
      _webViewController!.reload();
    }
  }

  /// 切换桌面版/移动版
  void _toggleDesktopMode() {
    setState(() {
      _desktopMode = !_desktopMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_desktopMode ? '已切换桌面版，重新加载中...' : '已恢复移动版，重新加载中...'),
        duration: const Duration(seconds: 1),
      ),
    );
    // 重建 WebViewContainer 时会用新的 userAgent 加载
    if (_webViewController != null) {
      _webViewController!.reload();
    }
  }

  /// 页内查找
  void _findInPage(String query) async {
    if (_webViewController == null) return;
    if (query.isEmpty) {
      // 清除高亮
      await _webViewController!.evaluateJavascript(source: '''
        document.querySelectorAll('.__wl_highlight__').forEach(function(el) {
          var p = el.parentNode;
          p.replaceChild(document.createTextNode(el.textContent), el);
          p.normalize();
        });
      ''');
      return;
    }
    var escapedQuery = query
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('"', r'\"')
        .replaceAll('/', r'\/');
    await _webViewController!.evaluateJavascript(source: '''
      (function() {
        document.querySelectorAll('.__wl_highlight__').forEach(function(el) {
          var p = el.parentNode;
          p.replaceChild(document.createTextNode(el.textContent), el);
          p.normalize();
        });
        var q = "$escapedQuery";
        if (!q) return;
        var body = document.body, count = 0;
        var walker = document.createTreeWalker(body, NodeFilter.SHOW_TEXT);
        var nodes = [];
        while (walker.nextNode()) nodes.push(walker.currentNode);
        nodes.forEach(function(node) {
          var idx = node.textContent.toLowerCase().indexOf(q.toLowerCase());
          if (idx >= 0) {
            var span = document.createElement('span');
            span.className = '__wl_highlight__';
            span.style.cssText = 'background:#FFEB3B;color:#000;';
            span.textContent = node.textContent;
            node.parentNode.replaceChild(span, node);
            count++;
          }
        });
        return count;
      })();
    ''');
  }

  void _findNext(bool forward) async {
    // 简单滚动到第一个高亮处
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(source: '''
        (function() {
          var hl = document.querySelector('.__wl_highlight__');
          if (hl) hl.scrollIntoView({behavior: 'smooth', block: 'center'});
        })();
      ''');
    }
  }

  void _closeFindBar() {
    _findController.clear();
    if (_webViewController != null) {
      _webViewController!.evaluateJavascript(source: '''
        document.querySelectorAll('.__wl_highlight__').forEach(function(el) {
          var parent = el.parentNode;
          parent.replaceChild(document.createTextNode(el.textContent), el);
          parent.normalize();
        });
      ''');
    }
    setState(() => _showFindBar = false);
  }

  // 翻译功能
  void _onTranslatePressed() {
    switch (_translateState) {
      case TranslateButtonState.idle:
        _startTranslation();
        break;
      case TranslateButtonState.success:
        _toggleTranslationMode();
        break;
      case TranslateButtonState.failed:
        _startTranslation();
        break;
      default:
        break;
    }
  }

  void _startTranslation() {
    if (_jsService == null || !_jsReady) {
      if (kDebugMode) print('[BrowserPage] 翻译未就绪: jsService=$_jsService jsReady=$_jsReady');
      return;  // 静默返回，不弹 SnackBar（自动翻译时常见）
    }
    setState(() {
      _translateState = TranslateButtonState.loading;
      _translationMode = TranslationMode.translated;
      _loadProgress = 0;
    });
    
    // 记录翻译发起的URL，防止旧翻译回调覆盖新页面状态
    final translatingUrl = _currentUrl;
    _translatingUrl = translatingUrl;

    // 记录最后一个进度事件，用于 onDone 判断是否真正成功
    TranslationProgress? lastProgress;

    _coordinator?.translatePage(targetLanguage: 'zh-CN').listen(
      (progress) {
        // 仅当仍在同一页面时更新状态
        if (_translatingUrl != _currentUrl) return;
        lastProgress = progress;
        setState(() {
          _loadProgress = progress.progress;
        });
        // 如果收到失败事件，立即切换到失败态
        if (!progress.success && progress.stage == TranslationStage.complete) {
          if (mounted) {
            setState(() {
              _translateState = TranslateButtonState.failed;
              _loadProgress = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(progress.message ?? '翻译失败')),
            );
          }
        }
      },
      onDone: () {
        if (!mounted) return;
        // 仅当仍在同一页面时更新状态
        if (_translatingUrl != _currentUrl) return;
        _translatingUrl = null;
        final succeeded = lastProgress != null && lastProgress!.success;
        setState(() {
          _translateState = succeeded
              ? TranslateButtonState.success
              : TranslateButtonState.failed;
          _translationMode = TranslationMode.translated;
          _loadProgress = 0;
        });
        if (succeeded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lastProgress?.message ?? AppStrings.translateComplete)),
          );
        }
      },
      onError: (error) {
        if (!mounted) return;
        if (_translatingUrl != _currentUrl) return;
        _translatingUrl = null;
        setState(() {
          _translateState = TranslateButtonState.failed;
          _loadProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('翻译失败: $error')),
        );
      },
    );
  }

  void _toggleTranslationMode() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _TranslationModeSheet(
        currentMode: _translationMode,
        onModeChanged: (mode) async {
          setState(() {
            _translationMode = mode;
          });
          await _coordinator?.setDisplayMode(mode);
          Navigator.pop(context);
        },
        onRetranslate: () {
          _startTranslation();
        },
      ),
    );
  }

  // 收藏功能
  void _addToFavorite() {
    if (_currentUrl.isEmpty) return;
    
    final categories = ref.read(favoritesProvider.notifier).getAllCategories();
    String selectedCategory = categories.isNotEmpty ? categories.first : '其他';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加到收藏'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('标题: $_currentTitle'),
              const SizedBox(height: AppDimens.spacing8),
              Text('网址: $_currentUrl', 
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.spacing16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: '选择分类',
                ),
                items: ['技术', '新闻', '学习', '工作', '娱乐', '其他'].map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final favoriteItem = FavoriteItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  url: _currentUrl,
                  title: _currentTitle.isNotEmpty ? _currentTitle : _currentUrl,
                  category: selectedCategory,
                );
                await ref.read(favoritesProvider.notifier).addFavorite(favoriteItem);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已添加到收藏')),
                  );
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDrawer() {
    _showUnifiedMenu();
  }

  void _showMoreOptions() {
    _showUnifiedMenu();
  }

  void _showUnifiedMenu() {
    final autoOn = ref.read(autoTranslateProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _UnifiedMenuSheet(
        currentUrl: _currentUrl,
        currentTitle: _currentTitle,
        desktopMode: _desktopMode,
        autoTranslate: autoOn,
        incognitoMode: _incognitoMode,
        onCopyUrl: () {
          Clipboard.setData(ClipboardData(text: _currentUrl));
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.copySuccess)),
          );
        },
        onShare: () {
          Navigator.pop(ctx);
          if (_currentUrl.isNotEmpty) {
            Share.share(_currentUrl, subject: _currentTitle);
          }
        },
        onFavorite: () {
          Navigator.pop(ctx);
          _addToFavorite();
        },
        onFindInPage: () {
          Navigator.pop(ctx);
          setState(() => _showFindBar = true);
        },
        onDesktopMode: () {
          Navigator.pop(ctx);
          _toggleDesktopMode();
        },
        onAutoTranslate: () {
          Navigator.pop(ctx);
          ref.read(autoTranslateProvider.notifier).toggle();
          setState(() {});
        },
        onIncognito: () {
          Navigator.pop(ctx);
          setState(() => _incognitoMode = !_incognitoMode);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 无痕模式指示条
            if (_incognitoMode)
              Container(
                width: double.infinity,
                height: 3,
                color: Colors.grey[900],
              ),
            UrlBar(
              controller: _urlController,
              focusNode: _urlFocusNode,
              isLoading: _pageState == BrowserPageState.loading,
              loadProgress: _loadProgress,
              onSubmit: _onUrlSubmitted,
              onMenuPressed: _showUnifiedMenu,
              onTabPressed: _showTabManager,
              onClearPressed: _goToHomePage,
              tabCount: _tabs.length,
              searchIcon: SearchEngine.findById(ref.watch(searchEngineProvider)).icon,
              incognito: _incognitoMode,
            ),
            if (_tabs.length > 1)
              TabBarWidget(
                tabs: _tabs,
                currentIndex: _currentTabIndex,
                onTabSelected: _switchTab,
                onTabClosed: _closeTab,
                onAddTab: _addNewTab,
              ),
            // 页内查找栏（URL 栏下方）
            if (_showFindBar) _buildFindBar(theme),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_pageState) {
      case BrowserPageState.home:
        return HomePage(
          onUrlSelected: _onUrlSubmitted,
          onSearchSubmitted: _onUrlSubmitted,
        );
      case BrowserPageState.loading:
      case BrowserPageState.loaded:
        return WebViewContainer(
          url: _currentUrl,
          desktopMode: _desktopMode,
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onProgressChanged: _onProgressChanged,
          onError: _onError,
          onTitleChanged: (title) {
            setState(() {
              _currentTitle = title;
              if (_currentTabIndex < _tabs.length) {
                _tabs[_currentTabIndex] =
                    _tabs[_currentTabIndex].copyWith(title: title);
              }
            });
          },
          onWebViewCreated: _onWebViewCreated,
          onJsServiceReady: _onJsServiceReady,
          onTextSelected: _onTextSelected,
        );
      case BrowserPageState.error:
        return _buildErrorState(theme);
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _loadProgress > 0 ? _loadProgress : null,
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: AppDimens.spacing16),
          Text(
            AppStrings.loading,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 页内查找栏
  Widget _buildFindBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _findController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '页面内查找...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: _findMatchCount > 0 ? '${_findCurrentMatch + 1}/$_findMatchCount' : null,
              ),
              onChanged: (v) => _findInPage(v),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 20),
            onPressed: () => _findNext(false),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 20),
            onPressed: () => _findNext(true),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _closeFindBar,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppDimens.spacing16),
            Text(
              AppStrings.errorNetwork,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppDimens.spacing24),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spacing16,
            vertical: AppDimens.spacing8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BottomBarButton(
                icon: Icons.arrow_back_ios,
                onTap: _goBack,
              ),
              _BottomBarButton(
                icon: Icons.arrow_forward_ios,
                onTap: _goForward,
              ),
              _BottomBarButton(
                icon: Icons.refresh,
                onTap: _refresh,
              ),
              _AutoTranslateToggle(
                onToggle: () {
                  ref.read(autoTranslateProvider.notifier).toggle();
                  final isOn = ref.read(autoTranslateProvider);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isOn ? '自动翻译：已开启' : '自动翻译：已关闭'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
                    ),
                  );
                  setState(() {});
                },
              ),
              TranslateButton(
                state: _translateState,
                onPressed: _onTranslatePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTabManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TabManagerSheet(
        tabs: _tabs,
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          _switchTab(index);
          Navigator.pop(context);
        },
        onTabClosed: _closeTab,
        onAddTab: () {
          _addNewTab();
          Navigator.pop(context);
        },
      ),
    );
  }

}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BottomBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusButton),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing8),
        child: Icon(
          icon,
          size: AppDimens.iconSizeMedium,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// 自动翻译开关按钮
class _AutoTranslateToggle extends ConsumerWidget {
  final VoidCallback onToggle;

  const _AutoTranslateToggle({required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoOn = ref.watch(autoTranslateProvider);
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppDimens.radiusButton),
      child: Tooltip(
        message: autoOn ? '自动翻译：开（点击关闭）' : '自动翻译：关（点击开启）',
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacing8),
          child: Icon(
            autoOn ? Icons.auto_awesome : Icons.auto_awesome_outlined,
            size: AppDimens.iconSizeMedium,
            color: autoOn
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _TranslationModeSheet extends StatelessWidget {
  final TranslationMode currentMode;
  final ValueChanged<TranslationMode> onModeChanged;
  final VoidCallback? onRetranslate;

  const _TranslationModeSheet({
    required this.currentMode,
    required this.onModeChanged,
    this.onRetranslate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacing16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('翻译模式', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppDimens.spacing16),
          ListTile(
            leading: Icon(Icons.translate,
                color: currentMode == TranslationMode.translated
                    ? theme.colorScheme.primary
                    : null),
            title: const Text(AppStrings.translatedOnly),
            trailing: currentMode == TranslationMode.translated
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () => onModeChanged(TranslationMode.translated),
          ),
          ListTile(
            leading: Icon(Icons.compare_arrows,
                color: currentMode == TranslationMode.bilingual
                    ? theme.colorScheme.primary
                    : null),
            title: const Text(AppStrings.bilingualMode),
            trailing: currentMode == TranslationMode.bilingual
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () => onModeChanged(TranslationMode.bilingual),
          ),
          ListTile(
            leading: Icon(Icons.text_fields,
                color: currentMode == TranslationMode.original
                    ? theme.colorScheme.primary
                    : null),
            title: const Text('显示原文'),
            trailing: currentMode == TranslationMode.original
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () => onModeChanged(TranslationMode.original),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.refresh, color: theme.colorScheme.primary),
            title: Text('重新翻译', style: TextStyle(color: theme.colorScheme.primary)),
            subtitle: const Text('包含页面新加载的内容'),
            onTap: () {
              Navigator.pop(context);
              onRetranslate?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _UnifiedMenuSheet extends StatelessWidget {
  final String currentUrl;
  final String currentTitle;
  final bool desktopMode;
  final bool autoTranslate;
  final bool incognitoMode;
  final VoidCallback onCopyUrl;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback onFindInPage;
  final VoidCallback onDesktopMode;
  final VoidCallback onAutoTranslate;
  final VoidCallback onIncognito;

  const _UnifiedMenuSheet({
    required this.currentUrl,
    required this.currentTitle,
    required this.desktopMode,
    required this.autoTranslate,
    required this.incognitoMode,
    required this.onCopyUrl,
    required this.onShare,
    required this.onFavorite,
    required this.onFindInPage,
    required this.onDesktopMode,
    required this.onAutoTranslate,
    required this.onIncognito,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacing16),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 页面操作
          _SectionTitle(theme, '页面操作'),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('复制链接'),
            onTap: onCopyUrl,
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('分享'),
            onTap: onShare,
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('收藏当前页'),
            onTap: onFavorite,
          ),
          const Divider(),
          // 浏览工具
          _SectionTitle(theme, '浏览工具'),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('页面内查找'),
            onTap: onFindInPage,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.desktop_windows),
            title: const Text('桌面版网站'),
            value: desktopMode,
            onChanged: (_) => onDesktopMode(),
          ),
          SwitchListTile(
            secondary: Icon(autoTranslate ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                color: autoTranslate ? theme.colorScheme.primary : null),
            title: const Text('自动翻译'),
            subtitle: const Text('加载外文页面时自动翻译'),
            value: autoTranslate,
            onChanged: (_) => onAutoTranslate(),
          ),
          const Divider(),
          SwitchListTile(
            secondary: Icon(
              incognitoMode ? Icons.visibility_off : Icons.visibility,
              color: incognitoMode ? theme.colorScheme.error : null,
            ),
            title: const Text('无痕模式'),
            subtitle: const Text('不记录历史、不保存缓存'),
            value: incognitoMode,
            onChanged: (_) => onIncognito(),
          ),
          const SizedBox(height: AppDimens.spacing8),
        ],
      ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final ThemeData theme;
  final String text;
  const _SectionTitle(this.theme, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Text(text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _TabManagerSheet extends StatelessWidget {
  final List<TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onTabClosed;
  final VoidCallback onAddTab;

  const _TabManagerSheet({
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onAddTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.radiusBottomSheet),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimens.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.tabManage,
                        style: theme.textTheme.titleMedium),
                    IconButton(
                      onPressed: onAddTab,
                      icon: const Icon(Icons.add),
                      tooltip: AppStrings.newTabTooltip,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimens.spacing8),
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final tab = tabs[index];
                    final isSelected = index == currentIndex;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spacing8,
                        vertical: AppDimens.spacing4,
                      ),
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : null,
                      child: ListTile(
                        leading: Icon(
                          Icons.language,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          tab.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          tab.url.isEmpty ? AppStrings.newTab : tab.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: tabs.length > 1
                            ? IconButton(
                                onPressed: () => onTabClosed(index),
                                icon: const Icon(Icons.close, size: 20),
                                tooltip: AppStrings.closeTabTooltip,
                              )
                            : null,
                        onTap: () => onTabSelected(index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}