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
  late PageController _pageController;
  final TextEditingController _pageNumberController = TextEditingController();
  int _currentPage = 0;
  bool _tajweedEnabled = true;
  bool _justifyEnabled = true;
  int _fontSize = 0; // 0 = auto-fit (default)
  double _lineHeightDivisor =
      0.0; // 0 = no extra spacing (native handles defaults)
  bool? _wasLandscape; // Track orientation changes

  static const int totalPages = 604;

  // Light mode = white, Dark mode = black
  int getLightBackgroundColor() => 0xFFFFFFFF; // Pure white
  int getDarkBackgroundColor() => 0x000000FF; // True black

  @override
  void dispose() {
    _pageController.dispose();
    _pageNumberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _pageNumberController.text = '${_currentPage + 1}';
  }

  void _goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      _pageNumberController.text = '${page + 1}';
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _jumpToPageFromInput() {
    final raw = _pageNumberController.text.trim();
    final page = int.tryParse(raw);
    if (page == null) return;
    if (page < 1 || page > totalPages) return;
    _goToPage(page - 1);
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
                // Justification toggle
                SwitchListTile(
                  secondary: const Icon(Icons.format_align_justify),
                  title: const Text('Justify Text'),
                  subtitle: const Text('Enable kashida justification'),
                  value: _justifyEnabled,
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _justifyEnabled = value;
                      });
                    });
                  },
                ),
                const Divider(),
                // Line height divisor
                ListTile(
                  leading: const Icon(Icons.height),
                  title: const Text('Line Height Divisor'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: _lineHeightDivisor,
                        min: 0,
                        max: 15,
                        divisions: 30,
                        label: _lineHeightDivisor == 0
                            ? 'None'
                            : _lineHeightDivisor.toStringAsFixed(1),
                        onChanged: (value) {
                          setModalState(() {
                            setState(() {
                              _lineHeightDivisor = value;
                            });
                          });
                        },
                      ),
                      Text(
                        'Extra line spacing = height / divisor\n0 = no extra spacing (renderer default)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Text(
                    _lineHeightDivisor == 0
                        ? 'None'
                        : _lineHeightDivisor.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // On orientation change, recreate PageController to preserve current page
    if (_wasLandscape != null && _wasLandscape != isLandscape) {
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPage);
    }
    _wasLandscape = isLandscape;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: isLandscape
          ? null
          : AppBar(
              title: const Text('Quran Reader'),
              centerTitle: true,
              actions: [
                // Surah list button
                IconButton(
                  icon: const Icon(Icons.list),
                  tooltip: 'Surahs',
                  onPressed: _showSurahList,
                ),
                // Settings button
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: _showSettings,
                ),
              ],
            ),
      body: Column(
        children: [
          if (isLandscape)
            Material(
              elevation: 4,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.list, size: 20),
                          tooltip: 'Surahs',
                          onPressed: _showSurahList,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, size: 20),
                          tooltip: 'Settings',
                          onPressed: _showSettings,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Expanded(child: _buildNavigationControls(compact: true)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: PageView.builder(
              key: ValueKey('pageview_${isLandscape ? "land" : "port"}'),
              controller: _pageController,
              itemCount: totalPages,
              reverse: true, // RTL for Arabic
              physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _pageNumberController.text = '${_currentPage + 1}';
                });
              },
              itemBuilder: (context, index) {
                return QuranPageWidget(
                  key: ValueKey(
                    'page_${index}_${_tajweedEnabled}_${_justifyEnabled}_${_fontSize}_${_lineHeightDivisor}_${isLandscape}',
                  ),
                  pageIndex: index,
                  tajweed: _tajweedEnabled,
                  justify: _justifyEnabled,
                  fontSize: _fontSize,
                  lightBackgroundColor: getLightBackgroundColor(),
                  darkBackgroundColor: getDarkBackgroundColor(),
                  lineHeightDivisor: _lineHeightDivisor,
                );
              },
            ),
          ),
          if (!isLandscape)
            SafeArea(
              top: false,
              child: BottomAppBar(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: _buildNavigationControls(compact: false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls({required bool compact}) {
    return Row(
      mainAxisAlignment: compact
          ? MainAxisAlignment.end
          : MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.first_page, size: compact ? 20 : 24),
          tooltip: 'First page',
          onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
          padding: compact ? const EdgeInsets.all(4) : null,
          constraints: compact ? const BoxConstraints() : null,
        ),
        IconButton(
          icon: Icon(Icons.chevron_left, size: compact ? 20 : 24),
          tooltip: 'Next page (RTL)',
          onPressed: _currentPage < totalPages - 1
              ? () => _goToPage(_currentPage + 1)
              : null,
          padding: compact ? const EdgeInsets.all(4) : null,
          constraints: compact ? const BoxConstraints() : null,
        ),
        if (!compact) const SizedBox(width: 8),
        SizedBox(
          width: compact ? 60 : 84,
          child: TextField(
            controller: _pageNumberController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: compact ? const TextStyle(fontSize: 12) : null,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 4 : 8,
                vertical: compact ? 6 : 10,
              ),
            ),
            onSubmitted: (_) => _jumpToPageFromInput(),
          ),
        ),
        SizedBox(width: compact ? 4 : 8),
        Text(
          '/ $totalPages',
          style: compact ? const TextStyle(fontSize: 12) : null,
        ),
        if (!compact) const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.chevron_right, size: compact ? 20 : 24),
          tooltip: 'Previous page (RTL)',
          onPressed: _currentPage > 0
              ? () => _goToPage(_currentPage - 1)
              : null,
          padding: compact ? const EdgeInsets.all(4) : null,
          constraints: compact ? const BoxConstraints() : null,
        ),
        IconButton(
          icon: Icon(Icons.last_page, size: compact ? 20 : 24),
          tooltip: 'Last page',
          onPressed: _currentPage < totalPages - 1
              ? () => _goToPage(totalPages - 1)
              : null,
          padding: compact ? const EdgeInsets.all(4) : null,
          constraints: compact ? const BoxConstraints() : null,
        ),
      ],
    );
  }
}
