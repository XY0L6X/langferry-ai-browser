import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  String _status = '';
  double _ocrProgress = 0;
  bool _isProcessing = false;
  String? _filePath;
  String? _fileName;
  List<String> _originalTexts = [];
  List<String> _translatedTexts = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _isProcessing = false;
    _pollTimer?.cancel();
    super.dispose();
  }

  void _loadToken() {
    final token = ref.read(paddleOcrTokenProvider);
    final model = ref.read(paddleOcrModelProvider);
    _ocrService.setToken(token);
    _ocrService.setModel(model);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        _status = '';
        _originalTexts = [];
        _translatedTexts = [];
      });
    }
  }

  Future<void> _startOcr() async {
    if (_filePath == null) {
      setState(() => _status = '请先选择文件');
      return;
    }
    final token = ref.read(paddleOcrTokenProvider);
    if (token.isEmpty) {
      setState(() => _status = '请先在设置中配置 PaddleOCR API 密钥');
      return;
    }
    _ocrService.setToken(token);

    setState(() {
      _isProcessing = true;
      _status = '正在提交 OCR 任务...';
      _ocrProgress = 0;
      _originalTexts = [];
      _translatedTexts = [];
    });

    try {
      final jobId = await _ocrService.submitJob(_filePath!);
      setState(() => _status = '任务已提交，等待处理...');

      _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
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
    final ts = ref.read(translationServiceProvider);
    _translatedTexts = [];
    for (var i = 0; i < _originalTexts.length; i++) {
      try {
        final result = await ts.translate(text: _originalTexts[i], targetLanguage: 'zh-CN', useCache: true);
        _translatedTexts.add(result.translatedText);
      } catch (e) {
        _translatedTexts.add('翻译失败: $e');
      }
      if (mounted) setState(() => _status = '翻译中... ${i + 1}/${_originalTexts.length}');
    }
    setState(() { _isProcessing = false; _status = '翻译完成'; });
  }

  Future<void> _exportResult() async {
    if (_originalTexts.isEmpty || _translatedTexts.isEmpty) return;
    final buffer = StringBuffer();
    buffer.writeln('文档翻译结果');
    buffer.writeln('文件: $_fileName');
    buffer.writeln('');
    for (var i = 0; i < _originalTexts.length; i++) {
      buffer.writeln('--- 第 ${i + 1} 段 ---');
      buffer.writeln('原文: ${_originalTexts[i]}');
      buffer.writeln('译文: ${_translatedTexts[i]}');
      buffer.writeln('');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/翻译_${_fileName ?? "doc"}_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: '文档翻译导出');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasToken = ref.watch(paddleOcrTokenProvider).isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('文档翻译'),
        actions: [
          if (_originalTexts.isNotEmpty)
            IconButton(icon: const Icon(Icons.share), onPressed: _exportResult, tooltip: '导出'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 文件选择区
            Card(
              child: InkWell(
                onTap: _isProcessing ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(_filePath != null ? Icons.insert_drive_file : Icons.cloud_upload,
                          size: 48, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(_fileName ?? '点击选择文件',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('支持 PDF / Word / TXT / 图片',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing || _filePath == null ? null : _startOcr,
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('开始识别并翻译'),
                  ),
                ),
              ],
            ),
            if (!hasToken)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('⚠️ 请先在设置中配置 PaddleOCR API 密钥',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center),
              ),
            // 进度
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _ocrProgress > 0 ? _ocrProgress : null),
              const SizedBox(height: 8),
              Text(_status, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
            // 对照结果
            if (_originalTexts.isNotEmpty && _translatedTexts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('翻译结果', style: theme.textTheme.titleMedium),
              ...List.generate(_originalTexts.length, (index) => Card(
                margin: const EdgeInsets.only(top: 8),
                child: ExpansionTile(
                  title: Text('第 ${index + 1} 段', style: theme.textTheme.bodyMedium),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('原文', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(_originalTexts[index]),
                        const Divider(),
                        Text('译文', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(index < _translatedTexts.length ? _translatedTexts[index] : '翻译中...'),
                      ]),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
