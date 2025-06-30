import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_remote_config/flutter_remote_config.dart';

void main() {
  group('RemoteConfigOptions', () {
    test('creates options with required parameters', () {
      final options = RemoteConfigOptions(
        gistId: 'test-gist-id',
        githubToken: 'test-token',
      );
      
      expect(options.gistId, 'test-gist-id');
      expect(options.githubToken, 'test-token');
      expect(options.configFileName, 'config.json');
      expect(options.enableDebugLogs, false);
    });

    test('creates options from environment', () {
      final options = RemoteConfigOptions.fromEnvironment(
        fallbackGistId: 'fallback-gist',
        fallbackToken: 'fallback-token',
      );
      
      expect(options.gistId, 'fallback-gist');
      expect(options.githubToken, 'fallback-token');
    });

    test('copyWith creates new instance with updated values', () {
      final original = RemoteConfigOptions(
        gistId: 'original-gist',
        githubToken: 'original-token',
      );
      
      final copied = original.copyWith(
        gistId: 'new-gist',
        enableDebugLogs: true,
      );
      
      expect(copied.gistId, 'new-gist');
      expect(copied.githubToken, 'original-token');
      expect(copied.enableDebugLogs, true);
    });
  });

  group('BasicRemoteConfig', () {
    test('creates config from JSON', () {
      final json = {
        'version': '2',
        'isRedirectEnabled': true,
        'redirectUrl': 'https://example.com',
      };
      
      final config = BasicRemoteConfig.fromJson(json);
      
      expect(config.version, '2');
      expect(config.getValue('isRedirectEnabled', false), true);
      expect(config.getValue('redirectUrl', ''), 'https://example.com');
    });

    test('gets configuration values correctly', () {
      final config = BasicRemoteConfig(
        version: '2',
        data: {
          'version': '2',
          'isRedirectEnabled': true,
          'redirectUrl': 'https://example.com/redirect',
        },
      );
      
      expect(config.getValue('version', ''), '2');
      expect(config.getValue('isRedirectEnabled', false), true);
      expect(config.getValue('redirectUrl', ''), 'https://example.com/redirect');
      expect(config.getValue('nonexistent', 'default'), 'default');
    });

    test('checks if key exists', () {
      final config = BasicRemoteConfig(
        data: {
          'version': '1',
          'isRedirectEnabled': false,
          'redirectUrl': '',
        },
      );
      
      expect(config.hasKey('version'), true);
      expect(config.hasKey('isRedirectEnabled'), true);
      expect(config.hasKey('redirectUrl'), true);
      expect(config.hasKey('nonexistent'), false);
    });

    test('equality works correctly', () {
      final config1 = BasicRemoteConfig(
        version: '1',
        data: {
          'version': '1',
          'isRedirectEnabled': false,
          'redirectUrl': '',
        },
      );
      
      final config2 = BasicRemoteConfig(
        version: '1',
        data: {
          'version': '1',
          'isRedirectEnabled': false,
          'redirectUrl': '',
        },
      );
      
      final config3 = BasicRemoteConfig(
        version: '2',
        data: {
          'version': '2',
          'isRedirectEnabled': true,
          'redirectUrl': 'https://example.com',
        },
      );
      
      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('copyWith creates new instance', () {
      final original = BasicRemoteConfig(
        version: '1',
        data: {
          'version': '1',
          'isRedirectEnabled': false,
          'redirectUrl': '',
        },
      );
      
      final copied = original.copyWith(
        version: '2',
      );
      
      expect(copied.version, '2');
      expect(copied.data['version'], '1'); // Data unchanged
      expect(original.version, '1'); // Original unchanged
    });
  });
}
