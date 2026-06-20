import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../../models/api_config.dart';

/// 翻译响应模型
class TranslationResponse {
  final String translatedText;
  final String model;
  final int? promptTokens;
  final int? completionTokens;

  const TranslationResponse({
    required this.translatedText,
    required this.model,
    this.promptTokens,
    this.completionTokens,
  });

  factory TranslationResponse.fromJson(Map<String, dynamic> json, String model) {
    return TranslationResponse(
      translatedText: json['choices'][0]['message']['content'] as String,
      model: model,
      promptTokens: json['usage']?['prompt_tokens'] as int?,
      completionTokens: json['usage']?['completion_tokens'] as int?,
    );
  }
}

/// API测试结果
class ApiTestResult {
  final bool success;
  final String message;
  final String? response;

  const ApiTestResult({
    required this.success,
    required this.message,
    this.response,
  });
}

/// API客户端
/// 封装Dio，支持多种翻译API
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
      ));
    }
  }

  /// 发送翻译请求（非流式）
  Future<TranslationResponse> translate({
    required ApiConfig config,
    required String text,
    required String targetLanguage,
    String? systemPrompt,
  }) async {
    final request = _buildRequest(
      config: config,
      text: text,
      targetLanguage: targetLanguage,
      systemPrompt: systemPrompt,
      stream: false,
    );

    // 构建完整URL
    String url = config.endpoint;
    if (!url.endsWith('/chat/completions')) {
      if (url.endsWith('/')) {
        url = '${url}chat/completions';
      } else {
        url = '$url/chat/completions';
      }
    }

    if (kDebugMode) {
      print('[ApiClient] 请求URL: $url');
      print('[ApiClient] 请求模型: ${config.model}');
    }

    final response = await _dio.post(
      url,
      options: Options(
        headers: _buildHeaders(config),
      ),
      data: request,
    );

    return TranslationResponse.fromJson(response.data, config.model);
  }

  /// 发送翻译请求（流式）
  Stream<String> translateStream({
    required ApiConfig config,
    required String text,
    required String targetLanguage,
    String? systemPrompt,
  }) async* {
    final request = _buildRequest(
      config: config,
      text: text,
      targetLanguage: targetLanguage,
      systemPrompt: systemPrompt,
      stream: true,
    );

    final response = await _dio.post(
      config.endpoint,
      options: Options(
        headers: _buildHeaders(config),
        responseType: ResponseType.stream,
      ),
      data: request,
    );

    // 解析SSE流
    yield* _parseSSEStream(response.data.stream);
  }

  /// 构建请求头
  Map<String, String> _buildHeaders(ApiConfig config) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
  }

  /// 构建请求体
  Map<String, dynamic> _buildRequest({
    required ApiConfig config,
    required String text,
    required String targetLanguage,
    String? systemPrompt,
    bool stream = false,
  }) {
    final defaultPrompt =
        '你是一个专业的网页翻译助手。请将以下内容翻译成$targetLanguage，保持自然流畅，不要添加任何解释。';

    return {
      'model': config.model,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt ?? defaultPrompt,
        },
        {
          'role': 'user',
          'content': text,
        },
      ],
      'stream': stream,
      'temperature': 0.3,
      'max_tokens': 4096,
    };
  }

  /// 解析SSE流
  Stream<String> _parseSSEStream(Stream<List<int>> stream) async* {
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);

      // 按行解析SSE
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // 保留未完成的行

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;

          try {
            final json = jsonDecode(data);
            final choices = json['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'];
              if (delta != null && delta['content'] != null) {
                yield delta['content'] as String;
              }
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    }
  }

  /// 测试API连接
  Future<ApiTestResult> testConnection(ApiConfig config) async {
    try {
      if (kDebugMode) {
        final keyPreview = config.apiKey.length > 10 ? '${config.apiKey.substring(0, 10)}...' : (config.apiKey.isEmpty ? '(空)' : config.apiKey);
        print('[ApiClient] 测试连接: ${config.name}, endpoint: ${config.endpoint}');
        print('[ApiClient] 模型: ${config.model}');
        print('[ApiClient] API Key 长度: ${config.apiKey.length}');
      }
      
      final response = await translate(
        config: config,
        text: 'Hello',
        targetLanguage: 'Chinese',
      );
      
      if (kDebugMode) print('[ApiClient] 测试成功: ${response.translatedText}');
      return ApiTestResult(
        success: true,
        message: '连接成功',
        response: response.translatedText,
      );
    } on DioException catch (e) {
      String errorMsg = '请求失败';
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        final respStr = responseData?.toString() ?? '';
        errorMsg = 'HTTP $statusCode: ${respStr.length > 100 ? '${respStr.substring(0, 100)}...' : respStr}';
        if (errorMsg.isEmpty) errorMsg = 'HTTP $statusCode: 未知错误';
        if (kDebugMode) print('[ApiClient] HTTP错误: $errorMsg');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = '连接超时';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMsg = '发送超时';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '接收超时';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '连接错误: ${e.message}';
      }
      if (kDebugMode) print('[ApiClient] 测试连接失败: $errorMsg');
      return ApiTestResult(
        success: false,
        message: errorMsg,
      );
    } catch (e) {
      if (kDebugMode) print('[ApiClient] 测试连接异常: $e');
      return ApiTestResult(
        success: false,
        message: e.toString().length > 100
            ? '异常: ${e.toString().substring(0, 100)}...'
            : '异常: $e',
      );
    }
  }

  /// 生成缓存键
  static String generateCacheKey(String text, String targetLanguage) {
    final bytes = utf8.encode('$text:$targetLanguage');
    return sha256.convert(bytes).toString();
  }
}