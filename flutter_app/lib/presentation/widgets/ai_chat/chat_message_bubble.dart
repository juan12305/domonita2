import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/color_utils.dart';
import '../../../l10n/l10n_extensions.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.isTablet,
    required this.maxBubbleWidth,
    required this.horizontalInset,
  });

  final String message;
  final bool isUser;
  final bool isTablet;
  final double maxBubbleWidth;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isTablet ? 16 : 12,
        left: isUser ? horizontalInset : 0,
        right: isUser ? 0 : horizontalInset,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: isUser
                  ? adjustOpacity(AppColors.tealAccent, 0.2)
                  : AppColors.darkSecondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
              ),
              border: Border.all(
                color: isUser ? adjustOpacity(AppColors.tealAccent, 0.3) : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUser ? Icons.person : Icons.smart_toy_rounded,
                      color: isUser ? AppColors.tealAccent : AppColors.blueAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUser
                          ? context.l10n.literal(es: 'Tú', en: 'You')
                          : context.l10n.literal(
                              es: 'Asistente IA',
                              en: 'AI assistant',
                            ),
                      style: GoogleFonts.poppins(
                        color: isUser ? AppColors.tealAccent : AppColors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: AppColors.whiteText,
                    fontSize: isTablet ? 16 : 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: isUser ? 0.2 : -0.2,
          duration: 300.ms,
        );
  }
}
