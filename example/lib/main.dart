import 'package:flutter/material.dart';
import 'package:flutter_remote_config/flutter_remote_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 超简单初始化 - 一行代码搞定！
  await EasyRemoteConfig.init(
    gistId: 'fa5c67b67b8f1b3c3aa7fa11d6a9f607', // 替换为你的Gist ID
    githubToken: 'github_pat_11BUBMXYY0dIiHaT9CeLrU_...', // 替换为你的GitHub Token
    defaults: ConfigTemplates.defaultRedirectConfig, // 使用默认重定向配置
    debugMode: true, // 开发时启用调试
  );
  
  // 🔧 启用调试工具（可选）
  if (EasyRemoteConfig.instance.getBool('debug.enableDebugHelper', true)) {
    RemoteConfigDebugHelper.enableDebug(enableHealthCheck: true);
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Remote Config Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 🌐 方式1：使用最简单的重定向组件（推荐）
      home: EasyRedirectWidgets.simpleRedirect(
        homeWidget: MyHomePage(),
        loadingWidget: LoadingScreen(),
      ),
      
      // 或者使用调试面板（开发环境）
      // home: ConfigDebugPanel(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remote Config Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigDebugPanel(),
                ),
              );
            },
            tooltip: '调试面板',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 展示不同的使用方式
            _buildBasicUsageCard(),
            SizedBox(height: 16),
            _buildRedirectInfoCard(),
            SizedBox(height: 16),
            _buildConfigBuilderExample(),
            SizedBox(height: 16),
            _buildConfigInfoCard(),
            SizedBox(height: 16),
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicUsageCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚀 基础用法演示',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow('重定向状态', EasyRemoteConfig.instance.isRedirectEnabled ? '启用' : '禁用'),
            _buildInfoRow('重定向URL', EasyRemoteConfig.instance.redirectUrl.isEmpty 
              ? '未设置' : EasyRemoteConfig.instance.redirectUrl),
            _buildInfoRow('配置版本', EasyRemoteConfig.instance.configVersion),
            _buildInfoRow('是否应该重定向', EasyRemoteConfig.instance.shouldRedirect ? '是' : '否'),
          ],
        ),
      ),
    );
  }

  Widget _buildRedirectInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌐 重定向信息（一次性获取）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Builder(
              builder: (context) {
                final redirectInfo = EasyRemoteConfig.instance.redirectInfo;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('状态', redirectInfo.isEnabled ? '启用' : '禁用'),
                    _buildInfoRow('URL', redirectInfo.url.isEmpty ? '未设置' : redirectInfo.url),
                    _buildInfoRow('版本', redirectInfo.version),
                    _buildInfoRow('应该重定向', redirectInfo.shouldRedirect ? '是' : '否'),
                    SizedBox(height: 8),
                    Text('完整信息: ${redirectInfo.toString()}', 
                         style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigBuilderExample() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎨 ConfigBuilder 演示',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('以下内容会根据配置变化自动更新：'),
            SizedBox(height: 8),
            
            // 演示重定向状态监听
            ConfigBuilder<bool>(
              configKey: 'isRedirectEnabled',
              defaultValue: false,
              builder: (isRedirectEnabled) {
                return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRedirectEnabled ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isRedirectEnabled ? Icons.warning : Icons.check_circle,
                        color: isRedirectEnabled ? Colors.red : Colors.green,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '重定向状态: ${isRedirectEnabled ? '启用' : '禁用'}',
                      ),
                    ],
                  ),
                );
              },
            ),
            
            SizedBox(height: 8),
            
            // 演示配置版本监听
            ConfigBuilder<String>(
              configKey: 'version',
              defaultValue: '1',
              builder: (version) {
                return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '配置版本: $version',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 配置信息演示',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow('配置版本', EasyRemoteConfig.instance.configVersion),
            _buildInfoRow('重定向状态', EasyRemoteConfig.instance.isRedirectEnabled ? '启用' : '禁用'),
            _buildInfoRow('重定向URL', EasyRemoteConfig.instance.redirectUrl.isNotEmpty ? EasyRemoteConfig.instance.redirectUrl : '未设置'),
            _buildInfoRow('需要重定向', EasyRemoteConfig.instance.shouldRedirect ? '是' : '否'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ 操作演示',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await EasyRemoteConfig.instance.refresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('配置已刷新')),
                    );
                  },
                  child: Text('刷新配置'),
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('所有配置'),
                        content: SingleChildScrollView(
                          child: Text(
                            EasyRemoteConfig.instance.getAllConfig().toString(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('关闭'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('查看所有配置'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 演示手动重定向检查
                    if (EasyRemoteConfig.instance.shouldRedirect) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('应该重定向到: ${EasyRemoteConfig.instance.redirectUrl}'),
                          action: SnackBarAction(
                            label: '执行重定向',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebViewDemo(
                                    url: EasyRemoteConfig.instance.redirectUrl,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('当前不需要重定向')),
                      );
                    }
                  },
                  child: Text('检查重定向'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载配置...'),
          ],
        ),
      ),
    );
  }
}

class WebViewDemo extends StatelessWidget {
  final String url;

  const WebViewDemo({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('重定向演示'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              '这里应该显示网页内容',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('URL: $url'),
            SizedBox(height: 16),
            Text(
              '请安装 webview_flutter 插件来显示实际网页',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
} 