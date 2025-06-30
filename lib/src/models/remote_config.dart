/// 远程配置接口
/// 
/// 所有远程配置类都应该实现此接口
abstract class RemoteConfig {
  /// 配置版本号
  String? get version;
  
  /// 从JSON创建配置实例
  /// 
  /// 子类必须实现此方法
  static RemoteConfig fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by subclass');
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson();
  
  /// 复制配置并修改部分字段
  RemoteConfig copyWith();
}

/// 基础远程配置实现
/// 
/// 提供了基本的配置结构，可以直接使用或继承
class BasicRemoteConfig implements RemoteConfig {
  @override
  final String? version;
  
  /// 自定义配置数据
  final Map<String, dynamic> data;

  const BasicRemoteConfig({
    this.version,
    this.data = const {},
  });

  /// 从JSON创建基础配置
  factory BasicRemoteConfig.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as String?;
    final data = Map<String, dynamic>.from(json);
    
    // 移除version字段，其余作为data
    data.remove('version');
    
    return BasicRemoteConfig(
      version: version,
      data: data,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final result = Map<String, dynamic>.from(data);
    if (version != null) {
      result['version'] = version;
    }
    return result;
  }

  @override
  BasicRemoteConfig copyWith({
    String? version,
    Map<String, dynamic>? data,
  }) {
    return BasicRemoteConfig(
      version: version ?? this.version,
      data: data ?? this.data,
    );
  }

  /// 获取配置值，支持嵌套键访问（如：'app.settings.theme'）
  T getValue<T>(String key, T defaultValue) {
    return _getNestedValue<T>(data, key) ?? defaultValue;
  }

  /// 获取配置值，如果不存在则返回默认值（简化版本）
  T getValueOrDefault<T>(String key, T defaultValue) {
    return getValue<T>(key, defaultValue);
  }

  /// 检查是否包含指定的配置键（支持嵌套键）
  bool containsKey(String key) {
    return hasKey(key);
  }

  /// 检查是否包含指定的配置键（支持嵌套键，新方法名）
  bool hasKey(String key) {
    return _getNestedValue<dynamic>(data, key) != null;
  }

  /// 获取嵌套值的辅助方法
  T? _getNestedValue<T>(Map<String, dynamic> map, String key) {
    if (!key.contains('.')) {
      return map[key] as T?;
    }
    
    final keys = key.split('.');
    dynamic current = map;
    
    for (final k in keys) {
      if (current is! Map<String, dynamic> || !current.containsKey(k)) {
        return null;
      }
      current = current[k];
    }
    
    return current as T?;
  }

  /// 获取所有配置键
  Iterable<String> get keys => data.keys;

  /// 获取所有配置值
  Iterable<dynamic> get values => data.values;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BasicRemoteConfig &&
        other.version == version &&
        _mapEquals(other.data, data);
  }

  @override
  int get hashCode {
    return version.hashCode ^ data.hashCode;
  }

  @override
  String toString() {
    return 'BasicRemoteConfig(version: $version, data: $data)';
  }

  /// 辅助方法：比较两个Map是否相等
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }
} 