import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'quran_renderer.dart';

/// Widget that displays a Quran page using the native FFI renderer
class QuranPageWidget extends StatefulWidget {
  final int pageIndex;
  final bool tajweed;
  final double fontScale;

  const QuranPageWidget({
    super.key,
    required this.pageIndex,
    this.tajweed = true,
    this.fontScale = 1.0,
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

  @override
  void didUpdateWidget(QuranPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex ||
        oldWidget.tajweed != widget.tajweed ||
        oldWidget.fontScale != widget.fontScale) {
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

      // Render the page
      final pixels = QuranRenderer.renderPage(
        pageIndex: widget.pageIndex,
        width: width,
        height: height,
        tajweed: widget.tajweed,
        fontScale: widget.fontScale,
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
        // Get theme brightness for background
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.white;

        // Render at screen dimensions with dynamic height adjustment
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final renderWidth = (constraints.maxWidth * pixelRatio).toInt();

        // Dynamic height multiplier based on aspect ratio
        // Wide screens (unfolded): aspect > 0.8 needs significantly more height
        // Narrow screens (folded): aspect <= 0.5 needs less height
        final aspectRatio = constraints.maxWidth / constraints.maxHeight;
        final heightMultiplier = aspectRatio > 0.8
            ? 1.4 // Unfolded/tablet - more height for proper line spacing
            : aspectRatio > 0.5
            ? 1.2 // Medium screens
            : 1.1; // Folded/narrow - less extra height
        final renderHeight =
            (constraints.maxHeight * pixelRatio * heightMultiplier).toInt();

        print(
          'aspectRatio=$aspectRatio, heightMultiplier=$heightMultiplier, size=${renderWidth}x$renderHeight',
        );

        // Trigger render if size changed or no image yet
        if ((renderWidth != _lastWidth || renderHeight != _lastHeight) &&
            !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _renderPage(renderWidth, renderHeight);
          });
        }

        if (_isLoading || _image == null) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        return Container(
          color: bgColor,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(0),
            constrained: false,
            child: RawImage(
              image: _image,
              width: constraints.maxWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
        );
      },
    );
  }
}
