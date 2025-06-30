import 'dart:async';
import 'package:flutter/material.dart';
import '../debug/debug_helper.dart';


class ConfigDebugPanel extends StatefulWidget {
  const ConfigDebugPanel({super.key});

  @override
  State<ConfigDebugPanel> createState() => _ConfigDebugPanelState();
}

class _ConfigDebugPanelState extends State<ConfigDebugPanel> {
  Map<String, dynamic>? _healthStatus;
  Map<String, dynamic>? _diagnosis;
  bool _autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _healthStatus = RemoteConfigDebugHelper.getHealthStatus();
      _diagnosis = RemoteConfigDebugHelper.diagnoseConfig();
    });
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
    });

    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _refreshData();
      });
    } else {
      _refreshTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('远程配置调试面板'),
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoRefresh,
            tooltip: _autoRefresh ? '停止自动刷新' : '开始自动刷新',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '手动刷新',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthStatusCard(),
            const SizedBox(height: 16),
            _buildDiagnosisCard(),
            const SizedBox(height: 16),
            _buildLogsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusCard() {
    final status = _healthStatus;
    if (status == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('加载中...'),
        ),
      );
    }

    final isHealthy = status['initialized'] == true && status['hasConfig'] == true;
    
    return Card(
      color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: isHealthy ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  '健康状态',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...status.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text('${entry.key}:', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Text(entry.value.toString())),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    final diagnosis = _diagnosis;
    if (diagnosis == null) return const SizedBox();

    final overall = diagnosis['overall'] as String;
    Color cardColor;
    IconData icon;
    
    switch (overall) {
      case 'healthy':
        cardColor = Colors.green.shade50;
        icon = Icons.check_circle;
        break;
      case 'warning':
        cardColor = Colors.orange.shade50;
        icon = Icons.warning;
        break;
      case 'error':
        cardColor = Colors.red.shade50;
        icon = Icons.error;
        break;
      default:
        cardColor = Colors.grey.shade50;
        icon = Icons.help;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _getColorForStatus(overall)),
                const SizedBox(width: 8),
                const Text(
                  '诊断结果',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (diagnosis['issues'].isNotEmpty) ...[
              const Text('🔴 问题:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...diagnosis['issues'].map((issue) => Text('• $issue')),
              const SizedBox(height: 8),
            ],
            if (diagnosis['warnings'].isNotEmpty) ...[
              const Text('🟡 警告:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ...diagnosis['warnings'].map((warning) => Text('• $warning')),
              const SizedBox(height: 8),
            ],
            if (diagnosis['suggestions'].isNotEmpty) ...[
              const Text('💡 建议:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ...diagnosis['suggestions'].map((suggestion) => Text('• $suggestion')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard() {
    final logs = RemoteConfigDebugHelper.getLogs();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '调试日志',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    RemoteConfigDebugHelper.clearLogs();
                    _refreshData();
                  },
                  child: const Text('清除'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: logs.isEmpty
                  ? const Center(child: Text('暂无日志'))
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[logs.length - 1 - index]; // 倒序显示
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Text(
                            log,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'healthy': return Colors.green;
      case 'warning': return Colors.orange;
      case 'error': return Colors.red;
      default: return Colors.grey;
    }
  }
} 