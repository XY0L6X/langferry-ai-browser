import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/download_service.dart';

/// 下载页面
class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key});

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  final DownloadService _downloadService = DownloadService.instance;
  
  @override
  void initState() {
    super.initState();
    _downloadService.addListener(_onDownloadsChanged);
  }

  @override
  void dispose() {
    _downloadService.removeListener(_onDownloadsChanged);
    super.dispose();
  }

  void _onDownloadsChanged() {
    if (mounted) setState(() {});
  }

  void _loadDownloads() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloads = _downloadService.getAllDownloads();

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        actions: [
          if (downloads.isNotEmpty)
            IconButton(
              onPressed: () {
                _showClearAllDialog();
              },
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空记录',
            ),
        ],
      ),
      body: Column(
        children: [
          // 下载目录信息
          _buildDownloadPathInfo(theme),
          
          // 下载列表
          Expanded(
            child: downloads.isEmpty
                ? _buildEmptyState(theme)
                : _buildDownloadList(downloads, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadPathInfo(ThemeData theme) {
    return FutureBuilder<String>(
      future: _downloadService.getDownloadPath(),
      builder: (context, snapshot) {
        final path = snapshot.data ?? '加载中...';
        return Container(
          padding: const EdgeInsets.all(AppDimens.spacing16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          child: Row(
            children: [
              Icon(
                Icons.folder,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppDimens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '下载目录',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      path,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _changeDownloadPath,
                child: const Text('更改'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppDimens.spacing16),
          Text(
            '暂无下载记录',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppDimens.spacing8),
          Text(
            '在浏览网页时点击下载链接即可开始下载',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadList(List<DownloadRecord> downloads, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.spacing16),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final record = downloads[index];
        return _buildDownloadItem(record, theme);
      },
    );
  }

  Widget _buildDownloadItem(DownloadRecord record, ThemeData theme) {
    final statusColor = _getStatusColor(record.status, theme);
    final statusIcon = _getStatusIcon(record.status);
    final statusText = _getStatusText(record.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: AppDimens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.fileName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.spacing4),
                      Text(
                        record.url,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    if (record.status == DownloadStatus.downloading)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel),
                            SizedBox(width: 8),
                            Text('取消'),
                          ],
                        ),
                      ),
                    if (record.status == DownloadStatus.completed)
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new),
                            SizedBox(width: 8),
                            Text('打开'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('删除记录'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    _handleMenuAction(record, value);
                  },
                ),
              ],
            ),
            if (record.status == DownloadStatus.downloading) ...[
              const SizedBox(height: AppDimens.spacing8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: record.progress,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacing8),
                  Text(
                    '${(record.progress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppDimens.spacing4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                  ),
                ),
                Text(
                  _formatDate(record.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DownloadStatus status, ThemeData theme) {
    switch (status) {
      case DownloadStatus.downloading:
        return theme.colorScheme.primary;
      case DownloadStatus.completed:
        return theme.colorScheme.error.withOpacity(0.7);
      case DownloadStatus.failed:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.5);
    }
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Icons.download;
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.completed:
        return '下载完成';
      case DownloadStatus.failed:
        return '下载失败';
      default:
        return '等待中';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(DownloadRecord record, String action) {
    switch (action) {
      case 'cancel':
        _downloadService.cancelDownload(record.id);
        break;
      case 'open':
        _openFile(record);
        break;
      case 'delete':
        _showDeleteDialog(record);
        break;
    }
  }

  /// 打开已下载的文件
  void _openFile(DownloadRecord record) async {
    final filePath = '${record.savePath}/${record.fileName}';
    final file = File(filePath);
    
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件不存在，可能已被移动或删除')),
        );
      }
      return;
    }
    
    try {
      // 使用 share_plus 打开文件（用户可选择应用打开）
      await Share.shareXFiles(
        [XFile(filePath)],
        text: record.fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示删除确认对话框（可选是否同时删除本地文件）
  void _showDeleteDialog(DownloadRecord record) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除下载记录'),
        content: Text('"${record.fileName}"\n\n请选择删除方式：'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'record_only'),
            child: const Text('仅删记录'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'delete_file'),
            child: const Text('删除记录和文件'),
          ),
        ],
      ),
    );
    
    if (result == 'record_only') {
      _downloadService.deleteDownload(record.id);
    } else if (result == 'delete_file') {
      _downloadService.deleteDownload(record.id);
      // 同时删除本地文件
      try {
        final filePath = '${record.savePath}/${record.fileName}';
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  void _changeDownloadPath() async {
    final currentPath = await _downloadService.getDownloadPath();
    final controller = TextEditingController(text: currentPath);
    
    final newPath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更改下载目录'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入目录路径',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (newPath != null && newPath.isNotEmpty && newPath != currentPath) {
      try {
        await _downloadService.setDownloadPath(newPath);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('下载目录已更改为: $newPath')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更改失败: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空下载记录'),
        content: const Text('确定要清空所有下载记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: 清空所有下载记录
              Navigator.pop(context);
              _loadDownloads();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}