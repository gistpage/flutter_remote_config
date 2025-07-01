import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_remote_config/src/core/config_event_manager.dart';
import 'package:flutter_remote_config/src/core/config_cache_manager.dart';
import 'package:flutter_remote_config/src/core/lifecycle_aware_manager.dart';
import 'package:flutter/widgets.dart';

class DummyConfig extends Object {}

// 移到main外部
class TestManager extends LifecycleAwareManager {
  final void Function() onResumed;
  final void Function() onPaused;
  final void Function() onDetached;
  TestManager(this.onResumed, this.onPaused, this.onDetached);
  @override
  void onAppResumed() => onResumed();
  @override
  void onAppPaused() => onPaused();
  @override
  void onAppDetached() => onDetached();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('v0.1.0 优化验证', () {
    test('统一事件管理器基本功能', () {
      final manager = ConfigEventManager.instance;
      expect(manager, isNotNull);
      final manager2 = ConfigEventManager.instance;
      expect(identical(manager, manager2), isTrue);
    });

    test('缓存管理器批量操作', () async {
      final cacheManager = ConfigCacheManager(keyPrefix: 'test');
      await cacheManager.saveCacheData(
        etag: 'test-etag',
        version: '1.0',
        configJson: '{"test": true}',
      );
      final cacheData = await cacheManager.loadCacheData();
      expect(cacheData.etag, 'test-etag');
      expect(cacheData.version, '1.0');
      expect(cacheData.hasValidCache, isTrue);
      await cacheManager.clearCache();
    }, skip: '依赖shared_preferences原生插件，需在集成测试环境下运行');

    test('生命周期基类可用', () {
      bool resumed = false;
      bool paused = false;
      bool detached = false;
      final m = TestManager(() => resumed = true, () => paused = true, () => detached = true);
      m.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(resumed, isTrue);
      m.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(paused, isTrue);
      m.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(detached, isTrue);
    });
  });
} 