import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vr_word_guesser/main.dart';

void main() {
  testWidgets('loads phrase data and starts on the difficulty screen', (
    WidgetTester tester,
  ) async {
    await _pumpLoadedAssetApp(tester);

    expect(find.text('Choose Difficulty'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Easy'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Medium'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Hard'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Animals'), findsNothing);
  });

  testWidgets('moves from difficulty to category chooser', (
    WidgetTester tester,
  ) async {
    await _pumpChooserApp(tester);

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
    await _pumpChooserApp(tester);

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
    await _pumpChooserApp(tester);

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
    await _pumpChooserApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Easy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Animals'));
    await tester.pumpAndSettle();

    final firstPhrase = _currentPhraseText(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New Word/Phrase'));
    await tester.pumpAndSettle();

    expect(_currentPhraseText(tester), isNot(firstPhrase));
  });

  test('parsePhraseBank rejects missing categories', () {
    const jsonText = '''
{
  "Easy": {
    "Animals": ["Cat"],
    "Everyday Foods": ["Apple"],
    "Household Objects": ["Chair"],
    "Jobs": ["Teacher"],
    "Sports": ["Soccer"]
  },
  "Medium": {
    "Animals": ["Dolphin"],
    "Everyday Foods": ["Pancakes"],
    "Household Objects": ["Vacuum cleaner"],
    "Jobs": ["Firefighter"]
  },
  "Hard": {
    "Animals": ["Chameleon"],
    "Everyday Foods": ["Blueberry muffin"],
    "Household Objects": ["Smoke detector"],
    "Jobs": ["Marine biologist"],
    "Sports": ["Rock climbing"]
  }
}
''';

    expect(
      () => parsePhraseBank(jsonText),
      throwsA(isA<PhraseLoadException>()),
    );
  });

  test('parsePhraseBank rejects empty phrase lists', () {
    const jsonText = '''
{
  "Easy": {
    "Animals": [],
    "Everyday Foods": ["Apple"],
    "Household Objects": ["Chair"],
    "Jobs": ["Teacher"],
    "Sports": ["Soccer"]
  },
  "Medium": {
    "Animals": ["Dolphin"],
    "Everyday Foods": ["Pancakes"],
    "Household Objects": ["Vacuum cleaner"],
    "Jobs": ["Firefighter"],
    "Sports": ["Volleyball"]
  },
  "Hard": {
    "Animals": ["Chameleon"],
    "Everyday Foods": ["Blueberry muffin"],
    "Household Objects": ["Smoke detector"],
    "Jobs": ["Marine biologist"],
    "Sports": ["Rock climbing"]
  }
}
''';

    expect(
      () => parsePhraseBank(jsonText),
      throwsA(isA<PhraseLoadException>()),
    );
  });
}

Future<void> _pumpLoadedAssetApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());

  for (var i = 0; i < 20; i += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('Choose Difficulty').evaluate().isNotEmpty) {
      return;
    }
  }

  fail('The app did not finish loading phrase data.');
}

Future<void> _pumpChooserApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: WordChooserPage(phraseBank: _testPhraseBank)),
  );
  await tester.pump();
}

String _currentPhraseText(WidgetTester tester) {
  final textWidget = tester.widget<Text>(
    find.byKey(const ValueKey('current-phrase')),
  );
  return textWidget.data ?? '';
}

final PhraseBank _testPhraseBank = parsePhraseBank('''
{
  "Easy": {
    "Animals": ["Cat", "Dog"],
    "Everyday Foods": ["Apple"],
    "Household Objects": ["Chair"],
    "Jobs": ["Teacher"],
    "Sports": ["Soccer"]
  },
  "Medium": {
    "Animals": ["Dolphin"],
    "Everyday Foods": ["Pancakes"],
    "Household Objects": ["Vacuum cleaner"],
    "Jobs": ["Firefighter"],
    "Sports": ["Volleyball"]
  },
  "Hard": {
    "Animals": ["Chameleon"],
    "Everyday Foods": ["Blueberry muffin"],
    "Household Objects": ["Smoke detector"],
    "Jobs": ["Marine biologist"],
    "Sports": ["Rock climbing"]
  }
}
''');
