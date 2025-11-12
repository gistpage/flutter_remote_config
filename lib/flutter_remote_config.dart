// 顶层仅做导出聚合，无需引入 material

// 🚀 简化API (推荐使用)
export 'src/easy_remote_config.dart';
export 'src/config_builder.dart';
export 'src/config_templates.dart';
export 'src/redirect_config.dart';

// 🎨 改进版组件 (推荐)
export 'src/widgets/improved_redirect_widgets.dart';
export 'src/widgets/redirect_widgets.dart';
export 'src/widgets/internal_widgets.dart';
export 'src/widgets/redirect_webview.dart';

// 🎯 状态管理 (新增)
export 'src/state_management/config_state_manager.dart';

// 🔧 高级API (需要更多控制时使用)
export 'src/manager/advanced_config_manager.dart';
export 'src/config/remote_config_options.dart';
export 'src/models/remote_config.dart';
export 'src/manager/remote_config_manager.dart';
export 'src/services/remote_config_service.dart';

// 🛠️ 调试工具
export 'src/debug/debug_helper.dart';
export 'src/widgets/debug_panel.dart';
