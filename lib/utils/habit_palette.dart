import 'package:flutter/material.dart';

/// Palet warna terinspirasi desain "Habit Tracker App" oleh Ronas IT (Dribbble),
/// dengan ciri khas warna-warna cerah & dinamis untuk efek gamifikasi.
class HabitPalette {
  static const List<Color> backgrounds = [
    Color(0xFF728AED), // ungu-biru (primary)
    Color(0xFF7AD326), // hijau cerah
    Color(0xFFCB9444), // tan/oranye
    Color(0xFF3039C5), // biru tua
    Color(0xFFE85D9C), // pink cerah pelengkap
    Color(0xFF2BB6A3), // teal pelengkap
  ];

  // Semua teks di atas background solid ini pakai putih, supaya kontras tinggi
  static const Color foreground = Colors.white;

  static Color bg(int index) => backgrounds[index % backgrounds.length];
  static Color fg(int index) => foreground;
}
