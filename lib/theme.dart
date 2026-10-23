import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final accent = ValueNotifier<Color>(accents[0]);
  static final mode = ValueNotifier<int>(0); // 0 auto, 1 light, 2 dark, 3 amoled

  static const accents = [
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFFE84393),
    Color(0xFFF39C12),
  ];

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final a = p.getInt('accent');
    if (a != null) accent.value = Color(a);
    mode.value = p.getInt('mode') ?? 0;
  }

  static Future<void> setAccent(Color c) async {
    accent.value = c;
    (await SharedPreferences.getInstance()).setInt('accent', c.toARGB32());
  }

  static Future<void> setMode(int m) async {
    mode.value = m;
    (await SharedPreferences.getInstance()).setInt('mode', m);
  }

  static ThemeData build(Brightness b, Color seed, {bool amoled = false}) {
    var s = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    if (amoled) {
      s = s.copyWith(
        surface: Colors.black,
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF111111),
        surfaceContainerHigh: const Color(0xFF181818),
        surfaceContainerHighest: const Color(0xFF202020),
      );
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      scaffoldBackgroundColor: s.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: s.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}
