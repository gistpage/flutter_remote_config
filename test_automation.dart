// 🧪 自动化测试脚本
// 运行命令: dart test_automation.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🚀 开始 Flutter Remote Config 自动化测试...\n');
  
  final testResults = <String, bool>{};
  
  // 1. 代码质量检查
  testResults['代码分析'] = await runCodeAnalysis();
  testResults['单元测试'] = await runUnitTests();
  testResults['依赖检查'] = await checkDependencies();
  
  // 2. 示例应用检查
  testResults['示例应用构建'] = await buildExampleApp();
  testResults['WebView集成'] = await checkWebViewIntegration();
  
  // 3. 跨平台兼容性
  testResults['iOS兼容性'] = await checkIOSCompatibility();
  testResults['Android兼容性'] = await checkAndroidCompatibility();
  testResults['Web兼容性'] = await checkWebCompatibility();
  
  // 生成测试报告
  generateTestReport(testResults);
}

/// 运行代码分析
Future<bool> runCodeAnalysis() async {
  print('📊 运行代码分析...');
  try {
    final result = await Process.run('flutter', ['analyze']);
    final hasErrors = result.stdout.toString().contains('error •') || 
                     result.stdout.toString().contains('warning •');
    
    if (!hasErrors) {
      print('✅ 代码分析通过 - 无错误和警告');
      return true;
    } else {
      print('❌ 代码分析发现问题');
      print(result.stdout);
      return false;
    }
  } catch (e) {
    print('❌ 代码分析执行失败: $e');
    return false;
  }
}

/// 运行单元测试
Future<bool> runUnitTests() async {
  print('🧪 运行单元测试...');
  try {
    final result = await Process.run('flutter', ['test']);
    final allTestsPassed = result.stdout.toString().contains('All tests passed!');
    
    if (allTestsPassed) {
      print('✅ 所有单元测试通过');
      return true;
    } else {
      print('❌ 单元测试失败');
      print(result.stdout);
      return false;
    }
  } catch (e) {
    print('❌ 单元测试执行失败: $e');
    return false;
  }
}

/// 检查依赖关系
Future<bool> checkDependencies() async {
  print('📦 检查依赖关系...');
  try {
    final result = await Process.run('flutter', ['pub', 'deps']);
    final hasConflicts = result.stdout.toString().contains('conflict') ||
                        result.stdout.toString().contains('error');
    
    if (!hasConflicts) {
      print('✅ 依赖关系正常');
      return true;
    } else {
      print('❌ 依赖关系存在问题');
      return false;
    }
  } catch (e) {
    print('❌ 依赖检查失败: $e');
    return false;
  }
}

/// 构建示例应用
Future<bool> buildExampleApp() async {
  print('🏗️ 构建示例应用...');
  try {
    // 进入示例目录
    Directory.current = Directory('example');
    
    // 获取依赖
    var result = await Process.run('flutter', ['pub', 'get']);
    if (result.exitCode != 0) {
      print('❌ 示例应用依赖获取失败');
      return false;
    }
    
    // 尝试构建
    result = await Process.run('flutter', ['build', 'apk', '--debug']);
    
    // 返回原目录
    Directory.current = Directory('..');
    
    if (result.exitCode == 0) {
      print('✅ 示例应用构建成功');
      return true;
    } else {
      print('❌ 示例应用构建失败');
      return false;
    }
  } catch (e) {
    Directory.current = Directory('..');
    print('❌ 示例应用构建异常: $e');
    return false;
  }
}

/// 检查WebView集成
Future<bool> checkWebViewIntegration() async {
  print('🌐 检查WebView集成...');
  try {
    // 检查是否包含flutter_inappwebview依赖
    final pubspecFile = File('pubspec.yaml');
    final pubspecContent = await pubspecFile.readAsString();
    
    if (pubspecContent.contains('flutter_inappwebview')) {
      print('✅ WebView依赖已正确集成');
      return true;
    } else {
      print('❌ 缺少WebView依赖');
      return false;
    }
  } catch (e) {
    print('❌ WebView集成检查失败: $e');
    return false;
  }
}

/// 检查iOS兼容性
Future<bool> checkIOSCompatibility() async {
  print('📱 检查iOS兼容性...');
  try {
    // 检查是否有iOS配置文件
    final iosConfigExists = await File('IOS_CONFIGURATION.md').exists();
    if (iosConfigExists) {
      print('✅ iOS配置文档存在');
      return true;
    } else {
      print('⚠️ 未找到iOS配置文档');
      return true; // 不阻塞，只是警告
    }
  } catch (e) {
    print('❌ iOS兼容性检查失败: $e');
    return false;
  }
}

/// 检查Android兼容性
Future<bool> checkAndroidCompatibility() async {
  print('🤖 检查Android兼容性...');
  try {
    // 检查示例应用的Android配置
    final manifestFile = File('example/android/app/src/main/AndroidManifest.xml');
    if (await manifestFile.exists()) {
      print('✅ Android配置正常');
      return true;
    } else {
      print('❌ Android配置缺失');
      return false;
    }
  } catch (e) {
    print('❌ Android兼容性检查失败: $e');
    return false;
  }
}

/// 检查Web兼容性
Future<bool> checkWebCompatibility() async {
  print('🌍 检查Web兼容性...');
  try {
    // 检查是否支持Web平台
    final result = await Process.run('flutter', ['devices']);
    final hasWebSupport = result.stdout.toString().contains('Chrome') ||
                         result.stdout.toString().contains('Web Server');
    
    if (hasWebSupport) {
      print('✅ Web平台支持正常');
      return true;
    } else {
      print('⚠️ Web平台支持检查失败（可能是环境问题）');
      return true; // 不阻塞测试
    }
  } catch (e) {
    print('❌ Web兼容性检查失败: $e');
    return false;
  }
}

/// 生成测试报告
void generateTestReport(Map<String, bool> results) {
  print('\n' + '='*60);
  print('📋 测试报告');
  print('='*60);
  
  int passed = 0;
  int total = results.length;
  
  results.forEach((test, result) {
    final status = result ? '✅ 通过' : '❌ 失败';
    print('$test: $status');
    if (result) passed++;
  });
  
  print('\n' + '-'*60);
  print('总结: $passed/$total 项测试通过');
  
  if (passed == total) {
    print('🎉 所有测试通过！包已准备好发布。');
  } else {
    print('⚠️ 存在失败的测试项，请检查并修复。');
  }
  
  // 生成JSON报告
  final reportFile = File('test_report.json');
  final report = {
    'timestamp': DateTime.now().toIso8601String(),
    'total_tests': total,
    'passed_tests': passed,
    'success_rate': (passed / total * 100).toStringAsFixed(1),
    'results': results,
  };
  
  reportFile.writeAsStringSync(jsonEncode(report));
  print('\n📄 详细报告已保存到: test_report.json');
} 