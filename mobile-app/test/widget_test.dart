import 'package:flutter_test/flutter_test.dart';
import 'package:svara_darshini/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SvaraDarshiniApp());

    // Verify that the app renders the title
    expect(find.text('Svara Darshini'), findsOneWidget);
  });
}
