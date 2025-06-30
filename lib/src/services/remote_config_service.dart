import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/remote_config.dart';
import '../config/remote_config_options.dart';

/// 远程配置服务
/// 
/// 智能配置管理策略：
/// 1. 版本号机制：配置包含版本号，快速检测更新
/// 2. ETag支持：利用HTTP ETag减少不必要的数据传输
/// 3. 多级缓存：不同场景使用不同缓存策略
/// 4. 应用状态感知：前台时更频繁检查更新
/// 5. 生命周期感知：启动和恢复前台时主动检查
class RemoteConfigService<T extends RemoteConfig> {
  final RemoteConfigOptions options;
  final T Function(Map<String, dynamic>) configFactory;
  final String _cacheKey;
  final String _cacheTimeKey;
  final String _etagKey;
  final String _versionKey;
  final String _lastCheckKey;

  RemoteConfigService({
    required this.options,
    required this.configFactory,
    String? cacheKeyPrefix,
  }) : _cacheKey = '${cacheKeyPrefix ?? 'remote_config'}_cache',
       _cacheTimeKey = '${cacheKeyPrefix ?? 'remote_config'}_cache_time',
       _etagKey = '${cacheKeyPrefix ?? 'remote_config'}_etag',
       _versionKey = '${cacheKeyPrefix ?? 'remote_config'}_version',
       _lastCheckKey = '${cacheKeyPrefix ?? 'remote_config'}_last_check';

  /// 获取远程配置
  /// [forceRefresh] 强制从远程获取
  /// [isAppInForeground] 应用是否在前台（影响缓存策略）
  /// [skipCacheTimeCheck] 跳过缓存时间检查（应用恢复前台时使用）
  Future<T> getConfig({
    bool forceRefresh = false,
    bool isAppInForeground = true,
    bool skipCacheTimeCheck = false,
  }) async {
    try {
      // 强制刷新时直接从远程获取
      if (forceRefresh) {
        if (options.enableDebugLogs && kDebugMode) {
          print('🔄 强制刷新配置');
        }
        return await _fetchAndCacheFromGist();
      }

      // 跳过缓存时间检查 或 正常的时间检查
      if (skipCacheTimeCheck || await _shouldCheckForUpdate(isAppInForeground)) {
        if (options.enableDebugLogs) {
          print('⏰ 检查配置更新');
        }
        return await _checkForUpdateAndGet(isAppInForeground);
      }

      // 使用缓存配置
      final cachedConfig = await _getCachedConfig(isAppInForeground);
      if (cachedConfig != null) {
        if (options.enableDebugLogs) {
          final version = await _getCachedVersion();
          print('📦 使用缓存配置: version=$version');
        }
        return cachedConfig;
      }

      // 缓存不可用，从远程获取
      if (options.enableDebugLogs) {
        print('🌐 缓存不可用，从远程获取配置');
      }
      return await _fetchAndCacheFromGist();
      
    } catch (e) {
      if (options.enableDebugLogs) {
        print('❌ 获取配置失败: $e');
      }
      return await _handleFetchError();
    }
  }

  /// 应用启动时获取配置（绕过短期缓存）
  Future<T> getConfigOnLaunch() async {
    if (options.enableDebugLogs) {
      print('🚀 应用启动，检查最新配置');
    }
    
    try {
      // 检查是否有配置更新（使用ETag优化）
      final hasUpdate = await _checkVersionUpdate();
      if (hasUpdate) {
        if (options.enableDebugLogs) {
          print('🆕 启动时发现配置更新');
        }
        return await _fetchAndCacheFromGist();
      }
      
      // 没有更新，使用缓存（即使是短期缓存）
      final cachedConfig = await _getAnyCachedConfig();
      if (cachedConfig != null) {
        if (options.enableDebugLogs) {
          print('📦 启动时使用缓存配置: version=${cachedConfig.version}');
        }
        return cachedConfig;
      }
      
      // 缓存也没有，从远程获取
      if (options.enableDebugLogs) {
        print('🌐 启动时首次获取配置');
      }
      return await _fetchAndCacheFromGist();
      
    } catch (e) {
      if (options.enableDebugLogs) {
        print('❌ 启动时获取配置失败: $e');
      }
      return await _handleFetchError();
    }
  }

  /// 应用恢复前台时检查配置
  Future<T> getConfigOnResume() async {
    if (options.enableDebugLogs) {
      print('👀 应用恢复前台，检查配置更新');
    }
    
    // 恢复前台时使用正常的更新检查逻辑，但跳过缓存时间检查
    return await getConfig(
      forceRefresh: false,
      isAppInForeground: true,
      skipCacheTimeCheck: true,
    );
  }

  /// 智能检查并获取配置（核心方法）
  Future<T> _checkForUpdateAndGet(bool isAppInForeground) async {
    final hasUpdate = await _checkVersionUpdate();
    if (hasUpdate) {
      if (options.enableDebugLogs) {
        print('🆕 发现配置更新');
      }
      return await _fetchAndCacheFromGist();
    }
    
    // 没有更新，返回缓存配置
    final cachedConfig = await _getCachedConfig(isAppInForeground);
    if (cachedConfig != null) {
      if (options.enableDebugLogs) {
        print('📦 配置无更新，使用缓存');
      }
      // 更新最后检查时间
      await _updateLastCheckTime();
      return cachedConfig;
    }
    
    // 缓存不可用，从远程获取
    return await _fetchAndCacheFromGist();
  }

  /// 检查是否需要更新（基于时间间隔）
  Future<bool> _shouldCheckForUpdate(bool isAppInForeground) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckTime = prefs.getInt(_lastCheckKey);
    
    if (lastCheckTime == null) return true;
    
    final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
    final now = DateTime.now();
    final timeSinceLastCheck = now.difference(lastCheck);
    
    final checkInterval = isAppInForeground 
        ? options.foregroundCheckInterval 
        : options.backgroundCheckInterval;
    
    return timeSinceLastCheck >= checkInterval;
  }

  /// 检查版本更新（使用ETag优化）
  Future<bool> _checkVersionUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedETag = prefs.getString(_etagKey);
      
      final url = Uri.parse('https://api.github.com/gists/${options.gistId}');
      
      final headers = {
        'Authorization': 'Bearer ${options.githubToken}',
        'Accept': 'application/vnd.github.v3+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };
      
      // 如果有ETag，添加If-None-Match头
      if (cachedETag != null && cachedETag.isNotEmpty) {
        headers['If-None-Match'] = cachedETag;
      }
      
      if (options.enableDebugLogs) {
        print('🔍 检查配置版本更新...');
      }
      
      final response = await http.get(url, headers: headers).timeout(options.requestTimeout);
      
      if (response.statusCode == 304) {
        // 304 Not Modified - 配置没有变化
        if (options.enableDebugLogs) {
          print('✅ 配置无变化 (304)');
        }
        await _updateLastCheckTime();
        return false;
      }
      
      if (response.statusCode == 200) {
        // 有新内容，检查版本号
        final responseETag = response.headers['etag'];
        final data = json.decode(response.body);
        final files = data['files'];
        
        String? configContent = _extractConfigContent(files);
        
        if (configContent != null) {
          final configJson = json.decode(configContent);
          final remoteVersion = configJson['version'] as String?;
          final cachedVersion = prefs.getString(_versionKey);
          
          if (options.enableDebugLogs) {
            print('🏷️ 远程版本: $remoteVersion, 缓存版本: $cachedVersion');
          }

          // 比较版本号
          if (remoteVersion != cachedVersion) {
            if (options.enableDebugLogs) {
              print('🆕 发现新版本: $remoteVersion');
            }
            return true;
          }
        }
        
        // 版本相同，更新ETag和检查时间
        if (responseETag != null) {
          await prefs.setString(_etagKey, responseETag);
        }
        await _updateLastCheckTime();
        return false;
      }
      
      // 其他状态码当作没有更新
      if (options.enableDebugLogs) {
        print('⚠️ 检查更新失败: ${response.statusCode}');
      }
      return false;
      
    } catch (e) {
      if (options.enableDebugLogs) {
        print('⚠️ 检查版本更新失败: $e');
      }
      return false; // 网络错误时保守处理
    }
  }

  /// 从远程获取配置并缓存
  Future<T> _fetchAndCacheFromGist() async {
    if (options.enableDebugLogs) {
      print('🌐 从 GitHub Gist 获取配置...');
    }
    
    final url = Uri.parse('https://api.github.com/gists/${options.gistId}');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${options.githubToken}',
        'Accept': 'application/vnd.github.v3+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ).timeout(options.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final files = data['files'];
      final responseETag = response.headers['etag'];
      
      // 查找配置文件
      String? configContent = _extractConfigContent(files);
      
      if (configContent == null) {
        throw Exception('在 Gist 中未找到配置文件 ${options.configFileName}');
      }

      final configJson = json.decode(configContent);
      
      // 验证配置格式
      if (!_isValidConfig(configJson)) {
        throw Exception('配置格式无效');
      }
      
      final config = configFactory(configJson);
      
      // 缓存配置和元数据
      await _cacheConfig(config, responseETag);
      
      if (options.enableDebugLogs) {
        print('✅ 成功获取远程配置: version=${config.version}');
      }
      return config;
    } else if (response.statusCode == 401) {
      throw Exception('GitHub Token 无效或已过期');
    } else if (response.statusCode == 404) {
      throw Exception('Gist 不存在或无法访问');
    } else {
      throw Exception('GitHub API 请求失败: ${response.statusCode}');
    }
  }

  /// 从 Gist 文件中提取配置内容
  String? _extractConfigContent(Map<String, dynamic> files) {
    // 优先查找指定的配置文件
    if (files.containsKey(options.configFileName)) {
      return files[options.configFileName]['content'] as String?;
    }
    
    // 如果指定的文件名不是默认的 config.json，也尝试查找 config.json
    if (options.configFileName != 'config.json' && files.containsKey('config.json')) {
      return files['config.json']['content'] as String?;
    }
    
    // 查找其他可能的配置文件名
    final configFileNames = ['app_config.json', 'settings.json', 'configuration.json'];
    for (final fileName in configFileNames) {
      if (files.containsKey(fileName)) {
        return files[fileName]['content'] as String?;
      }
    }
    
    // 如果没有找到特定的配置文件，使用第一个 .json 文件
    for (final entry in files.entries) {
      final fileName = entry.key;
      if (fileName.endsWith('.json')) {
        return entry.value['content'] as String?;
      }
    }
    
    return null;
  }

  /// 获取缓存的配置（智能缓存策略）
  Future<T?> _getCachedConfig(bool isAppInForeground) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedConfigJson = prefs.getString(_cacheKey);
      final cacheTime = prefs.getInt(_cacheTimeKey);
      
      if (cachedConfigJson != null && cacheTime != null) {
        final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final now = DateTime.now();
        final timeSinceCache = now.difference(cacheDateTime);
        
        // 根据应用状态使用不同缓存策略
        final cacheExpiry = isAppInForeground 
            ? options.shortCacheExpiry 
            : options.longCacheExpiry;
        
        // 检查缓存是否过期
        if (timeSinceCache < cacheExpiry) {
          final configJson = json.decode(cachedConfigJson) as Map<String, dynamic>;
          return configFactory(configJson);
        }
      }
    } catch (e) {
      if (options.enableDebugLogs) {
        print('⚠️ 读取缓存配置失败: $e');
      }
    }
    
    return null;
  }

  /// 获取任何缓存配置（忽略过期时间）
  Future<T?> _getAnyCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedConfigJson = prefs.getString(_cacheKey);
      
      if (cachedConfigJson != null) {
        final configJson = json.decode(cachedConfigJson) as Map<String, dynamic>;
        return configFactory(configJson);
      }
    } catch (e) {
      if (options.enableDebugLogs) {
        print('⚠️ 读取任意缓存配置失败: $e');
      }
    }
    
    return null;
  }

  /// 缓存配置到本地（包含版本和ETag信息）
  Future<void> _cacheConfig(T config, String? etag) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(config.toJson());
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(_cacheKey, configJson);
      await prefs.setInt(_cacheTimeKey, currentTime);
      
      // 缓存版本号和ETag
      if (config.version != null) {
        await prefs.setString(_versionKey, config.version!);
      }
      if (etag != null) {
        await prefs.setString(_etagKey, etag);
      }
      
      // 更新最后检查时间
      await _updateLastCheckTime();
      
      if (options.enableDebugLogs) {
        print('💾 配置已缓存: version=${config.version}');
      }
    } catch (e) {
      if (options.enableDebugLogs) {
        print('❌ 缓存配置失败: $e');
      }
    }
  }

  /// 清除所有缓存（用于强制刷新配置）
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
      await prefs.remove(_etagKey);
      await prefs.remove(_versionKey);
      await prefs.remove(_lastCheckKey);
      if (options.enableDebugLogs) {
        print('🗑️ 所有配置缓存已清除');
      }
    } catch (e) {
      if (options.enableDebugLogs) {
        print('❌ 清除缓存失败: $e');
      }
    }
  }

  /// 处理获取配置失败的情况
  Future<T> _handleFetchError() async {
    // 尝试获取过期的缓存作为备用
    final expiredCachedConfig = await _getAnyCachedConfig();
    if (expiredCachedConfig != null) {
      if (options.enableDebugLogs) {
        print('🔄 使用过期缓存配置作为备用');
      }
      return expiredCachedConfig;
    }
    
    // 如果没有缓存，抛出异常让上层处理
    throw Exception('无法获取配置且没有可用的缓存');
  }

  /// 更新最后检查时间
  Future<void> _updateLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastCheckKey, currentTime);
    } catch (e) {
      if (options.enableDebugLogs) {
        print('⚠️ 更新检查时间失败: $e');
      }
    }
  }

  /// 获取缓存的版本号
  Future<String?> _getCachedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_versionKey);
    } catch (e) {
      if (options.enableDebugLogs) {
        print('⚠️ 获取缓存版本失败: $e');
      }
      return null;
    }
  }

  /// 验证配置的基本有效性
  bool _isValidConfig(Map<String, dynamic> config) {
    // 基本验证：确保是有效的JSON对象
    if (config.isEmpty) {
      if (options.enableDebugLogs) {
        print('⚠️ 配置不能为空');
      }
      return false;
    }
    
    // 如果有版本号，确保是字符串类型
    if (config.containsKey('version')) {
      final version = config['version'];
      if (version is! String) {
        if (options.enableDebugLogs) {
          print('⚠️ 版本号必须是字符串类型');
        }
        return false;
      }
    }
    
    return true;
  }
}
