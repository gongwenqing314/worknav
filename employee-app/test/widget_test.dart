/// Widget 测试
/// 基础 Widget 测试，验证应用能正常启动
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worknav_employee_app/app.dart';

void main() {
  testWidgets('应用启动测试', (WidgetTester tester) async {
    // 构建应用并触发一帧
    await tester.pumpWidget(const WorkNavApp());

    // 验证应用标题
    expect(find.text('工作导航'), findsOneWidget);

    // 验证启动页存在
    expect(find.text('StepByStep'), findsOneWidget);
  });

  testWidgets('启动页显示欢迎信息', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkNavApp());

    // 等待动画播放
    await tester.pump(const Duration(milliseconds: 2000));

    // 验证欢迎信息
    expect(find.text('你好，开始今天的工作吧。'), findsOneWidget);
  });
}
