import 'package:flutter/material.dart';

class AppColors {
  // 🟢 Main Green Theme Colors
  static const primaryGreen = Color(0xFF0F8A4B);
  static const darkGreen = Color(0xFF074726);
  static const lightGreenBg = Color(0xFFF0FDF4);
  static const mint = Color(0xFF00FF88);
  
  // 🟢 Missing Variables Added (Green Theme Match)
  static const amber = Color(0xFFD97706); // Warm Amber / Orange for Pending status
  static const navy = Color(0xFF0F8A4B);  // Replacing Navy with Primary Green
  
  // ⚪ Canvas & Neutral Colors
  static const paper = Color(0xFFF8FAFC);
  static const card = Colors.white;
  static const ink = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);

  // 🟢 Accent
  static const ember = Color(0xFF0F8A4B); 
  static const sky = Color(0xFF38A5FF);

  // 🌈 Gradients
  static const splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryGreen, darkGreen],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryGreen, lightGreenBg, paper],
    stops: [0.0, 0.35, 1.0],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, darkGreen],
  );
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGreen,
        secondary: AppColors.ember,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        background: AppColors.paper,
        onBackground: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.ink),
        bodyMedium: TextStyle(color: AppColors.muted),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }

  static BoxDecoration softCard({Color? bgColor}) {
    return BoxDecoration(
      color: bgColor ?? AppColors.card,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.shade200, width: 1),
    );
  }
}