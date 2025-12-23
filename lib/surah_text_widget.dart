import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'quran_renderer.dart';
import 'quran_database.dart';

/// Widget that displays a Surah's text using the native FFI text renderer
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
  ui.Image? _image;
  bool _isLoading = false;
  String? _error;
  String? _surahText;
  int _lastWidth = 0;
  int _lastFontSize = 0;

  @override
  void initState() {
    super.initState();
    _loadSurahText();
  }

  @override
  void didUpdateWidget(SurahTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      _loadSurahText();
    } else if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.lightBackgroundColor != widget.lightBackgroundColor ||
        oldWidget.darkBackgroundColor != widget.darkBackgroundColor) {
      // Force re-render
      _lastWidth = 0;
      _lastFontSize = 0;
    }
  }

  Future<void> _loadSurahText() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _surahText = null;
      _image?.dispose();
      _image = null;
      _lastWidth = 0;
      _lastFontSize = 0;
    });

    try {
      final text = await QuranDatabase.getSurahText(widget.surahNumber);
      if (mounted) {
        setState(() {
          _surahText = text;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading surah text: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _renderText(int width) async {
    if (width <= 0 || _surahText == null) return;
    if (_isLoading) return;
    if (width == _lastWidth &&
        widget.fontSize == _lastFontSize &&
        _image != null)
      return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bgColor = isDark
          ? widget.darkBackgroundColor
          : widget.lightBackgroundColor;

      // Estimate height based on text length and font size
      final lineCount = _surahText!.split('\n').length;
      final estimatedLineHeight = (widget.fontSize * 2.0)
          .toInt(); // Assume ~2x line height
      final height = (lineCount * estimatedLineHeight + widget.fontSize * 2)
          .clamp(500, 50000);

      print(
        'SurahTextWidget: Rendering ${lineCount} lines at ${width}x$height',
      );

      final pixels = QuranRenderer.renderMultilineTextToPixels(
        width: width,
        height: height,
        text: _surahText!,
        fontSize: widget.fontSize,
        textColor: 0, // Auto-detect based on background
        backgroundColor: bgColor,
        justify: true,
        lineWidth: 0, // Auto-fit to width
        rightToLeft: true,
      );

      final image = await _createImage(pixels, width, height);

      if (mounted) {
        setState(() {
          _image?.dispose();
          _image = image;
          _isLoading = false;
          _lastWidth = width;
          _lastFontSize = widget.fontSize;
        });
      }
    } catch (e, stackTrace) {
      print('SurahTextWidget error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSurahText,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_surahText == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final renderWidth = (constraints.maxWidth * pixelRatio).toInt();

        // Trigger render if width changed or no image yet
        if (renderWidth != _lastWidth && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _renderText(renderWidth);
          });
        }

        if (_isLoading || _image == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: RawImage(
            image: _image,
            width: constraints.maxWidth,
            fit: BoxFit.fitWidth,
          ),
        );
      },
    );
  }
}

/// Page that displays a surah's text
class SurahTextPage extends StatelessWidget {
  final int surahNumber;
  final String surahName;

  const SurahTextPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(surahName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SurahTextWidget(surahNumber: surahNumber),
    );
  }
}
