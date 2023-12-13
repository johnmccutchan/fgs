import 'dart:async';
import 'dart:convert';

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fgs/main.dart';
import 'package:fgs/golden_target.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  goldenFileComparator = VmServiceGoldenFileComparator();

  testWidgets('Golden basic', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await expectLater(find.byType(MyApp), matchesGoldenFile('basic.png'));
  });

  testWidgets('Second method just for shits', (WidgetTester tester) async {
    await tester.pumpWidget(Container(color: Colors.red));

    await expectLater(find.byType(Container), matchesGoldenFile('solid_color.png'));
  });

  tearDownAll(() {
    developer.postEvent('fgs.done', {});
  });
}
