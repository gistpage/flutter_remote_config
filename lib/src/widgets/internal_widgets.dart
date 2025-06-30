import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 内部组件：信息行显示
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const InfoRow(this.label, this.value, this.style, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: style?.copyWith(fontWeight: FontWeight.w500) ?? 
                     const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// 内部组件：功能完整的WebView页面
/// 
/// 使用 flutter_inappwebview 实现，提供完整的WebView功能
class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('重定向页面'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (webViewController != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => webViewController!.reload(),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              // 启用 JavaScript
              javaScriptEnabled: true,
              // 启用 DOM 存储
              domStorageEnabled: true,
              // 设置用户代理（可选）
              userAgent: 'Flutter Remote Config WebView',
              // 启用缓存
              cacheEnabled: true,
              // 清除缓存
              clearCache: false,
              // 启用缩放
              supportZoom: true,
              builtInZoomControls: true,
              displayZoomControls: false,
              // 媒体播放设置
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                isLoading = false;
              });
            },
            onReceivedError: (controller, request, error) {
              setState(() {
                isLoading = false;
                errorMessage = '加载失败: ${error.description}';
              });
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              setState(() {
                isLoading = false;
                errorMessage = '网络错误: HTTP ${errorResponse.statusCode}';
              });
            },
          ),
          
          // 加载指示器
          if (isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在加载页面...'),
                  ],
                ),
              ),
            ),
          
          // 错误提示
          if (errorMessage != null && !isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '目标地址:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        widget.url,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });
                        webViewController?.reload();
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}