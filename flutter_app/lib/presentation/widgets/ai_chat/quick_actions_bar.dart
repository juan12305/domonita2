import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/color_utils.dart';
import '../../../l10n/l10n_extensions.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({
    super.key,
    required this.isLoading,
    required this.isTablet,
    required this.messageCount,
    required this.onGenerateAnalysis,
    required this.horizontalPadding,
  });

  final bool isLoading;
  final bool isTablet;
  final int messageCount;
  final VoidCallback onGenerateAnalysis;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final analysisLabel =
        l10n.literal(es: 'Análisis de Datos', en: 'Data analysis');
    final generatingLabel =
        l10n.literal(es: 'Generando...', en: 'Generating...');
    final messagesLabel = l10n.literal(es: 'mensajes', en: 'messages');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isTablet ? 12 : 8,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stackContent = constraints.maxWidth < 420;
          final Widget analysisButton = SizedBox(
            width: stackContent ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onGenerateAnalysis,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics_outlined),
              label: Text(
                isLoading ? generatingLabel : analysisLabel,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: adjustOpacity(AppColors.tealAccent, 0.12),
                foregroundColor: AppColors.tealAccent,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : (stackContent ? 18 : 16),
                  vertical: isTablet ? 14 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.tealAccent, width: 1),
                ),
                elevation: 0,
              ),
            ),
          );

          final Widget messageCounter = Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: stackContent ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: adjustOpacity(AppColors.blueAccent, 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: adjustOpacity(AppColors.blueAccent, 0.35)),
            ),
            child: Text(
              '$messageCount $messagesLabel',
              style: GoogleFonts.poppins(
                color: AppColors.blueAccent,
                fontSize: stackContent ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );

          if (stackContent) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                analysisButton,
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: messageCounter,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: analysisButton),
              const SizedBox(width: 12),
              messageCounter,
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
