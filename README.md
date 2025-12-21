# Quran App Android

A beautiful Flutter-based Quran reader application for Android with native rendering support, Tajweed highlighting, and customizable font scaling.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white)

## ✨ Features

- 📖 **Complete Quran** - All 604 pages of the Holy Quran
- 🎨 **Tajweed Support** - Toggle Tajweed color highlighting on/off
- 🔍 **Font Scaling** - Adjustable font size (50% - 200%) for comfortable reading
- 📱 **Native Rendering** - High-quality text rendering using native Android views
- 🌙 **Dark/Light Theme** - Automatic theme support based on system settings
- ↔️ **RTL Support** - Right-to-left page navigation for natural Arabic reading
- 🔢 **Page Navigation** - Quick jump to any page with the "Go to Page" dialog

## 📸 Screenshots

| Home Screen | Tajweed Enabled | Font Scaling |
|-------------|-----------------|--------------|
| Page view with navigation | Colorful Tajweed rules | Zoom in/out controls |

## 🏗️ Architecture

The app uses a hybrid architecture combining Flutter for the UI framework and native Android views for high-quality Quran text rendering.

```
lib/
├── main.dart              # App entry point, theme, and main UI
└── quran_page_widget.dart # Flutter wrapper for native Android view

android/app/src/main/kotlin/com/example/quran_app/
├── MainActivity.kt         # App initialization and renderer setup
├── QuranPageView.kt        # Native Android view for Quran rendering
└── QuranPageViewFactory.kt # Platform view factory and method channel handler
```

### Platform Channel Communication

The app uses Flutter Platform Channels to communicate between Dart and native Android:

```dart
// Flutter side - sending commands to native
_channel!.invokeMethod('setPage', {'page': widget.pageIndex});
_channel!.invokeMethod('setTajweed', {'enabled': widget.tajweed});
_channel!.invokeMethod('setFontScale', {'scale': widget.fontScale});
```

```kotlin
// Android side - handling commands
override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
        "setPage" -> quranView.setPage(call.argument<Int>("page") ?: 0)
        "setTajweed" -> quranView.setTajweed(call.argument<Boolean>("enabled") ?: true)
        "setFontScale" -> quranView.setFontScale(call.argument<Double>("scale")?.toFloat() ?: 1.0f)
    }
}
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.10.3)
- Android Studio / VS Code
- Android device or emulator (API 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/hussainak/quran-app-android.git
   cd quran-app-android
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## 📖 Usage

### Navigation Controls

| Control | Action |
|---------|--------|
| Swipe Left | Next page (RTL) |
| Swipe Right | Previous page (RTL) |
| `◀◀` Button | Go to first page |
| `◀` Button | Go to previous page |
| `▶` Button | Go to next page |
| `▶▶` Button | Go to last page |
| 📖 Icon | Open "Go to Page" dialog |

### Font Size Controls

Located in the app bar:

| Control | Action |
|---------|--------|
| `A-` Button | Decrease font size by 10% |
| Percentage Text | Tap to reset to 100% |
| `A+` Button | Increase font size by 10% |

Font size range: **50% - 200%**

### Tajweed Toggle

Use the "Tajweed" switch in the app bar to enable/disable Tajweed color highlighting.

## 🛠️ Configuration

### Customizing Theme Colors

Edit the theme in `lib/main.dart`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal, // Change primary color
    brightness: Brightness.light,
  ),
  useMaterial3: true,
),
```

### Adjusting Font Scale Limits

Modify constants in `lib/main.dart`:

```dart
static const double _minFontSize = 0.5;  // Minimum 50%
static const double _maxFontSize = 2.0;  // Maximum 200%
static const double _fontSizeStep = 0.1; // 10% increments
```

## 📁 Project Structure

```
quran-app-android/
├── android/                    # Android native code
│   └── app/
│       ├── src/main/kotlin/    # Kotlin source files
│       └── libs/               # Native rendering library (AAR)
├── lib/                        # Flutter/Dart source files
│   ├── main.dart               # Main application
│   └── quran_page_widget.dart  # Platform view widget
├── pubspec.yaml                # Flutter dependencies
└── README.md                   # This file
```

## 🔧 Dependencies

- **Flutter SDK** - Cross-platform UI framework
- **DigitalKhatt Quran Renderer** - Native Arabic text rendering library (AAR)

### Native Rendering Library (AAR)

The app uses a native Android library (`.aar` file) for high-quality Quran text rendering with the **Digital Khatt** font. This AAR is generated from the following open-source project:

**Repository:** [https://github.com/hussainak/quran-renderer.git](https://github.com/hussainak/quran-renderer.git)

To build the AAR from source:

1. **Clone the quran-renderer repository**
   ```bash
   git clone https://github.com/hussainak/quran-renderer.git
   cd quran-renderer
   ```

2. **Build the AAR**
   ```bash
   ./gradlew assembleRelease
   ```

3. **Copy the generated AAR** to this project's `android/app/libs/` directory

The AAR provides:
- Digital Khatt font rendering engine
- Tajweed color highlighting support
- High-precision Arabic text layout
- Optimized performance for Quran pages

## 📄 License

This project is private and proprietary.

## 🤝 Contributing

This is a private repository. Please contact the maintainers for contribution guidelines.

## 📞 Support

For issues and feature requests, please create an issue in the repository.

---

Made with ❤️ for the Muslim Ummah
