/// 远程配置选项
/// 
/// 配置GitHub Gist的访问参数和缓存策略
class RemoteConfigOptions {
  /// GitHub Gist ID (必需)
  final String gistId;
  
  /// GitHub Personal Access Token (必需)
  final String githubToken;
  
  /// 配置文件名 (默认: "config.json")
  final String configFileName;
  
  /// 短期缓存过期时间 (默认: 15分钟)
  final Duration shortCacheExpiry;
  
  /// 长期缓存过期时间 (默认: 4小时)
  final Duration longCacheExpiry;
  
  /// 后台检查间隔 (默认: 5分钟)
  final Duration backgroundCheckInterval;
  
  /// 前台检查间隔 (默认: 2分钟)
  final Duration foregroundCheckInterval;
  
  /// 请求超时时间 (默认: 10秒)
  final Duration requestTimeout;
  
  /// 是否启用调试日志 (默认: false)
  final bool enableDebugLogs;

  const RemoteConfigOptions({
    required this.gistId,
    required this.githubToken,
    this.configFileName = 'config.json',
    this.shortCacheExpiry = const Duration(minutes: 15),
    this.longCacheExpiry = const Duration(hours: 4),
    this.backgroundCheckInterval = const Duration(minutes: 5),
    this.foregroundCheckInterval = const Duration(minutes: 2),
    this.requestTimeout = const Duration(seconds: 10),
    this.enableDebugLogs = false,
  });

  /// 从环境变量创建配置选项
  /// 
  /// 环境变量：
  /// - GIST_ID: GitHub Gist ID
  /// - GITHUB_TOKEN: GitHub Personal Access Token
  factory RemoteConfigOptions.fromEnvironment({
    String? fallbackGistId,
    String? fallbackToken,
    String configFileName = 'config.json',
    Duration shortCacheExpiry = const Duration(minutes: 15),
    Duration longCacheExpiry = const Duration(hours: 4),
    Duration backgroundCheckInterval = const Duration(minutes: 5),
    Duration foregroundCheckInterval = const Duration(minutes: 2),
    Duration requestTimeout = const Duration(seconds: 10),
    bool enableDebugLogs = false,
  }) {
    const String.fromEnvironment('GIST_ID', defaultValue: '');
    const String.fromEnvironment('GITHUB_TOKEN', defaultValue: '');

    final gistId = const String.fromEnvironment('GIST_ID', defaultValue: '');
    final token = const String.fromEnvironment('GITHUB_TOKEN', defaultValue: '');

    return RemoteConfigOptions(
      gistId: gistId.isNotEmpty ? gistId : (fallbackGistId ?? ''),
      githubToken: token.isNotEmpty ? token : (fallbackToken ?? ''),
      configFileName: configFileName,
      shortCacheExpiry: shortCacheExpiry,
      longCacheExpiry: longCacheExpiry,
      backgroundCheckInterval: backgroundCheckInterval,
      foregroundCheckInterval: foregroundCheckInterval,
      requestTimeout: requestTimeout,
      enableDebugLogs: enableDebugLogs,
    );
  }

  /// 复制配置选项并修改部分字段
  RemoteConfigOptions copyWith({
    String? gistId,
    String? githubToken,
    String? configFileName,
    Duration? shortCacheExpiry,
    Duration? longCacheExpiry,
    Duration? backgroundCheckInterval,
    Duration? foregroundCheckInterval,
    Duration? requestTimeout,
    bool? enableDebugLogs,
  }) {
    return RemoteConfigOptions(
      gistId: gistId ?? this.gistId,
      githubToken: githubToken ?? this.githubToken,
      configFileName: configFileName ?? this.configFileName,
      shortCacheExpiry: shortCacheExpiry ?? this.shortCacheExpiry,
      longCacheExpiry: longCacheExpiry ?? this.longCacheExpiry,
      backgroundCheckInterval: backgroundCheckInterval ?? this.backgroundCheckInterval,
      foregroundCheckInterval: foregroundCheckInterval ?? this.foregroundCheckInterval,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      enableDebugLogs: enableDebugLogs ?? this.enableDebugLogs,
    );
  }

  @override
  String toString() {
    return 'RemoteConfigOptions('
        'gistId: ${gistId.isNotEmpty ? '${gistId.substring(0, 8)}...' : 'empty'}, '
        'configFileName: $configFileName, '
        'shortCacheExpiry: $shortCacheExpiry, '
        'longCacheExpiry: $longCacheExpiry, '
        'enableDebugLogs: $enableDebugLogs)';
  }
} 