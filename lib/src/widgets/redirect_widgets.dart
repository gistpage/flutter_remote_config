import 'package:flutter/material.dart';
import '../manager/advanced_config_manager.dart';
import '../models/remote_config.dart';
import '../config_builder.dart';
import '../easy_remote_config.dart';
import 'internal_widgets.dart';
import 'dart:async';

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
    return _SimpleRedirectWidget(
      homeWidget: homeWidget,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
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

/// 🔧 私有的简化重定向Widget实现
/// 
/// 解决原版本的无限等待问题：
/// 1. 使用 FutureBuilder 替代 StreamBuilder
/// 2. 添加3秒超时保护
/// 3. 直接检查配置状态
/// 4. 提供调试日志
class _SimpleRedirectWidget extends StatelessWidget {
  final Widget homeWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const _SimpleRedirectWidget({
    required this.homeWidget,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveWidget(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        
        // 显示加载状态
        return loadingWidget ?? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载配置...', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Future<Widget> _resolveWidget() async {
    const debugMode = true; // 临时启用调试
    
    try {
      if (debugMode) {
        print('🔧 SimpleRedirect: 开始解析widget');
      }

      // 首先尝试使用 EasyRemoteConfig（它包含默认配置兜底逻辑）
      try {
        if (EasyRemoteConfig.isInitialized) {
          final isRedirectEnabled = EasyRemoteConfig.instance.isRedirectEnabled;
          final redirectUrl = EasyRemoteConfig.instance.redirectUrl;

          if (debugMode) {
            print('🔧 SimpleRedirect: 使用EasyRemoteConfig - 重定向启用=$isRedirectEnabled, URL=$redirectUrl');
          }

          if (isRedirectEnabled && redirectUrl.isNotEmpty) {
            return WebViewPage(url: redirectUrl);
          }
          
          if (debugMode) {
            print('🔧 SimpleRedirect: EasyRemoteConfig显示重定向未启用，返回主页面');
          }
          return homeWidget;
        }
      } catch (e) {
        if (debugMode) {
          print('🔧 SimpleRedirect: EasyRemoteConfig获取配置失败: $e，尝试AdvancedConfigManager');
        }
      }

      // 备用方案：检查 AdvancedConfigManager 是否已初始化
      if (!AdvancedConfigManager.isManagerInitialized) {
        if (debugMode) {
          print('🔧 SimpleRedirect: AdvancedConfigManager也未初始化，返回主页面');
        }
        return homeWidget;
      }

      // 最后的备用方案：直接从 AdvancedConfigManager 获取配置
      final configFuture = AdvancedConfigManager.instance.getConfig();
      final config = await configFuture.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (debugMode) {
            print('🔧 SimpleRedirect: 获取配置超时，返回主页面');
          }
          throw TimeoutException('获取配置超时', const Duration(seconds: 3));
        },
      );

      if (debugMode) {
        print('🔧 SimpleRedirect: 从AdvancedConfigManager成功获取配置');
      }

      // 处理配置
      if (config is BasicRemoteConfig) {
        final isRedirectEnabled = config.getValue('isRedirectEnabled', false);
        final redirectUrl = config.getValue('redirectUrl', '');

        if (debugMode) {
          print('🔧 SimpleRedirect: AdvancedConfigManager - 重定向启用=$isRedirectEnabled, URL=$redirectUrl');
        }

        if (isRedirectEnabled && redirectUrl.isNotEmpty) {
          return WebViewPage(url: redirectUrl);
        }
      }

      return homeWidget;

    } catch (e) {
      if (debugMode) {
        print('🔧 SimpleRedirect: 解析失败: $e, 返回主页面');
      }
      return errorWidget ?? homeWidget;
    }
  }
}