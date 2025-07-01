import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_remote_config/src/widgets/internal_widgets.dart';

void main() {
  group('AppLoadingWidget Tests', () {
    testWidgets('现代风格加载动画应该正确渲染', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(
              style: LoadingStyle.modern,
              primaryColor: Colors.blue,
              backgroundColor: Colors.white,
              size: 80,
            ),
          ),
        ),
      );

      // 验证容器存在
      expect(find.byType(Container), findsWidgets);
      
      // 验证动画控制器正常工作
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      
      // 验证没有文字显示
      expect(find.text('加载'), findsNothing);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('极简风格加载动画应该正确渲染', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(
              style: LoadingStyle.minimal,
              primaryColor: Colors.green,
              size: 60,
            ),
          ),
        ),
      );

      // 验证CircularProgressIndicator存在
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // 验证动画正常工作
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('优雅风格加载动画应该正确渲染', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(
              style: LoadingStyle.elegant,
              primaryColor: Colors.purple,
              backgroundColor: Colors.black,
              size: 100,
            ),
          ),
        ),
      );

      // 验证容器存在
      expect(find.byType(Container), findsWidgets);
      
      // 验证动画正常工作
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('平滑风格加载动画应该正确渲染', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(
              style: LoadingStyle.smooth,
              primaryColor: Colors.orange,
              size: 90,
            ),
          ),
        ),
      );

      // 验证CustomPaint存在（可能有多个，因为Container也会创建CustomPaint）
      expect(find.byType(CustomPaint), findsWidgets);
      
      // 验证动画正常工作
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('默认样式应该使用现代风格', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(),
          ),
        ),
      );

      // 验证默认样式正确渲染
      expect(find.byType(Container), findsWidgets);
      
      // 验证动画正常工作
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('加载动画不应该显示任何文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(
              style: LoadingStyle.modern,
            ),
          ),
        ),
      );

      // 验证没有任何文字显示
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('加载动画不应该显示任何按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(
              style: LoadingStyle.modern,
            ),
          ),
        ),
      );

      // 验证没有任何按钮显示
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });
  });
} 