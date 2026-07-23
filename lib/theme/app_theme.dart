import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF101525);
  static const navy = Color(0xFF181D33);
  
  // 💡 Orange (Ember) ની જગ્યાએ Indigo Accent કલર
  static const ember = Color(0xFF312E81); 
  static const amber = Color.fromARGB(255, 212, 151, 59);
  static const mint = Color(0xFF21C7A8);
  static const sky = Color(0xFF38A5FF);
  static const paper = Color(0xFFF6F7FB);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color.fromARGB(255, 83, 87, 99);

  // 💡 Splash Gradient માં પણ Indigo Tint સેટ કર્યો
  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ink, navy, Color(0xFF312E81), Color(0xFF312E81)],
    stops: [0, 0.34, 0.68, 1],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ink, Color(0xFF272D49), paper],
    stops: [0, 0.42, 1],
  );

  // 💡 નવું Light Indigo & Cyan Attractive Hero Gradient
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFFCFFAFE)],
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor:Color(0xFF312E81),
        primary: Color(0xFF312E81),
        secondary: AppColors.mint,
        surface: AppColors.card,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withAlpha(15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color:Color(0xFF312E81), width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:Color(0xFF312E81),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.ink.withAlpha(30)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
      ),
    );
  }

  static BoxDecoration softCard({
    Color bgColor = AppColors.card,
    Color? borderColor,
  }) {
    final bColor = borderColor ?? Colors.black.withAlpha(10);
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      border: borderColor == Colors.transparent
          ? null
          : Border.all(color: bColor),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withAlpha(20),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }
}