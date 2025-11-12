import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'manager/advanced_config_manager.dart';
import 'config/remote_config_options.dart';
import 'models/remote_config.dart';
import 'state_management/config_state_manager.dart';
// 移除未使用的 UI 相关导入，保持该文件纯逻辑
import 'core/config_event_manager.dart';

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
class EasyRemoteConfig with WidgetsBindingObserver {
  static EasyRemoteConfig? _instance;
  static EasyRemoteConfig get instance => _instance ??= EasyRemoteConfig._();
  EasyRemoteConfig._() {
    // 注册前后台监听
    WidgetsBinding.instance.addObserver(this);
  }

  bool _initialized = false;
  late final ConfigStateManager _stateManager;
  StreamSubscription<BasicRemoteConfig>? _configChangeSubscription;
  String? _cachedIpCountry;
  DateTime? _cachedIpFetchTime;
  static const Duration _ipCacheTTL = Duration(hours: 6);
  static const Map<String, List<int>> _countryOffsetHoursMap = {
    'US': [-10, -9, -8, -7, -6, -5, -4],
    'BR': [-5, -4, -3, -2],
    'CN': [8],
    'GB': [0, 1],
    'IN': [5, 6],
    'JP': [9],
    'KR': [9],
    'AU': [8, 9, 10, 11],
    'DE': [1, 2],
    'FR': [1, 2],
    'CA': [-8, -7, -6, -5, -4],
  };
  static const Map<String, List<int>> _countryOffsetMinutesMap = {
    'US': [-600, -540, -480, -420, -360, -300, -240],
    'BR': [-240, -180, -120],
    'CN': [480],
    'GB': [0, 60],
    'IN': [330],
    'JP': [540],
    'KR': [540],
    'AU': [480, 570, 600, 630, 660],
    'DE': [60, 120],
    'FR': [60, 120],
    'CA': [-480, -420, -360, -300, -240, -210, -150],
  };

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
      debugPrint('🚀 EasyRemoteConfig V2 开始初始化...');
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

      // 桥接 AdvancedConfigManager 的配置变更到状态流，避免重复刷新导致的日志噪音
      try {
        final Stream<BasicRemoteConfig> stream =
            AdvancedConfigManager.instance.configStream
                as Stream<BasicRemoteConfig>;
        instance._configChangeSubscription = stream.listen((newConfig) {
          instance._stateManager.setLoaded(newConfig, '配置更新（事件桥接）');
        });
      } catch (_) {
        // 忽略类型桥接失败的情况（极少发生），不影响正常功能
      }

      if (debugMode) {
        debugPrint('✅ EasyRemoteConfig V2 初始化完成');
      }
    } catch (e) {
      if (debugMode) {
        debugPrint('❌ EasyRemoteConfig V2 初始化失败: $e');
        debugPrint('⚠️ EasyRemoteConfig: 启用本地defaults作为兜底配置');
        debugPrint('📋 默认配置内容: $defaults');
      }

      // 创建默认配置作为备用
      final defaultConfig = BasicRemoteConfig(data: defaults);

      if (debugMode) {
        debugPrint('✅ 成功创建默认配置对象');
        debugPrint('📄 默认配置 JSON: ${defaultConfig.toJson()}');
        debugPrint('🔧 默认配置详细信息:');
        defaults.forEach((key, value) {
          debugPrint('   ├─ $key: $value (${value.runtimeType})');
        });

        // 特别显示重定向相关配置
        final isRedirectEnabled = defaultConfig.getValue(
          'isRedirectEnabled',
          false,
        );
        final redirectUrl = defaultConfig.getValue('redirectUrl', '');
        final version = defaultConfig.getValue('version', '1');

        debugPrint('🌐 重定向配置检查:');
        debugPrint('   ├─ isRedirectEnabled: $isRedirectEnabled');
        debugPrint('   ├─ redirectUrl: $redirectUrl');
        debugPrint('   └─ version: $version');

        if (isRedirectEnabled == true && redirectUrl.toString().isNotEmpty) {
          debugPrint('🔀 将执行重定向到: $redirectUrl');
        } else {
          debugPrint('🏠 将显示主页面（重定向未启用或URL为空）');
        }
      }

      // 修复：直接setLoaded，保证UI能用defaults兜底
      instance._stateManager.setLoaded(defaultConfig, '使用默认配置');
      // 新增：手动广播配置变更事件，确保UI能收到
      ConfigEventManager.instance.emit(ConfigChangedEvent(defaultConfig));
      // 仍然标记为已初始化，允许使用默认配置
      instance._initialized = true;

      if (debugMode) {
        debugPrint('✅ EasyRemoteConfig V2 使用默认配置初始化完成');
      }
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
    final value = _currentConfig?.getValue<dynamic>(key, defaultValue);
    if (value is List) {
      try {
        return List<T>.from(value);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ EasyRemoteConfig: 类型转换失败 $key -> List<$T>, 返回默认值');
        }
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// 🎯 获取Map
  Map<String, dynamic> getMap(
    String key, [
    Map<String, dynamic> defaultValue = const {},
  ]) {
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
      // 检查 AdvancedConfigManager 是否可用
      if (AdvancedConfigManager.isManagerInitialized) {
        final config = await AdvancedConfigManager.instance.refreshConfig();
        _stateManager.setLoaded(config, '配置刷新成功');
      } else {
        // AdvancedConfigManager 不可用时，使用当前配置
        final currentConfig = _currentConfig;
        if (currentConfig != null) {
          _stateManager.setLoaded(currentConfig, '使用当前配置（管理器不可用）');
        } else {
          _stateManager.setError('配置管理器不可用且无当前配置', null);
        }
      }
    } catch (e) {
      _stateManager.setError('配置刷新失败: $e', _currentConfig);
    }
  }

  // ===== 针对重定向配置的专用方法 =====

  /// 🌐 检查是否启用重定向
  bool get isRedirectEnabled {
    return getBool('isRedirectEnabled', false);
  }

  /// 🌐 获取重定向URL
  String get redirectUrl {
    return getString('redirectUrl', '');
  }

  List<String> get allowCountries {
    return getList<String>('allowCountries', const []);
  }

  bool get isCountryCheckEnabled {
    return getBool('isCountryCheckEnabled', false);
  }

  bool get isTimezoneCheckEnabled {
    return getBool('isTimezoneCheckEnabled', false);
  }

  bool get isIpAttributionCheckEnabled {
    return getBool('isIpAttributionCheckEnabled', false);
  }

  /// 🌐 获取配置版本
  String get configVersion {
    final config = _currentConfig;
    if (config?.version != null) {
      return config!.version!;
    }
    return getString('version', '1');
  }

  /// 🌐 检查是否需要重定向（组合判断）
  bool get shouldRedirect {
    return isRedirectEnabled && redirectUrl.isNotEmpty;
  }

  Future<bool> gatedShouldRedirect() async {
    _checkInitialized();
    if (!(isRedirectEnabled && redirectUrl.isNotEmpty)) {
      return false;
    }
    final allowed = allowCountries.map((e) => e.toUpperCase()).toSet();
    if (allowed.isEmpty &&
        (isCountryCheckEnabled ||
            isTimezoneCheckEnabled ||
            isIpAttributionCheckEnabled)) {
      return false;
    }
    if (isCountryCheckEnabled) {
      final lc = _deviceLocaleCountryCode?.toUpperCase();
      if (lc == null || !allowed.contains(lc)) {
        return false;
      }
    }
    if (isTimezoneCheckEnabled) {
      final om = DateTime.now().timeZoneOffset.inMinutes;
      var ok = false;
      for (final code in allowed) {
        final m = _countryOffsetMinutesMap[code];
        if (m != null && m.contains(om)) {
          ok = true;
          break;
        }
        final h = _countryOffsetHoursMap[code];
        if (h != null && h.contains(om ~/ 60)) {
          ok = true;
          break;
        }
      }
      if (!ok) {
        return false;
      }
    }
    if (isIpAttributionCheckEnabled) {
      final ipCountry = await _getIpCountry();
      if (ipCountry == null || !allowed.contains(ipCountry.toUpperCase())) {
        return false;
      }
    }
    return true;
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

  /// 🎯 静态方法：检查是否已初始化
  static bool get isInitialized {
    return _instance?._initialized ?? false;
  }

  /// 🎯 重置实例（仅用于测试）
  static void resetInstance() {
    _instance = null;
  }

  /// 🎯 获取当前配置状态
  ConfigState get configState {
    return _stateManager.currentState;
  }

  /// 配置状态流（用于UI自动响应配置变化）
  Stream<ConfigState> get configStateStream {
    return _stateManager.stateStream;
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

  String? get _deviceLocaleCountryCode {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return locale.countryCode;
  }

  Future<String?> _getIpCountry() async {
    final now = DateTime.now();
    if (_cachedIpCountry != null && _cachedIpFetchTime != null) {
      if (now.difference(_cachedIpFetchTime!) < _ipCacheTTL) {
        return _cachedIpCountry;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('erc_ip_country');
      final ts = prefs.getInt('erc_ip_ts');
      if (saved != null && ts != null) {
        final t = DateTime.fromMillisecondsSinceEpoch(ts);
        if (now.difference(t) < _ipCacheTTL) {
          _cachedIpCountry = saved;
          _cachedIpFetchTime = t;
          return saved;
        }
      }
    } catch (_) {}
    return await _resolveIpCountry();
  }

  Future<String?> _resolveIpCountry() async {
    String? found;
    // ipapi.co
    try {
      final resp = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        found = (data['country'] as String?)?.toUpperCase();
      }
    } catch (_) {}
    // ipinfo.io
    if (found == null || found.isEmpty) {
      try {
        final resp = await http
            .get(Uri.parse('https://ipinfo.io/json'))
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          found = (data['country'] as String?)?.toUpperCase();
        }
      } catch (_) {}
    }
    // api.ip.sb
    if (found == null || found.isEmpty) {
      try {
        final resp = await http
            .get(Uri.parse('https://api.ip.sb/geoip'))
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          found = (data['country_code'] as String?)?.toUpperCase();
        }
      } catch (_) {}
    }
    if (found != null && found.isNotEmpty) {
      _cachedIpCountry = found;
      _cachedIpFetchTime = DateTime.now();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('erc_ip_country', found);
        await prefs.setInt('erc_ip_ts', _cachedIpFetchTime!.millisecondsSinceEpoch);
      } catch (_) {}
      return found;
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App 回到前台时自动刷新配置
      if (_initialized) {
        // 如果高级管理器已初始化，则依赖其前台检查与事件流，避免重复刷新
        if (!AdvancedConfigManager.isManagerInitialized) {
          debugPrint('🔄 [EasyRemoteConfig] App恢复前台，自动刷新配置...');
          refresh();
        }
      }
    }
  }

  // 记得在 dispose 时移除 observer（如有全局销毁场景）
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _configChangeSubscription?.cancel();
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
  String toString() =>
      'RedirectInfo(enabled: $isEnabled, url: $url, version: $version)';

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
