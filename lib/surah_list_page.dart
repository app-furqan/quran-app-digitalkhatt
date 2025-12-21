import 'package:flutter/material.dart';
import 'quran_renderer.dart';

class SurahListPage extends StatefulWidget {
  final Function(int pageIndex) onSurahSelected;

  const SurahListPage({super.key, required this.onSurahSelected});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  List<SurahInfo> _surahs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    setState(() => _isLoading = true);

    try {
      final surahCount = QuranRenderer.getSurahCount();
      final surahs = <SurahInfo>[];

      for (int i = 1; i <= surahCount; i++) {
        final info = QuranRenderer.getSurahInfo(i);
        if (info != null) {
          surahs.add(info);
        }
      }

      setState(() {
        _surahs = surahs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading surahs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surahs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _surahs.length,
              itemBuilder: (context, index) {
                final surah = _surahs[index];
                return _buildSurahTile(surah);
              },
            ),
    );
  }

  Widget _buildSurahTile(SurahInfo surah) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${surah.number}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                surah.nameEnglish,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              surah.nameArabic,
              style: const TextStyle(fontSize: 20, fontFamily: 'Arabic'),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              surah.nameTrans,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: surah.type.toLowerCase() == 'meccan'
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    surah.type,
                    style: TextStyle(
                      fontSize: 11,
                      color: surah.type.toLowerCase() == 'meccan'
                          ? Colors.orange.shade900
                          : Colors.green.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${surah.ayahCount} Ayahs',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Page ${surah.startPage + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigate to the surah's starting page
          widget.onSurahSelected(surah.startPage);
          Navigator.pop(context);
        },
      ),
    );
  }
}
