import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vr_word_guesser/main.dart';

void main() {
  testWidgets('starts on the difficulty screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Choose Difficulty'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Easy'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Medium'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Hard'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Animals'), findsNothing);
  });

  testWidgets('moves from difficulty to category chooser', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Easy'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Category'), findsOneWidget);
    for (final category in categories) {
      expect(find.widgetWithText(FilledButton, category), findsOneWidget);
    }
    expect(find.widgetWithText(OutlinedButton, 'Back'), findsOneWidget);
  });

  testWidgets('moves from category to picker and back', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Easy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Animals'));
    await tester.pumpAndSettle();

    expect(find.text('Your Word/Phrase'), findsOneWidget);
    expect(find.text('Easy - Animals'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'New Word/Phrase'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Back'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Start Over'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Category'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Animals'), findsOneWidget);
  });

  testWidgets('start over returns to difficulty chooser', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Easy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Animals'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Start Over'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Difficulty'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Easy'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Animals'), findsNothing);
  });

  testWidgets('new word phrase changes the displayed phrase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Easy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Animals'));
    await tester.pumpAndSettle();

    final firstPhrase = _currentPhraseText(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New Word/Phrase'));
    await tester.pumpAndSettle();

    expect(_currentPhraseText(tester), isNot(firstPhrase));
  });
}

String _currentPhraseText(WidgetTester tester) {
  final textWidget = tester.widget<Text>(
    find.byKey(const ValueKey('current-phrase')),
  );
  return textWidget.data ?? '';
}
