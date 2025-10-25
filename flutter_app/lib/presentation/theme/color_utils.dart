import 'dart:ui';

Color adjustOpacity(Color color, double opacity) =>
    color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
