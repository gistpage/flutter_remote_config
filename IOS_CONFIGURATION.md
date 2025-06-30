# iOS Configuration Guide for flutter_remote_config

## 说明

当在 iOS 应用中使用 `flutter_remote_config` 包进行开发和调试时，可能会遇到网络权限相关的错误。本指南提供了解决方案。

## 常见错误

```
[ERROR:flutter/shell/platform/darwin/ios/framework/Source/FlutterDartVMServicePublisher.mm(129)] Could not register as server for FlutterDartVMServicePublisher, permission denied. Check your 'Local Network' permissions for this app in the Privacy section of the system Settings.
```

## 解决方案

在您的 iOS 项目的 `ios/Runner/Info.plist` 文件中添加以下配置：

### 1. 本地网络权限描述

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>需要本地网络权限用于调试和开发</string>
```

### 2. Bonjour 服务声明

```xml
<key>NSBonjourServices</key>
<array>
    <string>_dartobservatory._tcp</string>
    <string>_dartVmService._tcp</string>
</array>
```

## 完整示例

在 `ios/Runner/Info.plist` 的 `<dict>` 标签内添加：

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>需要本地网络权限用于调试和开发</string>
<key>NSBonjourServices</key>
<array>
    <string>_dartobservatory._tcp</string>
    <string>_dartVmService._tcp</string>
</array>
```

## 为什么需要这些配置？

- **NSLocalNetworkUsageDescription**: iOS 14+ 需要明确声明本地网络使用权限
- **NSBonjourServices**: Flutter 调试模式使用 Bonjour 服务进行热重载和调试通信
- **_dartobservatory._tcp**: Flutter Observatory 调试服务
- **_dartVmService._tcp**: Dart VM 服务

## 注意事项

1. 这些配置主要影响开发和调试模式
2. 发布模式的应用通常不需要这些权限
3. 配置后需要重新构建应用才能生效

## 其他语言版本

如果您的应用需要支持英语，可以使用：

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Local network access is required for debugging and development</string>
``` 