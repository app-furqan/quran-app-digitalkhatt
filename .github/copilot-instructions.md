# Copilot Instructions for quran-app-digitalkhatt

## Updating Native Libraries from quran-renderer

When the user asks to copy/update the native libraries from `quran-renderer`, **copy the actual binary files** — NOT just the zip archive.

### Source locations (from quran-renderer build output)

| Artifact | Source Path |
|----------|-------------|
| macOS dylib | `/Users/hussain.khan/Desktop/Projects/quran-renderer/build/macos-dylib/libquranrenderer.dylib` |
| iOS XCFramework | `/Users/hussain.khan/Desktop/Projects/quran-renderer/build/apple/QuranRenderer.xcframework` |
| iOS Device .a | `/Users/hussain.khan/Desktop/Projects/quran-renderer/build/apple/ios/lib/libquranrenderer.a` |
| iOS Simulator .a | `/Users/hussain.khan/Desktop/Projects/quran-renderer/build/apple/ios-simulator/lib/libquranrenderer.a` |

### Destination locations (in this Flutter app repo)

| Artifact | Destination Path |
|----------|------------------|
| macOS dylib | `macos/libs/libquranrenderer.dylib` |
| iOS XCFramework | `ios/Frameworks/QuranRenderer.xcframework` |
| iOS Device .a | `ios/libs/device/libquranrenderer.a` |
| iOS Simulator .a | `ios/libs/simulator/libquranrenderer.a` |

### Copy commands

```bash
# macOS
cp -f /Users/hussain.khan/Desktop/Projects/quran-renderer/build/macos-dylib/libquranrenderer.dylib \
      macos/libs/libquranrenderer.dylib

# iOS XCFramework (replace entirely)
rm -rf ios/Frameworks/QuranRenderer.xcframework
cp -R /Users/hussain.khan/Desktop/Projects/quran-renderer/build/apple/QuranRenderer.xcframework \
      ios/Frameworks/QuranRenderer.xcframework

# iOS static libs
cp -f /Users/hussain.khan/Desktop/Projects/quran-renderer/build/apple/ios/lib/libquranrenderer.a \
      ios/libs/device/libquranrenderer.a
cp -f /Users/hussain.khan/Desktop/Projects/quran-renderer/build/apple/ios-simulator/lib/libquranrenderer.a \
      ios/libs/simulator/libquranrenderer.a
```

### After copying

1. Stage and commit all updated binaries.
2. Run smoke builds to verify:
   - `flutter build macos --debug`
   - `flutter build ios --release --no-codesign`

### DO NOT

- Copy only the `.zip` file; the zip is for distribution/archival, NOT used by the Flutter build.
- Forget to replace the XCFramework directory entirely (use `rm -rf` then `cp -R`).
