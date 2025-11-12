import 'package:flutter/material.dart';
import 'package:flutter_remote_config/flutter_remote_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyRemoteConfig.init(
    gistId: 'TODO',
    githubToken: 'TODO',
    debugMode: true,
    defaults: {
      'version': '1',
      'isRedirectEnabled': false,
      'redirectUrl': 'https://example.com',
      'allowCountries': <String>[],
      'isCountryCheckEnabled': false,
      'isTimezoneCheckEnabled': false,
      'isIpAttributionCheckEnabled': false,
      'extra': <String, dynamic>{},
      'welcomeMessage': '欢迎使用默认配置！',
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_remote_config 示例',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const EntryPage(),
    );
  }
}

class EntryPage extends StatelessWidget {
  const EntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ImprovedRedirectWidgets.smartRedirect(
      homeWidget: const HomePage(),
      loadingWidget: const LoadingPage(),
      enableDebugLogs: true,
      timeout: const Duration(seconds: 3),
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('加载中')),
      body: const Center(child: AppLoadingWidget(style: LoadingStyle.modern)),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _deviceCountryCode = '';
  String _deviceTimezone = '';
  String _ip = '';
  String _ipCountryCode = '';
  String _ipCountryName = '';
  bool _tzBelongsToDeviceCountry = false;
  bool _tzBelongsToAllowCountries = false;
  List<String> _configAllowCountries = const [];

  static const Map<String, List<int>> _countryOffsetMinutesMap = {
    'US': [-600, -540, -480, -420, -360, -300, -240],
    'BR': [-240, -180, -120],
    'CN': [480],
    'GB': [0, 60],
    'IN': [330],
    'JP': [540],
    'KR': [540],
    'AU': [480, 570, 600, 630, 660],
  };
  static const Map<String, List<int>> _countryOffsetHoursMap = {
    'US': [-10, -9, -8, -7, -6, -5, -4],
    'BR': [-5, -4, -3, -2],
    'CN': [8],
    'GB': [0, 1],
    'IN': [5, 6],
    'JP': [9],
    'KR': [9],
    'AU': [8, 9, 10, 11],
  };

  @override
  void initState() {
    super.initState();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _deviceCountryCode = locale.countryCode ?? '';
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.inMinutes >= 0 ? '+' : '-';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    _deviceTimezone = 'UTC$sign$hours:$minutes';
    final om = offset.inMinutes;
    final code = _deviceCountryCode.toUpperCase();
    final m = _countryOffsetMinutesMap[code];
    final h = _countryOffsetHoursMap[code];
    _tzBelongsToDeviceCountry =
        (m != null && m.contains(om)) || (h != null && h.contains(om ~/ 60));
    _recalcTimezoneMembership();
    _loadNetworkInfo();
  }

  void _recalcTimezoneMembership() {
    final om = DateTime.now().timeZoneOffset.inMinutes;
    final allowed = EasyRemoteConfig.instance.getList<String>(
      'allowCountries',
      const [],
    );
    _configAllowCountries = allowed.map((e) => e.toUpperCase()).toList();
    var ok = false;
    for (final code in _configAllowCountries) {
      final m = _countryOffsetMinutesMap[code];
      if (m != null && m.contains(om)) {
        ok = true;
        break;
      }
      final h = _countryOffsetHoursMap[code];
      if (h != null && h.contains(om ~/ 60)) {
        ok = true;
        break;
      }
    }
    _tzBelongsToAllowCountries = ok;
  }

  Future<void> _loadNetworkInfo() async {
    try {
      final resp = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _ip = (data['ip'] as String?) ?? '';
          _ipCountryCode = ((data['country_code'] as String?) ?? '')
              .toUpperCase();
          _ipCountryName = (data['country_name'] as String?) ?? '';
        });
        return;
      }
    } catch (_) {}
    try {
      final resp = await http
          .get(Uri.parse('https://ipinfo.io/json'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _ip = (data['ip'] as String?) ?? '';
          _ipCountryCode = ((data['country'] as String?) ?? '').toUpperCase();
          _ipCountryName = '';
        });
        return;
      }
    } catch (_) {}
    try {
      final resp = await http
          .get(Uri.parse('https://api.ip.sb/geoip'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _ip = (data['ip'] as String?) ?? '';
          _ipCountryCode = ((data['country_code'] as String?) ?? '')
              .toUpperCase();
          _ipCountryName = (data['country'] as String?) ?? '';
        });
        return;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final message = EasyRemoteConfig.instance.getString('welcomeMessage');
    final isEnabled = EasyRemoteConfig.instance.isRedirectEnabled;
    final redirect = EasyRemoteConfig.instance.redirectUrl;
    final version = EasyRemoteConfig.instance.configVersion;
    final isCountry = EasyRemoteConfig.instance.isCountryCheckEnabled;
    final isTimezone = EasyRemoteConfig.instance.isTimezoneCheckEnabled;
    final isIpAttr = EasyRemoteConfig.instance.isIpAttributionCheckEnabled;
    return Scaffold(
      appBar: AppBar(title: const Text('示例主页')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.isNotEmpty ? message : '测试成功！'),
            const SizedBox(height: 16),
            Text(
              '当前设备',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '设备国家码: ${_deviceCountryCode.isEmpty ? '-' : _deviceCountryCode}',
            ),
            const SizedBox(height: 6),
            Text('设备时区: ${_deviceTimezone.isEmpty ? '-' : _deviceTimezone}'),
            const SizedBox(height: 6),
            Text('时区是否属于设备国家码: ${_tzBelongsToDeviceCountry ? '是' : '否'}'),
            const SizedBox(height: 6),
            Text('设备 IP: ${_ip.isEmpty ? '-' : _ip}'),
            const SizedBox(height: 6),
            Text(
              '设备 IP 归属: ${_ipCountryCode.isEmpty ? '-' : _ipCountryCode}${_ipCountryName.isEmpty ? '' : ' ($_ipCountryName)'}',
            ),
            const SizedBox(height: 20),
            Text(
              '远程配置',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('配置版本: $version'),
            const SizedBox(height: 6),
            Text('是否启用跳转: ${isEnabled ? '是' : '否'}'),
            const SizedBox(height: 6),
            Text('跳转地址: ${redirect.isEmpty ? '-' : redirect}'),
            const SizedBox(height: 6),
            Text(
              'allowCountries: ${_configAllowCountries.isEmpty ? '-' : _configAllowCountries.join(', ')}',
            ),
            const SizedBox(height: 6),
            Text('国家校验: ${isCountry ? '开启' : '关闭'}'),
            const SizedBox(height: 6),
            Text('时区校验: ${isTimezone ? '开启' : '关闭'}'),
            const SizedBox(height: 6),
            Text('IP归属校验: ${isIpAttr ? '开启' : '关闭'}'),
            const SizedBox(height: 6),
            Text(
              '时区是否属于 allowCountries: ${_tzBelongsToAllowCountries ? '是' : '否'}',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await EasyRemoteConfig.instance.refresh();
                setState(() {
                  _recalcTimezoneMembership();
                });
              },
              child: const Text('刷新远程配置'),
            ),
          ],
        ),
      ),
    );
  }
}
