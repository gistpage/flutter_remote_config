import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/cupertino.dart';

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
      // 移除AppBar，仅保留WebView和必要的加载/错误提示
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              userAgent: 'Flutter Remote Config WebView',
              cacheEnabled: true,
              clearCache: false,
              supportZoom: true,
              builtInZoomControls: true,
              displayZoomControls: false,
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
                    errorMessage = error.description;
              });
            },
          ),
              ),
            ),
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
          if (isLoading && errorMessage == null)
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
}