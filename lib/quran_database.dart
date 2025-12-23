import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Ayah data model
class Ayah {
  final int surahNumber;
  final int ayahNumber;
  final String text;

  Ayah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      surahNumber: map['surah_number'] as int,
      ayahNumber: map['ayah_number'] as int,
      text: map['text'] as String,
    );
  }

  @override
  String toString() => 'Ayah($surahNumber:$ayahNumber)';
}

/// Database helper for Quran text
class QuranDatabase {
  static Database? _database;
  static const String _dbName = 'quran-uthmani.db';

  /// Initialize and get the database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database from assets
  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    // Check if database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Copy from assets
      print('QuranDatabase: Copying database from assets...');

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from assets
      final data = await rootBundle.load('assets/$_dbName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write to file
      await File(path).writeAsBytes(bytes, flush: true);
      print('QuranDatabase: Database copied to $path');
    }

    // Open database
    return openDatabase(path, readOnly: true);
  }

  /// Get all ayahs for a surah
  static Future<List<Ayah>> getAyahsForSurah(int surahNumber) async {
    final db = await database;
    final results = await db.query(
      'quran',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'ayah_number',
    );
    return results.map((map) => Ayah.fromMap(map)).toList();
  }

  /// Get a specific ayah
  static Future<Ayah?> getAyah(int surahNumber, int ayahNumber) async {
    final db = await database;
    final results = await db.query(
      'quran',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
    );
    if (results.isEmpty) return null;
    return Ayah.fromMap(results.first);
  }

  /// Get full surah text as a single string (ayahs separated by newlines)
  /// Uses the End of Ayah mark ۝ (U+06DD) which renders as a decorated circle with the number inside
  static Future<String> getSurahText(int surahNumber) async {
    final ayahs = await getAyahsForSurah(surahNumber);
    return ayahs
        .map((a) => '${a.text} ۝${_toArabicNumber(a.ayahNumber)}')
        .join('\n');
  }

  /// Get full surah text with each ayah on a separate line
  static Future<List<String>> getSurahAyahTexts(int surahNumber) async {
    final ayahs = await getAyahsForSurah(surahNumber);
    return ayahs
        .map((a) => '${a.text} ۝${_toArabicNumber(a.ayahNumber)}')
        .toList();
  }

  /// Convert number to Arabic numerals
  static String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  /// Close the database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
