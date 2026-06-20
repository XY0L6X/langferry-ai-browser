import 'dart:async';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'js_injection_service.dart';
import 'translation_service.dart';
import '../../providers/translation_provider.dart';

/// 翻译阶段
enum TranslationStage {
  extracting,
  translating,
  injecting,
  complete,
}

/// 翻译进度
class TranslationProgress {
  final TranslationStage stage;
  final double progress;
  final String? message;
  final bool success;
  final int? totalNodes;
  final int? processedNodes;

  const TranslationProgress({
    required this.stage,
    required this.progress,
    this.message,
    this.success = true,
    this.totalNodes,
    this.processedNodes,
  });
}

/// 翻译协调器
class TranslationCoordinator {
  final JsInjectionService _jsService;
  final TranslationService _translationService;
  bool _cancelled = false;
  StreamController<TranslationProgress>? _currentController;

  TranslationCoordinator({
    required JsInjectionService jsService,
    required TranslationService translationService,
  })  : _jsService = jsService,
        _translationService = translationService;

  /// 取消当前翻译
  void cancel() {
    _cancelled = true;
    _currentController?.close();
    _currentController = null;
  }

  /// 执行全页翻译（并发批处理 + 渐进注入 + 实时进度）
  Stream<TranslationProgress> translatePage({
    required String targetLanguage,
    String? systemPrompt,
    Function(List<TextNode>)? onTextExtracted,
  }) {
    _cancelled = false;
    final controller = StreamController<TranslationProgress>();
    _currentController = controller;

    _runTranslation(
      targetLanguage: targetLanguage,
      systemPrompt: systemPrompt,
      onTextExtracted: onTextExtracted,
      controller: controller,
    );

    return controller.stream;
  }

  Future<void> _runTranslation({
    required String targetLanguage,
    String? systemPrompt,
    Function(List<TextNode>)? onTextExtracted,
    required StreamController<TranslationProgress> controller,
  }) async {
    try {
      if (_cancelled) {
        controller.close();
        return;
      }
      
      controller.add(const TranslationProgress(
        stage: TranslationStage.extracting,
        progress: 0,
        message: '正在提取网页文本...',
      ));

      if (kDebugMode) print('[TranslationCoordinator] 开始提取网页文本');
      final textNodes = await _jsService.extractText();
      
      if (_cancelled) { controller.close(); return; }
      
      if (kDebugMode) print('[TranslationCoordinator] 提取到 ${textNodes.length} 个文本节点');

      if (textNodes.isEmpty) {
        controller.add(const TranslationProgress(
          stage: TranslationStage.complete,
          progress: 1,
          success: false,
          message: '未找到可翻译的文本',
        ));
        controller.close();
        return;
      }

      onTextExtracted?.call(textNodes);

      final total = textNodes.length;
      controller.add(TranslationProgress(
        stage: TranslationStage.translating,
        progress: 0.1,
        message: '正在并发翻译 $total 个文本段...',
        totalNodes: total,
        processedNodes: 0,
      ));

      // 并发批处理翻译（通过回调报告进度）
      final completed = await _translationService.translatePageNodes(
        textNodes: textNodes,
        targetLanguage: targetLanguage,
        systemPrompt: systemPrompt,
        maxConcurrency: 4,
        maxBatchChars: 2000,
        isCancelled: () => _cancelled,
        onBatchComplete: (batchTranslations) async {
          if (!_cancelled) {
            await _jsService.replaceText(batchTranslations);
          }
        },
        onProgress: (done, totalNodes) {
          if (!_cancelled) {
            final progress = 0.1 + (0.7 * done / totalNodes);
            controller.add(TranslationProgress(
              stage: TranslationStage.translating,
              progress: progress,
              message: '翻译中... $done/$totalNodes',
              totalNodes: totalNodes,
              processedNodes: done,
            ));
          }
        },
      );

      if (_cancelled) { controller.close(); return; }

      await _jsService.showTranslated();

      final successCount = completed.where((t) => t.success).length;
      final failedCount = total - successCount;

      if (failedCount > 0 && failedCount == total) {
        controller.add(TranslationProgress(
          stage: TranslationStage.complete,
          progress: 1,
          success: false,
          message: '翻译失败: 全部 $total 个节点翻译失败',
          totalNodes: total,
          processedNodes: 0,
        ));
      } else {
        controller.add(TranslationProgress(
          stage: TranslationStage.complete,
          progress: 1,
          success: true,
          message: failedCount > 0
              ? '翻译完成（部分失败: $failedCount/$total）'
              : '翻译完成',
          totalNodes: total,
          processedNodes: successCount,
        ));
      }
    } catch (e) {
      if (_cancelled) { controller.close(); return; }
      final errStr = e.toString();
      final msg = errStr.length > 80 ? '${errStr.substring(0, 80)}...' : errStr;
      if (kDebugMode) print('[TranslationCoordinator] 翻译流程异常: $errStr');
      controller.add(TranslationProgress(
        stage: TranslationStage.complete,
        progress: 1,
        success: false,
        message: '翻译失败: $msg',
      ));
    }
    controller.close();
  }

  /// 切换显示模式
  Future<void> setDisplayMode(TranslationMode mode) async {
    switch (mode) {
      case TranslationMode.original:
        await _jsService.showOriginal();
        break;
      case TranslationMode.translated:
        await _jsService.showTranslated();
        break;
      case TranslationMode.bilingual:
        await _jsService.showBilingual();
        break;
    }
  }

  /// 获取翻译统计信息
  Future<TranslationStats?> getStats() async {
    return await _jsService.getTranslationStats();
  }

  /// 清除所有翻译
  Future<void> clearTranslations() async {
    await _jsService.clearTranslations();
  }
}