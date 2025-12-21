#include <stdio.h>
#include <dlfcn.h>

typedef int (*get_surah_count_fn)();
typedef bool (*get_surah_info_fn)(int, void*);

struct QuranSurahInfo {
    int number;
    int ayahCount;
    int startAyah;
    const char* nameArabic;
    const char* nameTrans;
    const char* nameEnglish;
    const char* type;
    int revelationOrder;
    int rukuCount;
};

int main() {
    void* lib = dlopen("linux/libs/libquranrenderer.so", RTLD_NOW);
    if (!lib) {
        printf("Failed to load library: %s\n", dlerror());
        return 1;
    }

    auto getSurahCount = (get_surah_count_fn)dlsym(lib, "quran_renderer_get_surah_count");
    auto getSurahInfo = (get_surah_info_fn)dlsym(lib, "quran_renderer_get_surah_info");

    if (!getSurahCount || !getSurahInfo) {
        printf("Failed to load symbols\n");
        return 1;
    }

    printf("Total surahs: %d\n", getSurahCount());

    QuranSurahInfo info;
    if (getSurahInfo(1, &info)) {
        printf("Surah 1: %s (%s) - %s - %d ayahs\n",
               info.nameEnglish, info.nameTrans, info.nameArabic, info.ayahCount);
    }

    dlclose(lib);
    return 0;
}
