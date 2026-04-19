import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

const List<String> difficulties = ['Easy', 'Medium', 'Hard'];

const String genericBucket = 'Generic';
const String emotionalBucket = 'Emotional';
const String requiredAnimalCategory = 'Animals';

class PhraseData {
  const PhraseData({
    required this.categories,
    required this.nounsByCategory,
    required this.genericAdjectives,
    required this.emotionalAdjectives,
    required this.genericGerunds,
    required this.emotionalGerunds,
  });

  final List<String> categories;
  final Map<String, List<String>> nounsByCategory;
  final List<String> genericAdjectives;
  final List<String> emotionalAdjectives;
  final List<String> genericGerunds;
  final List<String> emotionalGerunds;
}

class PhraseLoadException implements Exception {
  const PhraseLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<PhraseData> loadPhraseData({
  String assetPath = 'assets/phrases.json',
}) async {
  final jsonText = await rootBundle.loadString(assetPath);
  return parsePhraseData(jsonText);
}

PhraseData parsePhraseData(String jsonText) {
  final Object? decoded;

  try {
    decoded = jsonDecode(jsonText);
  } on FormatException catch (error) {
    throw PhraseLoadException(
      'Phrase data is not valid JSON: ${error.message}',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    throw const PhraseLoadException('Phrase data must be a JSON object.');
  }

  final nouns = _readNounLists(decoded);
  final adjectives = _readStringListsByKey(
    decoded,
    sectionName: 'Adjectives',
    requiredKeys: const [genericBucket, emotionalBucket],
  );
  final gerunds = _readStringListsByKey(
    decoded,
    sectionName: 'Gerunds',
    requiredKeys: const [genericBucket, emotionalBucket],
  );

  return PhraseData(
    categories: List<String>.unmodifiable(nouns.keys),
    nounsByCategory: nouns,
    genericAdjectives: adjectives[genericBucket]!,
    emotionalAdjectives: adjectives[emotionalBucket]!,
    genericGerunds: gerunds[genericBucket]!,
    emotionalGerunds: gerunds[emotionalBucket]!,
  );
}

Map<String, List<String>> _readNounLists(Map<String, dynamic> json) {
  final nouns = _readStringListsFromSection(json, sectionName: 'Nouns');

  if (nouns.isEmpty) {
    throw const PhraseLoadException('Nouns needs at least one category.');
  }

  if (!nouns.containsKey(requiredAnimalCategory)) {
    throw const PhraseLoadException('Nouns must include Animals.');
  }

  return nouns;
}

Map<String, List<String>> _readStringListsByKey(
  Map<String, dynamic> json, {
  required String sectionName,
  required List<String> requiredKeys,
}) {
  final section = _readStringListsFromSection(json, sectionName: sectionName);

  for (final key in requiredKeys) {
    if (!section.containsKey(key)) {
      throw PhraseLoadException('Missing phrase list for $sectionName $key.');
    }
  }

  return {for (final key in requiredKeys) key: section[key]!};
}

Map<String, List<String>> _readStringListsFromSection(
  Map<String, dynamic> json, {
  required String sectionName,
}) {
  final rawSection = json[sectionName];
  if (rawSection is! Map<String, dynamic>) {
    throw PhraseLoadException('Missing $sectionName phrase data.');
  }

  final section = <String, List<String>>{};

  for (final entry in rawSection.entries) {
    final key = entry.key.trim();
    if (key.isEmpty) {
      throw PhraseLoadException(
        '$sectionName category names must be non-empty.',
      );
    }

    final rawList = entry.value;
    if (rawList is! List<dynamic>) {
      throw PhraseLoadException('Missing phrase list for $sectionName $key.');
    }

    final phrases = <String>[];
    for (final rawPhrase in rawList) {
      if (rawPhrase is! String || rawPhrase.trim().isEmpty) {
        throw PhraseLoadException(
          'Every phrase in $sectionName $key must be non-empty text.',
        );
      }

      phrases.add(rawPhrase.trim());
    }

    if (phrases.isEmpty) {
      throw PhraseLoadException('$sectionName $key needs at least one phrase.');
    }

    section[key] = phrases;
  }

  return section;
}

List<String> buildPhrasePool({
  required PhraseData phraseData,
  required String difficulty,
  required String category,
}) {
  final nouns = phraseData.nounsByCategory[category] ?? const <String>[];

  return switch (difficulty) {
    'Easy' => List<String>.of(nouns),
    'Medium' => _combineMediumPhrases(phraseData, nouns),
    'Hard' => _combineHardPhrases(phraseData, nouns),
    _ => const <String>[],
  };
}

List<String> _combineMediumPhrases(PhraseData phraseData, List<String> nouns) {
  final phrases = <String>[];
  final adjectives = [
    ...phraseData.genericAdjectives,
    ...phraseData.emotionalAdjectives,
  ];

  for (final adjective in adjectives) {
    for (final noun in nouns) {
      phrases.add('$adjective $noun');
    }
  }

  return phrases;
}

List<String> _combineHardPhrases(PhraseData phraseData, List<String> nouns) {
  final phrases = <String>[];
  final allowedBuckets = [
    (
      gerunds: phraseData.genericGerunds,
      adjectives: phraseData.genericAdjectives,
    ),
    (
      gerunds: phraseData.genericGerunds,
      adjectives: phraseData.emotionalAdjectives,
    ),
    (
      gerunds: phraseData.emotionalGerunds,
      adjectives: phraseData.genericAdjectives,
    ),
  ];

  for (final bucketPair in allowedBuckets) {
    for (final gerund in bucketPair.gerunds) {
      for (final adjective in bucketPair.adjectives) {
        for (final noun in nouns) {
          phrases.add('$gerund $adjective $noun');
        }
      }
    }
  }

  return phrases;
}

enum AppScreen { difficulty, category, picker }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Guesser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PhraseDataLoader(),
    );
  }
}

class PhraseDataLoader extends StatefulWidget {
  const PhraseDataLoader({super.key});

  @override
  State<PhraseDataLoader> createState() => _PhraseDataLoaderState();
}

class _PhraseDataLoaderState extends State<PhraseDataLoader> {
  late final Future<PhraseData> _phraseDataFuture;

  @override
  void initState() {
    super.initState();
    _phraseDataFuture = loadPhraseData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PhraseData>(
      future: _phraseDataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorScreen(message: snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const LoadingScreen();
        }

        return WordChooserPage(phraseData: snapshot.requireData);
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Phrase data problem',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WordChooserPage extends StatefulWidget {
  const WordChooserPage({super.key, required this.phraseData});

  final PhraseData phraseData;

  @override
  State<WordChooserPage> createState() => _WordChooserPageState();
}

class _WordChooserPageState extends State<WordChooserPage> {
  final Random _random = Random();

  AppScreen _screen = AppScreen.difficulty;
  String? _selectedDifficulty;
  String? _selectedCategory;
  String? _currentPhrase;
  List<String> _remainingPhrases = [];

  void _selectDifficulty(String difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
      _selectedCategory = null;
      _currentPhrase = null;
      _remainingPhrases = [];
      _screen = AppScreen.category;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _screen = AppScreen.picker;
      _reshufflePhrases();
      _currentPhrase = _drawNextPhrase();
    });
  }

  void _goBackToDifficulty() {
    setState(() {
      _selectedDifficulty = null;
      _selectedCategory = null;
      _currentPhrase = null;
      _remainingPhrases = [];
      _screen = AppScreen.difficulty;
    });
  }

  void _goBackToCategory() {
    setState(() {
      _selectedCategory = null;
      _currentPhrase = null;
      _remainingPhrases = [];
      _screen = AppScreen.category;
    });
  }

  void _showNextPhrase() {
    setState(() {
      _currentPhrase = _drawNextPhrase();
    });
  }

  void _reshufflePhrases() {
    final difficulty = _selectedDifficulty;
    final category = _selectedCategory;
    if (difficulty == null || category == null) {
      _remainingPhrases = [];
      return;
    }

    _remainingPhrases = buildPhrasePool(
      phraseData: widget.phraseData,
      difficulty: difficulty,
      category: category,
    )..shuffle(_random);
  }

  String? _drawNextPhrase() {
    if (_remainingPhrases.isEmpty) {
      _reshufflePhrases();
    }

    if (_remainingPhrases.isEmpty) {
      return null;
    }

    return _remainingPhrases.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (_screen) {
      AppScreen.difficulty => _buildDifficultyScreen(context),
      AppScreen.category => _buildCategoryScreen(context),
      AppScreen.picker => _buildPickerScreen(context),
    };

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDifficultyScreen(BuildContext context) {
    return _ScreenLayout(
      key: const ValueKey('difficulty-screen'),
      title: 'Choose Difficulty',
      subtitle: 'Pick a level to start.',
      children: [
        for (final difficulty in difficulties)
          _PrimaryButton(
            label: difficulty,
            onPressed: () => _selectDifficulty(difficulty),
          ),
      ],
    );
  }

  Widget _buildCategoryScreen(BuildContext context) {
    return _ScreenLayout(
      key: const ValueKey('category-screen'),
      title: 'Choose Category',
      subtitle: _selectedDifficulty ?? '',
      children: [
        for (final category in widget.phraseData.categories)
          _PrimaryButton(
            label: category,
            onPressed: () => _selectCategory(category),
          ),
        _SecondaryButton(label: 'Back', onPressed: _goBackToDifficulty),
      ],
    );
  }

  Widget _buildPickerScreen(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return _ScreenLayout(
      key: const ValueKey('picker-screen'),
      title: 'Your Word/Phrase',
      subtitle: '${_selectedDifficulty ?? ''} - ${_selectedCategory ?? ''}',
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _currentPhrase ?? 'No phrase available',
            key: const ValueKey('current-phrase'),
            textAlign: TextAlign.center,
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _PrimaryButton(label: 'New Word/Phrase', onPressed: _showNextPhrase),
        _SecondaryButton(label: 'Back', onPressed: _goBackToCategory),
        _SecondaryButton(label: 'Start Over', onPressed: _goBackToDifficulty),
      ],
    );
  }
}

class _ScreenLayout extends StatelessWidget {
  const _ScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              ...children.expand(
                (child) => [child, const SizedBox(height: 14)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Theme.of(context).textTheme.titleLarge,
      ),
      child: Text(label),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
      child: Text(label),
    );
  }
}
