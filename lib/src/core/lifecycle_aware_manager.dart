import 'package:flutter/widgets.dart';

/// 🔄 生命周期感知基类 - 消除重复代码
abstract class LifecycleAwareManager with WidgetsBindingObserver {
  bool _isAppInForeground = true;
  bool _isDisposed = false;
  
  bool get isAppInForeground => _isAppInForeground;
  bool get isDisposed => _isDisposed;
  
  void initializeLifecycle() {
    if (!_isDisposed) {
      WidgetsBinding.instance.addObserver(this);
    }
  }
  
  void disposeLifecycle() {
    if (!_isDisposed) {
      WidgetsBinding.instance.removeObserver(this);
      _isDisposed = true;
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        onAppResumed();
        break;
      case AppLifecycleState.paused:
        _isAppInForeground = false;
        onAppPaused();
        break;
      case AppLifecycleState.detached:
        onAppDetached();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }
  
  // 🎯 子类需要实现的方法
  void onAppResumed() {}
  void onAppPaused() {}
  void onAppDetached() {
    disposeLifecycle();
  }
} 