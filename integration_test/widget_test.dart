import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fgs/main.dart';
import 'package:fgs/golden_target.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  goldenFileComparator = HostGoldenFileComparator();

  testWidgets('Golden basic', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await expectLater(find.byType(MyApp), matchesGoldenFile('basic.png'));
  });
}
