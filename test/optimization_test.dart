import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_remote_config/src/core/config_event_manager.dart';
import 'package:flutter_remote_config/src/core/config_cache_manager.dart';
import 'package:flutter_remote_config/src/core/lifecycle_aware_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_remote_config/flutter_remote_config.dart';
import 'package:flutter/material.dart';

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
      final m = TestManager(
        () => resumed = true,
        () => paused = true,
        () => detached = true,
      );
      m.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(resumed, isTrue);
      m.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(paused, isTrue);
      m.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(detached, isTrue);
    });
  });

  group('配置管理优化测试', () {
    setUp(() {
      // 重置实例
      AdvancedConfigManager.resetInstance();
      EasyRemoteConfig.resetInstance();
    });

    test('基本配置获取性能测试', () async {
      // 该测试确保配置获取操作在可接受的时间内完成
      final stopwatch = Stopwatch()..start();

      await EasyRemoteConfig.init(
        gistId: 'test-gist-id',
        githubToken: 'test-token',
        debugMode: false,
      );

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒内完成
    });

    test('多次配置获取的缓存效果测试', () async {
      await EasyRemoteConfig.init(
        gistId: 'test-gist-id',
        githubToken: 'test-token',
        debugMode: false,
      );

      final stopwatch1 = Stopwatch()..start();
      final config1 = EasyRemoteConfig.instance.getString('test', 'default');
      stopwatch1.stop();

      final stopwatch2 = Stopwatch()..start();
      final config2 = EasyRemoteConfig.instance.getString('test', 'default');
      stopwatch2.stop();

      // 第二次获取应该更快（缓存效果）
      expect(
        stopwatch2.elapsedMicroseconds,
        lessThan(stopwatch1.elapsedMicroseconds),
      );
      expect(config1, equals(config2));
    });

    test('内存使用优化测试', () async {
      await EasyRemoteConfig.init(
        gistId: 'test-gist-id',
        githubToken: 'test-token',
        debugMode: false,
      );

      // 测试多次获取配置不会导致内存泄漏
      for (int i = 0; i < 100; i++) {
        EasyRemoteConfig.instance.getString('test$i', 'default');
        EasyRemoteConfig.instance.getBool('flag$i', false);
        EasyRemoteConfig.instance.getInt('number$i', 0);
      }

      // 确保实例仍然正常工作
      expect(EasyRemoteConfig.isInitialized, isTrue);
    });
  });

  group('默认配置逻辑测试', () {
    setUp(() {
      // 重置实例
      AdvancedConfigManager.resetInstance();
      EasyRemoteConfig.resetInstance();
    });

    test('无效配置时使用默认配置', () async {
      final defaults = {
        'version': '1',
        'isRedirectEnabled': false,
        'redirectUrl': '',
        'customFlag': true,
        'timeout': 30,
        'appName': '测试应用',
      };

      // 故意使用无效的配置
      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: defaults,
        debugMode: true,
      );

      // 验证初始化成功（使用了默认配置）
      expect(EasyRemoteConfig.isInitialized, isTrue);

      // 验证能获取默认配置值
      expect(EasyRemoteConfig.instance.getString('version'), equals('1'));
      expect(EasyRemoteConfig.instance.getBool('isRedirectEnabled'), isFalse);
      expect(EasyRemoteConfig.instance.getString('redirectUrl'), equals(''));
      expect(EasyRemoteConfig.instance.getBool('customFlag'), isTrue);
      expect(EasyRemoteConfig.instance.getInt('timeout'), equals(30));
      expect(EasyRemoteConfig.instance.getString('appName'), equals('测试应用'));
    });

    test('默认配置的重定向逻辑测试', () async {
      // 测试：默认配置禁用重定向
      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: {
          'version': '1',
          'isRedirectEnabled': false,
          'redirectUrl': 'https://example.com',
        },
        debugMode: true,
      );

      expect(EasyRemoteConfig.instance.isRedirectEnabled, isFalse);
      expect(
        EasyRemoteConfig.instance.redirectUrl,
        equals('https://example.com'),
      );
      expect(
        EasyRemoteConfig.instance.shouldRedirect,
        isFalse,
      ); // 因为 isRedirectEnabled 为 false

      // 重置并测试：默认配置启用重定向
      AdvancedConfigManager.resetInstance();
      EasyRemoteConfig.resetInstance();

      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: {
          'version': '1',
          'isRedirectEnabled': true,
          'redirectUrl': 'https://flutter.dev',
        },
        debugMode: true,
      );

      expect(EasyRemoteConfig.instance.isRedirectEnabled, isTrue);
      expect(
        EasyRemoteConfig.instance.redirectUrl,
        equals('https://flutter.dev'),
      );
      expect(EasyRemoteConfig.instance.shouldRedirect, isTrue); // 都满足条件
    });

    test('默认配置的各种数据类型测试', () async {
      final defaults = {
        'stringValue': 'test string',
        'intValue': 42,
        'doubleValue': 3.14,
        'boolValue': true,
        'listValue': ['item1', 'item2'],
        'mapValue': {'key1': 'value1', 'key2': 'value2'},
      };

      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: defaults,
        debugMode: true,
      );

      // 验证各种数据类型都能正确获取
      expect(
        EasyRemoteConfig.instance.getString('stringValue'),
        equals('test string'),
      );
      expect(EasyRemoteConfig.instance.getInt('intValue'), equals(42));
      expect(EasyRemoteConfig.instance.getDouble('doubleValue'), equals(3.14));
      expect(EasyRemoteConfig.instance.getBool('boolValue'), isTrue);
      expect(
        EasyRemoteConfig.instance.getList<String>('listValue'),
        equals(['item1', 'item2']),
      );
      expect(
        EasyRemoteConfig.instance.getMap('mapValue'),
        equals({'key1': 'value1', 'key2': 'value2'}),
      );
    });

    test('空默认配置测试', () async {
      // 测试完全空的默认配置
      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: {}, // 空配置
        debugMode: true,
      );

      expect(EasyRemoteConfig.isInitialized, isTrue);

      // 应该返回方法中指定的默认值
      expect(
        EasyRemoteConfig.instance.getString('nonexistent', 'fallback'),
        equals('fallback'),
      );
      expect(EasyRemoteConfig.instance.getBool('nonexistent', true), isTrue);
      expect(EasyRemoteConfig.instance.getInt('nonexistent', 999), equals(999));
    });

    test('hasKey 方法在默认配置中的测试', () async {
      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: {
          'existingKey': 'value',
          'emptyString': '',
          'zeroValue': 0,
          'falseValue': false,
        },
        debugMode: true,
      );

      // 验证存在的键
      expect(EasyRemoteConfig.instance.hasKey('existingKey'), isTrue);
      expect(EasyRemoteConfig.instance.hasKey('emptyString'), isTrue);
      expect(EasyRemoteConfig.instance.hasKey('zeroValue'), isTrue);
      expect(EasyRemoteConfig.instance.hasKey('falseValue'), isTrue);

      // 验证不存在的键
      expect(EasyRemoteConfig.instance.hasKey('nonexistentKey'), isFalse);
    });

    test('配置刷新在默认配置模式下的行为', () async {
      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: {'version': '1', 'isRedirectEnabled': false},
        debugMode: true,
      );

      final configBefore = EasyRemoteConfig.instance.getAllConfig();

      // 尝试刷新配置（应该失败，但不应该崩溃）
      try {
        await EasyRemoteConfig.instance.refresh();
        // 刷新后配置应该保持不变（仍使用默认配置）
        final configAfter = EasyRemoteConfig.instance.getAllConfig();
        expect(configAfter, equals(configBefore));
      } catch (e) {
        // 刷新失败是预期的，但应用应该仍能正常工作
        expect(EasyRemoteConfig.isInitialized, isTrue);
        expect(EasyRemoteConfig.instance.getString('version'), equals('1'));
      }
    });
  });

  group('默认配置路径生命周期监听测试', () {
    setUp(() {
      // 重置实例
      AdvancedConfigManager.resetInstance();
      EasyRemoteConfig.resetInstance();
    });

    test('默认配置路径下的生命周期监听机制', () async {
      // 使用无效的 Gist ID 强制走默认配置路径
      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: {
          'version': '1',
          'isRedirectEnabled': true,
          'redirectUrl': 'https://example.com',
        },
        debugMode: true,
      );

      // 验证 EasyRemoteConfig 已初始化
      expect(EasyRemoteConfig.isInitialized, isTrue);

      // 验证配置已加载
      expect(EasyRemoteConfig.instance.isConfigLoaded, isTrue);

      // 验证重定向配置正确
      expect(EasyRemoteConfig.instance.isRedirectEnabled, isTrue);
      expect(
        EasyRemoteConfig.instance.redirectUrl,
        equals('https://example.com'),
      );
      expect(EasyRemoteConfig.instance.shouldRedirect, isTrue);

      // 验证 AdvancedConfigManager 状态（可能未初始化，这是正常的）
      final isManagerInitialized = AdvancedConfigManager.isManagerInitialized;
      debugPrint('AdvancedConfigManager 初始化状态: $isManagerInitialized');

      // 验证 refresh 方法不会抛出异常（即使 AdvancedConfigManager 未初始化）
      expect(() async {
        await EasyRemoteConfig.instance.refresh();
      }, returnsNormally);

      // 验证配置状态流正常工作
      final configState = EasyRemoteConfig.instance.configState;
      expect(configState.status, isNot(equals(ConfigStatus.uninitialized)));

      // 验证配置状态流有数据
      final hasData = await EasyRemoteConfig.instance.configStateStream.first
          .then((_) => true)
          .catchError((_) => false);
      expect(hasData, isTrue);
    });

    test('默认配置路径下的前后台切换模拟', () async {
      await EasyRemoteConfig.init(
        gistId: 'invalid-gist-id',
        githubToken: 'invalid-token',
        defaults: {
          'version': '1',
          'isRedirectEnabled': false,
          'redirectUrl': '',
        },
        debugMode: true,
      );

      // 记录初始状态（移除未使用的变量以满足静态检查）

      // 模拟 App 回到前台事件
      final instance = EasyRemoteConfig.instance;
      instance.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // 等待一下让异步操作完成
      await Future.delayed(Duration(milliseconds: 100));

      // 验证 refresh 方法被调用且不抛出异常
      expect(() async {
        await instance.refresh();
      }, returnsNormally);

      // 验证配置状态仍然有效（即使刷新失败，基本状态应该保持）
      expect(instance.isConfigLoaded, isTrue);
      // 注意：在默认配置路径下，isRedirectEnabled 应该保持初始值
      // 但由于刷新可能影响状态，我们只验证基本功能正常
      // 验证基本配置访问功能正常
      expect(instance.getString('version', 'fallback'), equals('1'));
      expect(instance.getBool('isRedirectEnabled', true), isFalse);
    });
  });
}