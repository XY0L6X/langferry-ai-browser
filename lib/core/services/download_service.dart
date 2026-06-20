import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 下载状态
enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
}

/// 下载记录
class DownloadRecord {
  final String id;
  final String url;
  final String fileName;
  final String savePath;
  final int? fileSize;
  final DownloadStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double progress;

  DownloadRecord({
    required this.id,
    required this.url,
    required this.fileName,
    required this.savePath,
    this.fileSize,
    this.status = DownloadStatus.idle,
    DateTime? createdAt,
    this.completedAt,
    this.progress = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  DownloadRecord copyWith({
    String? id,
    String? url,
    String? fileName,
    String? savePath,
    int? fileSize,
    DownloadStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    double? progress,
  }) {
    return DownloadRecord(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      savePath: savePath ?? this.savePath,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
    );
  }
}

/// 下载服务
class DownloadService extends ChangeNotifier {
  static final DownloadService instance = DownloadService._();
  
  DownloadService._();
  
  final Dio _dio = Dio();
  final List<DownloadRecord> _downloads = [];
  
  /// 下载目录
  String _downloadPath = '';
  
  /// 获取下载目录
  Future<String> getDownloadPath() async {
    if (_downloadPath.isNotEmpty) return _downloadPath;
    
    if (Platform.isAndroid) {
      // 优先尝试公共下载目录
      final publicDownload = '/storage/emulated/0/Download/WebLingo';
      try {
        final dir = Directory(publicDownload);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        // 验证可写
        final testFile = File('${dir.path}/.write_test');
        await testFile.writeAsString('test');
        await testFile.delete();
        _downloadPath = publicDownload;
        return _downloadPath;
      } catch (_) {
        // 公共目录不可写，回退到应用外部存储目录
      }
      
      // 回退：应用外部存储目录（Android/data/...）
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          _downloadPath = '${extDir.path}/Downloads';
        }
      } catch (_) {}
    }
    
    // 最终回退：应用文档目录
    if (_downloadPath.isEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      _downloadPath = '${appDir.path}/Downloads';
    }
    
    // 确保目录存在
    final dir = Directory(_downloadPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return _downloadPath;
  }
  
  /// 设置下载目录
  Future<void> setDownloadPath(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _downloadPath = path;
  }
  
  /// 检查存储权限（使用应用内目录，Android 10+ 无需额外权限）
  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      // 应用内文档目录在 Android 所有版本均无需权限
      // 若将来改为公共下载目录，需要在此处申请权限
      return true;
    }
    return true;
  }
  
  /// 从URL提取文件名
  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.isNotEmpty) {
        final fileName = path.split('/').last;
        if (fileName.isNotEmpty && fileName.contains('.')) {
          return Uri.decodeComponent(fileName);
        }
      }
    } catch (e) {
      // 忽略解析错误
    }
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// 获取文件扩展名
  String _getExtension(String url, String? contentType) {
    // 从URL获取扩展名
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.contains('.')) {
        final ext = path.split('.').last.toLowerCase();
        if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'rar', 'jpg', 'jpeg', 'png', 'gif', 'mp4', 'mp3'].contains(ext)) {
          return '.$ext';
        }
      }
    } catch (e) {}
    
    // 从Content-Type获取扩展名
    if (contentType != null) {
      if (contentType.contains('pdf')) return '.pdf';
      if (contentType.contains('image/jpeg')) return '.jpg';
      if (contentType.contains('image/png')) return '.png';
      if (contentType.contains('video/mp4')) return '.mp4';
      if (contentType.contains('audio/mpeg')) return '.mp3';
      if (contentType.contains('application/zip')) return '.zip';
    }
    
    return '';
  }
  
  /// 开始下载
  Future<DownloadRecord> startDownload(String url) async {
    // 检查权限
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('没有存储权限');
    }
    
    // 获取下载目录
    final downloadPath = await getDownloadPath();
    
    // 创建下载记录
    final record = DownloadRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      fileName: _getFileNameFromUrl(url),
      savePath: downloadPath,
    );
    
    _downloads.add(record);
    notifyListeners();
    
    // 开始下载
    _downloadFile(record);
    
    return record;
  }
  
  /// 下载文件
  Future<void> _downloadFile(DownloadRecord record) async {
    try {
      // 更新状态为下载中
      final index = _downloads.indexWhere((d) => d.id == record.id);
      if (index != -1) {
        _downloads[index] = record.copyWith(status: DownloadStatus.downloading);
        notifyListeners();
      }
      
      // 发送请求获取文件信息
      final response = await _dio.download(
        record.url,
        '${record.savePath}/${record.fileName}',
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final idx = _downloads.indexWhere((d) => d.id == record.id);
            if (idx != -1) {
              _downloads[idx] = _downloads[idx].copyWith(
                progress: progress,
                fileSize: total,
              );
              notifyListeners();
            }
          }
        },
        options: Options(
          headers: {
            'Accept': '*/*',
          },
        ),
      );
      
      // 下载完成
      final idx = _downloads.indexWhere((d) => d.id == record.id);
      if (idx != -1) {
        _downloads[idx] = _downloads[idx].copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          completedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      // 下载失败
      final idx = _downloads.indexWhere((d) => d.id == record.id);
      if (idx != -1) {
        _downloads[idx] = _downloads[idx].copyWith(
          status: DownloadStatus.failed,
        );
        notifyListeners();
      }
      if (kDebugMode) print('[DownloadService] 下载失败: $e');
    }
  }
  
  /// 获取所有下载记录
  List<DownloadRecord> getAllDownloads() {
    return List.from(_downloads);
  }
  
  /// 获取下载记录
  DownloadRecord? getDownload(String id) {
    try {
      return _downloads.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 取消下载
  void cancelDownload(String id) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads.removeAt(index);
      notifyListeners();
    }
  }
  
  /// 删除下载记录
  void deleteDownload(String id) {
    _downloads.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}