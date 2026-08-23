import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/main.dart';

void main() {
  testWidgets('App boots to splash', (tester) async {
    await tester.pumpWidget(const KaamWalaApp());
    expect(find.text('KaamWala'), findsOneWidget);
  });
}
