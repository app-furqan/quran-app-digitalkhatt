import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuranPageWidget extends StatefulWidget {
  final int pageIndex;
  final bool tajweed;
  final double fontSize;

  const QuranPageWidget({
    super.key,
    required this.pageIndex,
    this.tajweed = true,
    this.fontSize = 1.0,
  });

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(QuranPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_channel != null) {
      if (oldWidget.pageIndex != widget.pageIndex) {
        _channel!.invokeMethod('setPage', {'page': widget.pageIndex});
      }
      if (oldWidget.tajweed != widget.tajweed) {
        _channel!.invokeMethod('setTajweed', {'enabled': widget.tajweed});
      }
      if (oldWidget.fontSize != widget.fontSize) {
        _channel!.invokeMethod('setFontSize', {'size': widget.fontSize});
      }
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('quran_page_view_$viewId');
  }

  @override
  Widget build(BuildContext context) {
    const String viewType = 'quran-page-view';
    final Map<String, dynamic> creationParams = {
      'pageIndex': widget.pageIndex,
      'tajweed': widget.tajweed,
      'fontSize': widget.fontSize,
    };

    return AndroidView(
      viewType: viewType,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }
}
