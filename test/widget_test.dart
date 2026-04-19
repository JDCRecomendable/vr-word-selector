import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final assetPhraseData = parsePhraseData(
      await rootBundle.loadString('assets/phrases.json'),
    );
    expect(assetPhraseData.categories, isNotEmpty);
    expect(assetPhraseData.categories, contains('Animals'));
  });

  testWidgets('moves from difficulty to category chooser', (
    WidgetTester tester,
  ) async {
    await _pumpChooserApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Easy'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Category'), findsOneWidget);
    for (final category in _testPhraseData.categories) {
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

  testWidgets('new word phrase avoids exact repeats while phrases remain', (
    WidgetTester tester,
  ) async {
    await _pumpChooserApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Easy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Animals'));
    await tester.pumpAndSettle();

    final seenPhrases = <String>{_currentPhraseText(tester)};

    await tester.tap(find.widgetWithText(FilledButton, 'New Word/Phrase'));
    await tester.pumpAndSettle();

    expect(seenPhrases.add(_currentPhraseText(tester)), isTrue);
  });

  testWidgets('easy picker displays a noun-only phrase', (
    WidgetTester tester,
  ) async {
    await _pumpChooserApp(tester);

    await _openPicker(tester, difficulty: 'Easy', category: 'Animals');

    expect(_currentPhraseText(tester).split(' '), hasLength(1));
  });

  testWidgets('medium picker displays adjective and noun', (
    WidgetTester tester,
  ) async {
    await _pumpChooserApp(tester);

    await _openPicker(tester, difficulty: 'Medium', category: 'Animals');

    expect(_currentPhraseText(tester).split(' '), hasLength(2));
  });

  testWidgets('hard picker displays gerund adjective and noun', (
    WidgetTester tester,
  ) async {
    await _pumpChooserApp(tester);

    await _openPicker(tester, difficulty: 'Hard', category: 'Animals');

    expect(_currentPhraseText(tester).split(' '), hasLength(3));
  });

  test(
    'hard phrases never combine emotional gerund and emotional adjective',
    () {
      final phrases = buildPhrasePool(
        phraseData: _testPhraseData,
        difficulty: 'Hard',
        category: 'Animals',
      );

      expect(phrases, isNotEmpty);
      expect(phrases, isNot(contains('Crying Sad Cat')));
      expect(phrases, isNot(contains('Crying Sad Dog')));
    },
  );

  test(
    'buildPhrasePool creates expected Easy Medium and Hard phrase shapes',
    () {
      expect(
        buildPhrasePool(
          phraseData: _testPhraseData,
          difficulty: 'Easy',
          category: 'Animals',
        ),
        unorderedEquals(['Cat', 'Dog']),
      );

      expect(
        buildPhrasePool(
          phraseData: _testPhraseData,
          difficulty: 'Medium',
          category: 'Animals',
        ),
        unorderedEquals(['Bright Cat', 'Bright Dog', 'Sad Cat', 'Sad Dog']),
      );

      expect(
        buildPhrasePool(
          phraseData: _testPhraseData,
          difficulty: 'Hard',
          category: 'Animals',
        ),
        unorderedEquals([
          'Running Bright Cat',
          'Running Bright Dog',
          'Running Sad Cat',
          'Running Sad Dog',
          'Crying Bright Cat',
          'Crying Bright Dog',
        ]),
      );
    },
  );

  test('parsePhraseData rejects missing schema keys', () {
    const jsonText = '''
{
  "Nouns": {
    "Animals": ["Cat"],
    "Everyday Foods": ["Apple"],
    "Household Objects": ["Chair"],
    "Jobs": ["Teacher"],
    "Sports": ["Soccer"]
  },
  "Adjectives": {
    "Generic": ["Bright"],
    "Emotional": ["Sad"]
  }
}
''';

    expect(
      () => parsePhraseData(jsonText),
      throwsA(isA<PhraseLoadException>()),
    );
  });

  test('parsePhraseData rejects empty required lists', () {
    const jsonText = '''
{
  "Nouns": {
    "Animals": [],
    "Everyday Foods": ["Apple"],
    "Household Objects": ["Chair"],
    "Jobs": ["Teacher"],
    "Sports": ["Soccer"]
  },
  "Adjectives": {
    "Generic": ["Bright"],
    "Emotional": ["Sad"]
  },
  "Gerunds": {
    "Generic": ["Running"],
    "Emotional": ["Crying"]
  }
}
''';

    expect(
      () => parsePhraseData(jsonText),
      throwsA(isA<PhraseLoadException>()),
    );
  });

  test('parsePhraseData derives categories from Nouns in JSON order', () {
    final phraseData = parsePhraseData('''
{
  "Nouns": {
    "Animals": ["Cat"],
    "Vehicles": ["Truck"]
  },
  "Adjectives": {
    "Generic": ["Bright"],
    "Emotional": ["Sad"]
  },
  "Gerunds": {
    "Generic": ["Running"],
    "Emotional": ["Crying"]
  }
}
''');

    expect(phraseData.categories, ['Animals', 'Vehicles']);
    expect(
      buildPhrasePool(
        phraseData: phraseData,
        difficulty: 'Easy',
        category: 'Vehicles',
      ),
      ['Truck'],
    );
  });

  test('parsePhraseData rejects Nouns without Animals', () {
    const jsonText = '''
{
  "Nouns": {
    "Vehicles": ["Truck"]
  },
  "Adjectives": {
    "Generic": ["Bright"],
    "Emotional": ["Sad"]
  },
  "Gerunds": {
    "Generic": ["Running"],
    "Emotional": ["Crying"]
  }
}
''';

    expect(
      () => parsePhraseData(jsonText),
      throwsA(isA<PhraseLoadException>()),
    );
  });

  test('parsePhraseData rejects empty Nouns object', () {
    const jsonText = '''
{
  "Nouns": {},
  "Adjectives": {
    "Generic": ["Bright"],
    "Emotional": ["Sad"]
  },
  "Gerunds": {
    "Generic": ["Running"],
    "Emotional": ["Crying"]
  }
}
''';

    expect(
      () => parsePhraseData(jsonText),
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
    MaterialApp(home: WordChooserPage(phraseData: _testPhraseData)),
  );
  await tester.pump();
}

Future<void> _openPicker(
  WidgetTester tester, {
  required String difficulty,
  required String category,
}) async {
  await tester.tap(find.widgetWithText(FilledButton, difficulty));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, category));
  await tester.pumpAndSettle();
}

String _currentPhraseText(WidgetTester tester) {
  final textWidget = tester.widget<Text>(
    find.byKey(const ValueKey('current-phrase')),
  );
  return textWidget.data ?? '';
}

final PhraseData _testPhraseData = parsePhraseData('''
{
  "Nouns": {
    "Animals": ["Cat", "Dog"],
    "Everyday Foods": ["Apple"],
    "Household Objects": ["Chair"],
    "Jobs": ["Teacher"],
    "Sports": ["Soccer"]
  },
  "Adjectives": {
    "Generic": ["Bright"],
    "Emotional": ["Sad"]
  },
  "Gerunds": {
    "Generic": ["Running"],
    "Emotional": ["Crying"]
  }
}
''');
