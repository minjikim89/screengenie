import 'package:flutter_test/flutter_test.dart';
import 'package:screengenie/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ScreenGenieApp());
    expect(find.text('ScreenGenie'), findsOneWidget);
    expect(find.text('Start Genie'), findsOneWidget);
  });
}
