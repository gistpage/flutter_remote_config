import 'models/remote_config.dart';

/// 🔒 重定向配置类（类型安全）
/// 
/// 这是一个类型安全的重定向配置实现，继承自 RemoteConfig。
/// 专门为重定向场景设计，提供了强类型的访问方法和验证逻辑。
/// 
/// 使用示例：
/// ```dart
/// // 从JSON创建
/// final config = RedirectConfig.fromJson(gistData);
/// 
/// // 类型安全的访问
/// if (config.shouldRedirect) {
///   navigate(config.redirectUrl!);
/// }
/// 
/// // 创建新配置
/// final newConfig = RedirectConfig.enabled(
///   url: 'https://example.com',
///   version: '2',
/// );
/// ```
class RedirectConfig extends RemoteConfig {
  @override
  final String version;
  final bool isRedirectEnabled;
  final String? redirectUrl;
  
  /// 创建重定向配置
  RedirectConfig({
    required this.version,
    required this.isRedirectEnabled,
    this.redirectUrl,
  });

  /// 从JSON创建配置
  factory RedirectConfig.fromJson(Map<String, dynamic> json) {
    return RedirectConfig(
      version: json['version'] ?? '1',
      isRedirectEnabled: json['isRedirectEnabled'] ?? false,
      redirectUrl: json['redirectUrl'],
    );
  }

  /// 默认配置（禁用重定向）
  factory RedirectConfig.defaultConfig() => RedirectConfig(
    version: '1',
    isRedirectEnabled: false,
    redirectUrl: null,
  );

  /// 创建禁用重定向的配置
  factory RedirectConfig.disabled({String version = '1'}) => RedirectConfig(
    version: version,
    isRedirectEnabled: false,
    redirectUrl: null,
  );

  /// 创建启用重定向的配置
  factory RedirectConfig.enabled({
    required String url,
    String version = '1',
  }) => RedirectConfig(
    version: version,
    isRedirectEnabled: true,
    redirectUrl: url,
  );

  /// 从现有配置创建并切换状态
  factory RedirectConfig.toggle(
    RedirectConfig current, {
    String? newUrl,
    String? newVersion,
  }) {
    if (current.isRedirectEnabled) {
      // 当前是启用状态，切换为禁用
      return RedirectConfig.disabled(version: newVersion ?? current.version);
    } else {
      // 当前是禁用状态，切换为启用
      final url = newUrl ?? current.redirectUrl ?? 'https://example.com';
      return RedirectConfig.enabled(
        url: url,
        version: newVersion ?? current.version,
      );
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'isRedirectEnabled': isRedirectEnabled,
    if (redirectUrl != null) 'redirectUrl': redirectUrl,
  };

  @override
  RedirectConfig copyWith({
    String? version,
    bool? isRedirectEnabled,
    String? redirectUrl,
  }) {
    return RedirectConfig(
      version: version ?? this.version,
      isRedirectEnabled: isRedirectEnabled ?? this.isRedirectEnabled,
      redirectUrl: redirectUrl ?? this.redirectUrl,
    );
  }

  /// 是否应该执行重定向
  bool get shouldRedirect => isRedirectEnabled && hasValidUrl;

  /// 是否有有效的重定向URL
  bool get hasValidUrl => redirectUrl?.isNotEmpty == true;

  /// 获取有效的重定向URL，如果无效则抛出异常
  String get validRedirectUrl {
    if (!hasValidUrl) {
      throw StateError('重定向URL无效: $redirectUrl');
    }
    return redirectUrl!;
  }

  /// 获取安全的重定向URL，如果无效则返回默认值
  String safeRedirectUrl([String defaultUrl = '']) {
    return hasValidUrl ? redirectUrl! : defaultUrl;
  }

  /// 验证配置的完整性
  bool get isValid {
    // 版本号不能为空
    if (version.isEmpty) return false;
    
    // 如果启用重定向，必须有有效的URL
    if (isRedirectEnabled) {
      return hasValidUrl && _isValidUrl(redirectUrl!);
    }
    
    return true;
  }

  /// 获取配置状态描述
  String get statusDescription {
    if (!isValid) return '配置无效';
    
    if (shouldRedirect) {
      return '重定向已启用 -> $redirectUrl';
    } else if (isRedirectEnabled && !hasValidUrl) {
      return '重定向已启用但URL无效';
    } else {
      return '重定向已禁用';
    }
  }

  /// 获取详细信息
  RedirectConfigInfo get info => RedirectConfigInfo(
    version: version,
    isEnabled: isRedirectEnabled,
    url: redirectUrl,
    isValid: isValid,
    shouldRedirect: shouldRedirect,
    statusDescription: statusDescription,
  );

  /// 与另一个配置比较是否有差异
  bool hasDifference(RedirectConfig other) {
    return version != other.version ||
           isRedirectEnabled != other.isRedirectEnabled ||
           redirectUrl != other.redirectUrl;
  }

  /// 获取与另一个配置的差异描述
  List<String> getDifferences(RedirectConfig other) {
    final differences = <String>[];
    
    if (version != other.version) {
      differences.add('版本: $version -> ${other.version}');
    }
    
    if (isRedirectEnabled != other.isRedirectEnabled) {
      differences.add('重定向状态: ${isRedirectEnabled ? '启用' : '禁用'} -> ${other.isRedirectEnabled ? '启用' : '禁用'}');
    }
    
    if (redirectUrl != other.redirectUrl) {
      differences.add('重定向URL: ${redirectUrl ?? '未设置'} -> ${other.redirectUrl ?? '未设置'}');
    }
    
    return differences;
  }

  /// 简单的URL格式验证
  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  String toString() => 'RedirectConfig(version: $version, enabled: $isRedirectEnabled, url: $redirectUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedirectConfig &&
        other.version == version &&
        other.isRedirectEnabled == isRedirectEnabled &&
        other.redirectUrl == redirectUrl;
  }

  @override
  int get hashCode => Object.hash(version, isRedirectEnabled, redirectUrl);
}

/// 📋 重定向配置信息类
/// 
/// 包含重定向配置的所有详细信息，用于状态展示和调试。
class RedirectConfigInfo {
  final String version;
  final bool isEnabled;
  final String? url;
  final bool isValid;
  final bool shouldRedirect;
  final String statusDescription;

  const RedirectConfigInfo({
    required this.version,
    required this.isEnabled,
    required this.url,
    required this.isValid,
    required this.shouldRedirect,
    required this.statusDescription,
  });

  /// 转换为Map，方便序列化或调试
  Map<String, dynamic> toMap() => {
    'version': version,
    'isEnabled': isEnabled,
    'url': url,
    'isValid': isValid,
    'shouldRedirect': shouldRedirect,
    'statusDescription': statusDescription,
  };

  @override
  String toString() => 'RedirectConfigInfo($statusDescription)';
}

/// 🔧 重定向配置工具类
/// 
/// 提供重定向配置相关的工具方法和验证函数。
class RedirectConfigUtils {
  /// 验证URL格式
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 标准化URL格式
  static String? normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // 如果没有协议，添加https
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    try {
      final uri = Uri.parse(url);
      return uri.toString();
    } catch (e) {
      return null;
    }
  }

  /// 比较两个配置的优先级
  /// 返回值：-1 表示 a 优先级低于 b，0 表示相等，1 表示 a 优先级高于 b
  static int compareConfigPriority(RedirectConfig a, RedirectConfig b) {
    // 首先比较版本号（假设版本号是数字）
    try {
      final versionA = int.parse(a.version);
      final versionB = int.parse(b.version);
      if (versionA != versionB) {
        return versionA.compareTo(versionB);
      }
    } catch (e) {
      // 如果版本号不是数字，按字符串比较
      final versionComparison = a.version.compareTo(b.version);
      if (versionComparison != 0) {
        return versionComparison;
      }
    }
    
    // 版本号相同时，启用的配置优先级更高
    if (a.isRedirectEnabled != b.isRedirectEnabled) {
      return a.isRedirectEnabled ? 1 : -1;
    }
    
    // 都启用或都禁用时，有URL的优先级更高
    if (a.hasValidUrl != b.hasValidUrl) {
      return a.hasValidUrl ? 1 : -1;
    }
    
    return 0; // 完全相同
  }

  /// 合并多个配置，返回优先级最高的
  static RedirectConfig mergeConfigs(List<RedirectConfig> configs) {
    if (configs.isEmpty) {
      return RedirectConfig.defaultConfig();
    }
    
    if (configs.length == 1) {
      return configs.first;
    }
    
    configs.sort(compareConfigPriority);
    return configs.last; // 返回优先级最高的
  }

  /// 创建配置的安全副本
  static RedirectConfig createSafeCopy(RedirectConfig config) {
    return RedirectConfig(
      version: config.version,
      isRedirectEnabled: config.isRedirectEnabled,
      redirectUrl: config.redirectUrl,
    );
  }

  /// 检查配置是否需要更新
  static bool needsUpdate(RedirectConfig current, RedirectConfig remote) {
    return compareConfigPriority(current, remote) < 0;
  }
} 