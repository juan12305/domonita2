import '../../controllers/sensor_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';

/// Normaliza una acción a String
String? normalizeAction(dynamic rawAction) {
  if (rawAction == null) return null;
  if (rawAction is String) return rawAction.trim();
  if (rawAction is Map && rawAction['action'] is String) {
    return (rawAction['action'] as String).trim();
  }
  return rawAction.toString().trim();
}

/// Verifica si una acción parece ser "auto mode on"
bool looksLikeAutoModeOnAction(String action) {
  if (!action.contains('AUTO')) return false;
  return VoiceCommandActions.autoOnKeywords.any((keyword) => action.contains(keyword));
}

/// Verifica si una acción parece ser "auto mode off"
bool looksLikeAutoModeOffAction(String action) {
  if (!action.contains('AUTO')) return false;
  return VoiceCommandActions.autoOffKeywords.any((keyword) => action.contains(keyword));
}

/// Enum para intención de modo automático
enum AutoIntent { on, off, none }

/// Detecta la intención de modo automático en el texto
AutoIntent detectAutoIntent(String normalized) {
  // Verificar frases de apagado
  for (final phrase in IntentKeywords.autoOffPhrases) {
    if (normalized.contains(phrase)) {
      return AutoIntent.off;
    }
  }

  // Verificar frases de encendido
  for (final phrase in IntentKeywords.autoOnPhrases) {
    if (normalized.contains(phrase)) {
      return AutoIntent.on;
    }
  }

  // Verificar si menciona modo automático
  final mentionsAuto = IntentKeywords.autoModeKeywords.any((keyword) => normalized.contains(keyword));
  if (!mentionsAuto) {
    return AutoIntent.none;
  }

  final wantsOn = containsAny(normalized, IntentKeywords.turnOnKeywords);
  final wantsOff = containsAny(normalized, IntentKeywords.turnOffKeywords);

  if (wantsOn && !wantsOff) return AutoIntent.on;
  if (wantsOff && !wantsOn) return AutoIntent.off;

  return AutoIntent.none;
}

/// Mensaje de intención manejada
class HandledIntentMessage {
  const HandledIntentMessage({
    required this.text,
    this.affectedLight = false,
    this.affectedFan = false,
  });

  final String text;
  final bool affectedLight;
  final bool affectedFan;
}

/// Maneja intenciones de lenguaje natural
List<HandledIntentMessage> handleNaturalLanguageIntent(
  String text,
  SensorController controller,
  AppLocalizations l10n,
) {
  final lower = text.toLowerCase();
  final normalized = stripDiacritics(lower);

  final wantsOn = containsAny(normalized, IntentKeywords.turnOnKeywords);
  final wantsOff = containsAny(normalized, IntentKeywords.turnOffKeywords);
  final mentionsLight = containsAny(normalized, IntentKeywords.lightKeywords);
  final mentionsFan = containsAny(normalized, IntentKeywords.fanKeywords);

  final handledMessages = <HandledIntentMessage>[];

  if (mentionsLight && wantsOn && !wantsOff) {
    controller.turnLedOn();
    handledMessages.add(
      HandledIntentMessage(
        text: l10n.literal(es: 'Bombillo encendido.', en: 'Light turned on.'),
        affectedLight: true,
      ),
    );
  } else if (mentionsLight && wantsOff && !wantsOn) {
    controller.turnLedOff();
    handledMessages.add(
      HandledIntentMessage(
        text: l10n.literal(es: 'Bombillo apagado.', en: 'Light turned off.'),
        affectedLight: true,
      ),
    );
  }

  if (mentionsFan && wantsOn && !wantsOff) {
    controller.turnFanOn();
    handledMessages.add(
      HandledIntentMessage(
        text: l10n.literal(es: 'Ventilador encendido.', en: 'Fan turned on.'),
        affectedFan: true,
      ),
    );
  } else if (mentionsFan && wantsOff && !wantsOn) {
    controller.turnFanOff();
    handledMessages.add(
      HandledIntentMessage(
        text: l10n.literal(es: 'Ventilador apagado.', en: 'Fan turned off.'),
        affectedFan: true,
      ),
    );
  }

  return handledMessages;
}

/// Verifica si el texto contiene alguno de los patrones
bool containsAny(String text, List<String> patterns) {
  for (final pattern in patterns) {
    if (text.contains(pattern)) return true;
  }
  return false;
}

/// Elimina diacríticos del texto
String stripDiacritics(String input) {
  return input
      .replaceAll(RegExp(r'[\u00E1\u00E0\u00E2\u00E3\u00E4]'), 'a')
      .replaceAll(RegExp(r'[\u00E9\u00E8\u00EA\u00EB]'), 'e')
      .replaceAll(RegExp(r'[\u00ED\u00EC\u00EE\u00EF]'), 'i')
      .replaceAll(RegExp(r'[\u00F3\u00F2\u00F4\u00F5\u00F6]'), 'o')
      .replaceAll(RegExp(r'[\u00FA\u00F9\u00FB\u00FC]'), 'u')
      .replaceAll('\u00F1', 'n')
      .replaceAll('\u00E7', 'c');
}
