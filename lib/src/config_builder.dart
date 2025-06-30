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