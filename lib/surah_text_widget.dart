import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'quran_renderer.dart';
import 'quran_database.dart';

/// Widget that displays a single ayah rendered with native FFI
class AyahWidget extends StatefulWidget {
  final String ayahText;
  final int fontSize;
  final int backgroundColor;
  final int renderWidth;

  const AyahWidget({
    super.key,
    required this.ayahText,
    required this.fontSize,
    required this.backgroundColor,
    required this.renderWidth,
  });

  @override
  State<AyahWidget> createState() => _AyahWidgetState();
}

class _AyahWidgetState extends State<AyahWidget> {
  ui.Image? _image;
  bool _isRendering = false;
  String? _error;

  // Cache keys to detect changes
  String _lastAyahText = '';
  int _lastFontSize = 0;
  int _lastWidth = 0;
  int _lastBgColor = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _renderIfNeeded();
  }

  @override
  void didUpdateWidget(AyahWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _renderIfNeeded();
  }

  bool _needsRender() {
    return widget.ayahText != _lastAyahText ||
        widget.fontSize != _lastFontSize ||
        widget.renderWidth != _lastWidth ||
        widget.backgroundColor != _lastBgColor;
  }

  void _renderIfNeeded() {
    if (_needsRender() && !_isRendering && widget.renderWidth > 0) {
      _renderAyah();
    }
  }

  Future<void> _renderAyah() async {
    if (_isRendering) return;

    setState(() {
      _isRendering = true;
      _error = null;
    });

    try {
      final width = widget.renderWidth;

      // Estimate height for this single ayah
      // Each ayah wraps based on its length and font size
      final textLength = widget.ayahText.length;
      final charsPerLine = (width / (widget.fontSize * 0.6)).clamp(10.0, 200.0);
      final estimatedLines = (textLength / charsPerLine).ceil().clamp(1, 50);
      final lineHeight = (widget.fontSize * 2.0).toInt();
      final height = (estimatedLines * lineHeight + widget.fontSize).clamp(
        100,
        5000,
      );

      final pixels = QuranRenderer.renderMultilineTextToPixels(
        width: width,
        height: height,
        text: widget.ayahText,
        fontSize: widget.fontSize,
        textColor: 0, // Auto-detect
        backgroundColor: widget.backgroundColor,
        justify: true,
        lineWidth: 0, // Use buffer width
        rightToLeft: true,
        tajweed: true,
      );

      final image = await _createImage(pixels, width, height);

      if (mounted) {
        setState(() {
          _image?.dispose();
          _image = image;
          _isRendering = false;
          _lastAyahText = widget.ayahText;
          _lastFontSize = widget.fontSize;
          _lastWidth = widget.renderWidth;
          _lastBgColor = widget.backgroundColor;
        });
      }
    } catch (e) {
      print('AyahWidget render error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRendering = false;
        });
      }
    }
  }

  Future<ui.Image> _createImage(List<int> pixels, int width, int height) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      Uint8List.fromList(pixels),
    );

    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_isRendering || _image == null) {
      // Show placeholder with estimated height
      final estimatedHeight =
          (widget.fontSize * 2.0) *
          (widget.ayahText.length / 50).clamp(1.0, 10.0);
      return SizedBox(
        height: estimatedHeight,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return RawImage(
      image: _image,
      width: widget.renderWidth / pixelRatio,
      fit: BoxFit.fitWidth,
    );
  }
}

/// Widget that displays a Surah's text as a list of ayahs
class SurahTextWidget extends StatefulWidget {
  final int surahNumber;
  final int fontSize;
  final int lightBackgroundColor;
  final int darkBackgroundColor;

  const SurahTextWidget({
    super.key,
    required this.surahNumber,
    this.fontSize = 48,
    this.lightBackgroundColor = 0xFFFFFFFF, // White (RRGGBBAA format)
    this.darkBackgroundColor = 0x1E1E1EFF, // Dark gray (RRGGBBAA format)
  });

  @override
  State<SurahTextWidget> createState() => _SurahTextWidgetState();
}

class _SurahTextWidgetState extends State<SurahTextWidget> {
  List<String>? _ayahs;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAyahs();
  }

  @override
  void didUpdateWidget(SurahTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      _loadAyahs();
    }
  }

  Future<void> _loadAyahs() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _ayahs = null;
    });

    try {
      final ayahs = await QuranDatabase.getSurahAyahTexts(widget.surahNumber);
      if (mounted) {
        setState(() {
          _ayahs = ayahs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ayahs: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAyahs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_isLoading || _ayahs == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? widget.darkBackgroundColor
        : widget.lightBackgroundColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final renderWidth = (constraints.maxWidth * pixelRatio).toInt();

        return Container(
          color: Color(
            // Convert RRGGBBAA to Flutter Color (AARRGGBB)
            ((bgColor & 0xFF) << 24) | ((bgColor >> 8) & 0xFFFFFF),
          ),
          child: ListView.builder(
            itemCount: _ayahs!.length,
            itemBuilder: (context, index) {
              return AyahWidget(
                key: ValueKey(
                  'ayah_${widget.surahNumber}_${index}_${widget.fontSize}',
                ),
                ayahText: _ayahs![index],
                fontSize: widget.fontSize,
                backgroundColor: bgColor,
                renderWidth: renderWidth,
              );
            },
          ),
        );
      },
    );
  }
}

/// Page that displays a surah's text with font size controls
class SurahTextPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahTextPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<SurahTextPage> createState() => _SurahTextPageState();
}

class _SurahTextPageState extends State<SurahTextPage> {
  int _fontSize = 48;
  static const int _minFontSize = 24;
  static const int _maxFontSize = 96;
  static const int _fontSizeStep = 8;

  void _increaseFontSize() {
    if (_fontSize < _maxFontSize) {
      setState(() {
        _fontSize = (_fontSize + _fontSizeStep).clamp(
          _minFontSize,
          _maxFontSize,
        );
      });
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > _minFontSize) {
      setState(() {
        _fontSize = (_fontSize - _fontSizeStep).clamp(
          _minFontSize,
          _maxFontSize,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surahName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: _fontSize > _minFontSize ? _decreaseFontSize : null,
            tooltip: 'Decrease text size',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                '$_fontSize',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: _fontSize < _maxFontSize ? _increaseFontSize : null,
            tooltip: 'Increase text size',
          ),
        ],
      ),
      body: SurahTextWidget(
        surahNumber: widget.surahNumber,
        fontSize: _fontSize,
      ),
    );
  }
}
