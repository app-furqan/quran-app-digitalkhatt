import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// ============================================================================
// C Enums
// ============================================================================

/// Pixel format enumeration
class QuranPixelFormat {
  static const int rgba8888 = 0;
  static const int bgra8888 = 1;
}

// ============================================================================
// C Structs
// ============================================================================

/// Platform-agnostic pixel buffer for rendering
final class QuranPixelBuffer extends Struct {
  external Pointer<Uint8> pixels;
  @Int32()
  external int width;
  @Int32()
  external int height;
  @Int32()
  external int stride;
  @Int32()
  external int format;
}

/// Font data container
final class QuranFontData extends Struct {
  external Pointer<Uint8> data;
  @Size()
  external int size;
}

/// Renderer configuration
final class QuranRenderConfig extends Struct {
  @Bool()
  external bool tajweed;
  @Bool()
  external bool justify;
  @Float()
  external double fontScale;
}

/// Surah information structure
final class QuranSurahInfo extends Struct {
  @Int32()
  external int number;
  @Int32()
  external int ayahCount;
  @Int32()
  external int startAyah;
  external Pointer<Utf8> nameArabic;
  external Pointer<Utf8> nameTrans;
  external Pointer<Utf8> nameEnglish;
  external Pointer<Utf8> type;
  @Int32()
  external int revelationOrder;
  @Int32()
  external int rukuCount;
}

/// Ayah location structure
final class QuranAyahLocation extends Struct {
  @Int32()
  external int surahNumber;
  @Int32()
  external int ayahNumber;
  @Int32()
  external int pageIndex;
}

// ============================================================================
// Function Typedefs
// ============================================================================

// Renderer lifecycle
typedef _CreateC = Pointer<Void> Function(Pointer<QuranFontData> fontData);
typedef _CreateDart = Pointer<Void> Function(Pointer<QuranFontData> fontData);

typedef _DestroyC = Void Function(Pointer<Void> renderer);
typedef _DestroyDart = void Function(Pointer<Void> renderer);

// Rendering
typedef _DrawPageC =
    Void Function(
      Pointer<Void> renderer,
      Pointer<QuranPixelBuffer> buffer,
      Int32 pageIndex,
      Pointer<QuranRenderConfig> config,
    );
typedef _DrawPageDart =
    void Function(
      Pointer<Void> renderer,
      Pointer<QuranPixelBuffer> buffer,
      int pageIndex,
      Pointer<QuranRenderConfig> config,
    );

typedef _GetPageCountC = Int32 Function(Pointer<Void> renderer);
typedef _GetPageCountDart = int Function(Pointer<Void> renderer);

// Surah/Ayah functions
typedef _GetSurahCountC = Int32 Function();
typedef _GetSurahCountDart = int Function();

typedef _GetTotalAyahCountC = Int32 Function();
typedef _GetTotalAyahCountDart = int Function();

typedef _GetSurahInfoC =
    Bool Function(Int32 surahNumber, Pointer<QuranSurahInfo> info);
typedef _GetSurahInfoDart =
    bool Function(int surahNumber, Pointer<QuranSurahInfo> info);

typedef _GetAyahCountC = Int32 Function(Int32 surahNumber);
typedef _GetAyahCountDart = int Function(int surahNumber);

typedef _GetSurahStartPageC = Int32 Function(Int32 surahNumber);
typedef _GetSurahStartPageDart = int Function(int surahNumber);

typedef _GetAyahPageC = Int32 Function(Int32 surahNumber, Int32 ayahNumber);
typedef _GetAyahPageDart = int Function(int surahNumber, int ayahNumber);

typedef _GetPageLocationC =
    Bool Function(Int32 pageIndex, Pointer<QuranAyahLocation> location);
typedef _GetPageLocationDart =
    bool Function(int pageIndex, Pointer<QuranAyahLocation> location);

// ============================================================================
// QuranRenderer - Main rendering class
// ============================================================================

class QuranRenderer {
  static DynamicLibrary? _lib;
  static Pointer<Void>? _renderer;
  static Pointer<Uint8>? _fontDataPtr;

  // Cached function lookups
  static late final _DrawPageDart _drawPage;
  static late final _GetPageCountDart _getPageCount;

  /// Initialize the renderer with embedded font data
  static Future<void> initialize(Uint8List fontData) async {
    if (_renderer != null) return;

    print('QuranRenderer.initialize: Starting initialization');
    print('QuranRenderer.initialize: Font data size = ${fontData.length}');

    // Load the library
    _loadLibrary();
    print('QuranRenderer.initialize: Library loaded');

    // Allocate and copy font data
    _fontDataPtr = calloc<Uint8>(fontData.length);
    final fontDataList = _fontDataPtr!.asTypedList(fontData.length);
    fontDataList.setAll(0, fontData);
    print('QuranRenderer.initialize: Font data copied to native memory');

    // Create font data struct
    final fontDataStruct = calloc<QuranFontData>();
    fontDataStruct.ref.data = _fontDataPtr!;
    fontDataStruct.ref.size = fontData.length;
    print('QuranRenderer.initialize: Font data struct created');

    // Create renderer
    print('QuranRenderer.initialize: About to call quran_renderer_create...');
    final create = _lib!.lookupFunction<_CreateC, _CreateDart>(
      'quran_renderer_create',
    );
    _renderer = create(fontDataStruct);
    print(
      'QuranRenderer.initialize: quran_renderer_create returned: ${_renderer?.address}',
    );

    calloc.free(fontDataStruct);

    if (_renderer == null || _renderer!.address == 0) {
      throw Exception('Failed to create QuranRenderer');
    }

    print('QuranRenderer.initialize: Caching function lookups');
    // Cache function lookups
    _drawPage = _lib!.lookupFunction<_DrawPageC, _DrawPageDart>(
      'quran_renderer_draw_page',
    );
    _getPageCount = _lib!.lookupFunction<_GetPageCountC, _GetPageCountDart>(
      'quran_renderer_get_page_count',
    );
  }

  static void _loadLibrary() {
    if (_lib != null) return;

    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libquranrenderer.so');
    } else if (Platform.isLinux) {
      // Get the executable path to find the bundle lib directory
      final exePath = Platform.resolvedExecutable;
      final bundleDir = File(exePath).parent.path;

      final possiblePaths = [
        '$bundleDir/lib/libquranrenderer.so',
        'libquranrenderer.so',
        'linux/libs/libquranrenderer.so',
        '${Directory.current.path}/linux/libs/libquranrenderer.so',
        '/usr/lib/libquranrenderer.so',
      ];

      String? loadedPath;
      for (final path in possiblePaths) {
        try {
          // Check if file exists first
          if (!File(path).existsSync()) {
            print('File not found: $path');
            continue;
          }
          print('Trying to load: $path');
          _lib = DynamicLibrary.open(path);
          loadedPath = path;
          print('Successfully loaded library from: $path');
          break;
        } catch (e) {
          print('Failed to load $path: $e');
          continue;
        }
      }

      if (_lib == null) {
        throw UnsupportedError(
          'Could not load libquranrenderer.so. Tried: $possiblePaths',
        );
      }
    } else if (Platform.isMacOS || Platform.isIOS) {
      _lib = DynamicLibrary.open('libquranrenderer.dylib');
    } else if (Platform.isWindows) {
      _lib = DynamicLibrary.open('quranrenderer.dll');
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Destroy the renderer and free resources
  static void dispose() {
    if (_renderer != null) {
      final destroy = _lib!.lookupFunction<_DestroyC, _DestroyDart>(
        'quran_renderer_destroy',
      );
      destroy(_renderer!);
      _renderer = null;
    }

    if (_fontDataPtr != null) {
      calloc.free(_fontDataPtr!);
      _fontDataPtr = null;
    }
  }

  /// Get the total number of pages (604)
  static int getPageCount() {
    _ensureInitialized();
    return _getPageCount(_renderer!);
  }

  /// Render a page to RGBA pixel data
  /// Returns Uint8List with RGBA pixels (width * height * 4 bytes)
  static Uint8List renderPage({
    required int pageIndex,
    required int width,
    required int height,
    bool tajweed = true,
    bool justify = true,
    double fontScale = 1.0,
  }) {
    _ensureInitialized();

    final stride = width * 4; // RGBA = 4 bytes per pixel
    final bufferSize = stride * height;

    // Allocate pixel buffer
    final pixels = calloc<Uint8>(bufferSize);

    // Create buffer struct
    final buffer = calloc<QuranPixelBuffer>();
    buffer.ref.pixels = pixels;
    buffer.ref.width = width;
    buffer.ref.height = height;
    buffer.ref.stride = stride;
    buffer.ref.format = QuranPixelFormat.rgba8888;

    // Create config struct
    final config = calloc<QuranRenderConfig>();
    config.ref.tajweed = tajweed;
    config.ref.justify = justify;
    config.ref.fontScale = fontScale;

    print(
      'renderPage: tajweed=$tajweed, justify=$justify, fontScale=$fontScale',
    );

    // Render
    _drawPage(_renderer!, buffer, pageIndex, config);

    // Copy pixels to Dart
    final result = Uint8List(bufferSize);
    result.setAll(0, pixels.asTypedList(bufferSize));

    // Free native memory
    calloc.free(config);
    calloc.free(buffer);
    calloc.free(pixels);

    return result;
  }

  static void _ensureInitialized() {
    if (_renderer == null) {
      throw StateError(
        'QuranRenderer not initialized. Call initialize() first.',
      );
    }
  }

  // ============================================================================
  // Surah/Ayah API (static, don't need renderer instance)
  // ============================================================================

  /// Get the total number of surahs (always 114)
  static int getSurahCount() {
    _loadLibrary();
    final fn = _lib!.lookupFunction<_GetSurahCountC, _GetSurahCountDart>(
      'quran_renderer_get_surah_count',
    );
    return fn();
  }

  /// Get the total number of ayahs (always 6236)
  static int getTotalAyahCount() {
    _loadLibrary();
    final fn = _lib!
        .lookupFunction<_GetTotalAyahCountC, _GetTotalAyahCountDart>(
          'quran_renderer_get_total_ayah_count',
        );
    return fn();
  }

  /// Get the number of ayahs in a surah
  static int getAyahCount(int surahNumber) {
    _loadLibrary();
    final fn = _lib!.lookupFunction<_GetAyahCountC, _GetAyahCountDart>(
      'quran_renderer_get_ayah_count',
    );
    return fn(surahNumber);
  }

  /// Get the page index where a surah starts
  static int getSurahStartPage(int surahNumber) {
    _loadLibrary();
    final fn = _lib!
        .lookupFunction<_GetSurahStartPageC, _GetSurahStartPageDart>(
          'quran_renderer_get_surah_start_page',
        );
    return fn(surahNumber);
  }

  /// Get the page index for a specific ayah
  static int getAyahPage(int surahNumber, int ayahNumber) {
    _loadLibrary();
    final fn = _lib!.lookupFunction<_GetAyahPageC, _GetAyahPageDart>(
      'quran_renderer_get_ayah_page',
    );
    return fn(surahNumber, ayahNumber);
  }

  /// Get information about a surah
  static SurahInfo? getSurahInfo(int surahNumber) {
    _loadLibrary();
    final fn = _lib!.lookupFunction<_GetSurahInfoC, _GetSurahInfoDart>(
      'quran_renderer_get_surah_info',
    );

    final ptr = calloc<QuranSurahInfo>();
    try {
      if (fn(surahNumber, ptr)) {
        final startPage = getSurahStartPage(surahNumber);
        return SurahInfo(
          number: ptr.ref.number,
          ayahCount: ptr.ref.ayahCount,
          startAyah: ptr.ref.startAyah,
          nameArabic: ptr.ref.nameArabic.toDartString(),
          nameTrans: ptr.ref.nameTrans.toDartString(),
          nameEnglish: ptr.ref.nameEnglish.toDartString(),
          type: ptr.ref.type.toDartString(),
          revelationOrder: ptr.ref.revelationOrder,
          rukuCount: ptr.ref.rukuCount,
          startPage: startPage,
        );
      }
      return null;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Get surah and ayah number from a page index
  static AyahLocation? getPageLocation(int pageIndex) {
    _loadLibrary();
    final fn = _lib!.lookupFunction<_GetPageLocationC, _GetPageLocationDart>(
      'quran_renderer_get_page_location',
    );

    final ptr = calloc<QuranAyahLocation>();
    try {
      if (fn(pageIndex, ptr)) {
        return AyahLocation(
          surahNumber: ptr.ref.surahNumber,
          ayahNumber: ptr.ref.ayahNumber,
          pageIndex: ptr.ref.pageIndex,
        );
      }
      return null;
    } finally {
      calloc.free(ptr);
    }
  }
}

// ============================================================================
// Dart Models
// ============================================================================

class SurahInfo {
  final int number;
  final int ayahCount;
  final int startAyah;
  final String nameArabic;
  final String nameTrans;
  final String nameEnglish;
  final String type;
  final int revelationOrder;
  final int rukuCount;
  final int startPage;

  SurahInfo({
    required this.number,
    required this.ayahCount,
    required this.startAyah,
    required this.nameArabic,
    required this.nameTrans,
    required this.nameEnglish,
    required this.type,
    required this.revelationOrder,
    required this.rukuCount,
    required this.startPage,
  });

  @override
  String toString() =>
      'SurahInfo($number: $nameTrans - $nameEnglish, $ayahCount ayahs, page ${startPage + 1})';
}

class AyahLocation {
  final int surahNumber;
  final int ayahNumber;
  final int pageIndex;

  AyahLocation({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageIndex,
  });

  @override
  String toString() =>
      'AyahLocation(Surah $surahNumber, Ayah $ayahNumber, Page $pageIndex)';
}
