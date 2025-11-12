import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/remote_config.dart';
import '../services/remote_config_service.dart';
import '../config/remote_config_options.dart';
import '../core/lifecycle_aware_manager.dart';
import '../core/config_event_manager.dart';

/// 高级配置管理器
/// 
/// 这是一个单例模式的全局配置管理器，具备：
/// 1. 应用生命周期感知的配置更新
/// 2. 自动定时检查配置更新
/// 3. 智能缓存策略
/// 4. 配置变化监听
/// 5. 错误容错机制
/// 
/// 使用示例：
/// ```dart
/// // 初始化
/// await AdvancedConfigManager.initialize(
///   options: RemoteConfigOptions(
///     gistId: 'your-gist-id',
///     githubToken: 'your-token',
///   ),
///   defaultConfigFactory: () => YourConfigClass(),
/// );
/// 
/// // 获取配置
/// final config = await AdvancedConfigManager.instance.getConfig();
/// 
/// // 监听配置变化
/// AdvancedConfigManager.instance.addConfigListener((config) {
///   print('配置已更新: ${config.version}');
/// });
/// ```
class AdvancedConfigManager<T extends RemoteConfig> extends LifecycleAwareManager {
  static AdvancedConfigManager? _instance;
  
  /// 获取单例实例
  static AdvancedConfigManager get instance {
    if (_instance == null) {
      throw StateError('AdvancedConfigManager尚未初始化，请先调用initialize()');
    }
    return _instance!;
  }

  /// 安全获取单例实例（不抛出异常）
  static AdvancedConfigManager? get instanceOrNull => _instance;

  /// 检查是否已初始化
  static bool get isManagerInitialized => _instance != null;

  /// 重置实例（仅用于测试）
  static void resetInstance() {
    if (_instance != null) {
      (_instance as AdvancedConfigManager)._dispose();
      _instance = null;
    }
  }

  final RemoteConfigService<T> _configService;
  final T Function() _defaultConfigFactory;
  final RemoteConfigOptions _options;
  
  T? _currentConfig;
  Timer? _updateTimer;
  bool _isInitialized = false;
  int? _lastCheckIntervalMinutes;
  bool? _lastForegroundState;

  
  /// 配置变化流（通过统一事件管理器）
  Stream<T> get configStream => ConfigEventManager.instance.configStream<T>();

  /// 当前配置
  T? get currentConfig => _currentConfig;
  
  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  AdvancedConfigManager._({
    required RemoteConfigOptions options,
    required T Function(Map<String, dynamic>) configFactory,
    required T Function() defaultConfigFactory,
    String? cacheKeyPrefix,
  }) : _configService = RemoteConfigService<T>(
         options: options,
         configFactory: configFactory,
         cacheKeyPrefix: cacheKeyPrefix,
       ),
       _defaultConfigFactory = defaultConfigFactory,
       _options = options {
    // 使用 RemoteConfigService 自身的缓存策略，无需额外的本地缓存管理器
  }

  /// 初始化全局配置管理器
  /// 
  /// [options] GitHub Gist 配置选项
  /// [configFactory] 从JSON创建配置对象的工厂方法
  /// [defaultConfigFactory] 创建默认配置的工厂方法
  /// [cacheKeyPrefix] 缓存键前缀，用于多配置隔离
  static Future<void> initialize<T extends RemoteConfig>({
    required RemoteConfigOptions options,
    required T Function(Map<String, dynamic>) configFactory,
    required T Function() defaultConfigFactory,
    String? cacheKeyPrefix,
  }) async {
    if (_instance != null) {
      (_instance as AdvancedConfigManager)._dispose();
    }

    _instance = AdvancedConfigManager<T>._(
      options: options,
      configFactory: configFactory,
      defaultConfigFactory: defaultConfigFactory,
      cacheKeyPrefix: cacheKeyPrefix,
    );

    await (_instance as AdvancedConfigManager<T>)._initialize();
  }

  /// 便捷初始化方法 - 使用 BasicRemoteConfig
  static Future<void> initializeBasic({
    required RemoteConfigOptions options,
    Map<String, dynamic> defaultConfigData = const {},
    String? cacheKeyPrefix,
  }) async {
    await initialize<BasicRemoteConfig>(
      options: options,
      configFactory: BasicRemoteConfig.fromJson,
      defaultConfigFactory: () => BasicRemoteConfig(data: defaultConfigData),
      cacheKeyPrefix: cacheKeyPrefix,
    );
  }

  /// 私有初始化方法
  Future<void> _initialize() async {
    if (_isInitialized) return;

    if (_options.enableDebugLogs) {
      debugPrint('🚀 初始化高级配置管理器');
    }
    
    // 注册生命周期监听
    WidgetsBinding.instance.addObserver(this);
    
    // 启动时获取配置
    await _loadInitialConfig();
    
    // 启动定时检查
    _startPeriodicCheck();
    
    _isInitialized = true;
    if (_options.enableDebugLogs) {
      debugPrint('✅ 高级配置管理器初始化完成');
    }
  }

  /// 获取配置（对外统一接口）
  Future<T> getConfig({bool forceRefresh = false}) async {
    if (!_isInitialized) {
      throw StateError('配置管理器尚未初始化');
    }

    try {
      final config = await _configService.getConfig(
        forceRefresh: forceRefresh,
        isAppInForeground: isAppInForeground,
      );
      
      // 检查配置是否有变化
      if (_currentConfig == null || _hasConfigChanged(_currentConfig, config)) {
        _currentConfig = config;
        _notifyConfigChanged(config);
      }
      
      return config;
    } catch (e) {
      if (_options.enableDebugLogs) {
        debugPrint('❌ AdvancedConfigManager获取配置失败: $e');
      }
      // 返回当前配置或默认配置
      final fallbackConfig = _currentConfig ?? _defaultConfigFactory();
      
      if (_options.enableDebugLogs) {
        if (_currentConfig != null) {
          debugPrint('🔄 使用当前缓存的配置作为兜底');
          debugPrint('📄 当前配置内容: ${_currentConfig?.toJson()}');
        } else {
          final defaultConfig = _defaultConfigFactory();
          debugPrint('🏠 使用默认配置作为兜底');
          debugPrint('📄 默认配置 JSON: ${defaultConfig.toJson()}');
          if (defaultConfig is BasicRemoteConfig) {
            debugPrint('🔧 默认配置详细信息:');
            final configData = defaultConfig.toJson();
            configData.forEach((key, value) {
              debugPrint('   ├─ $key: $value (${value.runtimeType})');
            });
          }
        }
      }
      
      return fallbackConfig;
    }
  }

  /// 手动刷新配置
  Future<T> refreshConfig() async {
    if (_options.enableDebugLogs) {
      debugPrint('🔄 手动刷新配置');
    }
    return await getConfig(forceRefresh: true);
  }

  /// 清除缓存
  Future<void> clearCache() async {
    await _configService.clearCache();
    _currentConfig = null;
  }

  /// 生命周期回调由基类统一处理
  @override
  void onAppResumed() {
    _checkConfigOnResume();
    _startPeriodicCheck();
  }
  @override
  void onAppPaused() {
    _startPeriodicCheck(); // 切换到后台模式
  }
  @override
  void onAppDetached() {
    _dispose();
  }

  // ============ 生命周期处理由基类统一分发 ============
  // 依赖 LifecycleAwareManager.didChangeAppLifecycleState -> onAppResumed/onAppPaused/onAppDetached
  // 避免重复的生命周期分发导致的重复日志与重复检查

  // ============ 私有方法 ============

  /// 加载初始配置
  Future<void> _loadInitialConfig() async {
    try {
      if (_options.enableDebugLogs) {
        debugPrint('📥 加载初始配置');
      }
      _currentConfig = await _configService.getConfigOnLaunch();
      if (_options.enableDebugLogs) {
        debugPrint('✅ 初始配置加载完成: version=${_currentConfig?.version}');
      }
      
      // 通知初始配置
      if (_currentConfig != null) {
        _notifyConfigChanged(_currentConfig!);
      }
    } catch (e) {
      if (_options.enableDebugLogs) {
        debugPrint('❌ 加载初始配置失败: $e');
        debugPrint('⚠️ AdvancedConfigManager: 启用本地defaults作为兜底配置');
      }
      // 使用默认配置
      _currentConfig = _defaultConfigFactory();
      
      if (_options.enableDebugLogs) {
        debugPrint('✅ AdvancedConfigManager: 成功创建默认配置');
        debugPrint('📄 AdvancedConfigManager 默认配置 JSON: ${_currentConfig?.toJson()}');
        if (_currentConfig is BasicRemoteConfig) {
          debugPrint('🔧 AdvancedConfigManager 默认配置详细信息:');
          final configData = (_currentConfig as BasicRemoteConfig).toJson();
          configData.forEach((key, value) {
            debugPrint('   ├─ $key: $value (${value.runtimeType})');
          });
          
          // 特别显示重定向相关配置
          final basicConfig = _currentConfig as BasicRemoteConfig;
          final isRedirectEnabled = basicConfig.getValue('isRedirectEnabled', false);
          final redirectUrl = basicConfig.getValue('redirectUrl', '');
          final version = basicConfig.getValue('version', '1');
          
          debugPrint('🌐 AdvancedConfigManager 重定向配置检查:');
          debugPrint('   ├─ isRedirectEnabled: $isRedirectEnabled');
          debugPrint('   ├─ redirectUrl: $redirectUrl');
          debugPrint('   └─ version: $version');
        }
      }
      
      _notifyConfigChanged(_currentConfig!);
    }
  }

  /// 恢复前台时检查配置
  void _checkConfigOnResume() {
    // 异步检查，不阻塞UI
    Future(() async {
      try {
        if (_options.enableDebugLogs) {
          debugPrint('🔍 恢复前台时检查配置更新');
        }
        final config = await _configService.getConfigOnResume();
        
        // 比较配置是否有变化
        if (_hasConfigChanged(_currentConfig, config)) {
          if (_options.enableDebugLogs) {
            debugPrint('🆕 恢复前台时发现配置更新');
          }
          _currentConfig = config;
          _notifyConfigChanged(config);
        }
      } catch (e) {
        if (_options.enableDebugLogs) {
          debugPrint('⚠️ 恢复前台时检查配置失败: $e');
        }
      }
    });
  }

  /// 启动定时检查
  void _startPeriodicCheck() {
    _updateTimer?.cancel();
    
    // 根据应用状态选择检查间隔
    final interval = isAppInForeground 
        ? _options.foregroundCheckInterval   // 前台：可配置间隔
        : _options.backgroundCheckInterval;  // 后台：可配置间隔
    
    // 仅在检查参数变化时输出日志，减少噪音
    final shouldLog = _lastCheckIntervalMinutes != interval.inMinutes ||
        _lastForegroundState != isAppInForeground;
    if (shouldLog && _options.enableDebugLogs) {
      debugPrint('⏰ 启动定时检查 (间隔: ${interval.inMinutes}分钟, 前台: $isAppInForeground)');
    }
    _lastCheckIntervalMinutes = interval.inMinutes;
    _lastForegroundState = isAppInForeground;
    
    _updateTimer = Timer.periodic(interval, (timer) async {
      await _periodicConfigCheck();
    });
  }

  /// 定时配置检查
  Future<void> _periodicConfigCheck() async {
    try {
      if (_options.enableDebugLogs) {
        debugPrint('⏰ 定时检查配置更新');
      }
      final config = await _configService.getConfig(
        forceRefresh: false,
        isAppInForeground: isAppInForeground,
      );
      
      // 检查配置是否有变化
      if (_hasConfigChanged(_currentConfig, config)) {
        if (_options.enableDebugLogs) {
          debugPrint('🆕 定时检查发现配置更新');
        }
        _currentConfig = config;
        _notifyConfigChanged(config);
      }
    } catch (e) {
      if (_options.enableDebugLogs) {
        debugPrint('⚠️ 定时检查配置失败: $e');
      }
    }
  }

  /// 检查配置是否有变化
  bool _hasConfigChanged(T? oldConfig, T newConfig) {
    if (oldConfig == null) return true;
    
    // 首先比较版本号
    if (oldConfig.version != newConfig.version) {
      return true;
    }
    
    // 如果版本号相同，比较整个配置内容
    try {
      final oldJson = oldConfig.toJson();
      final newJson = newConfig.toJson();
      return !_mapEquals(oldJson, newJson);
    } catch (e) {
      // 如果序列化失败，认为配置有变化
      return true;
    }
  }

  /// 深度比较两个Map是否相等
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      
      final value1 = map1[key];
      final value2 = map2[key];
      
      if (value1.runtimeType != value2.runtimeType) return false;
      
      if (value1 is Map<String, dynamic> && value2 is Map<String, dynamic>) {
        if (!_mapEquals(value1, value2)) return false;
      } else if (value1 is List && value2 is List) {
        if (!_listEquals(value1, value2)) return false;
      } else if (value1 != value2) {
        return false;
      }
    }
    
    return true;
  }

  /// 深度比较两个List是否相等
  bool _listEquals(List list1, List list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      final item1 = list1[i];
      final item2 = list2[i];
      
      if (item1.runtimeType != item2.runtimeType) return false;
      
      if (item1 is Map<String, dynamic> && item2 is Map<String, dynamic>) {
        if (!_mapEquals(item1, item2)) return false;
      } else if (item1 is List && item2 is List) {
        if (!_listEquals(item1, item2)) return false;
      } else if (item1 != item2) {
        return false;
      }
    }
    
    return true;
  }

  /// 通知配置变化（通过事件管理器广播）
  void _notifyConfigChanged(T newConfig) {
    if (_options.enableDebugLogs) {
      debugPrint('📢 配置变化通知: version=${newConfig.version}');
    }
    ConfigEventManager.instance.emit(ConfigChangedEvent(newConfig));
  }

  /// 添加配置监听器（兼容旧API，底层已切换为事件管理器）
  StreamSubscription<T> addConfigListener(void Function(T) onConfigChanged) {
    return configStream.listen(onConfigChanged);
  }

  /// 私有销毁方法
  void _dispose() {
    if (_options.enableDebugLogs) {
      debugPrint('🔄 销毁高级配置管理器');
    }
    disposeLifecycle();
    _updateTimer?.cancel();
    _updateTimer = null;
    _isInitialized = false;
  }
}