import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RedirectWebView extends StatefulWidget {
  final String url;
  final VoidCallback? onBack;
  final String? title;

  const RedirectWebView({
    Key? key,
    required this.url,
    this.onBack,
    this.title,
  }) : super(key: key);

  @override
  State<RedirectWebView> createState() => _RedirectWebViewState();
}

class _RedirectWebViewState extends State<RedirectWebView> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasTimedOut = false;
  String _currentTitle = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 设置30秒超时保护
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isLoading && !_hasError) {
        setState(() {
          _hasTimedOut = true;
          _isLoading = false;
          _errorMessage = '加载超时，请检查网络连接或iOS权限配置';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? (_currentTitle.isEmpty ? '重定向页面' : _currentTitle)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: [
          if (_webViewController != null && !_hasError && !_hasTimedOut) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reload,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasError && !_hasTimedOut)
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              onWebViewCreated: (controller) => _webViewController = controller,
              onLoadStart: (controller, url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                    _hasTimedOut = false;
                  });
                }
              },
              onLoadStop: (controller, url) async {
                if (mounted) {
                  setState(() => _isLoading = false);
                  try {
                    final title = await controller.getTitle();
                    if (title != null && title.isNotEmpty && mounted) {
                      setState(() => _currentTitle = title);
                    }
                  } catch (e) {
                    // 忽略获取标题失败
                  }
                }
              },
              onTitleChanged: (controller, title) {
                if (title != null && mounted) {
                  setState(() => _currentTitle = title);
                }
              },
              onReceivedError: (controller, request, error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage = error.description;
                  });
                }
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage = 'HTTP错误: ${errorResponse.statusCode}';
                  });
                }
              },
              initialSettings: InAppWebViewSettings(
                // 基础设置
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                
                // 网络和安全
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                allowsBackForwardNavigationGestures: true,
                allowsLinkPreview: true,
                
                // 媒体播放
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                
                // 缓存和性能
                cacheEnabled: true,
                clearCache: false,
                
                // iOS 特定设置
                allowsAirPlayForMediaPlayback: true,
                allowsPictureInPictureMediaPlayback: true,
                
                // 用户体验
                supportZoom: true,
                builtInZoomControls: false,
                displayZoomControls: false,
                
                // 减少限制，使用兼容参数
                useShouldOverrideUrlLoading: false,
                useOnDownloadStart: false,
                useOnNavigationResponse: false,
              ),
            ),
          
          // 错误状态显示
          if (_hasError || _hasTimedOut)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasTimedOut ? Icons.access_time : Icons.error_outline,
                        size: 64,
                        color: _hasTimedOut ? Colors.orange : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _hasTimedOut ? '加载超时' : '加载失败',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage.isNotEmpty ? _errorMessage : '未知错误',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '目标地址:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.url,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_hasTimedOut) ...[
                        const Text(
                          '可能的解决方案：',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• 检查网络连接\n• 确认目标网址可访问\n• iOS需要配置Info.plist网络权限\n• 尝试使用https协议',
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _handleBack,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('返回'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // 加载指示器
          if (_isLoading && !_hasError && !_hasTimedOut)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      '正在加载重定向页面...',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '目标: ${widget.url}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleBack,
                      child: const Text('取消加载'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(
              _hasError || _hasTimedOut ? Icons.error : Icons.info_outline,
              size: 16,
              color: _hasError || _hasTimedOut ? Colors.red : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _hasError || _hasTimedOut 
                  ? '加载失败: ${widget.url}'
                  : '重定向目标: ${widget.url}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: _handleBack,
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _reload() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasTimedOut = false;
      _errorMessage = '';
    });
    
    if (_webViewController != null) {
      _webViewController!.reload();
    } else {
      // 如果控制器为空，重新构建WebView
      setState(() {});
    }
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('页面信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目标URL: ${widget.url}'),
            const SizedBox(height: 8),
            Text('状态: ${_hasError ? "错误" : _hasTimedOut ? "超时" : _isLoading ? "加载中" : "已加载"}'),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('错误信息: $_errorMessage'),
            ],
            const SizedBox(height: 16),
            const Text(
              'iOS加载问题解决方案：\n\n1. 在Info.plist中添加：\n<key>NSAppTransportSecurity</key>\n<dict>\n  <key>NSAllowsArbitraryLoads</key>\n  <true/>\n</dict>\n\n2. 确保目标网址可访问',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 