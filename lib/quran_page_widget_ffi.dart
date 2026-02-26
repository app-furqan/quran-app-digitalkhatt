import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'quran_renderer.dart';

/// Widget that displays a Quran page using the native FFI renderer
class QuranPageWidget extends StatefulWidget {
  final int pageIndex;
  final bool tajweed;
  final bool justify;
  final int fontSize; // 0 = auto-fit (default), or specific px size
  final int lightBackgroundColor;
  final int darkBackgroundColor;
  final double lineHeightDivisor; // 0 = auto (10.0 for regular, 7.5 for Fatiha)
  final double topMarginLines; // 0 = auto (3.5 for Fatiha, 0 for others)

  const QuranPageWidget({
    super.key,
    required this.pageIndex,
    this.tajweed = true,
    this.justify = true,
    this.fontSize = 0, // 0 = auto-fit to screen
    this.lightBackgroundColor = 0xFFFFFFFF, // White (RRGGBBAA format)
    this.darkBackgroundColor = 0x000000FF, // True black (RRGGBBAA format)
    this.lineHeightDivisor = 0.0, // 0 = auto
    this.topMarginLines = 0.0, // 0 = auto
  });

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  ui.Image? _image;
  bool _isLoading = false;
  String? _error;
  int _lastWidth = 0;
  int _lastHeight = 0;
  Brightness? _lastBrightness;

  @override
  void didUpdateWidget(QuranPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex ||
        oldWidget.tajweed != widget.tajweed ||
        oldWidget.justify != widget.justify ||
        oldWidget.fontSize != widget.fontSize ||
        oldWidget.lightBackgroundColor != widget.lightBackgroundColor ||
        oldWidget.darkBackgroundColor != widget.darkBackgroundColor ||
        oldWidget.lineHeightDivisor != widget.lineHeightDivisor ||
        oldWidget.topMarginLines != widget.topMarginLines) {
      // Force re-render on next build
      _lastWidth = 0;
      _lastHeight = 0;
    }
  }

  Future<void> _renderPage(int width, int height) async {
    if (width <= 0 || height <= 0) return;
    if (_isLoading) return;
    if (width == _lastWidth && height == _lastHeight && _image != null) return;

    print('_renderPage: Starting for page ${widget.pageIndex}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('_renderPage: Rendering ${width}x${height} pixels');

      // Get background color based on theme
      final isDark = Theme.of(context).brightness == Brightness.dark;
      // Renderer expects backgroundColor as 0xRRGGBBAA.
      final bgColor = isDark
          ? widget.darkBackgroundColor
          : widget.lightBackgroundColor;

      print(
        '_renderPage: isDark=$isDark, bgColor=0x${bgColor.toRadixString(16)}, tajweed=${widget.tajweed}',
      );

      // Match native reference sizing behavior:
      // - char_height ~= (width / 17) * 0.9
      // - inter_line ~= height / 15
      final effectiveFontSize = widget.fontSize > 0
          ? widget.fontSize
          : ((width / 17.0) * 0.9).round();
      final effectiveLineHeightDivisor = widget.lineHeightDivisor > 0
          ? widget.lineHeightDivisor
          : 15.0;

      print(
        '_renderPage: effectiveFontSize=$effectiveFontSize, effectiveLineHeightDivisor=$effectiveLineHeightDivisor',
      );

      // Render the page
      // NOTE: useForeground can override per-glyph colors (tajweed), so keep it
      // false and rely on the renderer's background-luminance auto logic.
      final pixels = QuranRenderer.renderPage(
        pageIndex: widget.pageIndex,
        width: width,
        height: height,
        tajweed: widget.tajweed,
        justify: widget.justify,
        fontSize: effectiveFontSize,
        backgroundColor: bgColor,
        useForeground: false,
        lineHeightDivisor: effectiveLineHeightDivisor,
        topMarginLines: widget.topMarginLines,
      );

      print(
        '_renderPage: Got ${pixels.length} bytes, first 20: ${pixels.take(20).toList()}',
      );

      // Convert to Flutter image
      final image = await _createImage(pixels, width, height);
      print('_renderPage: Image created: ${image.width}x${image.height}');

      if (mounted) {
        setState(() {
          _image?.dispose();
          _image = image;
          _isLoading = false;
          _lastWidth = width;
          _lastHeight = height;
        });
      }
    } catch (e, stackTrace) {
      print('QuranPageWidget error: $e');
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
              onPressed: () {
                _lastWidth = 0;
                _lastHeight = 0;
                setState(() {});
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Render using full available viewport so orientation is reflected.
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final targetDisplayWidth = constraints.maxWidth;
        final targetDisplayHeight = constraints.maxHeight;
        final renderWidth = (targetDisplayWidth * pixelRatio).toInt();
        final renderHeight = (targetDisplayHeight * pixelRatio).toInt();

        final aspectRatio = targetDisplayWidth / targetDisplayHeight;
        print(
          'aspectRatio=$aspectRatio, pageSize=${renderWidth}x$renderHeight',
        );

        // Check if brightness changed (theme switch)
        final currentBrightness = Theme.of(context).brightness;
        final brightnessChanged =
            _lastBrightness != null && _lastBrightness != currentBrightness;
        if (brightnessChanged) {
          _lastBrightness = currentBrightness;
          // Force re-render by resetting dimensions
          _lastWidth = 0;
          _lastHeight = 0;
        }
        _lastBrightness = currentBrightness;

        // Trigger render if size changed or no image yet
        if ((renderWidth != _lastWidth || renderHeight != _lastHeight) &&
            !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _renderPage(renderWidth, renderHeight);
          });
        }

        // Show spinner while loading OR if we need a new render (dimensions changed)
        final needsRerender =
            renderWidth != _lastWidth || renderHeight != _lastHeight;
        if (_isLoading || _image == null || needsRerender) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        return ClipRect(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            panEnabled: true,
            scaleEnabled: true,
            constrained: true,
            child: RawImage(
              image: _image,
              width: targetDisplayWidth,
              height: targetDisplayHeight,
              fit: BoxFit.fill,
            ),
          ),
        );
      },
    );
  }
}
