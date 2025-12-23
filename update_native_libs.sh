#!/bin/bash
# update_native_libs.sh - Updates native libraries from quran-renderer build output
#
# Usage: ./update_native_libs.sh [path_to_quran_renderer]
#
# If no path is provided, defaults to: ~/Desktop/Projects/quran-renderer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDERER_PATH="${1:-$HOME/Desktop/Projects/quran-renderer}"
BUILD_OUTPUT="$RENDERER_PATH/build/final-output"

echo "=========================================="
echo "Quran Renderer Native Library Updater"
echo "=========================================="
echo ""
echo "Source: $BUILD_OUTPUT"
echo "Target: $SCRIPT_DIR"
echo ""

# Check source exists
if [ ! -d "$BUILD_OUTPUT" ]; then
    echo "❌ ERROR: Build output not found at: $BUILD_OUTPUT"
    echo "   Please build quran-renderer first or provide correct path."
    exit 1
fi

# Define library mappings (source -> destination)
declare -A LIB_MAP=(
    ["android-arm64-v8a"]="android/app/src/main/jniLibs/arm64-v8a"
    ["android-armeabi-v7a"]="android/app/src/main/jniLibs/armeabi-v7a"
    ["android-x86_64"]="android/app/src/main/jniLibs/x86_64"
    ["linux-x86_64"]="linux/libs"
)

echo "📦 Copying libraries..."
for src_name in "${!LIB_MAP[@]}"; do
    src="$BUILD_OUTPUT/$src_name/libquranrenderer.so"
    dst_dir="$SCRIPT_DIR/${LIB_MAP[$src_name]}"
    dst="$dst_dir/libquranrenderer.so"
    
    if [ -f "$src" ]; then
        mkdir -p "$dst_dir"
        cp "$src" "$dst"
        size=$(ls -lh "$dst" | awk '{print $5}')
        echo "   ✅ $src_name → ${LIB_MAP[$src_name]} ($size)"
    else
        echo "   ⚠️  $src_name: Source not found, skipping"
    fi
done

# Verify symbols
echo ""
echo "🔍 Verifying exported symbols..."
JNILIBS_DIR="$SCRIPT_DIR/android/app/src/main/jniLibs"
if command -v nm &> /dev/null && [ -f "$JNILIBS_DIR/arm64-v8a/libquranrenderer.so" ]; then
    SYMBOLS=$(nm -D "$JNILIBS_DIR/arm64-v8a/libquranrenderer.so" 2>/dev/null | grep -c "quran_renderer_" || echo "0")
    echo "   Found $SYMBOLS quran_renderer_* symbols"
    
    # Check for key functions
    for func in "draw_page" "draw_text" "draw_multiline_text" "measure_text"; do
        if nm -D "$JNILIBS_DIR/arm64-v8a/libquranrenderer.so" 2>/dev/null | grep -q "quran_renderer_$func"; then
            echo "   ✅ quran_renderer_$func"
        else
            echo "   ❌ quran_renderer_$func (MISSING!)"
        fi
    done
else
    echo "   ⚠️  'nm' command not found or library missing, skipping verification"
fi

# Remove any duplicate libs folder (common mistake)
DUPE_LIBS="$SCRIPT_DIR/android/app/libs"
if [ -d "$DUPE_LIBS" ]; then
    echo ""
    echo "⚠️  Found duplicate libs folder: $DUPE_LIBS"
    echo "   Removing to prevent version conflicts..."
    rm -rf "$DUPE_LIBS"
    echo "   ✅ Removed"
fi

echo ""
echo "=========================================="
echo "✅ Libraries updated!"
echo ""
echo "Next steps:"
echo "  1. flutter clean"
echo "  2. flutter pub get"
echo "  3. flutter run"
echo "=========================================="
