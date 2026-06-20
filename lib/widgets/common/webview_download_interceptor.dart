import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView下载拦截器
/// 拦截WebView中的下载请求
class WebViewDownloadInterceptor extends StatefulWidget {
  final Widget child;
  final Function(String url, String userAgent, String contentDisposition, String mimeType)? onDownloadStart;

  const WebViewDownloadInterceptor({
    super.key,
    required this.child,
    this.onDownloadStart,
  });

  @override
  State<WebViewDownloadInterceptor> createState() => _WebViewDownloadInterceptorState();
}

class _WebViewDownloadInterceptorState extends State<WebViewDownloadInterceptor> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 下载拦截器配置
class DownloadInterceptorConfig {
  /// 需要拦截的文件类型
  static const List<String> interceptableTypes = [
    'application/pdf',
    'application/zip',
    'application/x-rar-compressed',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/octet-stream',
    'image/jpeg',
    'image/png',
    'image/gif',
    'video/mp4',
    'audio/mpeg',
    'text/plain',
    'text/csv',
  ];

  /// 检查是否应该拦截下载
  static bool shouldIntercept(String mimeType) {
    return interceptableTypes.any((type) => mimeType.toLowerCase().contains(type));
  }
}

/// 下载链接检测JavaScript
const String downloadDetectionScript = '''
(function() {
    // 拦截所有点击事件
    document.addEventListener('click', function(e) {
        const link = e.target.closest('a');
        if (link && link.href) {
            const href = link.href.toLowerCase();
            const downloadAttr = link.getAttribute('download');
            
            // 检测是否是下载链接
            if (downloadAttr || 
                href.includes('.pdf') || 
                href.includes('.zip') || 
                href.includes('.rar') || 
                href.includes('.doc') || 
                href.includes('.docx') || 
                href.includes('.xls') || 
                href.includes('.xlsx') || 
                href.includes('.ppt') || 
                href.includes('.pptx') || 
                href.includes('.txt') || 
                href.includes('.csv') || 
                href.includes('.jpg') || 
                href.includes('.jpeg') || 
                href.includes('.png') || 
                href.includes('.gif') || 
                href.includes('.mp4') || 
                href.includes('.mp3')) {
                
                // 发送下载事件到Flutter
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('onDownloadStart', {
                        url: link.href,
                        userAgent: navigator.userAgent,
                        contentDisposition: downloadAttr || '',
                        mimeType: 'application/octet-stream'
                    });
                }
            }
        }
    }, true);
})();
''';