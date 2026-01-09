# Quran App DigitalKhatt

A beautiful cross-platform Quran reader application built with Flutter, featuring native C++ rendering with FFI for high-performance text rendering, Tajweed highlighting, and the Digital Khatt font for authentic Arabic calligraphy.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=flat&logo=apple&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white)
![C++](https://img.shields.io/badge/C++-00599C?style=flat&logo=cplusplus&logoColor=white)

## ✨ Features

- 📖 **Complete Quran** - All 604 pages of the Holy Quran with Uthmani script
- 📚 **Surah List** - Browse and navigate through all 114 surahs
- 🎨 **Tajweed Support** - Toggle Tajweed color highlighting on/off
- 📱 **Cross-Platform** - Runs on iOS and Android with native performance
- ⚡ **FFI-Based Rendering** - High-performance text rendering using C++ via Dart FFI
- 🖋️ **Digital Khatt Font** - Beautiful Arabic calligraphy optimized for Quran display
- 🌙 **Clean UI** - Material Design 3 with modern, intuitive interface
- 📄 **Page View** - Smooth page navigation with rendered Quran pages
- 🔍 **Text View** - Read individual ayahs with native Flutter text rendering
- 💾 **SQLite Database** - Fast local access to Quran text and metadata

## 📸 Screenshots

| Surah List | Page View | Text View |
|------------|-----------|-----------|
| Browse all surahs | High-quality rendered pages | Individual ayah display |

## 🏗️ Architecture

The app uses a hybrid architecture combining Flutter for UI and native C++ for high-performance Quran text rendering via Dart FFI (Foreign Function Interface).

```
lib/
├── main.dart                   # App entry point with navigation
├── surah_list_page.dart        # Surah list screen
├── quran_page_widget.dart      # Page-based Quran view (rendered images)
├── quran_page_widget_ffi.dart  # FFI wrapper for C++ renderer
├── quran_renderer.dart         # Dart FFI bindings for native renderer
├── surah_text_widget.dart      # Text-based ayah view
└── quran_database.dart         # SQLite database access layer

ios/
├── Frameworks/
│   └── QuranRenderer.xcframework/   # iOS/macOS native libraries
└── libs/
    ├── device/libquranrenderer.a    # iOS device library
    └── simulator/libquranrenderer.a # iOS simulator library

android/app/libs/
└── [platform]/libquranrenderer.so   # Android native libraries
```

### FFI (Foreign Function Interface)

The app uses Dart FFI to communicate directly with native C++ code for optimal rendering performance:

```dart
// Load the native library
final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open('libquranrenderer.so')
    : DynamicLibrary.process();

// Define native function signatures
typedef NativeCreateRenderer = Pointer<Void> Function(Pointer<Uint8>, Int32);
typedef DartCreateRenderer = Pointer<Void> Function(Pointer<Uint8>, int);

// Lookup and call native functions
final createRenderer = nativeLib
    .lookup<NativeFunction<NativeCreateRenderer>>('quran_renderer_create')
    .asFunction<DartCreateRenderer>();
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.10.3)
- Xcode (for iOS development)
- Android Studio / VS Code
- iOS device or simulator (iOS 12.0+)
- Android device or emulator (API 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/app-furqan/quran-app-digitalkhatt.git
   cd quran-app-digitalkhatt
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For iOS
   flutter run -d "iPhone 15 Pro"
   
   # For Android
   flutter run -d emulator-5554
   ```

### Building for Release

```bash
# Build iOS IPA
flutter build ios --release

# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release
```

## 📖 Usage

### Surah List Screen

- Browse all 114 surahs with Arabic names and metadata
- Tap any surah to view its pages or text
- Toggle between Page View and Text View modes

### Page View Mode

- View high-quality rendered Quran pages
- Swipe left/right to navigate between pages
- Pages are rendered using native C++ for optimal quality

### Text View Mode

- Read individual ayahs with Flutter's native text rendering
- Smooth scrolling through ayahs
- Tajweed highlighting support

## 🛠️ Configuration

### Updating Native Libraries

The native rendering libraries are managed in the repository using Git LFS. To update them:

1. Build new libraries from [quran-renderer](https://github.com/app-furqan/quran-renderer.git)
2. Extract the release zip:
   ```bash
   unzip quran-renderer-release.zip
   ```
3. Copy libraries to the project:
   ```bash
   # iOS
   cp -r QuranRenderer.xcframework ios/Frameworks/
   cp ios/lib/libquranrenderer.a ios/libs/device/
   cp ios-simulator/lib/libquranrenderer.a ios/libs/simulator/
   
   # Android
   cp android/arm64-v8a/libquranrenderer.so android/app/src/main/jniLibs/arm64-v8a/
   cp android/armeabi-v7a/libquranrenderer.so android/app/src/main/jniLibs/armeabi-v7a/
   ```

### Database Schema

The app uses a SQLite database (`assets/quran-uthmani.db`) with the following schema:

```sql
-- Surahs table
CREATE TABLE surahs (
    id INTEGER PRIMARY KEY,
    name TEXT,
    transliteration TEXT,
    translation TEXT,
    type TEXT,
    total_verses INTEGER
);

-- Ayahs table
CREATE TABLE quran (
    surah INTEGER,
    ayah INTEGER,
    text TEXT,
    page INTEGER
);
```

## 📁 Project Structure

```
quran-app-digitalkhatt/
├── android/                      # Android native code
│   └── app/
│       ├── libs/                 # Android native libraries (AAR)
│       └── src/main/jniLibs/     # Native .so libraries
├── ios/                          # iOS native code
│   ├── Frameworks/               # iOS xcframework
│   └── libs/                     # iOS static libraries
├── lib/                          # Flutter/Dart source files
│   ├── main.dart                 # Main application
│   ├── surah_list_page.dart      # Surah list UI
│   ├── quran_page_widget.dart    # Page view widget
│   ├── quran_page_widget_ffi.dart # FFI rendering wrapper
│   ├── quran_renderer.dart       # Native bindings
│   ├── surah_text_widget.dart    # Text view widget
│   └── quran_database.dart       # Database access
├── assets/                       # Application assets
│   ├── quran-uthmani.db          # Quran database
│   └── fonts/                    # Digital Khatt fonts
├── pubspec.yaml                  # Flutter dependencies
└── README.md                     # This file
```

## 🔧 Dependencies

### Flutter Packages
- **sqflite** - SQLite database access
- **path_provider** - File system paths
- **path** - Path manipulation utilities
- **ffi** - Foreign Function Interface for C++ integration

### Native Libraries
- **DigitalKhatt Quran Renderer** - C++ library for high-quality Arabic text rendering

The native renderer is built from the open-source project:

**Repository:** [https://github.com/app-furqan/quran-renderer.git](https://github.com/app-furqan/quran-renderer.git)

Features:
- Digital Khatt font rendering engine
- Tajweed color highlighting support
- High-precision Arabic text layout
- Cross-platform support (iOS, Android, macOS, Linux, Windows)
- Optimized performance for Quran pages

### Building Native Libraries from Source

1. **Clone the quran-renderer repository**
   ```bash
   git clone https://github.com/app-furqan/quran-renderer.git
   cd quran-renderer
   ```

2. **Build for iOS**
   ```bash
   # Build xcframework with all architectures
   ./build-apple.sh
   
   # Output: build/QuranRenderer.xcframework
   ```

3. **Build for Android**
   ```bash
   # Build for all Android architectures
   ./gradlew assembleRelease
   
   # Output: build/android/[arch]/libquranrenderer.so
   ```

4. **Copy libraries** to this project as described in the Configuration section

## 🧪 Testing

Run the Flutter tests:

```bash
flutter test
```

## 📄 License

This project is private and proprietary.

## 🤝 Contributing

This is a private repository. Please contact the maintainers for contribution guidelines.

## 📞 Support

For issues and feature requests, please create an issue in the repository.

## 🙏 Acknowledgments

- Digital Khatt font by [DigitalKhatt Project](https://github.com/DigitalKhatt/digitalkhatt)
- Quran text data from Tanzil Project
- Built with Flutter and Dart FFI

---

Made with ❤️ for the Muslim Ummah
