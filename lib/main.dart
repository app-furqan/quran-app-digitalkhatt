import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quran_renderer.dart';
import 'quran_page_widget_ffi.dart';
import 'surah_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler
  FlutterError.onError = (details) {
    print('FlutterError: ${details.exception}');
    print('Stack: ${details.stack}');
  };

  try {
    // Load font and initialize renderer
    print('Loading font...');
    final fontData = await rootBundle.load('assets/fonts/digitalkhatt.otf');
    print('Font loaded, initializing renderer...');
    await QuranRenderer.initialize(fontData.buffer.asUint8List());
    print('Renderer initialized successfully!');

    runApp(const QuranApp());
  } catch (e, stackTrace) {
    print('FATAL ERROR in main: $e');
    print('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Fatal error: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Reader',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
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
      home: QuranReaderPage(
        onThemeModeChanged: _changeThemeMode,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class QuranReaderPage extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const QuranReaderPage({
    super.key,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
  });

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _tajweedEnabled = true;
  int _fontSize = 0; // 0 = auto-fit (default)

  static const int totalPages = 604;

  // Light mode = white, Dark mode = black
  int getLightBackgroundColor() => 0xFFFFFFFF; // Pure white
  int getDarkBackgroundColor() => 0x000000FF; // True black

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

  void _showSurahList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahListPage(
          onSurahSelected: (pageIndex) {
            _goToPage(pageIndex);
          },
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                // Theme mode
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 16),
                      ),
                    ],
                    selected: {widget.currentThemeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      widget.onThemeModeChanged(newSelection.first);
                    },
                  ),
                ),
                const Divider(),
                // Font size
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Font Size'),
                  subtitle: Slider(
                    value: _fontSize.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: _fontSize == 0 ? 'Auto' : '${_fontSize}px',
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _fontSize = value.round();
                        });
                      });
                    },
                  ),
                  trailing: Text(
                    _fontSize == 0 ? 'Auto' : '${_fontSize}px',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // Tajweed toggle
                SwitchListTile(
                  secondary: const Icon(Icons.palette),
                  title: const Text('Tajweed Colors'),
                  subtitle: const Text('Show color-coded tajweed rules'),
                  value: _tajweedEnabled,
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _tajweedEnabled = value;
                      });
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Page ${_currentPage + 1} of $totalPages'),
        centerTitle: true,
        actions: [
          // Surah list button
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Surahs',
            onPressed: _showSurahList,
          ),
          // Go to page button
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Go to page',
            onPressed: _showGoToPageDialog,
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _showSettings,
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
            key: ValueKey(
              'page_${index}_${_tajweedEnabled}_${_fontSize}',
            ),
            pageIndex: index,
            tajweed: _tajweedEnabled,
            fontSize: _fontSize,
            lightBackgroundColor: getLightBackgroundColor(),
            darkBackgroundColor: getDarkBackgroundColor(),
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
