#include <stdint.h>

// This file exists purely to ensure the QuranRenderer C API symbols are referenced
// from the Runner target. That causes the linker to pull in only the needed object
// files from the vendored static library, without using -all_load/-force_load.
//
// IMPORTANT: Do not call these at runtime; taking their addresses is enough.

// Forward-declare the C API entrypoints we use from Dart FFI.
extern void* quran_renderer_create(const void* fontData);
extern void quran_renderer_destroy(void* renderer);
extern void quran_renderer_draw_page(void* renderer, void* buffer, int pageIndex, const void* config);
extern int quran_renderer_get_page_count(void* renderer);
extern int quran_renderer_draw_text(void* renderer, void* buffer, const char* text, int textLength, const void* config);
extern int quran_renderer_draw_multiline_text(void* renderer, void* buffer, const char* text, int textLength, const void* config, float lineSpacing);
extern int quran_renderer_measure_text(void* renderer, const char* text, int textLen, int fontSize, int* width, int* height);
extern int quran_renderer_get_surah_count(void);
extern int quran_renderer_get_total_ayah_count(void);
extern int quran_renderer_get_surah_info(int surahNumber, void* info);
extern int quran_renderer_get_ayah_count(int surahNumber);
extern int quran_renderer_get_surah_start_page(int surahNumber);
extern int quran_renderer_get_ayah_page(int surahNumber, int ayahNumber);
extern int quran_renderer_get_page_location(int pageIndex, void* location);

__attribute__((used))
static const void* _quran_renderer_ffi_keep_symbols[] = {
    (const void*)&quran_renderer_create,
    (const void*)&quran_renderer_destroy,
    (const void*)&quran_renderer_draw_page,
    (const void*)&quran_renderer_get_page_count,
    (const void*)&quran_renderer_draw_text,
    (const void*)&quran_renderer_draw_multiline_text,
    (const void*)&quran_renderer_measure_text,
    (const void*)&quran_renderer_get_surah_count,
    (const void*)&quran_renderer_get_total_ayah_count,
    (const void*)&quran_renderer_get_surah_info,
    (const void*)&quran_renderer_get_ayah_count,
    (const void*)&quran_renderer_get_surah_start_page,
    (const void*)&quran_renderer_get_ayah_page,
    (const void*)&quran_renderer_get_page_location,
};
