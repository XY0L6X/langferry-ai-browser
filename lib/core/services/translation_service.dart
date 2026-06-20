import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'api_client.dart';
import 'database_service.dart';
import 'js_injection_service.dart';
import '../../models/api_config.dart';

/// 翻译结果模型
class TranslationResult {
  final String translatedText;
  final bool fromCache;

  const TranslationResult({
    required this.translatedText,
    required this.fromCache,
  });
}

/// 翻译块模型（用于流式）
class TranslationChunk {
  final String text;
  final bool isComplete;

  const TranslationChunk({
    required this.text,
    required this.isComplete,
  });
}

/// 翻译异常
class TranslationException implements Exception {
  final String message;

  const TranslationException(this.message);

  @override
  String toString() => 'TranslationException: $message';
}

/// 翻译服务
/// 处理翻译业务逻辑，包括分段、缓存、历史记录
class TranslationService {
  final ApiClient _apiClient;
  final DatabaseService _database;

  TranslationService({
    required ApiClient apiClient,
    required DatabaseService database,
  })  : _apiClient = apiClient,
        _database = database;

  /// 翻译文本（非流式）
  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String? systemPrompt,
    bool useCache = true,
  }) async {
    // 1. 检查缓存
    if (useCache) {
      final cacheKey = _generateCacheKey(text, targetLanguage);
      final cached = _database.getCachedTranslation(cacheKey);
      if (cached != null) {
        return TranslationResult(
          translatedText: cached,
          fromCache: true,
        );
      }
    }

    // 2. 获取激活的API配置
    final config = _database.getActiveApiConfig();
    if (config == null) {
    if (kDebugMode) print('[TranslationService] 未找到激活的API配置');
    if (kDebugMode) print('[TranslationService] 所有配置: ${_database.getAllApiConfigs().map((c) => '${c.name} (active: ${c.isActive})').toList()}');
      throw const TranslationException('未配置API，请先在设置中配置翻译API');
    }
    
    if (kDebugMode) print('[TranslationService] 使用API: ${config.name}, model: ${config.model}');
    if (kDebugMode) print('[TranslationService] endpoint: ${config.endpoint}');

    // 3. 分段处理长文本
    final segments = _splitText(text);
    final translatedSegments = <String>[];

    for (final segment in segments) {
      final response = await _apiClient.translate(
        config: config,
        text: segment,
        targetLanguage: targetLanguage,
        systemPrompt: systemPrompt,
      );
      translatedSegments.add(response.translatedText);
    }

    // 4. 合并结果
    final translatedText = translatedSegments.join('\n');

    // 5. 保存缓存
    if (useCache) {
      final cacheKey = _generateCacheKey(text, targetLanguage);
      await _database.saveTranslationCache(cacheKey, translatedText);
    }

    return TranslationResult(
      translatedText: translatedText,
      fromCache: false,
    );
  }

  /// 翻译文本（流式）
  Stream<TranslationChunk> translateStream({
    required String text,
    required String targetLanguage,
    String? systemPrompt,
  }) async* {
    final config = _database.getActiveApiConfig();
    if (config == null) {
      throw const TranslationException('未配置API，请先在设置中配置翻译API');
    }

    final segments = _splitText(text);

    for (final segment in segments) {
      String fullText = '';

      await for (final chunk in _apiClient.translateStream(
        config: config,
        text: segment,
        targetLanguage: targetLanguage,
        systemPrompt: systemPrompt,
      )) {
        fullText += chunk;
        yield TranslationChunk(
          text: chunk,
          isComplete: false,
        );
      }

      // 保存完整翻译结果到缓存
      final cacheKey = _generateCacheKey(segment, targetLanguage);
      await _database.saveTranslationCache(cacheKey, fullText);
    }

    yield const TranslationChunk(
      text: '',
      isComplete: true,
    );
  }

  /// 全页翻译入口（给 TranslationCoordinator 调用）
  /// 自动处理缓存、批处理、并发，通过回调支持渐进注入
  Future<List<NodeTranslationResult>> translatePageNodes({
    required List<TextNode> textNodes,
    required String targetLanguage,
    String? systemPrompt,
    int maxConcurrency = 4,
    int maxBatchChars = 2000,
    bool Function()? isCancelled,
    Function(List<TranslationItem> translations)? onBatchComplete,
    Function(int done, int total)? onProgress,
  }) async {
    final config = _database.getActiveApiConfig();
    if (config == null) {
      throw const TranslationException('未配置API，请先在设置中配置翻译API');
    }

    // 1. 分离缓存命中和未缓存
    final results = List<NodeTranslationResult?>.filled(textNodes.length, null);
    final cacheHits = <TranslationItem>[];
    final toTranslate = <({int index, TextNode node})>[];

    for (var i = 0; i < textNodes.length; i++) {
      final node = textNodes[i];
      final cacheKey = _generateCacheKey(node.text, targetLanguage);
      final cached = _database.getCachedTranslation(cacheKey);
      if (cached != null) {
        results[i] = NodeTranslationResult(
          id: node.id,
          text: cached,
          success: true,
          fromCache: true,
        );
        cacheHits.add(TranslationItem(id: node.id, text: cached));
      } else {
        toTranslate.add((index: i, node: node));
      }
    }

    if (kDebugMode) print('[TranslationService] 缓存命中: ${cacheHits.length}/${textNodes.length}');

    // 立即注入缓存命中的结果
    if (cacheHits.isNotEmpty && onBatchComplete != null) {
      await onBatchComplete(cacheHits);
    }
    if (toTranslate.isEmpty) {
      onProgress?.call(textNodes.length, textNodes.length);
      return results.whereType<NodeTranslationResult>().toList();
    }

    // 2. 分批：将待翻译节点按字符数分组
    final batches = <_NodeBatch>[];
    var currentBatch = <({int index, TextNode node})>[];
    var currentChars = 0;

    for (final item in toTranslate) {
      if (currentChars + item.node.text.length > maxBatchChars && currentBatch.isNotEmpty) {
        batches.add(_NodeBatch(items: currentBatch));
        currentBatch = [];
        currentChars = 0;
      }
      currentBatch.add(item);
      currentChars += item.node.text.length;
    }
    if (currentBatch.isNotEmpty) {
      batches.add(_NodeBatch(items: currentBatch));
    }

    if (kDebugMode) print('[TranslationService] ${toTranslate.length} 个节点分为 ${batches.length} 个批次');

    // 3. 并发执行各批次
    final semaphore = _Semaphore(maxConcurrency);
    int completedBatches = 0;
    int completedItems = cacheHits.length;

    final futures = batches.map((batch) async {
      if (isCancelled?.call() == true) return;
      await semaphore.acquire();
      try {
        if (isCancelled?.call() == true) return;
        final batchResults = await _translateNodeBatch(
          config: config,
          batch: batch,
          targetLanguage: targetLanguage,
          systemPrompt: systemPrompt,
        );
        // 写入结果
        for (final entry in batchResults.entries) {
          results[entry.key] = entry.value;
        }
        // 渐进注入回调
        if (onBatchComplete != null) {
          final items = batchResults.entries
              .map((e) => TranslationItem(id: e.value.id, text: e.value.text))
              .toList();
          await onBatchComplete(items);
        }
        completedBatches++;
        completedItems += batch.items.length;
        onProgress?.call(completedItems, textNodes.length);
      } finally {
        semaphore.release();
      }
    }).toList();

    await Future.wait(futures);

    // 4. 为未翻译的节点填上原文
    for (var i = 0; i < results.length; i++) {
      results[i] ??= NodeTranslationResult(
        id: textNodes[i].id,
        text: textNodes[i].text,
        success: false,
        error: '未翻译',
      );
    }

    return results.whereType<NodeTranslationResult>().toList();
  }

  /// 翻译一个节点批次（JSON 模式，更可靠）
  Future<Map<int, NodeTranslationResult>> _translateNodeBatch({
    required ApiConfig config,
    required _NodeBatch batch,
    required String targetLanguage,
    String? systemPrompt,
  }) async {
    final items = batch.items;
    final texts = items.map((item) => item.node.text).toList();

    // JSON 数组格式的批处理提示词（比分隔符模式更可靠）
    final jsonInput = jsonEncode(texts);
    final batchPrompt = systemPrompt ??
        '你是一个专业的网页翻译助手。请将以下 JSON 数组中的每个文本翻译成$targetLanguage。'
            '返回一个 JSON 数组，顺序与输入一致。只输出 JSON 数组，不要添加任何解释。';

    if (kDebugMode) print('[TranslationService] 批次翻译: ${items.length} 个节点, ${jsonInput.length} 字符');

    try {
      final response = await _apiClient.translate(
        config: config,
        text: jsonInput,
        targetLanguage: targetLanguage,
        systemPrompt: batchPrompt,
      );

      // 尝试解析 JSON 响应
      final results = <int, NodeTranslationResult>{};
      List<String>? translatedParts;
      
      try {
        final decoded = jsonDecode(response.translatedText);
        if (decoded is List) {
          translatedParts = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // JSON 解析失败，回退到分隔符模式
      }
      
      if (translatedParts == null) {
        // 回退：尝试移除 markdown 代码块标记后解析
        var cleaned = response.translatedText.trim();
        cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
        cleaned = cleaned.replaceAll(RegExp(r'\s*```$'), '');
        try {
          final decoded = jsonDecode(cleaned);
          if (decoded is List) {
            translatedParts = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }

      // 如果 JSON 解析仍然失败，回退到分隔符模式
      if (translatedParts == null) {
        translatedParts = response.translatedText.split('|||LANGFERRY_SEP|||');
      }

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (i < translatedParts.length) {
          final translated = translatedParts[i].trim();
          if (translated.isNotEmpty) {
            // 即使是与原文相同（专有名词等），也算成功
            final cacheKey = _generateCacheKey(item.node.text, targetLanguage);
            await _database.saveTranslationCache(cacheKey, translated);
            results[item.index] = NodeTranslationResult(
              id: item.node.id,
              text: translated,
              success: true,
            );
          } else {
            results[item.index] = NodeTranslationResult(
              id: item.node.id,
              text: item.node.text,
              success: false,
              error: '译文为空',
            );
          }
        } else {
          results[item.index] = NodeTranslationResult(
            id: item.node.id,
            text: item.node.text,
            success: false,
            error: '批次解析失败：数量不匹配',
          );
        }
      }

      return results;
    } catch (e) {
      // 整个批次失败，回退为逐节点标记失败
      if (kDebugMode) print('[TranslationService] 批次翻译异常: $e');
      final results = <int, NodeTranslationResult>{};
      for (final item in items) {
        results[item.index] = NodeTranslationResult(
          id: item.node.id,
          text: item.node.text,
          success: false,
          error: e.toString(),
        );
      }
      return results;
    }
  }

  /// 分段处理长文本
  List<String> _splitText(String text, {int maxLength = 2000}) {
    if (text.length <= maxLength) {
      return [text];
    }

    final segments = <String>[];
    final paragraphs = text.split('\n');

    String currentSegment = '';

    for (final paragraph in paragraphs) {
      if (currentSegment.length + paragraph.length > maxLength) {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment);
        }
        currentSegment = paragraph;
      } else {
        if (currentSegment.isNotEmpty) {
          currentSegment += '\n';
        }
        currentSegment += paragraph;
      }
    }

    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    return segments;
  }

  /// 生成缓存键
  String _generateCacheKey(String text, String targetLanguage) {
    final bytes = utf8.encode('$text:$targetLanguage');
    return sha256.convert(bytes).toString();
  }
}

/// 批量翻译结果项
class TranslationItemResult {
  final String originalText;
  final String translatedText;
  final bool success;
  final String? error;

  const TranslationItemResult({
    required this.originalText,
    required this.translatedText,
    required this.success,
    this.error,
  });
}

/// 全页翻译节点结果
class NodeTranslationResult {
  final String id;
  final String text;
  final bool success;
  final bool fromCache;
  final String? error;

  const NodeTranslationResult({
    required this.id,
    required this.text,
    required this.success,
    this.fromCache = false,
    this.error,
  });
}

/// 翻译批次（内部使用）
class _NodeBatch {
  final List<({int index, TextNode node})> items;
  _NodeBatch({required this.items});
}

/// 简易信号量，控制并发数
class _Semaphore {
  int _permits;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this._permits);

  Future<void> acquire() async {
    if (_permits > 0) {
      _permits--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _permits++;
    }
  }
}