import 'package:flutter/material.dart';
import '../state_management/config_state_manager.dart';
import '../models/remote_config.dart';
import 'internal_widgets.dart';


/// 🚀 改进版重定向组件
/// 
/// 解决原版本的初始化卡住问题，提供更可靠的重定向逻辑
class ImprovedRedirectWidgets {
  
  /// 🚀 智能重定向组件（推荐使用）
  /// 
  /// 相比原版本的改进：
  /// 1. 使用状态管理器，避免依赖Stream的延迟
  /// 2. 内置超时保护，最多等待3秒
  /// 3. 更好的错误处理和降级策略
  /// 4. 支持配置更新的实时响应
  static Widget smartRedirect({
    required Widget homeWidget,
    Widget? loadingWidget,
    Widget? errorWidget,
    Duration timeout = const Duration(seconds: 3),
    bool enableDebugLogs = false,
  }) {
    return _SmartRedirectWidget(
      homeWidget: homeWidget,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      timeout: timeout,
      enableDebugLogs: enableDebugLogs,
    );
  }
}

/// 🧠 智能重定向Widget实现
class _SmartRedirectWidget extends StatefulWidget {
  final Widget homeWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Duration timeout;
  final bool enableDebugLogs;

  const _SmartRedirectWidget({
    required this.homeWidget,
    this.loadingWidget,
    this.errorWidget,
    required this.timeout,
    required this.enableDebugLogs,
  });

  @override
  State<_SmartRedirectWidget> createState() => _SmartRedirectWidgetState();
}

class _SmartRedirectWidgetState extends State<_SmartRedirectWidget> {
  late final ConfigStateManager _stateManager;
  Widget? _resolvedWidget;
  
  @override
  void initState() {
    super.initState();
    _stateManager = ConfigStateManager.instance;
    _resolveInitialWidget();
  }

  void _resolveInitialWidget() {
    final currentState = _stateManager.currentState;
    
    if (widget.enableDebugLogs) {
      print('🧠 SmartRedirect: 当前状态 ${currentState.status}');
    }
    
    // 立即检查当前状态
    if (currentState.canUseConfig) {
      _resolvedWidget = _buildFromConfig(currentState.config!);
      if (mounted) setState(() {});
      return;
    }
    
    // 如果没有配置，启动超时保护
    _startTimeoutProtection();
  }

  void _startTimeoutProtection() {
    Future.delayed(widget.timeout, () {
      if (mounted && _resolvedWidget == null) {
        if (widget.enableDebugLogs) {
          print('🧠 SmartRedirect: 超时保护触发，显示主界面');
        }
        setState(() {
          _resolvedWidget = widget.homeWidget;
        });
      }
    });
  }

  Widget _buildFromConfig(RemoteConfig config) {
    if (config is BasicRemoteConfig) {
      final isRedirectEnabled = config.getValue('isRedirectEnabled', false);
      final redirectUrl = config.getValue('redirectUrl', '');
      
      if (isRedirectEnabled && redirectUrl.isNotEmpty) {
        if (widget.enableDebugLogs) {
          print('🧠 SmartRedirect: 重定向到 $redirectUrl');
        }
        return WebViewPage(url: redirectUrl);
      }
    }
    
    if (widget.enableDebugLogs) {
      print('🧠 SmartRedirect: 显示主界面');
    }
    return widget.homeWidget;
  }

  @override
  Widget build(BuildContext context) {
    // 如果已有解析的Widget，直接返回
    if (_resolvedWidget != null) {
      return _resolvedWidget!;
    }
    
    // 否则监听状态变化
    return StreamBuilder<ConfigState>(
      stream: _stateManager.stateStream,
      initialData: _stateManager.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? ConfigState.uninitialized();
        
        // 处理错误状态
        if (state.status == ConfigStatus.error) {
          if (state.config != null) {
            // 有备用配置，使用备用配置
            return _buildFromConfig(state.config!);
          }
          // 没有备用配置，显示错误或主界面
          return widget.errorWidget ?? widget.homeWidget;
        }
        
        // 处理有配置的状态
        if (state.canUseConfig) {
          final resolvedWidget = _buildFromConfig(state.config!);
          // 缓存解析结果，避免重复构建
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _resolvedWidget = resolvedWidget;
              });
            }
          });
          return resolvedWidget;
        }
        
        // 加载中状态
        return widget.loadingWidget ?? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载配置...'),
            ],
          ),
        );
      },
    );
  }
}
