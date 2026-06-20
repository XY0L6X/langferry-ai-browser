import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/log_service.dart';
import '../../core/services/js_injection_service.dart';
import '../../providers/translation_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';

/// 调试控制台页面
class DebugConsolePage extends ConsumerStatefulWidget {
  final JsInjectionService? jsService;

  const DebugConsolePage({super.key, this.jsService});

  @override
  ConsumerState<DebugConsolePage> createState() => _DebugConsolePageState();
}

class _DebugConsolePageState extends ConsumerState<DebugConsolePage> {
  final TextEditingController _jsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _jsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _executeJs() {
    final code = _jsController.text.trim();
    if (code.isEmpty || widget.jsService == null) return;

    widget.jsService!.controller?.evaluateJavascript(source: code).then((result) {
      LogService.instance.info('JS Console', '>>> $code');
      LogService.instance.info('JS Console', '<<< $result');
      _jsController.clear();
      setState(() {});
    }).catchError((e) {
      LogService.instance.error('JS Console', 'Error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = LogService.instance.getRecentLogs();
    final debugOn = LogService.instance.debugMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('调试控制台'),
        actions: [
          IconButton(
            icon: Icon(debugOn ? Icons.bug_report : Icons.bug_report_outlined),
            tooltip: '调试模式',
            onPressed: () {
              LogService.instance.setDebugMode(!debugOn);
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: '清空日志',
            onPressed: () async {
              await LogService.instance.clearLogs();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '导出日志',
            onPressed: () => LogService.instance.exportLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态快速查看
          Container(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StateBadge(
                  label: '翻译',
                  value: ref.watch(translationProvider).status.name,
                  color: _statusColor(ref.watch(translationProvider).status.name),
                ),
                _StateBadge(
                  label: 'API配置',
                  value: '${ref.watch(apiConfigsProvider).length}个',
                  color: Colors.blue,
                ),
                _StateBadge(
                  label: '调试',
                  value: debugOn ? '开' : '关',
                  color: debugOn ? Colors.orange : Colors.grey,
                ),
                _StateBadge(
                  label: '日志',
                  value: '${logs.length}',
                  color: Colors.green,
                ),
              ],
            ),
          ),

          // JS 控制台
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _jsController,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: '输入 JavaScript...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _executeJs(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _executeJs,
                  tooltip: '执行 JS',
                ),
              ],
            ),
          ),

          // 日志列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _LogTile(entry: log);
              },
            ),
          ),

          // 底部自动滚动开关
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.pause),
                label: Text(_autoScroll ? '自动滚动' : '暂停滚动'),
                onPressed: () {
                  setState(() => _autoScroll = !_autoScroll);
                  if (_autoScroll && logs.isNotEmpty) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'loading': return Colors.orange;
      case 'success': return Colors.green;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _StateBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StateBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry entry;

  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (entry.level) {
      case LogLevel.error: color = Colors.red; break;
      case LogLevel.warn: color = Colors.orange; break;
      case LogLevel.debug: color = Colors.grey; break;
      default: color = Colors.black87;
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(entry.tag),
            content: SingleChildScrollView(child: Text(entry.message)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          entry.formatted,
          style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: color),
        ),
      ),
    );
  }
}
