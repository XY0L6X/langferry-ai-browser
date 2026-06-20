import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// PaddleOCR 任务状态
enum OcrJobState { pending, running, done, failed }

/// OCR 任务进度
class OcrProgress {
  final OcrJobState state;
  final int totalPages;
  final int extractedPages;
  final String? errorMsg;
  final String? resultUrl;

  OcrProgress({
    required this.state,
    this.totalPages = 0,
    this.extractedPages = 0,
    this.errorMsg,
    this.resultUrl,
  });

  double get progress => totalPages > 0 ? extractedPages / totalPages : 0;
}

/// OCR 结果页
class OcrPage {
  final int pageNum;
  final String markdown;
  final List<String> images;

  OcrPage({
    required this.pageNum,
    required this.markdown,
    this.images = const [],
  });
}

/// PaddleOCR API 服务
class PaddleOcrService {
  static const String _baseUrl = 'https://paddleocr.aistudio-app.com/api/v2/ocr/jobs';
  static const String _model = 'PaddleOCR-VL-1.6';

  final Dio _dio;
  String _token = '';

  PaddleOcrService() : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  void setToken(String token) => _token = token;

  Map<String, String> get _headers => {
        'Authorization': 'bearer $_token',
      };

  /// 提交 OCR 任务
  Future<String> submitJob(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('文件不存在: $filePath');

    final data = {
      'model': _model,
      'optionalPayload': jsonEncode({
        'useDocOrientationClassify': true,
        'useDocUnwarping': true,
        'useChartRecognition': false,
      }),
    };

    final formData = FormData.fromMap({
      ...data,
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post(_baseUrl, data: formData, options: Options(headers: _headers));
    return response.data['data']['jobId'];
  }

  /// 查询任务进度
  Future<OcrProgress> getProgress(String jobId) async {
    final response = await _dio.get('$_baseUrl/$jobId', options: Options(headers: _headers));
    final data = response.data['data'];
    final state = _parseState(data['state']);

    int total = 0, extracted = 0;
    if (data['extractProgress'] != null) {
      total = data['extractProgress']['totalPages'] ?? 0;
      extracted = data['extractProgress']['extractedPages'] ?? 0;
    }

    String? resultUrl;
    if (state == OcrJobState.done && data['resultUrl'] != null) {
      resultUrl = data['resultUrl']['jsonUrl'];
    }

    return OcrProgress(
      state: state,
      totalPages: total,
      extractedPages: extracted,
      errorMsg: state == OcrJobState.failed ? data['errorMsg'] : null,
      resultUrl: resultUrl,
    );
  }

  /// 下载并解析 OCR 结果
  Future<List<OcrPage>> fetchResults(String jsonlUrl) async {
    final response = await _dio.get(
      jsonlUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final lines = (response.data as String).trim().split('\n');
    final pages = <OcrPage>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      try {
        final result = jsonDecode(line)['result'];
        for (final res in result['layoutParsingResults']) {
          final mdText = res['markdown']['text'] ?? '';
          final images = <String>[];
          if (res['markdown']['images'] != null) {
            (res['markdown']['images'] as Map).forEach((_, url) {
              images.add(url.toString());
            });
          }
          pages.add(OcrPage(pageNum: pages.length, markdown: mdText, images: images));
        }
      } catch (e) {
        if (kDebugMode) print('[PaddleOCR] 解析行失败: $e');
      }
    }
    return pages;
  }

  OcrJobState _parseState(String state) {
    switch (state) {
      case 'pending': return OcrJobState.pending;
      case 'running': return OcrJobState.running;
      case 'done':    return OcrJobState.done;
      default:        return OcrJobState.failed;
    }
  }
}
