# Native Library Setup

This document describes how native libraries are managed in this Flutter project.

## Directory Structure

```
quran-app-android/
├── android/app/src/main/jniLibs/    # ✅ Android native libraries (SINGLE SOURCE)
│   ├── arm64-v8a/
│   │   ├── libquranrenderer.so
│   │   └── libc++_shared.so
│   ├── armeabi-v7a/
│   │   ├── libquranrenderer.so
│   │   └── libc++_shared.so
│   └── x86_64/
│       ├── libquranrenderer.so
│       └── libc++_shared.so
│
└── linux/libs/                      # ✅ Linux native libraries
    └── libquranrenderer.so
```

## ⚠️ IMPORTANT: Single Source of Truth

**Android libraries MUST only be in `android/app/src/main/jniLibs/`**

Do NOT create duplicate libraries in:
- ❌ `android/app/libs/` - This will cause version conflicts!
- ❌ `android/libs/`
- ❌ Any other location

The `jniLibs` folder is the standard Android location and is automatically picked up by Gradle.

## Updating Native Libraries

When you have new library builds from `quran-renderer`, run these commands:

```bash
# Copy Android libraries (all architectures)
cp /path/to/quran-renderer/build/final-output/android-arm64-v8a/libquranrenderer.so \
   android/app/src/main/jniLibs/arm64-v8a/

cp /path/to/quran-renderer/build/final-output/android-armeabi-v7a/libquranrenderer.so \
   android/app/src/main/jniLibs/armeabi-v7a/

cp /path/to/quran-renderer/build/final-output/android-x86_64/libquranrenderer.so \
   android/app/src/main/jniLibs/x86_64/

# Copy Linux library
cp /path/to/quran-renderer/build/final-output/linux-x86_64/libquranrenderer.so \
   linux/libs/

# IMPORTANT: Clean build to ensure new libraries are bundled
flutter clean
flutter pub get
flutter run
```

## Verifying Library Symbols

To check if a library has the required functions:

```bash
# Check exported symbols
nm -D android/app/src/main/jniLibs/arm64-v8a/libquranrenderer.so | grep quran_renderer

# Expected output should include:
# quran_renderer_create
# quran_renderer_destroy
# quran_renderer_draw_page
# quran_renderer_draw_text
# quran_renderer_draw_multiline_text
# quran_renderer_measure_text
# quran_renderer_get_surah_info
# ... etc
```

## Troubleshooting

### "undefined symbol" errors at runtime

1. **Cause**: Old library cached in APK
2. **Solution**: 
   ```bash
   cd android && ./gradlew clean && cd ..
   flutter clean
   flutter pub get
   flutter run
   ```

### Library not found

1. Check library exists in `jniLibs/{abi}/`
2. Verify the ABI matches your device (arm64-v8a for most modern phones)
3. Ensure `libc++_shared.so` is present alongside `libquranrenderer.so`

### Symbol version mismatch

1. Verify you're using the correct library version
2. Check FFI bindings in `lib/quran_renderer.dart` match the C API
3. Compare with header file: `quran-renderer/include/quran/renderer.h`

## C API Reference

The native library exports these functions:

### Renderer Lifecycle
- `quran_renderer_create(font_data)` - Create renderer with font
- `quran_renderer_destroy(renderer)` - Free resources

### Page Rendering (Mushaf Layout)
- `quran_renderer_draw_page(renderer, buffer, page_index, config)` - Render Quran page
- `quran_renderer_get_page_count(renderer)` - Returns 604

### Text Rendering (Generic Arabic)
- `quran_renderer_draw_text(renderer, buffer, text, length, config)` - Single line
- `quran_renderer_draw_multiline_text(renderer, buffer, text, length, config, line_spacing)` - Multi-line
- `quran_renderer_measure_text(renderer, text, length, font_size, &width, &height)` - Measure

### Surah/Ayah API
- `quran_renderer_get_surah_count()` - Returns 114
- `quran_renderer_get_surah_info(surah_number, &info)` - Get surah metadata
- `quran_renderer_get_surah_start_page(surah_number)` - Get starting page
- `quran_renderer_get_ayah_page(surah, ayah)` - Get page for specific ayah
