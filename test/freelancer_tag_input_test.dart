import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/freelancer/widgets/tag_input_field.dart';

void main() {
  testWidgets('empty field plus opens the add dialog', (tester) async {
    String? added;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagInputField(
            values: const [],
            hint: 'Add skill',
            addTooltip: 'Add skill',
            onAdd: (value) => added = value,
            onRemove: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Add skill'), findsWidgets);

    await tester.enterText(find.byType(TextField).last, 'Flutter');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(added, 'Flutter');
  });

  testWidgets('typed value is added without the dialog', (tester) async {
    String? added;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagInputField(
            values: const [],
            hint: 'Add skill',
            addTooltip: 'Add skill',
            onAdd: (value) => added = value,
            onRemove: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Dart');
    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await tester.pumpAndSettle();

    expect(added, 'Dart');
  });
}
