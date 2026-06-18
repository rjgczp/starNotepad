import 'package:flutter_test/flutter_test.dart';
import 'package:getx_notepad/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NotepadApp());
    await tester.pumpAndSettle();
    expect(find.text('📝 GetX 记事本'), findsOneWidget);
  });
}
