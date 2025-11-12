import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_remote_config/flutter_remote_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AdvancedConfigManager.resetInstance();
    EasyRemoteConfig.resetInstance();
  });

  test('当启用校验但allowCountries为空时不重定向', () async {
    await EasyRemoteConfig.init(
      gistId: 'invalid',
      githubToken: 'invalid',
      defaults: {
        'version': '4',
        'isRedirectEnabled': true,
        'redirectUrl': 'https://example.com',
        'allowCountries': [],
        'isCountryCheckEnabled': true,
        'isTimezoneCheckEnabled': false,
        'isIpAttributionCheckEnabled': false,
      },
      debugMode: false,
    );

    final result = await EasyRemoteConfig.instance.gatedShouldRedirect();
    expect(result, isFalse);
  });

  test('未启用任何校验时直接重定向', () async {
    await EasyRemoteConfig.init(
      gistId: 'invalid',
      githubToken: 'invalid',
      defaults: {
        'version': '4',
        'isRedirectEnabled': true,
        'redirectUrl': 'https://example.com',
        'allowCountries': ['US', 'BR'],
        'isCountryCheckEnabled': false,
        'isTimezoneCheckEnabled': false,
        'isIpAttributionCheckEnabled': false,
      },
      debugMode: false,
    );

    final result = await EasyRemoteConfig.instance.gatedShouldRedirect();
    expect(result, isTrue);
  });
}
