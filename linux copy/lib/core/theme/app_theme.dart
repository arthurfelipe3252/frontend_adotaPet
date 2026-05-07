import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Cores derivadas da paleta HSL do protótipo Lovable.
  // primary hsl(18 65% 50%) — laranja-terra
  static const Color primary = Color(0xFFD2693A);
  static const Color primaryDark = Color(0xFFA84F26);
  static const Color primaryLight = Color(0xFFE38559);

  // accent hsl(35 80% 58%) — dourado/âmbar
  static const Color accent = Color(0xFFEFA63B);

  // sage hsl(140 20% 55%) — verde acinzentado (botões "Próximo" do cadastro)
  static const Color sage = Color(0xFF7AAD83);
  static const Color sageMint = Color(0xFF6FBA9D);

  // background hsl(30 33% 97%) — creme
  static const Color background = Color(0xFFFAF6F1);
  static const Color surface = Color(0xFFFCFAF7);

  // foreground hsl(20 10% 15%) — quase-preto morno
  static const Color foreground = Color(0xFF2A2622);
  static const Color mutedForeground = Color(0xFF8A8378);

  static const Color destructive = Color(0xFFD93939);
  static const Color border = Color(0xFFE2DCD2);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        tertiary: sage,
        onTertiary: Colors.white,
        error: destructive,
        onError: Colors.white,
        surface: surface,
        onSurface: foreground,
      ),
      scaffoldBackgroundColor: background,
    );

    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.quicksand(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      displayMedium: GoogleFonts.quicksand(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      headlineSmall: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1ECE3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: destructive, width: 2),
        ),
        labelStyle: const TextStyle(color: foreground),
        hintStyle: const TextStyle(color: mutedForeground),
        prefixIconColor: mutedForeground,
        suffixIconColor: mutedForeground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          side: const BorderSide(color: border),
          textStyle: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
    );
  }
}
