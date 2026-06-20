import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

/// 日志条目
class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get formatted {
    final ts = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
    final levelStr = level.name.toUpperCase().padRight(5);
    return '[$ts] [$levelStr] [$tag] $message';
  }
}

/// 隐私过滤器 — 自动脱敏敏感信息
class _PrivacyFilter {
  // API Key 模式 (sk-*, Bearer tokens)
  static final _apiKeyRegex = RegExp(r'(sk-[a-zA-Z0-9]{8,})', caseSensitive: false);
  static final _bearerRegex = RegExp(r'Bearer\s+[a-zA-Z0-9\-_\.]+', caseSensitive: false);
  // URL 中的敏感参数 (token, key, api_key, auth 等)
  static final _urlParamRegex = RegExp(r'([?&](token|key|api_key|auth|secret|password)=)[^&\s]+', caseSensitive: false);
  // 完整 URL (保留域名，隐藏路径和参数)
  static final _fullUrlRegex = RegExp(r'https?://[^\s]{20,}');
  // 邮箱
  static final _emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');

  static String sanitize(String message) {
    var sanitized = message;
    // 脱敏 API Key
    sanitized = sanitized.replaceAllMapped(_apiKeyRegex, (m) => '${m.group(1)!.substring(0, 6)}***');
    // 脱敏 Bearer Token
    sanitized = sanitized.replaceAll(_bearerRegex, 'Bearer ***');
    // 脱敏 URL 敏感参数
    sanitized = sanitized.replaceAllMapped(_urlParamRegex, (m) => '${m.group(1)}***');
    // 脱敏邮箱
    sanitized = sanitized.replaceAllMapped(_emailRegex, (m) {
      final parts = m.group(0)!.split('@');
      if (parts.first.length > 3) {
        return '${parts.first.substring(0, 3)}***@${parts.last}';
      }
      return '***@${parts.last}';
    });
    return sanitized;
  }
}

/// 日志服务（单例，全局可用）
class LogService {
  static final LogService instance = LogService._();
  LogService._();

  bool _debugMode = false;
  bool _initialized = false;
  String _logFilePath = '';
  final List<LogEntry> _buffer = [];
  static const int _maxBufferSize = 2000;
  late File _logFile;

  bool get debugMode => _debugMode;
  List<LogEntry> get recentLogs => List.unmodifiable(_buffer);

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _logFilePath = '${dir.path}/langferry_debug.log';
    _logFile = File(_logFilePath);
    _initialized = true;

    // Flutter 框架错误捕获
    FlutterError.onError = (details) {
      error('Flutter', details.exceptionAsString());
    };

    // 平台层错误捕获
    PlatformDispatcher.instance.onError = (error, stack) {
      instance.error('Platform', error.toString());
      return true;
    };
  }

  /// 开启/关闭调试模式
  void setDebugMode(bool on) {
    _debugMode = on;
    info('LogService', '调试模式: ${on ? "开" : "关"}');
  }

  void debug(String tag, String msg) => _log(LogLevel.debug, tag, msg);
  void info(String tag, String msg) => _log(LogLevel.info, tag, msg);
  void warn(String tag, String msg) => _log(LogLevel.warn, tag, msg);
  void error(String tag, String msg) => _log(LogLevel.error, tag, msg);

  void _log(LogLevel level, String tag, String message) {
    // 隐私过滤
    final sanitized = _PrivacyFilter.sanitize(message);
    
    final entry = LogEntry(time: DateTime.now(), level: level, tag: tag, message: sanitized);

    // 内存缓冲
    _buffer.add(entry);
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    // 调试模式才写文件
    if (_debugMode && _initialized) {
      try {
        _logFile.writeAsStringSync('${entry.formatted}\n', mode: FileMode.append);
      } catch (_) {}
    }

    // 始终 print（但被 kDebugMode 控制）
    if (kDebugMode || _debugMode) {
      print('[${entry.tag}] $sanitized');
    }
  }

  /// 导出日志文件
  Future<void> exportLogs() async {
    if (!_initialized) return;
    try {
      final buffer = _buffer.map((e) => e.formatted).join('\n');
      final exportFile = File('${_logFilePath}.export');
      await exportFile.writeAsString(
        '=== 文渡 LangFerry Debug Log ===\n'
        '=== 注意：敏感信息已自动脱敏（API Key/Token/邮箱/URL参数）===\n'
        '=== 导出时间：${DateTime.now().toIso8601String()} ===\n\n'
        '$buffer'
      );
      await Share.shareXFiles([XFile(exportFile.path)], text: '文渡 调试日志（已脱敏）');
    } catch (e) {
      error('LogService', '导出日志失败: $e');
    }
  }

  /// 清空日志
  Future<void> clearLogs() async {
    _buffer.clear();
    if (_initialized) {
      try { await _logFile.delete(); } catch (_) {}
    }
  }

  /// 获取日志文件路径
  String get logFilePath => _logFilePath;

  /// 获取最近 N 条日志（用于 UI 展示）
  List<LogEntry> getRecentLogs({int count = 200}) {
    if (_buffer.length <= count) return _buffer.toList();
    return _buffer.sublist(_buffer.length - count);
  }
}
