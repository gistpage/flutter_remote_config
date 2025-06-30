import 'dart:async';
import 'package:flutter/foundation.dart';
import 'manager/advanced_config_manager.dart';
import 'config/remote_config_options.dart';
import 'models/remote_config.dart';
import 'state_management/config_state_manager.dart';

/// 🚀 简化API - 90%场景一行代码搞定
/// 
/// 这是一个简化版的远程配置API，专门为快速上手和常见场景设计。
/// 如果你需要更高级的功能，可以直接使用 AdvancedConfigManager。
/// 
/// V2 改进：
/// - 集成了新的状态管理器
/// - 解决了初始化卡住问题
/// - 提供更好的错误处理
/// 
/// 使用示例：
/// ```dart
/// // 🔥 一行初始化
/// await EasyRemoteConfig.init(
///   gistId: 'your-gist-id',
///   githubToken: 'your-token',
/// );
/// 
/// // 🎯 简单使用
/// final isEnabled = EasyRemoteConfig.instance.getBool('featureEnabled');
/// final apiUrl = EasyRemoteConfig.instance.getString('apiUrl');
/// 
/// // 🌐 重定向场景（专用方法）
/// if (EasyRemoteConfig.instance.shouldRedirect) {
///   // 执行重定向逻辑
/// }
/// ```
class EasyRemoteConfig {
  static EasyRemoteConfig? _instance;
  static EasyRemoteConfig get instance => _instance ??= EasyRemoteConfig._();
  EasyRemoteConfig._();

  bool _initialized = false;
  late final ConfigStateManager _stateManager;
  
  /// 🎯 超简单初始化（一行搞定）
  /// 
  /// [gistId] GitHub Gist ID
  /// [githubToken] GitHub Personal Access Token
  /// [defaults] 默认配置值
  /// [cacheTime] 缓存时间，默认1小时
  /// [debugMode] 是否启用调试模式
  static Future<void> init({
    required String gistId,
    required String githubToken,
    Map<String, dynamic> defaults = const {},
    Duration cacheTime = const Duration(hours: 1),
    bool debugMode = false,
  }) async {
    if (debugMode) {
      print('🚀 EasyRemoteConfig V2 开始初始化...');
    }
    
    // 初始化状态管理器
    final instance = EasyRemoteConfig.instance;
    instance._stateManager = ConfigStateManager.instance;
    
    // 设置初始化状态
    instance._stateManager.setInitializing('正在初始化远程配置...');
    
    try {
      final options = RemoteConfigOptions(
        gistId: gistId,
        githubToken: githubToken,
        shortCacheExpiry: cacheTime,
        enableDebugLogs: debugMode,
      );
      
      await AdvancedConfigManager.initializeBasic(
        options: options,
        defaultConfigData: defaults,
      );
      
      // 获取初始配置
      final config = await AdvancedConfigManager.instance.getConfig();
      instance._stateManager.setLoaded(config, '远程配置初始化成功');
      
      instance._initialized = true;
      
      if (debugMode) {
        print('✅ EasyRemoteConfig V2 初始化完成');
      }
    } catch (e) {
      if (debugMode) {
        print('❌ EasyRemoteConfig V2 初始化失败: $e');
      }
      
      // 创建默认配置作为备用
      final defaultConfig = BasicRemoteConfig(data: defaults);
      instance._stateManager.setError(e.toString(), defaultConfig);
      
      // 仍然标记为已初始化，允许使用默认配置
      instance._initialized = true;
    }
  }

  /// 🎯 获取字符串值
  String getString(String key, [String defaultValue = '']) {
    _checkInitialized();
    return _currentConfig?.getValue(key, defaultValue) ?? defaultValue;
  }

  /// 🎯 获取布尔值  
  bool getBool(String key, [bool defaultValue = false]) {
    _checkInitialized();
    return _currentConfig?.getValue(key, defaultValue) ?? defaultValue;
  }

  /// 🎯 获取整数值
  int getInt(String key, [int defaultValue = 0]) {
    _checkInitialized();
    return _currentConfig?.getValue(key, defaultValue) ?? defaultValue;
  }

  /// 🎯 获取双精度值
  double getDouble(String key, [double defaultValue = 0.0]) {
    _checkInitialized();
    return _currentConfig?.getValue(key, defaultValue) ?? defaultValue;
  }

  /// 🎯 获取列表
  List<T> getList<T>(String key, [List<T> defaultValue = const []]) {
    _checkInitialized();
    final value = _currentConfig?.getValue(key, defaultValue);
    if (value is List) {
      try {
        return List<T>.from(value as List<dynamic>);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ EasyRemoteConfig: 类型转换失败 $key -> List<$T>, 返回默认值');
        }
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// 🎯 获取Map
  Map<String, dynamic> getMap(String key, [Map<String, dynamic> defaultValue = const {}]) {
    _checkInitialized();
    final value = _currentConfig?.getValue(key, defaultValue);
    if (value is Map<String, dynamic>) {
      return value;
    }
    return defaultValue;
  }

  /// 🎯 检查配置键是否存在
  bool hasKey(String key) {
    _checkInitialized();
    return _currentConfig?.hasKey(key) ?? false;
  }

  /// 🎯 监听配置变化（简化版）
  StreamSubscription<void> listen(VoidCallback onChanged) {
    _checkInitialized();
    return _stateManager.stateStream.listen((_) => onChanged());
  }

  /// 🎯 刷新配置
  Future<void> refresh() async {
    _checkInitialized();
    try {
      _stateManager.setInitializing('正在刷新配置...');
      final config = await AdvancedConfigManager.instance.refreshConfig();
      _stateManager.setLoaded(config, '配置刷新成功');
    } catch (e) {
      _stateManager.setError('配置刷新失败: $e', _currentConfig);
    }
  }

  // ===== 🎯 针对重定向配置的专用方法 =====
  
  /// 🌐 检查是否启用重定向
  bool get isRedirectEnabled {
    return getBool('isRedirectEnabled', false);
  }

  /// 🌐 获取重定向URL
  String get redirectUrl {
    return getString('redirectUrl', '');
  }

  /// 🌐 获取配置版本
  String get configVersion {
    return getString('version', '1');
  }

  /// 🌐 检查是否需要重定向（组合判断）
  bool get shouldRedirect {
    return isRedirectEnabled && redirectUrl.isNotEmpty;
  }

  /// 🌐 获取重定向信息（一次性获取所有）
  RedirectInfo get redirectInfo {
    return RedirectInfo(
      isEnabled: isRedirectEnabled,
      url: redirectUrl,
      version: configVersion,
    );
  }

  /// 🎯 获取当前所有配置数据（调试用）
  Map<String, dynamic> getAllConfig() {
    _checkInitialized();
    return _currentConfig?.toJson() ?? {};
  }

  /// 🎯 检查配置是否已加载
  bool get isConfigLoaded {
    return _initialized && _currentConfig != null;
  }

  /// 🎯 获取当前配置状态
  ConfigState get configState {
    return _stateManager.currentState;
  }

  /// 获取当前配置对象
  BasicRemoteConfig? get _currentConfig {
    final state = _stateManager.currentState;
    return state.config as BasicRemoteConfig?;
  }
  
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('EasyRemoteConfig 未初始化！请先调用 EasyRemoteConfig.init()');
    }
  }
}

/// 📋 重定向配置信息类
/// 
/// 包含重定向相关的所有信息，提供便捷的访问方法
class RedirectInfo {
  final bool isEnabled;
  final String url;
  final String version;

  const RedirectInfo({
    required this.isEnabled,
    required this.url,
    required this.version,
  });

  /// 是否应该执行重定向
  bool get shouldRedirect => isEnabled && url.isNotEmpty;

  /// 是否有有效的重定向URL
  bool get hasValidUrl => url.isNotEmpty;

  @override
  String toString() => 'RedirectInfo(enabled: $isEnabled, url: $url, version: $version)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedirectInfo &&
        other.isEnabled == isEnabled &&
        other.url == url &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(isEnabled, url, version);
}
