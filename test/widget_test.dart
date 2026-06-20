import 'package:flutter_test/flutter_test.dart';
import 'package:langferry/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WebLingoApp());
    await tester.pumpAndSettle();
  });
}