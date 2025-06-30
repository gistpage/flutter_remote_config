import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../manager/advanced_config_manager.dart';
import '../models/remote_config.dart';
import '../easy_remote_config.dart';

/// 🐛 调试助手
/// 
/// 提供远程配置的调试和诊断功能，帮助开发者快速定位问题。
/// 这个工具主要在开发环境中使用，不建议在生产环境启用。
class RemoteConfigDebugHelper {
  static bool _debugEnabled = false;
  static final List<String> _logs = [];
  static Timer? _healthCheckTimer;
  
  /// 启用调试模式
  static void enableDebug({bool enableHealthCheck = false}) {
    _debugEnabled = true;
    log('🔧 RemoteConfig调试模式已启用');
    
    if (enableHealthCheck) {
      startHealthMonitoring();
    }
  }
  
  /// 禁用调试模式
  static void disableDebug() {
    _debugEnabled = false;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    log('🔧 RemoteConfig调试模式已禁用');
  }
  
  /// 记录调试日志
  static void log(String message) {
    if (_debugEnabled) {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] $message';
      _logs.add(logMessage);
      if (kDebugMode) {
        print('🔧 RemoteConfig: $message');
      }
      
      // 保持日志数量在合理范围内
      if (_logs.length > 100) {
        _logs.removeRange(0, 20);
      }
    }
  }
  
  /// 获取所有调试日志
  static List<String> getLogs() => List.unmodifiable(_logs);
  
  /// 清除调试日志
  static void clearLogs() {
    _logs.clear();
    log('调试日志已清除');
  }
  
  /// 检查配置健康状态
  static Map<String, dynamic> getHealthStatus() {
    log('检查配置健康状态');
    
    try {
      final manager = AdvancedConfigManager.instance;
      final isInitialized = manager.isInitialized;
      final hasConfig = manager.currentConfig != null;
      final config = manager.currentConfig;
      
      final status = {
        'timestamp': DateTime.now().toIso8601String(),
        'initialized': isInitialized,
        'hasConfig': hasConfig,
        'configVersion': config?.version ?? 'N/A',
        'configType': config?.runtimeType.toString() ?? 'N/A',
        'easyConfigInitialized': _checkEasyConfigStatus(),
        'memoryUsage': _getMemoryUsage(),
        'errors': _getRecentErrors(),
      };
      
      if (hasConfig && config is BasicRemoteConfig) {
        status['configData'] = config.toJson();
        status['configSize'] = config.toJson().toString().length;
      }
      
      log('健康状态检查完成: ${status['initialized'] == true ? '正常' : '异常'}');
      return status;
    } catch (e, stack) {
      final errorStatus = {
        'timestamp': DateTime.now().toIso8601String(),
        'error': 'Failed to check health status',
        'exception': e.toString(),
        'stackTrace': stack.toString(),
      };
      log('健康状态检查失败: $e');
      return errorStatus;
    }
  }
  
  /// 验证Gist配置连接
  static Future<Map<String, dynamic>> validateGistAccess(String gistId, String token) async {
    log('验证Gist访问: $gistId');
    
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'gistId': gistId,
      'success': false,
      'responseTime': 0,
    };
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse('https://api.github.com/gists/$gistId'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'flutter-remote-config-debug',
        },
      ).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      result['responseTime'] = stopwatch.elapsedMilliseconds;
      result['statusCode'] = response.statusCode;
      result['success'] = response.statusCode == 200;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        result['gistInfo'] = {
          'description': data['description'],
          'filesCount': data['files']?.length ?? 0,
          'updatedAt': data['updated_at'],
          'public': data['public'],
        };
        
        // 检查是否包含配置文件
        final files = data['files'] as Map<String, dynamic>?;
        if (files != null) {
          result['hasConfigFile'] = files.containsKey('config.json');
          result['availableFiles'] = files.keys.toList();
        }
        
        log('Gist访问验证成功: ${result['responseTime']}ms');
      } else {
        result['error'] = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        result['responseBody'] = response.body;
        log('Gist访问验证失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      result['error'] = e.toString();
      log('Gist访问验证异常: $e');
    }
    
    return result;
  }
  
  /// 诊断配置问题
  static Map<String, dynamic> diagnoseConfig() {
    log('开始配置诊断');
    
    final diagnosis = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'issues': <String>[],
      'warnings': <String>[],
      'suggestions': <String>[],
      'overall': 'unknown',
    };
    
    try {
      // 检查管理器状态
      final manager = AdvancedConfigManager.instance;
      if (!manager.isInitialized) {
        diagnosis['issues'].add('AdvancedConfigManager未初始化');
        diagnosis['suggestions'].add('请先调用AdvancedConfigManager.initialize()或EasyRemoteConfig.init()');
      }
      
      // 检查配置是否存在
      final config = manager.currentConfig;
      if (config == null) {
        diagnosis['issues'].add('当前没有配置数据');
        diagnosis['suggestions'].add('检查网络连接和Gist访问权限');
      } else {
        // 检查配置内容
        if (config is BasicRemoteConfig) {
          final data = config.toJson();
          if (data.isEmpty) {
            diagnosis['warnings'].add('配置数据为空');
          }
          
          // 检查重定向配置完整性
          if (data.containsKey('isRedirectEnabled')) {
            final isEnabled = data['isRedirectEnabled'];
            final url = data['redirectUrl'];
            
            if (isEnabled == true && (url == null || url.toString().isEmpty)) {
              diagnosis['issues'].add('重定向已启用但URL为空');
              diagnosis['suggestions'].add('设置有效的redirectUrl或禁用重定向');
            }
          }
        }
      }
      
      // 检查EasyRemoteConfig状态
      try {
        final easyConfig = EasyRemoteConfig.instance;
        if (!easyConfig.isConfigLoaded) {
          diagnosis['warnings'].add('EasyRemoteConfig配置未加载');
        }
      } catch (e) {
        diagnosis['warnings'].add('EasyRemoteConfig未初始化');
      }
      
      // 确定总体状态
      if (diagnosis['issues'].isNotEmpty) {
        diagnosis['overall'] = 'error';
      } else if (diagnosis['warnings'].isNotEmpty) {
        diagnosis['overall'] = 'warning';
      } else {
        diagnosis['overall'] = 'healthy';
      }
      
      log('配置诊断完成: ${diagnosis['overall']}');
    } catch (e) {
      diagnosis['issues'].add('诊断过程中发生异常: $e');
      diagnosis['overall'] = 'error';
      log('配置诊断异常: $e');
    }
    
    return diagnosis;
  }
  
  /// 导出调试报告
  static Map<String, dynamic> exportDebugReport() {
    log('导出调试报告');
    
    return {
      'reportId': DateTime.now().millisecondsSinceEpoch,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.toString(),
      'debugMode': kDebugMode,
      'healthStatus': getHealthStatus(),
      'diagnosis': diagnoseConfig(),
      'logs': getLogs(),
      'configuration': _getConfigurationDetails(),
    };
  }
  
  /// 启动健康监控
  static void startHealthMonitoring({Duration interval = const Duration(minutes: 1)}) {
    _healthCheckTimer?.cancel();
    
    _healthCheckTimer = Timer.periodic(interval, (timer) {
      final status = getHealthStatus();
      if (status['initialized'] != true || status['hasConfig'] != true) {
        log('⚠️ 健康检查警告: 配置状态异常');
      }
    });
    
    log('健康监控已启动，间隔: ${interval.inSeconds}秒');
  }
  
  /// 停止健康监控
  static void stopHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    log('健康监控已停止');
  }
  
  /// 模拟配置更新（用于测试）
  static Future<void> simulateConfigUpdate(Map<String, dynamic> newConfig) async {
    log('模拟配置更新: ${newConfig.toString()}');
    
    try {
      // 这里可以添加模拟更新的逻辑
      log('模拟配置更新完成');
    } catch (e) {
      log('模拟配置更新失败: $e');
    }
  }
  
  // ========== 私有辅助方法 ==========
  
  static bool _checkEasyConfigStatus() {
    try {
      return EasyRemoteConfig.instance.isConfigLoaded;
    } catch (e) {
      return false;
    }
  }
  
  static Map<String, dynamic> _getMemoryUsage() {
    // 这里可以添加内存使用情况的检查
    return {
      'logsCount': _logs.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  static List<String> _getRecentErrors() {
    // 返回最近的错误日志
    return _logs
        .where((log) => log.contains('错误') || log.contains('异常') || log.contains('失败'))
        .take(5)
        .toList();
  }
  
  static Map<String, dynamic> _getConfigurationDetails() {
    try {
      final manager = AdvancedConfigManager.instance;
      final config = manager.currentConfig;
      
      return {
        'managerType': manager.runtimeType.toString(),
        'configType': config?.runtimeType.toString(),
        'hasStreamListeners': 'unknown', // 这里需要根据实际实现添加
        'isInitialized': manager.isInitialized,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

/// 🎯 配置调试面板组件
/// 
/// 提供一个可视化的调试面板，显示配置状态和诊断信息。
/// 主要用于开发环境。