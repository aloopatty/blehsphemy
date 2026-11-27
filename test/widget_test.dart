import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studygram/features/app/studygram_app.dart';

void main() {
  testWidgets('StudyGram root renders without exceptions', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: StudyGramApp(home: Scaffold(body: Text('StudyGram smoke test'))),
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('StudyGram smoke test'), findsOneWidget);
  });
}
