import 'dart:async';
import '../models/remote_config.dart';
import '../state_management/config_state_manager.dart';

enum ConfigEventType { configChanged, stateChanged, error }

abstract class ConfigEvent {
  final ConfigEventType type;
  final DateTime timestamp;
  ConfigEvent(this.type) : timestamp = DateTime.now();
}

class ConfigChangedEvent extends ConfigEvent {
  final RemoteConfig config;
  ConfigChangedEvent(this.config) : super(ConfigEventType.configChanged);
}

class ConfigStateChangedEvent extends ConfigEvent {
  final ConfigState state;
  ConfigStateChangedEvent(this.state) : super(ConfigEventType.stateChanged);
}

/// 🎯 统一的配置事件管理器 - 替代多个StreamController
class ConfigEventManager {
  static ConfigEventManager? _instance;
  static ConfigEventManager get instance => _instance ??= ConfigEventManager._();
  ConfigEventManager._();

  StreamController<ConfigEvent>? _eventController;
  
  Stream<ConfigEvent> get events {
    _eventController ??= StreamController<ConfigEvent>.broadcast();
    return _eventController!.stream;
  }
  
  // 🔥 类型安全的流访问
  Stream<T> configStream<T extends RemoteConfig>() {
    return events
        .where((event) => event is ConfigChangedEvent)
        .map((event) => (event as ConfigChangedEvent).config)
        .cast<T>();
  }
  
  Stream<ConfigState> get stateStream {
    return events
        .where((event) => event is ConfigStateChangedEvent)
        .map((event) => (event as ConfigStateChangedEvent).state);
  }
  
  void emit(ConfigEvent event) {
    _eventController ??= StreamController<ConfigEvent>.broadcast();
    _eventController?.add(event);
  }
  
  void dispose() {
    _eventController?.close();
    _eventController = null;
    _instance = null;
  }
} 