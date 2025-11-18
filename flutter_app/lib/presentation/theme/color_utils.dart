import 'package:flutter/material.dart';

Color adjustOpacity(Color color, double opacity) =>
    color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

/// Colores de la aplicación
class AppColors {
  AppColors._();

  // Colores primarios
  static const Color tealAccent = Colors.tealAccent;
  static const Color cyanAccent = Colors.cyanAccent;
  static const Color blueAccent = Colors.blueAccent;
  static const Color redAccent = Colors.redAccent;

  // Colores de fondo
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSecondary = Color(0xFF16213E);
  static const Color darkTertiary = Color(0xFF0F3460);
  static const Color veryDarkBackground = Color(0xFF0F0F23);

  // Colores para fondos con opacidad
  static const Color blackBackground = Colors.black;
  static const Color whiteText = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white60 = Colors.white60;
  static const Color white38 = Colors.white38;

  // Gradientes de día
  static const LinearGradient dayGradient = LinearGradient(
    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED), Color(0xFF6DD5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradientes de noche
  static const LinearGradient nightGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
