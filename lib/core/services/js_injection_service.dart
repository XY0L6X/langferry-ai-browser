import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 文本节点模型
class TextNode {
  final String id;
  final String text;
  final String tag;
  final String? xpath;

  const TextNode({
    required this.id,
    required this.text,
    required this.tag,
    this.xpath,
  });

  factory TextNode.fromJson(Map<String, dynamic> json) {
    return TextNode(
      id: json['id'] as String,
      text: json['text'] as String,
      tag: json['tag'] as String,
      xpath: json['xpath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'tag': tag,
        'xpath': xpath,
      };
}

/// 翻译项目模型
class TranslationItem {
  final String id;
  final String text;

  const TranslationItem({
    required this.id,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
      };
}

/// 翻译统计信息
class TranslationStats {
  final int totalNodes;
  final int translatedNodes;
  final String currentMode;

  const TranslationStats({
    required this.totalNodes,
    required this.translatedNodes,
    required this.currentMode,
  });

  factory TranslationStats.fromJson(Map<String, dynamic> json) {
    return TranslationStats(
      totalNodes: json['totalNodes'] as int? ?? 0,
      translatedNodes: json['translatedNodes'] as int? ?? 0,
      currentMode: json['currentMode'] as String? ?? 'none',
    );
  }
}

/// JS注入服务
class JsInjectionService {
  InAppWebViewController? _controller;
  bool _isInitialized = false;

  JsInjectionService({InAppWebViewController? controller})
      : _controller = controller;

  set controller(InAppWebViewController? value) {
    _controller = value;
    _isInitialized = false;
  }

  InAppWebViewController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  /// 执行JavaScript代码
  Future<dynamic> _evaluateJavascript(String js) async {
    if (_controller == null) {
      throw Exception('WebView controller is not available');
    }
    return await _controller!.evaluateJavascript(source: js);
  }

  /// 注入JS文件
  Future<void> injectJsFile(String jsContent) async {
    if (_controller == null) return;
    try {
      await _controller!.evaluateJavascript(source: jsContent);
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] 注入JS文件失败: $e');
    }
  }

  /// 初始化JS脚本（每次页面加载时调用）
  Future<void> initScripts() async {
    if (_controller == null) return;
    try {
      final extractJs = await rootBundle.loadString('assets/js/extract_text.js');
      await injectJsFile(extractJs);

      final replaceJs = await rootBundle.loadString('assets/js/replace_text.js');
      await injectJsFile(replaceJs);

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] 初始化JS脚本失败: $e');
    }
  }

  /// 提取网页文本
  Future<List<TextNode>> extractText() async {
    if (_controller == null) {
      throw Exception('WebView controller is not available');
    }
    try {
      final result = await _evaluateJavascript(
        'JSON.stringify(window.extractTextContent())',
      );
      if (result == null || result.toString().isEmpty) {
        if (kDebugMode) print('[JsInjectionService] extractText返回空结果');
        return [];
      }
      final String resultStr = result.toString();
      if (kDebugMode) print('[JsInjectionService] extractText结果长度: ${resultStr.length}');
      
      // 检查是否是有效的JSON
      if (!resultStr.startsWith('[')) {
        final preview = resultStr.length > 100 ? '${resultStr.substring(0, 100)}...' : resultStr;
        if (kDebugMode) print('[JsInjectionService] extractText返回的不是JSON数组: $preview');
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(resultStr);
      if (kDebugMode) print('[JsInjectionService] extractText提取了 ${jsonList.length} 个文本节点');
      
      final textNodes = jsonList.map((json) => TextNode.fromJson(json)).toList();
      if (textNodes.isNotEmpty) {
        final firstText = textNodes.first.text;
        final preview = firstText.length > 50 ? '${firstText.substring(0, 50)}...' : firstText;
        if (kDebugMode) print('[JsInjectionService] 第一个节点: id=${textNodes.first.id}, text=$preview');
      }
      
      return textNodes;
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] 提取文本失败: $e');
      return [];
    }
  }

  /// 替换网页文本
  Future<int> replaceText(List<TranslationItem> translations) async {
    if (_controller == null) {
      throw Exception('WebView controller is not available');
    }
    try {
      if (kDebugMode) print('[JsInjectionService] replaceText: 准备替换 ${translations.length} 个节点');
      if (translations.isNotEmpty) {
        final firstText = translations.first.text;
        final preview = firstText.length > 50 ? '${firstText.substring(0, 50)}...' : firstText;
        if (kDebugMode) print('[JsInjectionService] 第一个翻译: id=${translations.first.id}, text=$preview');
      }
      
      final json = jsonEncode(translations.map((t) => t.toJson()).toList());
      if (kDebugMode) print('[JsInjectionService] replaceText JSON长度: ${json.length}');
      // 使用Base64编码安全传输JSON，避免特殊字符破坏JavaScript字符串
      final base64Json = base64Encode(utf8.encode(json));
      // 用TextDecoder正确解码UTF-8多字节字符（修复中文乱码）
      final result = await _evaluateJavascript(
        '(function(){'
        'var b="$base64Json";'
        'var s=atob(b);'
        'var u=new Uint8Array(s.length);'
        'for(var i=0;i<s.length;i++)u[i]=s.charCodeAt(i);'
        'return window.replaceTextContent(JSON.parse(new TextDecoder("utf-8").decode(u)));'
        '})()',
      );
      
      final replacedCount = int.tryParse(result?.toString() ?? '0') ?? 0;
      if (kDebugMode) print('[JsInjectionService] replaceText: 成功替换 $replacedCount 个节点');
      
      if (replacedCount == 0 && translations.isNotEmpty) {
        throw Exception('文本替换失败：0个节点被替换，预期 ${translations.length} 个节点');
      }
      
      return replacedCount;
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] 替换文本失败: $e');
      return 0;
    }
  }

  /// 切换到原文模式
  Future<void> showOriginal() async {
    try {
      await _evaluateJavascript('window.showOriginal()');
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] showOriginal失败: $e');
    }
  }

  /// 切换到译文模式
  Future<void> showTranslated() async {
    try {
      await _evaluateJavascript('window.showTranslated()');
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] showTranslated失败: $e');
    }
  }

  /// 切换到对照模式
  Future<void> showBilingual() async {
    try {
      await _evaluateJavascript('window.showBilingual()');
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] showBilingual失败: $e');
    }
  }

  /// 清除所有翻译
  Future<void> clearTranslations() async {
    try {
      await _evaluateJavascript('window.clearTranslations()');
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] clearTranslations失败: $e');
    }
  }

  /// 获取当前显示模式
  Future<String> getCurrentMode() async {
    try {
      final result = await _evaluateJavascript('window.getCurrentMode()');
      return result?.toString() ?? 'unknown';
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] getCurrentMode失败: $e');
      return 'unknown';
    }
  }

  /// 获取翻译统计信息
  Future<TranslationStats?> getTranslationStats() async {
    try {
      final result = await _evaluateJavascript(
        'JSON.stringify(window.getTranslationStats())',
      );
      if (result == null || result.toString().isEmpty) return null;
      final Map<String, dynamic> json = jsonDecode(result.toString());
      return TranslationStats.fromJson(json);
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] getTranslationStats失败: $e');
      return null;
    }
  }

  /// 获取网页标题
  Future<String> getPageTitle() async {
    try {
      final result = await _evaluateJavascript('window.getPageTitle()');
      return result?.toString() ?? '';
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] getPageTitle失败: $e');
      return '';
    }
  }

  /// 获取网页语言
  Future<String> getPageLanguage() async {
    try {
      final result = await _evaluateJavascript('window.getPageLanguage()');
      return result?.toString() ?? 'auto';
    } catch (e) {
      if (kDebugMode) print('[JsInjectionService] getPageLanguage失败: $e');
      return 'auto';
    }
  }

  /// 注入选中文本监听器
  Future<void> injectSelectionListener() async {
    const js = '''
      (function() {
          let selectionTimeout = null;
          document.addEventListener('selectionchange', function() {
              if (selectionTimeout) clearTimeout(selectionTimeout);
              selectionTimeout = setTimeout(function() {
                  const selection = window.getSelection();
                  if (selection && selection.toString().trim().length > 0) {
                      const text = selection.toString().trim();
                      if (text.length >= 2 && text.length <= 5000) {
                          if (window.flutter_inappwebview) {
                              window.flutter_inappwebview.callHandler('onTextSelected', text);
                          }
                      }
                  }
              }, 300);
          });
      })();
    ''';
    await injectJsFile(js);
  }
}