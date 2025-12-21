import 'package:flutter/material.dart';
import 'quran_page_widget.dart';

void main() {
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const QuranReaderPage(),
    );
  }
}

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key});

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _tajweedEnabled = true;
  double _fontSize = 1.0; // Font scale factor (1.0 = default)

  static const int totalPages = 604;
  static const double _minFontSize = 0.5;
  static const double _maxFontSize = 2.0;
  static const double _fontSizeStep = 0.1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showGoToPageDialog() {
    final controller = TextEditingController(text: '${_currentPage + 1}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Page (1-$totalPages)',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null && page >= 1 && page <= totalPages) {
              Navigator.pop(context);
              _goToPage(page - 1);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= totalPages) {
                Navigator.pop(context);
                _goToPage(page - 1);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page ${_currentPage + 1} of $totalPages'),
        centerTitle: true,
        actions: [
          // Font size controls
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'Decrease font size',
            onPressed: _fontSize > _minFontSize
                ? () {
                    setState(() {
                      _fontSize = (_fontSize - _fontSizeStep).clamp(
                        _minFontSize,
                        _maxFontSize,
                      );
                    });
                  }
                : null,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _fontSize = 1.0; // Reset to default
              });
            },
            child: Tooltip(
              message: 'Font size (tap to reset)',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${(_fontSize * 100).round()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'Increase font size',
            onPressed: _fontSize < _maxFontSize
                ? () {
                    setState(() {
                      _fontSize = (_fontSize + _fontSizeStep).clamp(
                        _minFontSize,
                        _maxFontSize,
                      );
                    });
                  }
                : null,
          ),
          const VerticalDivider(
            width: 16,
            thickness: 1,
            indent: 12,
            endIndent: 12,
          ),
          // Tajweed toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tajweed', style: TextStyle(fontSize: 12)),
              Switch(
                value: _tajweedEnabled,
                onChanged: (value) {
                  setState(() {
                    _tajweedEnabled = value;
                  });
                },
              ),
            ],
          ),
          // Go to page button
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Go to page',
            onPressed: _showGoToPageDialog,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: totalPages,
        reverse: true, // RTL for Arabic
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return QuranPageWidget(
            pageIndex: index,
            tajweed: _tajweedEnabled,
            fontScale: _fontSize,
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'First page',
              onPressed: () => _goToPage(0),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous page',
              onPressed: _currentPage > 0
                  ? () => _goToPage(_currentPage - 1)
                  : null,
            ),
            Text(
              '${_currentPage + 1} / $totalPages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next page',
              onPressed: _currentPage < totalPages - 1
                  ? () => _goToPage(_currentPage + 1)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              tooltip: 'Last page',
              onPressed: () => _goToPage(totalPages - 1),
            ),
          ],
        ),
      ),
    );
  }
}
