import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/services/js_injection_service.dart';
import '../../../core/services/download_service.dart';

/// WebView容器组件
class WebViewContainer extends StatefulWidget {
  final String url;
  final bool desktopMode;
  final ValueChanged<String> onPageStarted;
  final Function(String url, String title) onPageFinished;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<String> onError;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<InAppWebViewController>? onWebViewCreated;
  final ValueChanged<JsInjectionService>? onJsServiceReady;
  final ValueChanged<String>? onTextSelected;

  const WebViewContainer({
    super.key,
    required this.url,
    this.desktopMode = false,
    required this.onPageStarted,
    required this.onPageFinished,
    required this.onProgressChanged,
    required this.onError,
    required this.onTitleChanged,
    this.onWebViewCreated,
    this.onJsServiceReady,
    this.onTextSelected,
  });

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  InAppWebViewController? _webViewController;
  late JsInjectionService _jsService;
  String _currentUrl = '';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _jsService = JsInjectionService(controller: null);
  }

  void _loadUrl(String url) {
    if (_webViewController != null && url.isNotEmpty) {
      _webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );
    }
  }

  /// 处理下载请求
  void _handleDownload(String url) async {
    final downloadService = DownloadService.instance;
    try {
      await downloadService.startDownload(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始下载: ${Uri.parse(url).pathSegments.isNotEmpty ? Uri.parse(url).pathSegments.last : url}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 注入JS文件
  Future<void> _injectJsFiles() async {
    try {
      await _jsService.initScripts();

      // 注入选中文本监听器
      await _jsService.injectSelectionListener();

      // 注入广告拦截
      await _injectAdBlocker();

      if (kDebugMode) print('[WebViewContainer] JS文件注入完成');
    } catch (e) {
      if (kDebugMode) print('[WebViewContainer] 注入JS文件失败: $e');
    }
  }

  /// 注入基础广告拦截 CSS
  Future<void> _injectAdBlocker() async {
    if (_webViewController == null) return;
    const adBlockCss = r'''
      [class*="ad-"],[class*="-ad-"],[class*="_ad"],[class*="ad_"],
      [id*="ad-"],[id*="-ad-"],[id*="google_ads"],
      [class*="sponsor"],ins.adsbygoogle,
      iframe[src*="doubleclick"],iframe[src*="googlesyndication"],
      div[data-ad],div[id*="google_ads"],.adsbygoogle,.AdSense,
      .ad-container,.ad-wrapper,.advertisement,
      [aria-label*="广告"],[aria-label*="advertisement"],
      .popup-ad,.modal-ad,.sticky-ad,.float-ad
      {display:none!important;height:0!important;overflow:hidden!important;}
    ''';
    await _webViewController!.evaluateJavascript(source: '''
      (function() {
        var style = document.createElement('style');
        style.id = '__wl_adblock__';
        style.textContent = ${jsonEncode(adBlockCss)};
        document.head.appendChild(style);
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // WebView
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(widget.url.isNotEmpty ? widget.url : 'about:blank'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: false,
            supportZoom: true,
            builtInZoomControls: true,
            displayZoomControls: false,
            cacheEnabled: true,
            cacheMode: CacheMode.LOAD_DEFAULT,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
            mediaPlaybackRequiresUserGesture: false,
            verticalScrollBarEnabled: true,
            horizontalScrollBarEnabled: false,
            useWideViewPort: true,
            loadWithOverviewMode: true,
            overScrollMode: OverScrollMode.NEVER,
            // 启用下载功能
            useOnLoadResource: true,
            useOnDownloadStart: true,
            userAgent: widget.desktopMode
                ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                : null,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _jsService = JsInjectionService(controller: controller);
            widget.onWebViewCreated?.call(controller);
            
            // 添加JavaScript处理器来拦截下载
            controller.addJavaScriptHandler(
              handlerName: 'onDownloadStart',
              callback: (args) async {
                if (args.isNotEmpty && args[0] is Map) {
                  final data = args[0] as Map;
                  final url = data['url'] as String?;
                  if (url != null && url.isNotEmpty) {
                    _handleDownload(url);
                  }
                }
              },
            );
          },
          // 原生下载拦截（主要下载路径，不依赖JS注入）
          onDownloadStartRequest: (controller, request) async {
            final urlStr = request.url?.toString() ?? '';
            if (urlStr.isNotEmpty) {
              _handleDownload(urlStr);
            }
          },
          onLoadStart: (controller, url) {
            setState(() {
              _currentUrl = url?.toString() ?? '';
            });
            widget.onPageStarted(_currentUrl);
          },
          onLoadStop: (controller, url) async {
            // 注入JS文件
            await _injectJsFiles();

            // 通知外部JS服务就绪
            widget.onJsServiceReady?.call(_jsService);

            final title = await controller.getTitle();
            setState(() {
              _currentUrl = url?.toString() ?? '';
            });
            widget.onPageFinished(_currentUrl, title ?? '');
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              _progress = progress / 100;
            });
            widget.onProgressChanged(_progress);
          },
          onTitleChanged: (controller, title) {
            widget.onTitleChanged(title ?? '');
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('WebView Console: ${consoleMessage.message}');
          },
        ),

        // 加载进度条
        if (_progress > 0 && _progress < 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}