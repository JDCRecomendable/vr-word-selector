import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

typedef PhraseBank = Map<String, Map<String, List<String>>>;

const List<String> difficulties = ['Easy', 'Medium', 'Hard'];

const List<String> categories = [
  'Animals',
  'Everyday Foods',
  'Household Objects',
  'Jobs',
  'Sports',
];

class PhraseLoadException implements Exception {
  const PhraseLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<PhraseBank> loadPhraseBank({
  String assetPath = 'assets/phrases.json',
}) async {
  final jsonText = await rootBundle.loadString(assetPath);
  return parsePhraseBank(jsonText);
}

PhraseBank parsePhraseBank(String jsonText) {
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

  final phraseBank = <String, Map<String, List<String>>>{};

  for (final difficulty in difficulties) {
    final rawCategories = decoded[difficulty];
    if (rawCategories is! Map<String, dynamic>) {
      throw PhraseLoadException('Missing phrase data for $difficulty.');
    }

    final parsedCategories = <String, List<String>>{};

    for (final category in categories) {
      final rawPhrases = rawCategories[category];
      if (rawPhrases is! List<dynamic>) {
        throw PhraseLoadException(
          'Missing phrase list for $difficulty $category.',
        );
      }

      final phrases = <String>[];
      for (final rawPhrase in rawPhrases) {
        if (rawPhrase is! String || rawPhrase.trim().isEmpty) {
          throw PhraseLoadException(
            'Every phrase in $difficulty $category must be non-empty text.',
          );
        }

        phrases.add(rawPhrase.trim());
      }

      if (phrases.isEmpty) {
        throw PhraseLoadException(
          '$difficulty $category needs at least one phrase.',
        );
      }

      parsedCategories[category] = phrases;
    }

    phraseBank[difficulty] = parsedCategories;
  }

  return phraseBank;
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
      home: const PhraseBankLoader(),
    );
  }
}

class PhraseBankLoader extends StatefulWidget {
  const PhraseBankLoader({super.key});

  @override
  State<PhraseBankLoader> createState() => _PhraseBankLoaderState();
}

class _PhraseBankLoaderState extends State<PhraseBankLoader> {
  late final Future<PhraseBank> _phraseBankFuture;

  @override
  void initState() {
    super.initState();
    _phraseBankFuture = loadPhraseBank();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PhraseBank>(
      future: _phraseBankFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorScreen(message: snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const LoadingScreen();
        }

        return WordChooserPage(phraseBank: snapshot.requireData);
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
  const WordChooserPage({super.key, required this.phraseBank});

  final PhraseBank phraseBank;

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
    final phrases =
        widget.phraseBank[_selectedDifficulty]?[_selectedCategory] ?? [];
    _remainingPhrases = List<String>.of(phrases)..shuffle(_random);
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
        for (final category in categories)
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
