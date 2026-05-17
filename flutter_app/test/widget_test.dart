import 'package:flutter_test/flutter_test.dart';
import 'package:liberty_reach/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify the app renders something
    expect(find.byType(MyApp), findsOneWidget);
  });
}
