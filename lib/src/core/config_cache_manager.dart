import 'package:shared_preferences/shared_preferences.dart';

class ConfigCacheData {
  final String? etag;
  final int? cacheTime;
  final String? version;
  final String? configJson;
  final int? lastCheckTime;
  
  const ConfigCacheData({
    this.etag,
    this.cacheTime,
    this.version,
    this.configJson,
    this.lastCheckTime,
  });
  
  bool get hasValidCache => configJson != null && cacheTime != null;
  
  DateTime? get cacheDateTime => cacheTime != null 
      ? DateTime.fromMillisecondsSinceEpoch(cacheTime!) 
      : null;
}

/// 📦 批量缓存管理器 - 减少SharedPreferences访问次数
class ConfigCacheManager {
  final String keyPrefix;
  
  late final String _cacheKey;
  late final String _cacheTimeKey;
  late final String _etagKey;
  late final String _versionKey;
  late final String _lastCheckKey;
  
  ConfigCacheManager({required this.keyPrefix}) {
    _cacheKey = '${keyPrefix}_cache';
    _cacheTimeKey = '${keyPrefix}_cache_time';
    _etagKey = '${keyPrefix}_etag';
    _versionKey = '${keyPrefix}_version';
    _lastCheckKey = '${keyPrefix}_last_check';
  }
  
  /// 🔥 批量读取所有缓存数据
  Future<ConfigCacheData> loadCacheData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return ConfigCacheData(
      etag: prefs.getString(_etagKey),
      cacheTime: prefs.getInt(_cacheTimeKey),
      version: prefs.getString(_versionKey),
      configJson: prefs.getString(_cacheKey),
      lastCheckTime: prefs.getInt(_lastCheckKey),
    );
  }
  
  /// 🔥 批量保存缓存数据
  Future<void> saveCacheData({
    String? etag,
    String? configJson,
    String? version,
    int? cacheTime,
    int? lastCheckTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 并发执行所有写入操作
    final futures = <Future<bool>>[];
    
    if (etag != null) futures.add(prefs.setString(_etagKey, etag));
    if (configJson != null) futures.add(prefs.setString(_cacheKey, configJson));
    if (version != null) futures.add(prefs.setString(_versionKey, version));
    futures.add(prefs.setInt(_cacheTimeKey, cacheTime ?? now));
    futures.add(prefs.setInt(_lastCheckKey, lastCheckTime ?? now));
    
    await Future.wait(futures);
  }
  
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.remove(_cacheKey),
      prefs.remove(_cacheTimeKey),
      prefs.remove(_etagKey),
      prefs.remove(_versionKey),
      prefs.remove(_lastCheckKey),
    ]);
  }
} 