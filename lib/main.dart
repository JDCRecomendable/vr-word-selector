import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

const List<String> difficulties = ['Easy', 'Medium', 'Hard'];

const List<String> categories = [
  'Animals',
  'Everyday Foods',
  'Household Objects',
  'Jobs',
  'Sports',
];

const Map<String, Map<String, List<String>>> phraseBank = {
  'Easy': {
    'Animals': ['Cat', 'Dog', 'Fish', 'Bird', 'Rabbit'],
    'Everyday Foods': ['Apple', 'Rice', 'Bread', 'Egg', 'Soup'],
    'Household Objects': ['Chair', 'Lamp', 'Cup', 'Table', 'Pillow'],
    'Jobs': ['Teacher', 'Doctor', 'Chef', 'Farmer', 'Painter'],
    'Sports': ['Soccer', 'Running', 'Tennis', 'Swimming', 'Basketball'],
  },
  'Medium': {
    'Animals': ['Dolphin', 'Kangaroo', 'Penguin', 'Giraffe', 'Octopus'],
    'Everyday Foods': ['Pancakes', 'Spaghetti', 'Sandwich', 'Omelet', 'Salad'],
    'Household Objects': [
      'Vacuum cleaner',
      'Bookshelf',
      'Toothbrush',
      'Remote control',
      'Doormat',
    ],
    'Jobs': [
      'Firefighter',
      'Mechanic',
      'Photographer',
      'Librarian',
      'Carpenter',
    ],
    'Sports': [
      'Volleyball',
      'Skateboarding',
      'Baseball',
      'Cycling',
      'Badminton',
    ],
  },
  'Hard': {
    'Animals': [
      'Chameleon',
      'Porcupine',
      'Hammerhead shark',
      'Komodo dragon',
      'Hippopotamus',
    ],
    'Everyday Foods': [
      'Blueberry muffin',
      'Vegetable stir fry',
      'Chicken quesadilla',
      'Garlic mashed potatoes',
      'Peanut butter toast',
    ],
    'Household Objects': [
      'Smoke detector',
      'Laundry basket',
      'Measuring tape',
      'Extension cord',
      'Ironing board',
    ],
    'Jobs': [
      'Marine biologist',
      'Air traffic controller',
      'Graphic designer',
      'Emergency dispatcher',
      'Software developer',
    ],
    'Sports': [
      'Rock climbing',
      'Water polo',
      'Table tennis',
      'Figure skating',
      'Cross-country skiing',
    ],
  },
};

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
      home: const WordChooserPage(),
    );
  }
}

class WordChooserPage extends StatefulWidget {
  const WordChooserPage({super.key});

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
    final phrases = phraseBank[_selectedDifficulty]?[_selectedCategory] ?? [];
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
