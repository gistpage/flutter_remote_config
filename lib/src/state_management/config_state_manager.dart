import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/remote_config.dart';
import '../core/config_event_manager.dart';

/// 🎯 配置状态管理器
/// 
/// 解决初始化和状态同步问题，提供更可靠的配置状态管理
class ConfigStateManager {
  static ConfigStateManager? _instance;
  static ConfigStateManager get instance => _instance ??= ConfigStateManager._();
  ConfigStateManager._();

  ConfigState _currentState = ConfigState.uninitialized();
  
  /// 当前配置状态
  ConfigState get currentState => _currentState;
  
  /// 配置状态流（通过统一事件管理器）
  Stream<ConfigState> get stateStream => ConfigEventManager.instance.stateStream;
  
  /// 是否已初始化
  bool get isInitialized => _currentState.status != ConfigStatus.uninitialized;
  
  /// 是否有可用配置
  bool get hasConfig => _currentState.config != null;
  
  /// 更新状态
  void updateState(ConfigState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      ConfigEventManager.instance.emit(ConfigStateChangedEvent(newState));
      if (kDebugMode) {
        print('🎯 ConfigState: ${newState.status} - ${newState.message}');
      }
    }
  }
  
  /// 设置为初始化中状态
  void setInitializing([String? message]) {
    updateState(ConfigState.initializing(message: message));
  }
  
  /// 设置为已加载状态
  void setLoaded(RemoteConfig config, [String? message]) {
    updateState(ConfigState.loaded(config: config, message: message));
  }
  
  /// 设置为错误状态
  void setError(String error, [RemoteConfig? fallbackConfig]) {
    updateState(ConfigState.error(error: error, fallbackConfig: fallbackConfig));
  }
  
  /// 设置为超时状态
  void setTimeout([RemoteConfig? fallbackConfig]) {
    updateState(ConfigState.timeout(fallbackConfig: fallbackConfig));
  }
  
  /// 销毁
  void dispose() {
    _instance = null;
  }
}

/// 📊 配置状态枚举
enum ConfigStatus {
  uninitialized,  // 未初始化
  initializing,   // 初始化中
  loaded,         // 已加载
  error,          // 错误
  timeout,        // 超时
}

/// 📋 配置状态类
class ConfigState {
  final ConfigStatus status;
  final RemoteConfig? config;
  final String? message;
  final String? error;
  
  const ConfigState._({
    required this.status,
    this.config,
    this.message,
    this.error,
  });
  
  /// 未初始化状态
  factory ConfigState.uninitialized() => const ConfigState._(
    status: ConfigStatus.uninitialized,
    message: '等待初始化',
  );
  
  /// 初始化中状态
  factory ConfigState.initializing({String? message}) => ConfigState._(
    status: ConfigStatus.initializing,
    message: message ?? '正在初始化配置...',
  );
  
  /// 已加载状态
  factory ConfigState.loaded({required RemoteConfig config, String? message}) => ConfigState._(
    status: ConfigStatus.loaded,
    config: config,
    message: message ?? '配置加载成功',
  );
  
  /// 错误状态
  factory ConfigState.error({required String error, RemoteConfig? fallbackConfig}) => ConfigState._(
    status: ConfigStatus.error,
    config: fallbackConfig,
    error: error,
    message: '配置加载失败: $error',
  );
  
  /// 超时状态
  factory ConfigState.timeout({RemoteConfig? fallbackConfig}) => ConfigState._(
    status: ConfigStatus.timeout,
    config: fallbackConfig,
    error: '加载超时',
    message: '配置加载超时，使用缓存配置',
  );
  
  /// 是否可以使用配置
  bool get canUseConfig => config != null;
  
  /// 是否需要显示加载指示器
  bool get shouldShowLoading => status == ConfigStatus.initializing;
  
  /// 是否应该使用默认配置
  bool get shouldUseFallback => status == ConfigStatus.error || status == ConfigStatus.timeout;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfigState &&
        other.status == status &&
        other.config == config &&
        other.message == message &&
        other.error == error;
  }
  
  @override
  int get hashCode => Object.hash(status, config, message, error);
  
  @override
  String toString() => 'ConfigState(status: $status, hasConfig: ${config != null}, message: $message)';
}
