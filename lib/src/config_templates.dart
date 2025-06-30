/// 📋 配置模板 - 重定向配置的预设模板
/// 
/// 提供了重定向配置相关的预设模板，让你可以快速开始使用。
/// 你可以直接使用这些模板，也可以基于它们进行定制。
class ConfigTemplates {
  /// 🌐 重定向配置模板（核心模板）
  /// 
  /// 这是针对你的重定向配置需求设计的模板。
  /// 
  /// [version] 配置版本号
  /// [isRedirectEnabled] 是否启用重定向
  /// [redirectUrl] 重定向URL
  static Map<String, dynamic> redirectConfig({
    String version = '1',
    bool isRedirectEnabled = false,
    String? redirectUrl,
  }) => {
    'version': version,
    'isRedirectEnabled': isRedirectEnabled,
    'redirectUrl': redirectUrl ?? '',
  };

  /// 🌐 默认重定向配置（禁用状态）
  /// 
  /// 这是一个安全的默认配置，重定向功能被禁用。
  /// 适合作为初始化时的默认值。
  static Map<String, dynamic> get defaultRedirectConfig => {
    'version': '1',
    'isRedirectEnabled': false,
    'redirectUrl': '',
  };

  /// 🌐 启用重定向的配置示例
  /// 
  /// 展示了如何配置一个启用重定向的示例。
  static Map<String, dynamic> enabledRedirectExample({
    String url = 'https://example.com',
    String version = '1',
  }) => {
    'version': version,
    'isRedirectEnabled': true,
    'redirectUrl': url,
  };

  /// 🏠 专门为你的重定向配置设计的快速工厂方法
  /// 
  /// 这些方法专门针对你的使用场景优化，让配置创建更简单。
  
  /// 创建禁用重定向的配置
  static Map<String, dynamic> createDisabledRedirect({String version = '1'}) {
    return redirectConfig(
      version: version,
      isRedirectEnabled: false,
    );
  }

  /// 创建启用重定向的配置
  static Map<String, dynamic> createEnabledRedirect({
    required String url,
    String version = '1',
  }) {
    return redirectConfig(
      version: version,
      isRedirectEnabled: true,
      redirectUrl: url,
    );
  }

  /// 从现有配置切换重定向状态
  static Map<String, dynamic> toggleRedirect(
    Map<String, dynamic> currentConfig,
    {String? newUrl}
  ) {
    final isCurrentlyEnabled = currentConfig['isRedirectEnabled'] ?? false;
    final currentUrl = currentConfig['redirectUrl'] ?? '';
    
    return {
      ...currentConfig,
      'isRedirectEnabled': !isCurrentlyEnabled,
      'redirectUrl': newUrl ?? (isCurrentlyEnabled ? currentUrl : 'https://example.com'),
    };
  }

  /// 🔍 验证重定向配置的完整性
  static bool validateRedirectConfig(Map<String, dynamic> config) {
    // 检查必需字段
    if (!config.containsKey('version')) return false;
    if (!config.containsKey('isRedirectEnabled')) return false;
    if (!config.containsKey('redirectUrl')) return false;
    
    final isEnabled = config['isRedirectEnabled'];
    if (isEnabled is! bool) return false;
    
    final version = config['version'];
    if (version is! String || version.isEmpty) return false;
    
    final url = config['redirectUrl'];
    if (url is! String) return false;
    
    // 如果启用重定向，URL不能为空
    if (isEnabled && url.isEmpty) return false;
    
    return true;
  }

  /// 📝 配置的文本描述
  static String describeConfig(Map<String, dynamic> config) {
    if (!validateRedirectConfig(config)) {
      return '❌ 无效的配置格式';
    }
    
    final version = config['version'];
    final isEnabled = config['isRedirectEnabled'];
    final url = config['redirectUrl'];
    
    if (isEnabled) {
      return '✅ 版本 $version: 重定向已启用 → $url';
    } else {
      return '⭕ 版本 $version: 重定向已禁用';
    }
  }

  /// 🎯 常用的重定向场景预设
  
  /// App Store 更新重定向
  static Map<String, dynamic> appStoreRedirect({
    String version = '2',
    String appStoreUrl = 'https://apps.apple.com/app/yourapp',
  }) => {
    'version': version,
    'isRedirectEnabled': true,
    'redirectUrl': appStoreUrl,
  };

  /// 维护模式重定向
  static Map<String, dynamic> maintenanceRedirect({
    String version = '1',
    String maintenanceUrl = 'https://example.com/maintenance',
  }) => {
    'version': version,
    'isRedirectEnabled': true,
    'redirectUrl': maintenanceUrl,
  };

  /// 官网重定向
  static Map<String, dynamic> websiteRedirect({
    String version = '1',
    String websiteUrl = 'https://example.com',
  }) => {
    'version': version,
    'isRedirectEnabled': true,
    'redirectUrl': websiteUrl,
  };

  /// 禁用重定向（恢复正常）
  static Map<String, dynamic> disableRedirect({
    String version = '1',
  }) => {
    'version': version,
    'isRedirectEnabled': false,
    'redirectUrl': '',
  };
} 