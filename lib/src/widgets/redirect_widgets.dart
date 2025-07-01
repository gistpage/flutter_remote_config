import 'package:flutter/material.dart';
import '../manager/advanced_config_manager.dart';
import '../models/remote_config.dart';
import '../config_builder.dart';
import 'internal_widgets.dart';

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
          return WebViewPage(url: redirectUrl);
        }
        return homeWidget;
      },
    );
  }

  /// 🌐 重定向信息显示组件
  /// 
  /// 显示当前重定向配置信息，主要用于调试和状态展示。
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
                InfoRow('状态', isEnabled ? '已启用' : '已禁用', contentStyle),
                InfoRow('URL', url.isNotEmpty ? url : '未设置', contentStyle),
                InfoRow('版本', version, contentStyle),
                InfoRow('应该重定向', (isEnabled && url.isNotEmpty) ? '是' : '否', contentStyle),
              ],
            ),
          ),
        );
      },
    );
  }
}