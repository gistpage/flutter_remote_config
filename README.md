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

一个**超简单**的 Flutter 重定向控制包，通过 GitHub Gist 远程控制应用是否跳转到指定地址。

> **🚀 30秒快速集成**，一行代码实现远程重定向控制！

## 🎯 这个包能帮你做什么

**核心功能**：根据 GitHub Gist 中的配置，决定应用是否跳转到某个地址

**典型场景**：
- ✅ **App强制更新**：跳转到App Store更新页面
- ✅ **维护通知**：跳转到维护说明页面  
- ✅ **紧急公告**：跳转到重要通知页面
- ✅ **活动推广**：跳转到活动页面

**为什么选择这个包**：
- 🔥 **集成简单**：1行代码完成初始化
- 🌐 **免费稳定**：基于GitHub Gist，全球CDN加速
- ⚡ **几乎零流量**：智能缓存，网络优化
- 📱 **自动更新**：应用切换时检查最新配置

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

如果你在 iOS 开发调试中遇到网络权限相关错误，请参考：
📋 **[iOS 配置指南](IOS_CONFIGURATION.md)** - 解决 Flutter 调试模式网络权限问题

### 4. 添加导入

在需要使用的 Dart 文件中添加导入：

```dart
import 'package:flutter_remote_config/flutter_remote_config.dart';
```

## 🚀 快速开始（3分钟完成）

### 步骤1：创建 GitHub Gist 配置

1. 访问 [GitHub Gist](https://gist.github.com)
2. 创建新 Gist，文件名：`config.json`
3. 复制粘贴配置内容：

```json
{
  "version": "1",
  "isRedirectEnabled": true,
  "redirectUrl": "https://example.com"
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
        child: Text('欢迎使用我的应用！'),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

### 步骤4：测试效果

1. 运行应用：`flutter run`

2. 当前配置 `isRedirectEnabled: true`，应用会跳转到 `https://example.com`

3. 修改 Gist 配置测试：
   - `isRedirectEnabled: false` → 显示你的正常应用
   - `isRedirectEnabled: true` → 跳转到指定地址

**🎉 完成！** 3分钟搞定远程重定向控制！

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
  // 处理跳转逻辑，比如打开浏览器
  launchUrl(Uri.parse(url));
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

## 🔧 实用技巧

### 手动刷新配置

```dart
// 手动检查最新配置
await EasyRemoteConfig.instance.refresh();
```

### 监听配置变化

```dart
// 监听配置更新
EasyRemoteConfig.instance.listen(() {
  print('配置已更新');
  // 处理配置变化
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
```

### 3. 健康状态检查

```dart
// 📊 检查配置健康状态
final healthStatus = RemoteConfigDebugHelper.getHealthStatus();
print('配置是否正常: ${healthStatus['initialized']}');

// 🔍 诊断配置问题
final diagnosis = RemoteConfigDebugHelper.diagnoseConfig();
print('诊断结果: ${diagnosis['overall']}');
```

## 🎯 典型使用场景

### 1. App强制更新
```dart
// Gist 配置：
// {
//   "version": "1",
//   "isRedirectEnabled": true,
//   "redirectUrl": "https://apps.apple.com/app/yourapp"
// }

if (EasyRemoteConfig.instance.shouldRedirect) {
  String appStoreUrl = EasyRemoteConfig.instance.redirectUrl;
  launchUrl(Uri.parse(appStoreUrl)); // 跳转到App Store
}
```

### 2. 维护通知
```dart
// Gist 配置：
// {
//   "version": "1",
//   "isRedirectEnabled": true, 
//   "redirectUrl": "https://yoursite.com/maintenance"
// }

// 自动跳转到维护说明页面
```

### 3. 活动推广
```dart
// Gist 配置：
// {
//   "version": "1",
//   "isRedirectEnabled": true,
//   "redirectUrl": "https://yoursite.com/activity"
// }

// 自动跳转到活动页面
```

## 🔧 技术特性

### 智能缓存
- 📱 **应用切换检测**：从后台恢复时自动检查最新配置
- ⚡ **网络优化**：ETag 缓存技术，减少重复下载
- 🔄 **自动更新**：确保总是使用最新的跳转配置

## ⚙️ 配置选项

```dart
await EasyRemoteConfig.init(
  gistId: 'your-gist-id',        // 必需：GitHub Gist ID
  githubToken: 'your-token',     // 必需：GitHub Token
  debugMode: false,              // 可选：调试模式
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
if (redirectUrl.isNotEmpty && redirectUrl.startsWith('https://')) {
  // 只允许HTTPS重定向
  navigate(redirectUrl);
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
  
  @override
  void initState() {
    super.initState();
    // 缓存配置值
    _shouldRedirect = EasyRemoteConfig.instance.shouldRedirect;
  }
  
  @override
  Widget build(BuildContext context) {
    return _shouldRedirect ? RedirectWidget() : NormalWidget();
  }
}
```

## 🐛 故障排除

### 常见问题及解决方案

#### 1. Token 权限问题
**问题**: `401 Unauthorized` 错误
**解决**: 确保 Token 具有 `gist` 权限，检查 Token 是否过期

#### 2. 配置不更新
**问题**: Gist 更新了但应用没反应
**解决**: 
```dart
// 强制刷新配置
await EasyRemoteConfig.instance.refresh();
```

#### 3. 网络超时
**问题**: 请求 GitHub API 超时
**解决**: 增加超时时间或检查网络连接

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
```

## 🤝 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

1. **Fork** 项目仓库
2. **创建**功能分支 (`git checkout -b feature/amazing-feature`)
3. **提交**更改 (`git commit -m 'Add amazing feature'`)
4. **推送**到分支 (`git push origin feature/amazing-feature`)
5. **提交** Pull Request

### 版本管理策略

```yaml
# 使用特定标签（推荐）
dependencies:
  flutter_remote_config:
    git:
      url: https://github.com/gistpage/flutter_remote_config.git
      ref: v1.0.0

# 使用特定分支
dependencies:
  flutter_remote_config:
    git:
      url: https://github.com/gistpage/flutter_remote_config.git
      ref: develop
```

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持与反馈

- 🐛 **Bug 报告**: [GitHub Issues](https://github.com/gistpage/flutter_remote_config/issues)
- 💡 **功能建议**: [GitHub Discussions](https://github.com/gistpage/flutter_remote_config/discussions)
- 📖 **文档**: 此 README 文档
- 💬 **获取帮助**: 通过 GitHub Issues 提问

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

*最后更新时间: 2025-01-01 - 测试gistpage账户配置*
