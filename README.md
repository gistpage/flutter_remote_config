<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# 🚀 Flutter Remote Config

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Platform-Flutter-blue.svg)](https://flutter.dev)
[![GitHub](https://img.shields.io/badge/Source-GitHub-black.svg)](https://github.com)

一个**超简单**的 Flutter 远程配置和重定向控制包，通过 GitHub Gist 远程控制应用行为。

> **🚀 30秒快速集成**，一行代码实现远程重定向控制！**✅ 已通过真机测试验证**

## 🎯 这个包能帮你做什么

**核心功能**：根据 GitHub Gist 中的配置，决定应用是否跳转到指定地址

**典型场景**：
- ✅ **App强制更新**：跳转到App Store更新页面
- ✅ **维护通知**：跳转到维护说明页面  
- ✅ **紧急公告**：跳转到重要通知页面
- ✅ **活动推广**：跳转到活动页面
- ✅ **灰度发布**：控制新功能的开关
- ✅ **A/B测试**：动态切换不同的配置方案

**为什么选择这个包**：
- 🔥 **集成简单**：1行代码完成初始化
- 🌐 **免费稳定**：基于GitHub Gist，全球CDN加速
- ⚡ **几乎零流量**：智能缓存，网络优化
- 📱 **自动更新**：应用切换时检查最新配置
- 🎯 **即插即用**：内置WebView，无需额外配置
- ✅ **生产就绪**：已通过真机测试验证

## 📦 安装

### 1. 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # 网络请求依赖
  shared_preferences: ^2.2.0  # 缓存依赖
  flutter_remote_config:
    git:
      url: https://github.com/gistpage/flutter_remote_config.git
      ref: main
```

### 2. 安装包

```bash
flutter pub get
```

### 3. iOS 配置（重要）

**WebView 加载问题解决方案**：

如果在 iOS 上遇到 WebView 一直加载或无法访问网络的问题，请在 `ios/Runner/Info.plist` 中添加以下配置：

```xml
<!-- WebView 网络安全配置 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>

<!-- WebView 嵌入视图支持 -->
<key>io.flutter.embedded_views_preview</key>
<true/>

<!-- 网络使用描述 -->
<key>NSLocalNetworkUsageDescription</key>
<string>此应用需要访问网络以加载远程配置和重定向页面</string>
```

### 4. Android 配置

在 `android/app/src/main/AndroidManifest.xml` 中确保有网络权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 5. 添加导入

在需要使用的 Dart 文件中添加导入：

```dart
import 'package:flutter_remote_config/flutter_remote_config.dart';
```

## 🚀 快速开始（3分钟完成）

**⚠️ 注意事项：**

> **本包仅支持自动重定向。**
> 
> **强烈建议**仅在主页面（如 `homeWidget`）或需要重定向的业务入口页面调用自动重定向组件（如 `EasyRedirectWidgets.simpleRedirect`）。
> 
> **不要在所有页面都全局调用**，否则可能导致页面跳转混乱或用户体验异常。
> 
> 如需在特定页面才允许重定向，请只在该页面调用自动重定向组件。

### 步骤1：创建 GitHub Gist 配置

1. 访问 [GitHub Gist](https://gist.github.com)
2. 创建新 Gist，文件名：`config.json`
3. 复制粘贴配置内容：

```json
{
  "version": "1",
  "isRedirectEnabled": true,
  "redirectUrl": "https://flutter.dev"
}
```

4. 点击 "Create public gist"
5. **复制 Gist ID**（地址栏中的ID）：
   ```
   https://gist.github.com/username/abc123def456  ← abc123def456 就是 Gist ID
   ```

### 步骤2：获取 GitHub Token

1. 前往 [GitHub Settings > Personal access tokens](https://github.com/settings/tokens)
2. 点击 "Generate new token (classic)"
3. 填写 Token 描述（如：Flutter Remote Config）
4. **重要**：勾选 `gist` 权限（必须！）
5. 点击 "Generate token"
6. **立即复制 Token**（离开页面后无法再查看）

### 步骤3：集成到应用

在 `lib/main.dart` 中：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_remote_config/flutter_remote_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 替换为你的实际值
  await EasyRemoteConfig.init(
    gistId: 'abc123def456',           // 你的 Gist ID
    githubToken: 'ghp_xxxxxxxxxxxx', // 你的 GitHub Token
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的应用',
      // 🌐 根据配置自动处理重定向
      home: EasyRedirectWidgets.simpleRedirect(
        homeWidget: HomePage(),           // 正常情况显示的页面
        loadingWidget: LoadingScreen(),   // 加载时显示的页面
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('我的应用')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('欢迎使用我的应用！'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 手动触发重定向检查
                EasyRemoteConfig.redirectIfNeeded(context);
              },
              child: Text('检查重定向'),
            ),
          ],
        ),
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
```

### 步骤4：测试效果

1. 运行应用：`flutter run`

2. 当前配置 `isRedirectEnabled: true`，应用会跳转到 `https://flutter.dev`

3. 修改 Gist 配置测试：
   - `isRedirectEnabled: false` → 显示你的正常应用
   - `isRedirectEnabled: true` → 跳转到指定地址

**🎉 完成！** 3分钟搞定远程重定向控制！

## 🌐 内置 WebView 支持

本包已内置 **flutter_inappwebview** 依赖，提供完整的WebView功能：

### ✨ 特性
- 🔥 **开箱即用**：无需额外安装webview插件
- ⚡ **功能强大**：支持JavaScript、DOM存储、缓存等
- 🎯 **智能错误处理**：网络错误自动提示和重试
- 📱 **原生体验**：支持缩放、刷新等操作
- 🔄 **加载状态**：实时显示页面加载进度
- ⏱️ **超时保护**：30秒超时避免无限加载
- 🛡️ **错误恢复**：网络错误时提供重试选项

### 📦 无需额外配置
使用本包时，你**无需**在项目中再次添加webview相关依赖：
```yaml
# ❌ 不需要额外添加
dependencies:
  # webview_flutter: ^4.0.0  # 不需要
  # flutter_inappwebview: ^6.0.0  # 已内置
```

### 🎮 自动 WebView 行为
当配置启用重定向时，应用会自动：
1. 📊 显示加载进度指示器
2. 🌐 打开内置WebView加载目标页面
3. ⚠️ 智能处理网络错误和异常
4. 🔄 提供刷新和重试功能
5. ⏱️ 30秒超时保护避免卡死
6. 🔙 随时可以返回应用

## 🌐 常用方法

### 🎯 检查重定向状态

```dart
// 检查是否需要跳转
bool shouldRedirect = EasyRemoteConfig.instance.shouldRedirect;

// 获取跳转地址
String redirectUrl = EasyRemoteConfig.instance.redirectUrl;

// 检查是否启用跳转
bool isEnabled = EasyRemoteConfig.instance.isRedirectEnabled;

// 使用示例
if (EasyRemoteConfig.instance.shouldRedirect) {
  String url = EasyRemoteConfig.instance.redirectUrl;
  print('需要跳转到: $url');
}
```

### 🎨 自动重定向组件

```dart
// 使用预设组件自动处理重定向
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: EasyRedirectWidgets.simpleRedirect(
        homeWidget: HomePage(),       // 正常显示的页面
        loadingWidget: LoadingScreen(), // 加载时显示的页面
      ),
    );
  }
}
```

## 📚 API 参考

### 核心方法

```dart
// 初始化
await EasyRemoteConfig.init(
  gistId: 'your-gist-id',
  githubToken: 'your-token',
);

// 检查是否需要跳转
bool shouldRedirect = EasyRemoteConfig.instance.shouldRedirect;

// 获取跳转地址
String redirectUrl = EasyRemoteConfig.instance.redirectUrl;

// 检查是否启用跳转
bool isEnabled = EasyRemoteConfig.instance.isRedirectEnabled;

// 手动刷新配置
await EasyRemoteConfig.instance.refresh();

// 监听配置变化
EasyRemoteConfig.instance.listen(() {
  // 处理配置更新
});
```

### 配置获取方法

```dart
// 获取字符串值
String value = EasyRemoteConfig.instance.getString('key', 'defaultValue');

// 获取布尔值
bool flag = EasyRemoteConfig.instance.getBool('key', false);

// 获取整数值
int number = EasyRemoteConfig.instance.getInt('key', 0);

// 获取双精度值
double decimal = EasyRemoteConfig.instance.getDouble('key', 0.0);

// 获取Map对象
Map<String, dynamic> object = EasyRemoteConfig.instance.getMap('key', {});

// 获取List数组
List<dynamic> array = EasyRemoteConfig.instance.getList('key', []);

// 获取所有配置
Map<String, dynamic> allConfig = EasyRemoteConfig.instance.getAllConfig();
```

## 🔧 实用技巧

### 手动刷新配置

```dart
// 手动检查最新配置
await EasyRemoteConfig.instance.refresh();

// 带回调的刷新
EasyRemoteConfig.instance.refresh().then((_) {
  print('配置已更新');
}).catchError((error) {
  print('配置更新失败: $error');
});
```

### 监听配置变化

```dart
// 监听配置更新
EasyRemoteConfig.instance.listen(() {
  print('配置已更新');
  // 处理配置变化
  if (EasyRemoteConfig.instance.shouldRedirect) {
    // 新的重定向配置生效
  }
});
```

### 设置默认值

```dart
// 初始化时设置默认配置
await EasyRemoteConfig.init(
  gistId: 'your-gist-id',
  githubToken: 'your-token',
  defaults: {
    'version': '1',
    'isRedirectEnabled': false,
    'redirectUrl': '',
    'customFlag': true,
    'timeout': 30,
  },
);
```

## 🔧 调试工具

### 1. 启用调试模式

```dart
await EasyRemoteConfig.init(
  gistId: 'your-gist-id',
  githubToken: 'your-token',
  debugMode: true,  // 🔧 启用调试日志
);

// 🐛 启用高级调试工具
RemoteConfigDebugHelper.enableDebug(enableHealthCheck: true);
```

### 2. 可视化调试面板

```dart
// 🎯 在任何地方打开调试面板
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ConfigDebugPanel(),
));

// 或者在开发环境中添加浮动调试按钮
FloatingActionButton(
  onPressed: () {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ConfigDebugPanel(),
    ));
  },
  child: Icon(Icons.bug_report),
)
```

### 3. 健康状态检查

```dart
// 📊 检查配置健康状态
final healthStatus = RemoteConfigDebugHelper.getHealthStatus();
print('配置是否正常: ${healthStatus['initialized']}');

// 🔍 诊断配置问题
final diagnosis = RemoteConfigDebugHelper.diagnoseConfig();
print('诊断结果: ${diagnosis['overall']}');

// 获取详细的系统信息
final systemInfo = RemoteConfigDebugHelper.getSystemInfo();
print('系统信息: $systemInfo');
```

## 🎯 典型使用场景

### 1. App强制更新
```dart
// Gist 配置：
// {
//   "version": "1",
//   "isRedirectEnabled": true,
//   "redirectUrl": "https://apps.apple.com/app/yourapp",
//   "updateMessage": "发现新版本，请更新应用"
// }

if (EasyRemoteConfig.instance.shouldRedirect) {
  String appStoreUrl = EasyRemoteConfig.instance.redirectUrl;
  String message = EasyRemoteConfig.instance.getString('updateMessage', '需要更新');
  
  // 显示更新提示
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('应用更新'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            EasyRemoteConfig.redirectIfNeeded(context);
          },
          child: Text('立即更新'),
        ),
      ],
    ),
  );
}
```

### 2. 维护通知
```dart
// Gist 配置：
// {
//   "version": "1",
//   "isRedirectEnabled": true, 
//   "redirectUrl": "https://yoursite.com/maintenance",
//   "maintenanceMode": true,
//   "maintenanceMessage": "系统维护中，预计2小时后恢复"
// }

// 检查维护模式
if (EasyRemoteConfig.instance.getBool('maintenanceMode', false)) {
  // 自动跳转到维护说明页面
  EasyRemoteConfig.redirectIfNeeded(context, title: '系统维护');
}
```

### 3. 功能开关控制
```dart
// Gist 配置：
// {
//   "version": "1",
//   "features": {
//     "newUI": true,
//     "betaFeature": false,
//     "advancedMode": true
//   }
// }

// 根据远程配置控制功能显示
Widget buildUI() {
  bool useNewUI = EasyRemoteConfig.instance.getBool('features.newUI', false);
  bool showBeta = EasyRemoteConfig.instance.getBool('features.betaFeature', false);
  
  return useNewUI ? NewUIWidget() : OldUIWidget();
}
```

### 4. A/B测试
```dart
// Gist 配置：
// {
//   "version": "1",
//   "abTest": {
//     "buttonColor": "blue",  // 或 "red"
//     "layoutType": "grid",   // 或 "list"
//     "showAds": true
//   }
// }

// 根据A/B测试配置调整界面
Widget buildButton() {
  String buttonColor = EasyRemoteConfig.instance.getString('abTest.buttonColor', 'blue');
  
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: buttonColor == 'red' ? Colors.red : Colors.blue,
    ),
    onPressed: () {},
    child: Text('测试按钮'),
  );
}
```

## 🔧 高级配置

### 复杂配置示例

```json
{
  "version": "2",
  "isRedirectEnabled": false,
  "redirectUrl": "",
  "features": {
    "newUI": true,
    "darkMode": false,
    "notifications": true
  },
  "abTest": {
    "group": "A",
    "buttonColor": "blue",
    "showWelcome": true
  },
  "maintenance": {
    "enabled": false,
    "message": "系统维护中",
    "startTime": "2024-01-01T10:00:00Z",
    "endTime": "2024-01-01T12:00:00Z"
  },
  "update": {
    "required": false,
    "version": "1.0.0",
    "url": "https://apps.apple.com/app/yourapp"
  }
}
```

### 使用复杂配置

```dart
// 检查维护时间
String startTime = EasyRemoteConfig.instance.getString('maintenance.startTime', '');
if (startTime.isNotEmpty) {
  DateTime maintenanceStart = DateTime.parse(startTime);
  if (DateTime.now().isAfter(maintenanceStart)) {
    // 进入维护模式
  }
}

// A/B测试分组
String testGroup = EasyRemoteConfig.instance.getString('abTest.group', 'A');
switch (testGroup) {
  case 'A':
    // 显示版本A的界面
    break;
  case 'B':
    // 显示版本B的界面
    break;
}

// 功能开关
Map<String, dynamic> features = EasyRemoteConfig.instance.getMap('features', {});
bool newUIEnabled = features['newUI'] ?? false;
bool darkModeEnabled = features['darkMode'] ?? false;
```

## 🔧 技术特性

### 智能缓存
- 📱 **应用切换检测**：从后台恢复时自动检查最新配置
- ⚡ **网络优化**：ETag 缓存技术，减少重复下载
- 🔄 **自动更新**：确保总是使用最新的跳转配置
- 💾 **本地存储**：配置本地缓存，离线时使用缓存数据

### 错误处理
- 🛡️ **网络异常处理**：自动重试机制
- ⏱️ **超时保护**：避免长时间等待
- 🔄 **降级策略**：网络失败时使用本地缓存
- 📊 **错误统计**：记录错误信息便于调试

## ⚙️ 配置选项

```dart
await EasyRemoteConfig.init(
  gistId: 'your-gist-id',        // 必需：GitHub Gist ID
  githubToken: 'your-token',     // 必需：GitHub Token
  debugMode: false,              // 可选：调试模式
  cacheTimeout: 300,             // 可选：缓存超时时间（秒）
  networkTimeout: 10,            // 可选：网络请求超时时间（秒）
  defaults: {                    // 可选：默认配置
    'version': '1',
    'isRedirectEnabled': false,
    'redirectUrl': '',
  },
);
```

## 📚 API 参考

### 核心方法

```dart
// 初始化
await EasyRemoteConfig.init(
  gistId: 'your-gist-id',
  githubToken: 'your-token',
);

// 检查是否需要跳转
bool shouldRedirect = EasyRemoteConfig.instance.shouldRedirect;

// 获取跳转地址
String redirectUrl = EasyRemoteConfig.instance.redirectUrl;

// 检查是否启用跳转
bool isEnabled = EasyRemoteConfig.instance.isRedirectEnabled;

// 手动刷新配置
await EasyRemoteConfig.instance.refresh();

// 监听配置变化
EasyRemoteConfig.instance.listen(() {
  // 处理配置更新
});
```

### 配置获取方法

```dart
// 获取字符串值
String value = EasyRemoteConfig.instance.getString('key', 'defaultValue');

// 获取布尔值
bool flag = EasyRemoteConfig.instance.getBool('key', false);

// 获取整数值
int number = EasyRemoteConfig.instance.getInt('key', 0);

// 获取双精度值
double decimal = EasyRemoteConfig.instance.getDouble('key', 0.0);

// 获取Map对象
Map<String, dynamic> object = EasyRemoteConfig.instance.getMap('key', {});

// 获取List数组
List<dynamic> array = EasyRemoteConfig.instance.getList('key', []);

// 获取所有配置
Map<String, dynamic> allConfig = EasyRemoteConfig.instance.getAllConfig();
```

### 自动跳转组件

```dart
EasyRedirectWidgets.simpleRedirect(
  homeWidget: HomePage(),        // 正常页面
  loadingWidget: LoadingScreen(), // 加载页面
)
```

## ⚠️ 最佳实践

### 1. 安全建议
```dart
// ✅ 安全的重定向验证
final redirectUrl = EasyRemoteConfig.instance.getString('redirectUrl', '');
if (redirectUrl.isNotEmpty && (redirectUrl.startsWith('https://') || redirectUrl.startsWith('http://'))) {
  // 只允许HTTP/HTTPS重定向
  // 这里不再提供手动重定向API，所有跳转由自动重定向组件统一管理
} else {
  print('不安全的重定向URL: $redirectUrl');
}
```

### 2. 错误处理
```dart
// 🛡️ 优雅的错误处理
try {
  await EasyRemoteConfig.init(
    gistId: 'your-gist-id',
    githubToken: 'your-token',
  );
} catch (e) {
  // 初始化失败时使用本地默认配置
  print('远程配置加载失败，使用默认配置: $e');
  // 可以设置一些默认行为
}
```

### 3. 性能优化
```dart
// ⚡ 避免频繁检查配置
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late bool _shouldRedirect;
  late String _redirectUrl;
  
  @override
  void initState() {
    super.initState();
    // 缓存配置值
    _shouldRedirect = EasyRemoteConfig.instance.shouldRedirect;
    _redirectUrl = EasyRemoteConfig.instance.redirectUrl;
    
    // 监听配置变化
    EasyRemoteConfig.instance.listen(() {
      setState(() {
        _shouldRedirect = EasyRemoteConfig.instance.shouldRedirect;
        _redirectUrl = EasyRemoteConfig.instance.redirectUrl;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return _shouldRedirect ? RedirectWidget() : NormalWidget();
  }
}
```

### 4. 配置版本管理
```dart
// 📋 配置版本检查
String configVersion = EasyRemoteConfig.instance.getString('version', '1');
if (configVersion != '2') {
  // 配置版本不匹配，可能需要特殊处理
  print('配置版本不匹配，当前: $configVersion，期望: 2');
}
```

## 🐛 故障排除

### 常见问题及解决方案

#### 1. Token 权限问题
**问题**: `401 Unauthorized` 错误
**解决**: 
- 确保 Token 具有 `gist` 权限
- 检查 Token 是否过期
- 验证 Token 格式正确（通常以 `ghp_` 开头）

#### 2. 配置不更新
**问题**: Gist 更新了但应用没反应
**解决**: 
```dart
// 强制刷新配置
await EasyRemoteConfig.instance.refresh();

// 检查缓存是否过期
print('上次更新时间: ${EasyRemoteConfig.instance.lastUpdateTime}');
```

#### 3. WebView 加载问题
**问题**: WebView 一直显示加载中
**解决**: 
- 检查 iOS Info.plist 权限配置
- 确认目标URL可以正常访问
- 检查网络连接状态
- 使用调试模式查看详细错误信息

#### 4. 网络超时
**问题**: 请求 GitHub API 超时
**解决**: 
```dart
// 增加超时时间
await EasyRemoteConfig.init(
  gistId: 'your-gist-id',
  githubToken: 'your-token',
  networkTimeout: 30, // 增加到30秒
);
```

#### 5. Gist ID 错误
**问题**: `404 Not Found` 错误
**解决**: 
- 确认 Gist ID 正确（从URL中复制）
- 确认 Gist 是公开的（public）
- 检查 Gist 是否存在

### 调试步骤

1. **启用调试模式**
```dart
await EasyRemoteConfig.init(
  gistId: 'your-gist-id',
  githubToken: 'your-token',
  debugMode: true, // 查看详细日志
);
```

2. **使用调试面板**
```dart
// 打开可视化调试面板
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ConfigDebugPanel(),
));
```

3. **检查配置健康状态**
```dart
final healthStatus = RemoteConfigDebugHelper.getHealthStatus();
print('配置状态: $healthStatus');

// 获取详细诊断信息
final diagnosis = RemoteConfigDebugHelper.diagnoseConfig();
print('诊断结果: $diagnosis');
```

4. **验证网络连接**
```dart
// 手动测试 GitHub API 连接
try {
  await EasyRemoteConfig.instance.refresh();
  print('网络连接正常');
} catch (e) {
  print('网络连接失败: $e');
}
```

## 🔧 开发环境设置

### 本地测试配置

```dart
// 开发环境使用测试配置
await EasyRemoteConfig.init(
  gistId: 'your-test-gist-id',    // 测试用的Gist ID
  githubToken: 'your-token',
  debugMode: true,                // 开启调试
  defaults: {
    'version': '1',
    'isRedirectEnabled': false,   // 开发时默认不重定向
    'redirectUrl': 'https://flutter.dev',
  },
);
```

### 生产环境配置

```dart
// 生产环境配置
await EasyRemoteConfig.init(
  gistId: 'your-production-gist-id',
  githubToken: 'your-production-token',
  debugMode: false,               // 关闭调试
  cacheTimeout: 300,              // 5分钟缓存
  networkTimeout: 10,             // 10秒网络超时
);
```

## 🤝 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

1. **Fork** 项目仓库
2. **创建**功能分支 (`git checkout -b feature/amazing-feature`)
3. **提交**更改 (`git commit -m 'Add amazing feature'`)
4. **推送**到分支 (`git push origin feature/amazing-feature`)
5. **提交** Pull Request

### 开发环境设置

```bash
# 克隆项目
git clone https://github.com/gistpage/flutter_remote_config.git
cd flutter_remote_config

# 安装依赖
flutter pub get

# 运行测试
flutter test

# 运行示例项目
cd example
flutter pub get
flutter run
```

### 版本管理策略

```yaml
# 使用特定标签（推荐生产环境）
dependencies:
  flutter_remote_config:
    git:
      url: https://github.com/gistpage/flutter_remote_config.git
      ref: v1.0.0

# 使用最新版本（开发环境）
dependencies:
  flutter_remote_config:
    git:
      url: https://github.com/gistpage/flutter_remote_config.git
      ref: main
```

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持与反馈

- 🐛 **Bug 报告**: [GitHub Issues](https://github.com/gistpage/flutter_remote_config/issues)
- 💡 **功能建议**: [GitHub Discussions](https://github.com/gistpage/flutter_remote_config/discussions)
- 📖 **文档**: 此 README 文档
- 💬 **获取帮助**: 通过 GitHub Issues 提问

## 🏆 成功案例

> **✅ 真机测试验证**：本包已在 iPhone 15 Pro Max 上成功测试，WebView 加载正常，重定向功能完美运行。

### 测试环境
- **设备**: iPhone 15 Pro Max
- **系统**: iOS 17+
- **Flutter**: 3.0+
- **测试场景**: 
  - ✅ 远程配置加载
  - ✅ WebView 重定向跳转
  - ✅ 网络错误处理
  - ✅ 超时保护机制
  - ✅ 用户交互体验

---

<div align="center">

**喜欢这个项目？请给我们一个 ⭐️**

Made with ❤️ for Flutter Community

</div>

---

## 📞 联系方式

- **GitHub**: [gistpage](https://github.com/gistpage)
- **项目地址**: [flutter_remote_config](https://github.com/gistpage/flutter_remote_config)

---

*最后更新时间: 2025-01-01 - ✅ 真机测试验证通过*

## ⚠️ 平台兼容性与WebView配置

本包内置重定向WebView功能，依赖 [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview)。

### iOS 需在 Info.plist 添加：
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
  <key>NSAllowsArbitraryLoadsInWebContent</key>
  <true/>
</dict>
<key>io.flutter.embedded_views_preview</key>
<true/>
<key>NSLocalNetworkUsageDescription</key>
<string>此应用需要访问网络以加载远程配置和重定向页面</string>
```

### Android 需在 AndroidManifest.xml 添加：
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

如需更细致的WebView配置，请参考 [flutter_inappwebview官方文档](https://pub.dev/packages/flutter_inappwebview#android) 。

## 🚀 自动重定向用法

**⚠️ 注意事项：**

> 建议仅在主页面或需要重定向的页面调用自动重定向方法或组件，避免在所有页面重复调用，防止页面跳转异常。

```dart
// 初始化成功后自动检测并跳转
await EasyRemoteConfig.init(...);
// 自动重定向由 simpleRedirect 组件统一管理
```

## 🎯 快速测试指南

想要快速测试包的功能？按照以下步骤：

1. **使用示例配置**：
```json
{
  "version": "1",
  "isRedirectEnabled": true,
  "redirectUrl": "https://flutter.dev"
}
```

2. **运行示例项目**：
```bash
cd example
flutter run
```

3. **修改配置测试**：
   - 修改 Gist 中的 `isRedirectEnabled` 为 `false`
   - 重新打开应用查看效果
   - 修改 `redirectUrl` 测试不同的跳转地址

4. **测试网络异常**：
   - 断开网络连接
   - 查看应用如何处理网络错误
   - 重新连接网络测试自动恢复

**🎉 开始使用吧！**
