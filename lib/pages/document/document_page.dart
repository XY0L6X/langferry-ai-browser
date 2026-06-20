import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/paddle_ocr_service.dart';
import '../../core/services/translation_service.dart';
import '../../providers/translation_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';

/// 文档翻译页面
class DocumentPage extends ConsumerStatefulWidget {
  const DocumentPage({super.key});

  @override
  ConsumerState<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends ConsumerState<DocumentPage> {
  final PaddleOcrService _ocrService = PaddleOcrService();
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  String _status = '';
  double _ocrProgress = 0;
  bool _isProcessing = false;

  List<String> _originalTexts = [];
  List<String> _translatedTexts = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  void _loadToken() {
    final token = ref.read(paddleOcrTokenProvider);
    _ocrService.setToken(token);
    _tokenController.text = token;
  }

  Future<void> _startOcr() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      setState(() => _status = '请输入文件路径');
      return;
    }
    final file = File(path);
    if (!await file.exists()) {
      setState(() => _status = '文件不存在');
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = '正在提交 OCR 任务...';
      _ocrProgress = 0;
      _originalTexts = [];
      _translatedTexts = [];
    });

    try {
      final jobId = await _ocrService.submitJob(path);
      setState(() => _status = '任务已提交，等待处理...');

      Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (!_isProcessing) { timer.cancel(); return; }
        try {
          final progress = await _ocrService.getProgress(jobId);
          if (!mounted) return;
          setState(() {
            _ocrProgress = progress.progress;
            _status = '处理中... ${progress.extractedPages}/${progress.totalPages} 页';
          });
          if (progress.state == OcrJobState.done && progress.resultUrl != null) {
            timer.cancel();
            setState(() => _status = '正在下载结果...');
            final pages = await _ocrService.fetchResults(progress.resultUrl!);
            _originalTexts = pages.map((p) => p.markdown).where((t) => t.isNotEmpty).toList();
            setState(() {
              _status = 'OCR 完成，共 ${pages.length} 页，开始翻译...';
              _isProcessing = false;
            });
            _startTranslation();
          } else if (progress.state == OcrJobState.failed) {
            timer.cancel();
            setState(() {
              _status = 'OCR 失败: ${progress.errorMsg}';
              _isProcessing = false;
            });
          }
        } catch (e) {
          timer.cancel();
          setState(() {
            _status = '查询进度失败: $e';
            _isProcessing = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _status = '提交失败: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _startTranslation() async {
    if (_originalTexts.isEmpty) return;
    setState(() => _isProcessing = true);

    final translationService = ref.read(translationServiceProvider);
    _translatedTexts = [];

    for (var i = 0; i < _originalTexts.length; i++) {
      try {
        final result = await translationService.translate(
          text: _originalTexts[i],
          targetLanguage: 'zh-CN',
          useCache: true,
        );
        _translatedTexts.add(result.translatedText);
      } catch (e) {
        _translatedTexts.add('翻译失败: $e');
      }
      if (mounted) {
        setState(() => _status = '翻译中... ${i + 1}/${_originalTexts.length}');
      }
    }
    setState(() {
      _isProcessing = false;
      _status = '翻译完成';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('文档翻译')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pathController,
              decoration: InputDecoration(
                labelText: '文件路径',
                hintText: '/storage/emulated/0/Download/论文.pdf',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isProcessing ? null : _startOcr,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_status.isNotEmpty)
              Column(
                children: [
                  LinearProgressIndicator(value: _ocrProgress > 0 ? _ocrProgress : null),
                  const SizedBox(height: 8),
                  Text(_status, style: theme.textTheme.bodySmall),
                ],
              ),
            const SizedBox(height: 16),
            if (_originalTexts.isNotEmpty && _translatedTexts.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _originalTexts.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text('第 ${index + 1} 段', style: theme.textTheme.bodyMedium),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('原文', style: theme.textTheme.labelSmall),
                            Text(_originalTexts[index]),
                            const Divider(),
                            Text('译文', style: theme.textTheme.labelSmall),
                            Text(index < _translatedTexts.length
                                ? _translatedTexts[index]
                                : '翻译中...'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isProcessing = false;
    _pathController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}
