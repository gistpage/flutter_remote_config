import 'package:flutter/material.dart';
import 'manager/advanced_config_manager.dart';
import 'models/remote_config.dart';

/// 🎨 配置构建器 - 类型安全的配置访问
/// 
/// 这个Widget会自动监听配置变化并重新构建UI。
/// 非常适合需要根据远程配置动态调整UI的场景。
/// 
/// 使用示例：
/// ```dart
/// ConfigBuilder<bool>(
///   configKey: 'isNewFeatureEnabled',
///   defaultValue: false,
///   builder: (isEnabled) {
///     return isEnabled 
///       ? NewFeatureWidget() 
///       : OldFeatureWidget();
///   },
/// )
/// ```
class ConfigBuilder<T> extends StatelessWidget {
  final String configKey;
  final T defaultValue;
  final Widget Function(T value) builder;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;

  const ConfigBuilder({
    super.key,
    required this.configKey,
    required this.defaultValue,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // 检查 AdvancedConfigManager 是否已初始化
    if (!AdvancedConfigManager.isManagerInitialized) {
      // 未初始化时返回默认值构建的Widget（适用于测试环境等场景）
      return builder(defaultValue);
    }
    
    return StreamBuilder<RemoteConfig>(
      stream: AdvancedConfigManager.instance.configStream,
      builder: (context, snapshot) {
        // 错误处理
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(snapshot.error!);
          }
          // 默认错误处理：使用默认值
          return builder(defaultValue);
        }

        // 加载中
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return loadingWidget ?? const SizedBox.shrink();
        }
        
        // 获取配置值
        final config = snapshot.data as BasicRemoteConfig?;
        final value = config?.getValue(configKey, defaultValue) ?? defaultValue;
        
        try {
          return builder(value);
        } catch (e) {
          // 类型转换失败，使用默认值
          return builder(defaultValue);
        }
      },
    );
  }
}

/// 🎨 重定向组件集合
/// 
/// 提供了多种重定向场景的便捷组件，专门针对你的重定向配置优化。
/// 这些组件会自动处理配置监听、错误处理和加载状态。
class EasyRedirectWidgets {
  /// 🌐 简化版重定向组件（推荐使用）
  /// 
  /// 这是最简单的重定向组件，适合大多数场景。
  /// 它会自动检查 isRedirectEnabled 和 redirectUrl 配置。
  /// 
  /// [homeWidget] 正常情况下显示的主页面
  /// [loadingWidget] 加载配置时显示的组件
  /// [errorWidget] 配置加载失败时显示的组件
  static Widget simpleRedirect({
    required Widget homeWidget,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    // 检查 AdvancedConfigManager 是否已初始化
    if (!AdvancedConfigManager.isManagerInitialized) {
      // 未初始化时返回 homeWidget（适用于测试环境等场景）
      return homeWidget;
    }
    
    return StreamBuilder<RemoteConfig>(
      stream: AdvancedConfigManager.instance.configStream,
      builder: (context, snapshot) {
        // 错误处理
        if (snapshot.hasError) {
          return errorWidget ?? homeWidget;
        }

        // 加载中
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        final config = snapshot.data as BasicRemoteConfig?;
        final isRedirectEnabled = config?.getValue('isRedirectEnabled', false) ?? false;
        final redirectUrl = config?.getValue('redirectUrl', '') ?? '';
        
        // 检查是否需要重定向
        if (isRedirectEnabled && redirectUrl.isNotEmpty) {
          return _WebViewPage(url: redirectUrl);
        }
        
        return homeWidget;
      },
    );
  }

  /// 🌐 重定向检查组件（细粒度控制）
  /// 
  /// 提供更细粒度的控制，适合需要自定义重定向逻辑的场景。
  /// 
  /// [normalWidget] 不需要重定向时显示的组件
  /// [redirectBuilder] 需要重定向时的构建器，会传入重定向URL
  /// [loadingWidget] 加载时显示的组件
  static Widget redirectChecker({
    required Widget normalWidget,
    required Widget Function(String url) redirectBuilder,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    return ConfigBuilder<bool>(
      configKey: 'isRedirectEnabled',
      defaultValue: false,
      loadingWidget: loadingWidget,
      errorBuilder: errorWidget != null ? (_) => errorWidget : null,
      builder: (isRedirectEnabled) {
        if (!isRedirectEnabled) {
          return normalWidget;
        }
        
        return ConfigBuilder<String>(
          configKey: 'redirectUrl',
          defaultValue: '',
          builder: (redirectUrl) {
            if (redirectUrl.isEmpty) {
              return normalWidget;
            }
            return redirectBuilder(redirectUrl);
          },
        );
      },
    );
  }

  /// 🌐 条件重定向组件
  /// 
  /// 允许添加额外的重定向条件，比如版本检查、用户权限等。
  /// 
  /// [homeWidget] 正常显示的组件
  /// [additionalCondition] 额外的重定向条件检查
  /// [onRedirect] 重定向时的回调，可用于日志记录等
  static Widget conditionalRedirect({
    required Widget homeWidget,
    bool Function()? additionalCondition,
    void Function(String url)? onRedirect,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    // 检查 AdvancedConfigManager 是否已初始化
    if (!AdvancedConfigManager.isManagerInitialized) {
      // 未初始化时返回 homeWidget（适用于测试环境等场景）
      return homeWidget;
    }
    
    return StreamBuilder<RemoteConfig>(
      stream: AdvancedConfigManager.instance.configStream,
      builder: (context, snapshot) {
        // 错误处理
        if (snapshot.hasError) {
          return errorWidget ?? homeWidget;
        }

        // 加载中
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        final config = snapshot.data as BasicRemoteConfig?;
        final isRedirectEnabled = config?.getValue('isRedirectEnabled', false) ?? false;
        final redirectUrl = config?.getValue('redirectUrl', '') ?? '';
        
        // 检查重定向条件
        bool shouldRedirect = isRedirectEnabled && redirectUrl.isNotEmpty;
        
        // 检查额外条件
        if (shouldRedirect && additionalCondition != null) {
          shouldRedirect = additionalCondition();
        }
        
        if (shouldRedirect) {
          // 触发重定向回调
          onRedirect?.call(redirectUrl);
          return _WebViewPage(url: redirectUrl);
        }
        
        return homeWidget;
      },
    );
  }

  /// 🌐 重定向信息显示组件
  /// 
  /// 显示当前重定向配置的信息，主要用于调试和状态展示。
  static Widget redirectInfo({
    TextStyle? titleStyle,
    TextStyle? contentStyle,
  }) {
    return ConfigBuilder<Map<String, dynamic>>(
      configKey: '',
      defaultValue: const {},
      builder: (config) {
        final isEnabled = config['isRedirectEnabled'] ?? false;
        final url = config['redirectUrl'] ?? '';
        final version = config['version'] ?? '未知';
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '重定向配置信息',
                  style: titleStyle ?? const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow('状态', isEnabled ? '已启用' : '已禁用', contentStyle),
                _InfoRow('URL', url.isNotEmpty ? url : '未设置', contentStyle),
                _InfoRow('版本', version, contentStyle),
                _InfoRow('应该重定向', (isEnabled && url.isNotEmpty) ? '是' : '否', contentStyle),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 内部组件：信息行显示
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const _InfoRow(this.label, this.value, this.style);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: style?.copyWith(fontWeight: FontWeight.w500) ?? 
                     const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// 内部组件：简单的WebView页面
/// 
/// 这是一个简化的WebView实现，实际项目中你应该替换为
/// 你选择的WebView插件（如 webview_flutter）
class _WebViewPage extends StatelessWidget {
  final String url;

  const _WebViewPage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('重定向页面'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.web,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '重定向到:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '请安装并配置 webview_flutter 插件\n来显示实际的网页内容',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 