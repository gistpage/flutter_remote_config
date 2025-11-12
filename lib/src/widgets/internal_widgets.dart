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
              style:
                  style?.copyWith(fontWeight: FontWeight.w500) ??
                  const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: style)),
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
  void didUpdateWidget(covariant WebViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果url变化，自动reload
    if (widget.url != oldWidget.url && webViewController != null) {
      webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(widget.url)),
      );
    }
  }

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
          // 优化的加载动画 - 更像app资源加载
          if (isLoading && errorMessage == null)
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

  @override
  void dispose() {
    super.dispose();
  }
}

/// 🎨 应用资源加载动画组件
///
/// 提供多种优雅的加载动画，模拟app资源加载体验
/// 不显示任何文字、按钮或目标地址信息
class AppLoadingWidget extends StatefulWidget {
  final LoadingStyle style;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double size;

  const AppLoadingWidget({
    super.key,
    this.style = LoadingStyle.modern,
    this.primaryColor,
    this.backgroundColor,
    this.size = 80,
  });

  @override
  State<AppLoadingWidget> createState() => _AppLoadingWidgetState();
}

enum LoadingStyle {
  modern, // 现代风格：圆角容器 + 脉冲动画
  minimal, // 极简风格：纯旋转指示器
  elegant, // 优雅风格：渐变圆环
  smooth, // 平滑风格：波浪动画
}

class _AppLoadingWidgetState extends State<AppLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late AnimationController _waveController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化所有动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 设置动画
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // 启动动画
    _startAnimations();
  }

  void _startAnimations() {
    switch (widget.style) {
      case LoadingStyle.modern:
        _pulseController.repeat(reverse: true);
        _fadeController.repeat(reverse: true);
        break;
      case LoadingStyle.minimal:
        _rotateController.repeat();
        break;
      case LoadingStyle.elegant:
        _rotateController.repeat();
        _fadeController.repeat(reverse: true);
        break;
      case LoadingStyle.smooth:
        _waveController.repeat(reverse: true);
        _fadeController.repeat(reverse: true);
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Colors.blue;
    final backgroundColor = widget.backgroundColor ?? Colors.white;

    return Container(
      color: backgroundColor,
      child: Center(child: _buildLoadingAnimation(primaryColor)),
    );
  }

  Widget _buildLoadingAnimation(Color primaryColor) {
    switch (widget.style) {
      case LoadingStyle.modern:
        return AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _fadeController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(widget.size * 0.25),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: CupertinoActivityIndicator(
                      radius: widget.size * 0.25,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            );
          },
        );

      case LoadingStyle.minimal:
        return AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value * 2 * 3.14159,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            );
          },
        );

      case LoadingStyle.elegant:
        return AnimatedBuilder(
          animation: Listenable.merge([_rotateController, _fadeController]),
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value * 2 * 3.14159,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.1),
                        primaryColor.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size * 0.6,
                      height: widget.size * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: CupertinoActivityIndicator(
                          radius: widget.size * 0.2,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );

      case LoadingStyle.smooth:
        return AnimatedBuilder(
          animation: Listenable.merge([_waveController, _fadeController]),
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: WavePainter(
                    animation: _waveAnimation,
                    color: primaryColor,
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}

/// 波浪动画绘制器
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavePainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 绘制多个波浪圆环
    for (int i = 0; i < 3; i++) {
      final waveRadius = radius - (i * 8);
      final waveOpacity = (1.0 - i * 0.3) * animation.value;

      paint.color = color.withValues(alpha: waveOpacity * 0.6);

      canvas.drawCircle(center, waveRadius, paint);
    }

    // 中心指示器
    paint.color = color;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 📖 使用示例
/// 
/// ```dart
/// // 1. 现代风格（默认）- 圆角容器 + 脉冲动画
/// AppLoadingWidget(
///   style: LoadingStyle.modern,
///   primaryColor: Colors.blue,
///   backgroundColor: Colors.white,
///   size: 80,
/// )
/// 
/// // 2. 极简风格 - 纯旋转指示器
/// AppLoadingWidget(
///   style: LoadingStyle.minimal,
///   primaryColor: Colors.green,
///   size: 60,
/// )
/// 
/// // 3. 优雅风格 - 渐变圆环
/// AppLoadingWidget(
///   style: LoadingStyle.elegant,
///   primaryColor: Colors.purple,
///   backgroundColor: Colors.black,
///   size: 100,
/// )
/// 
/// // 4. 平滑风格 - 波浪动画
/// AppLoadingWidget(
///   style: LoadingStyle.smooth,
///   primaryColor: Colors.orange,
///   size: 90,
/// )
/// 
/// // 5. 在WebView中使用
/// if (isLoading)
///   const AppLoadingWidget(
///     style: LoadingStyle.modern,
///     primaryColor: Colors.blue,
///     backgroundColor: Colors.white,
///   )
/// ```