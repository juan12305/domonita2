import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/color_utils.dart';
import '../../../l10n/l10n_extensions.dart';

class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    super.key,
    required this.controller,
    required this.isLandscape,
    required this.isLoading,
    required this.isTablet,
    required this.outerMargin,
    required this.innerPadding,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLandscape;
  final bool isLoading;
  final bool isTablet;
  final EdgeInsets outerMargin;
  final EdgeInsets innerPadding;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hintText = l10n.literal(
      es: 'Pregunta sobre tu sistema de domótica...',
      en: 'Ask about your smart home system...',
    );
    final bool allowMultiLine = isLandscape || !isTablet;

    return Container(
      margin: outerMargin,
      padding: innerPadding,
      decoration: BoxDecoration(
        color: adjustOpacity(AppColors.blackBackground, 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adjustOpacity(AppColors.whiteText, 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(color: AppColors.whiteText),
              maxLines: allowMultiLine ? 2 : 1,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.white38,
                  fontSize: isTablet ? 16 : 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: allowMultiLine ? 8 : 12,
                ),
              ),
              onSubmitted: (_) {
                if (!isLoading) onSend();
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.tealAccent, AppColors.cyanAccent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteText),
                      ),
                    )
                  : const Icon(Icons.send, color: AppColors.whiteText),
              onPressed: isLoading ? null : onSend,
              padding: EdgeInsets.all(isTablet ? 16 : 12),
            ),
          ),
        ],
      ),
    );
  }
}
