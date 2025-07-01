import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/cupertino.dart';

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
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              child: InAppWebView(
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
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  allowsBackForwardNavigationGestures: true,
                  allowsLinkPreview: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  cacheEnabled: true,
                  clearCache: false,
                  allowsAirPlayForMediaPlayback: true,
                  allowsPictureInPictureMediaPlayback: true,
                  supportZoom: true,
                  builtInZoomControls: false,
                  displayZoomControls: false,
                  useShouldOverrideUrlLoading: false,
                  useOnDownloadStart: false,
                  useOnNavigationResponse: false,
                ),
              ),
            ),
          ),
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
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 加载指示器（仅动画，无文字、无按钮、无目标地址）
          if (_isLoading && !_hasError && !_hasTimedOut)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 16),
              ),
            ),
        ],
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