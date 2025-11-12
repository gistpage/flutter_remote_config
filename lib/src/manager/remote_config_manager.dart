import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/remote_config.dart';
import '../services/remote_config_service.dart';
import '../config/remote_config_options.dart';

/// 远程配置管理器
/// 
/// 负责：
/// 1. 应用生命周期感知的配置更新
/// 2. 定时检查配置更新
/// 3. 配置状态管理
/// 4. 统一的配置获取接口
class RemoteConfigManager<T extends RemoteConfig> with WidgetsBindingObserver {
  final RemoteConfigService<T> _service;
  final T Function() _defaultConfigFactory;
  final RemoteConfigOptions _options;
  T? _currentConfig;
  Timer? _updateTimer;
  bool _isInitialized = false;
  bool _isAppInForeground = true;

  final StreamController<T> _configController = StreamController<T>.broadcast();
  
  /// 配置变化流
  Stream<T> get configStream => _configController.stream;

  /// 当前配置
  T? get currentConfig => _currentConfig;
  
  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  RemoteConfigManager({
    required RemoteConfigOptions options,
    required T Function(Map<String, dynamic>) configFactory,
    required T Function() defaultConfigFactory,
    String? cacheKeyPrefix,
  }) : _service = RemoteConfigService<T>(
         options: options,
         configFactory: configFactory,
         cacheKeyPrefix: cacheKeyPrefix,
       ),
       _defaultConfigFactory = defaultConfigFactory,
       _options = options;

  /// 便捷构造方法 - 使用BasicRemoteConfig
  static RemoteConfigManager<BasicRemoteConfig> basic({
    required RemoteConfigOptions options,
    Map<String, dynamic> defaultConfigData = const {},
    String? cacheKeyPrefix,
  }) {
    return RemoteConfigManager<BasicRemoteConfig>(
      options: options,
      configFactory: BasicRemoteConfig.fromJson,
      defaultConfigFactory: () => BasicRemoteConfig(data: defaultConfigData),
      cacheKeyPrefix: cacheKeyPrefix,
    );
  }

  /// 初始化配置管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_options.enableDebugLogs) {
      debugPrint('🚀 初始化配置管理器');
    }
    
    // 注册生命周期监听
    WidgetsBinding.instance.addObserver(this);
    
    // 启动时获取配置
    await _loadInitialConfig();
    
    // 启动定时检查
    _startPeriodicCheck();
    
    _isInitialized = true;
    if (_options.enableDebugLogs) {
      debugPrint('✅ 配置管理器初始化完成');
    }
  }

  /// 销毁配置管理器
  void dispose() {
    if (_options.enableDebugLogs) {
      debugPrint('🔄 销毁配置管理器');
    }
    
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _updateTimer = null;
    _configController.close();
    _isInitialized = false;
  }

  /// 获取配置（对外统一接口）
  Future<T> getConfig({bool forceRefresh = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final config = await _service.getConfig(
        forceRefresh: forceRefresh,
        isAppInForeground: _isAppInForeground,
      );
      
      // 检查配置是否有变化
      if (_currentConfig == null || _hasConfigChanged(_currentConfig, config)) {
        _currentConfig = config;
        _notifyConfigChanged(config);
      }
      
      return config;
    } catch (e) {
      if (_options.enableDebugLogs) {
        debugPrint('❌ ConfigManager获取配置失败: $e');
      }
      // 返回当前配置或默认配置
      return _currentConfig ?? _defaultConfigFactory();
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
    await _service.clearCache();
    _currentConfig = null;
  }

  // ============ 生命周期处理 ============

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        // 应用非激活状态，通常是短暂的
        break;
      case AppLifecycleState.hidden:
        // 应用隐藏状态
        break;
    }
  }

  /// 应用恢复前台
  void _onAppResumed() {
    if (_options.enableDebugLogs) {
      debugPrint('👀 应用恢复前台');
    }
    _isAppInForeground = true;
    
    // 恢复前台时立即检查配置更新
    _checkConfigOnResume();
    
    // 重启定时检查（前台模式）
    _startPeriodicCheck();
  }

  /// 应用进入后台
  void _onAppPaused() {
    if (_options.enableDebugLogs) {
      debugPrint('🔔 应用进入后台');
    }
    _isAppInForeground = false;
    
    // 切换到后台模式的定时检查
    _startPeriodicCheck();
  }

  /// 应用被销毁
  void _onAppDetached() {
    if (_options.enableDebugLogs) {
      debugPrint('💀 应用被销毁');
    }
    dispose();
  }

  // ============ 私有方法 ============

  /// 加载初始配置
  Future<void> _loadInitialConfig() async {
    try {
      if (_options.enableDebugLogs) {
        debugPrint('📥 加载初始配置');
      }
      _currentConfig = await _service.getConfigOnLaunch();
      if (_options.enableDebugLogs) {
        debugPrint('✅ 初始配置加载完成: version=${_currentConfig?.version}');
      }
      
      // 通知初始配置
      if (_currentConfig != null) {
        _notifyConfigChanged(_currentConfig as T);
      }
    } catch (e) {
      if (_options.enableDebugLogs) {
        debugPrint('❌ 加载初始配置失败: $e');
      }
      // 使用默认配置
      _currentConfig = _defaultConfigFactory();
      _notifyConfigChanged(_currentConfig as T);
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
        final config = await _service.getConfigOnResume();
        
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
    final interval = _isAppInForeground 
        ? _options.foregroundCheckInterval   // 前台：可配置间隔
        : _options.backgroundCheckInterval;  // 后台：可配置间隔
    
    if (_options.enableDebugLogs) {
      debugPrint('⏰ 启动定时检查 (间隔: ${interval.inMinutes}分钟, 前台: $_isAppInForeground)');
    }
    
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
      final config = await _service.getConfig(
        forceRefresh: false,
        isAppInForeground: _isAppInForeground,
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

  /// 通知配置变化
  void _notifyConfigChanged(T newConfig) {
    if (_options.enableDebugLogs) {
      debugPrint('📢 配置变化通知: version=${newConfig.version}');
    }
    
    // 通过Stream发送配置更新事件
    if (!_configController.isClosed) {
      _configController.add(newConfig);
    }
  }

  /// 添加配置监听器
  StreamSubscription<T> addConfigListener(void Function(T) onConfigChanged) {
    return configStream.listen(onConfigChanged);
  }
}
