import 'package:flutter/material.dart';

/// Soft Medical theme: teal/white, rounded corners, clean UI.
class AppColors {
  static const Color primaryColor = Color(0xFF00897B); // Teal 600
  static const Color primaryLight = Color(0xFF4DB6AC); // Teal 300
  static const Color primaryDark = Color(0xFF00695C);  // Teal 800
  static const Color accentColor = Color(0xFF26A69A);  // Teal 400

  static const Color backgroundColor = Color(0xFFE0F2F1); // Teal 50
  static const Color backgroundColor2 = Color(0xFFB2DFDB); // Teal 100
  static const Color surfaceColor = Color(0xFFFFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE0F2F1), // Teal 50
      Color(0xFFF1F8E9), // Light green 50
      Color(0xFFE8F5E9), // Green 50
      Color(0xFFE0F7FA), // Cyan 50
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  static const LinearGradient backgroundGradientAlt = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFE8F5E9),
      Color(0xFFE0F2F1),
      Color(0xFFE0F7FA),
      Color(0xFFF1F8E9),
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textAccent = Color(0xFF00897B);

  // Vitals indicators
  static const Color sugarNormal = Color(0xFF4CAF50);
  static const Color sugarWarning = Color(0xFFFFA726);
  static const Color sugarHigh = Color(0xFFE53935);
}

class AppStyles {
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusCard = 20.0;
}
