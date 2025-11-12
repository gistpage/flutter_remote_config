import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'internal_widgets.dart';
import '../easy_remote_config.dart';
import 'dart:async';

class RedirectWebView extends StatefulWidget {
  final String url;

  const RedirectWebView({
    super.key,
    required this.url,
  });

  @override
  State<RedirectWebView> createState() => _RedirectWebViewState();
}

class _RedirectWebViewState extends State<RedirectWebView> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasTimedOut = false;
  String _errorMessage = '';
  late final StreamSubscription<void> _configSub; // 监听配置变化

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

    // 监听配置变化，isRedirectEnabled 变为 false 时自动关闭页面
    _configSub = EasyRemoteConfig.instance.listen(() {
      if (!EasyRemoteConfig.instance.isRedirectEnabled && mounted) {
        // 业务说明：当后台关闭重定向时，通过外层 Widget 的 declarative return 切换页面
        // 移除 maybePop() 调用，完全依赖外层的 StreamBuilder 监听和 return 切换
        debugPrint('🔄 检测到重定向已禁用，等待外层 Widget 切换页面');
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
                }
              },
              onTitleChanged: (controller, title) {},
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
          // 优化的加载动画 - 更像app资源加载
          if (_isLoading && !_hasError && !_hasTimedOut)
            const AppLoadingWidget(
              style: LoadingStyle.modern,
              primaryColor: Colors.blue,
              backgroundColor: Colors.white,
              size: 80,
            ),
        ],
      ),
    );
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


  @override
  void dispose() {
    _configSub.cancel();
    super.dispose();
  }
}