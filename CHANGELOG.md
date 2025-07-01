# 变更日志

所有重要的项目变更都将记录在此文件中。

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范。

## [0.0.4] - 2025-01-01

### ✅ 验证与完善
- **全面验证默认配置逻辑**
  - 确认在网络失败、Token错误、Gist不存在等情况下能正确使用默认配置
  - 验证重定向组件能正确处理默认配置的各种场景
  - 添加全面的单元测试覆盖默认配置逻辑

### 🔧 重要改进
- **重定向组件优化**
  - 重定向组件现在优先使用 `EasyRemoteConfig` 的配置（包含完善的默认配置兜底）
  - 增强多层降级策略：EasyRemoteConfig → AdvancedConfigManager → 主页面
  - 添加详细调试日志，便于问题排查

### 🧪 测试增强
- 添加 `EasyRemoteConfig.resetInstance()` 方法支持测试重置
- 添加 `AdvancedConfigManager.resetInstance()` 方法支持测试重置
- 新增 11 个测试用例覆盖默认配置的各种场景
- 验证性能、缓存效果、内存使用等关键指标

### 📚 文档完善
- 添加详细的"默认配置测试指南"
- 提供完整的测试代码示例和期望结果
- 包含多种场景的测试用例（禁用重定向、启用重定向、空配置等）

## [0.0.3] - 2025-01-01

### 🚨 重要修复
- **修复了 `EasyRedirectWidgets.simpleRedirect` 无限加载问题**
  - 替换有问题的 StreamBuilder 实现为更可靠的 FutureBuilder
  - 添加 3 秒超时保护，避免应用卡死
  - 增强错误处理和降级策略
  - 添加详细调试日志帮助排查问题

### 🔧 改进
- 重构 `_SimpleRedirectWidget` 为 StatelessWidget，提高性能
- 优化初始化检查逻辑，更快响应配置状态
- 增强调试信息输出，便于问题排查

### 📚 文档更新
- 添加紧急修复指南到快速测试指南
- 提供多种临时解决方案（包括使用 `ImprovedRedirectWidgets.smartRedirect`）
- 完善故障排除说明

## [0.0.2] - 2024-12-19

### ✨ 新增功能
- **内置 WebView 支持**: 集成 `flutter_inappwebview` 依赖，提供完整的WebView功能
- **开箱即用**: 用户无需额外安装webview插件，重定向功能直接可用
- **智能错误处理**: 网络错误自动提示和重试机制
- **原生体验**: 支持页面缩放、刷新、前进后退等操作
- **加载状态指示**: 实时显示页面加载进度

### 🔧 改进优化
- 替换占位符WebView为功能完整的实现
- 更新示例应用，展示真实的WebView功能
- 优化用户体验，提供更好的错误提示

### 🗑️ 移除
- 删除未使用的内部函数，清理代码
- 移除占位符提示信息

### 📚 文档更新
- 更新README，说明内置WebView功能特性
- 添加WebView相关的使用说明和配置介绍

## [0.0.1] - 2024-XX-XX

### 🎉 初始发布

这是 `flutter_remote_config` 包的首个版本，提供了功能完整的 GitHub Gist 远程配置管理解决方案。

### ✨ 新增功能

- **🚀 GitHub Gist 集成**
  - 支持使用 GitHub Gist 作为远程配置存储
  - 自动文件名检测（config.json、app_config.json 等）
  - GitHub API v3 完整支持

- **🧠 智能缓存策略**
  - 前台/后台不同的缓存过期时间
  - 短期缓存（15分钟）和长期缓存（4小时）
  - 智能缓存失效和回退机制

- **🔄 ETag 优化**
  - HTTP ETag 支持，减少不必要的网络请求
  - 304 Not Modified 响应处理
  - 网络带宽优化

- **📱 应用生命周期感知**
  - 应用启动时自动获取最新配置
  - 前台恢复时智能检查配置更新
  - 前台/后台不同的检查频率

- **🎯 版本控制系统**
  - 基于版本号的智能更新检测
  - 配置内容深度比较
  - 增量更新支持

- **🛡️ 完善的容错机制**
  - 网络错误时自动使用缓存配置
  - 配置解析失败时回退到默认配置
  - 完整的错误处理和日志记录

- **🔧 类型安全支持**
  - 支持自定义配置类型
  - 泛型支持确保类型安全
  - `BasicRemoteConfig` 开箱即用

- **📢 实时配置监听**
  - 配置变化 Stream 监听
  - 自动通知订阅者
  - 支持多个监听器

- **⚙️ 高度可配置**
  - 环境变量支持
  - 可配置的缓存策略
  - 可调整的检查间隔
  - 调试日志开关

### 🏗️ 核心组件

- **RemoteConfigService** - 底层配置服务，处理 GitHub API 交互
- **RemoteConfigManager** - 实例级配置管理器，支持生命周期感知
- **AdvancedConfigManager** - 单例全局配置管理器，推荐使用
- **RemoteConfigOptions** - 配置选项类，支持环境变量
- **BasicRemoteConfig** - 基础配置类，适用于大多数场景

### 📚 文档和示例

- 完整的 README.md 文档
- 详细的 API 参考
- 功能完整的示例应用
- 最佳实践指南
- 故障排除指南

### 🔧 开发工具

- 完整的调试日志系统
- 错误详情和堆栈跟踪
- 性能监控和优化建议

### 📦 依赖项

- `http: ^1.1.0` - HTTP 客户端
- `shared_preferences: ^2.2.2` - 本地缓存存储
- `flutter: >=1.17.0` - Flutter 框架支持

### 🎯 支持的功能

- ✅ GitHub Gist 集成
- ✅ 智能缓存策略
- ✅ ETag 优化
- ✅ 版本控制
- ✅ 生命周期感知
- ✅ 错误容错
- ✅ 类型安全
- ✅ 实时监听
- ✅ 环境变量配置
- ✅ 多配置实例
- ✅ 调试日志

### 🔮 未来计划

- 支持更多配置源（Firebase、自定义 API 等）
- A/B 测试功能
- 配置回滚机制
- 更丰富的缓存策略
- 配置加密支持

---

## 贡献指南

感谢您对本项目的关注！如果您想要贡献代码，请：

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

## 许可证

本项目基于 MIT 许可证开源 - 查看 [LICENSE](LICENSE) 文件了解详情。
