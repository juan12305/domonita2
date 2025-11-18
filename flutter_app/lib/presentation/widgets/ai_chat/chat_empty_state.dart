import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/color_utils.dart';
import '../../../l10n/l10n_extensions.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: adjustOpacity(AppColors.tealAccent, 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.tealAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.literal(
              es: '¡Hola! Soy tu asistente de IA',
              en: 'Hi! I am your AI assistant',
            ),
            style: GoogleFonts.poppins(
              color: AppColors.whiteText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.literal(
              es:
                  'Pregúntame sobre tu sistema de domótica,\nlos sensores o genera un análisis de datos.',
              en:
                  'Ask me about your smart home system,\nsensors, or generate a data analysis.',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }
}
