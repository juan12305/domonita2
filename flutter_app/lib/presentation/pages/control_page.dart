import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/sensor_data.dart';
import '../../l10n/l10n_extensions.dart';
import '../controllers/language_controller.dart';
import '../controllers/sensor_controller.dart';
import '../widgets/particle_field.dart';
import '../theme/color_utils.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  static const LinearGradient _dayGradient = LinearGradient(
    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED), Color(0xFF6DD5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _nightGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SensorController>();
    final sensorData = context.select<SensorController, SensorData?>(
      (c) => c.sensorData,
    );
    final connected = context.select<SensorController, bool>(
      (c) => c.connected,
    );
    final isAutoMode = context.select<SensorController, bool>(
      (c) => c.isAutoMode,
    );
    final level = context.select<SensorController, AiConsumptionLevel>(
      (c) => c.level,
    );
    final decisionDuration = context.select<SensorController, Duration>(
      (c) => c.decisionCacheDuration,
    );
    final languageController = context.read<LanguageController>();
    final currentLocale = context.select<LanguageController, Locale>(
      (c) => c.locale,
    );
    final isBright = sensorData?.light == 0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            final topSpacing = isCompact ? 12.0 : 16.0;
            final spacingAfterStatus = isCompact ? 20.0 : 30.0;
            final spacingAfterSensors = isCompact ? 24.0 : 36.0;

            final sensorContent = sensorData != null
                ? _SensorOverview(
                    data: sensorData,
                    isBright: isBright,
                    isCompact: isCompact,
                  )
                : const _WaitingData();
            final actionPanel = _ActionPanel(
              isAutoMode: isAutoMode,
              isCompact: isCompact,
              onToggleAuto: controller.setAutoMode,
              onLedOn: connected ? controller.turnLedOn : null,
              onLedOff: connected ? controller.turnLedOff : null,
              onFanOn: connected ? controller.turnFanOn : null,
              onFanOff: connected ? controller.turnFanOff : null,
              onHistory: () => Navigator.of(context).pushNamed('/history'),
              onAiChat: () => Navigator.of(context).pushNamed('/ai_chat'),
              onVoiceControl: () => Navigator.of(context).pushNamed('/voice_control'),
            );
            final statusBanner = _ConnectionStatus(connected: connected);

            return Stack(
              fit: StackFit.expand,
              children: [
                const ParticleField(),
                AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: isBright ? _dayGradient : _nightGradient,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16.0 : 32.0,
                      vertical: isCompact ? 16.0 : 24.0,
                    ),
                    child: isCompact
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: topSpacing),
                                statusBanner,
                                SizedBox(height: spacingAfterStatus),
                                Center(child: sensorContent),
                                SizedBox(height: spacingAfterSensors),
                                actionPanel,
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              SizedBox(height: topSpacing),
                              statusBanner,
                              SizedBox(height: spacingAfterStatus),
                              Expanded(child: Center(child: sensorContent)),
                              SizedBox(height: spacingAfterSensors),
                              actionPanel,
                            ],
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _TopMenu(
                    currentLevel: level,
                    decisionDuration: decisionDuration,
                    currentLocale: currentLocale,
                    onLevelChanged: controller.setConsumptionLevel,
                    onLocaleChanged: languageController.setLocale,
                    onLogout: () async {
                      try {
                        await Supabase.instance.client.auth.signOut();
                      } catch (_) {
                        // ignore errors; navigation proceeds regardless
                      }
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.greenAccent : Colors.redAccent;
    final statusLabel = connected
        ? context.l10n.literal(es: 'Conectado', en: 'Connected')
        : context.l10n.literal(es: 'Desconectado', en: 'Disconnected');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          connected ? Icons.wifi : Icons.wifi_off,
          color: color,
          size: 32,
        ).animate().scale(duration: 800.ms),
        const SizedBox(width: 8),
        Text(
          statusLabel,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(duration: 700.ms),
      ],
    );
  }
}


class _TopMenu extends StatelessWidget {
  const _TopMenu({
    required this.currentLevel,
    required this.decisionDuration,
    required this.currentLocale,
    required this.onLevelChanged,
    required this.onLocaleChanged,
    required this.onLogout,
  });

  final AiConsumptionLevel currentLevel;
  final Duration decisionDuration;
  final Locale currentLocale;
  final ValueChanged<AiConsumptionLevel> onLevelChanged;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageLabel = currentLocale.languageCode == 'es'
        ? l10n.t('language_spanish')
        : l10n.t('language_english');
    return PopupMenuButton<_ControlMenuAction>(
      tooltip: l10n.t('control_menu_tooltip'),
      color: adjustOpacity(Colors.black, 0.85),
      offset: const Offset(-4, 8),
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: adjustOpacity(Colors.black, 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: adjustOpacity(Colors.white, 0.15)),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<_ControlMenuAction>(
          value: _ControlMenuAction.settings,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune, color: Colors.tealAccent),
            title: Text(
              l10n.t('control_menu_ai_consumption'),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l10n.t(
                'control_menu_frequency',
                params: {
                  'seconds': decisionDuration.inSeconds.toString(),
                },
              ),
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
            ),
          ),
        ),
        PopupMenuItem<_ControlMenuAction>(
          value: _ControlMenuAction.language,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language, color: Colors.lightBlueAccent),
            title: Text(
              l10n.t('control_menu_language'),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l10n.t(
                'control_menu_language_current',
                params: {'language': languageLabel},
              ),
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
            ),
          ),
        ),
        PopupMenuItem<_ControlMenuAction>(
          value: _ControlMenuAction.logout,
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                l10n.t('action_logout'),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (action) async {
        switch (action) {
          case _ControlMenuAction.settings:
            final selected = await _showSettingsDialog(context);
            if (selected != null && selected != currentLevel) {
              onLevelChanged(selected);
            }
            break;
          case _ControlMenuAction.language:
            final selectedLocale =
                await _showLanguageDialog(context, currentLocale);
            if (selectedLocale != null &&
                selectedLocale.languageCode != currentLocale.languageCode) {
              await onLocaleChanged(selectedLocale);
            }
            break;
          case _ControlMenuAction.logout:
            await onLogout();
            break;
        }
      },
    );
  }

  Future<AiConsumptionLevel?> _showSettingsDialog(BuildContext context) {
    return showDialog<AiConsumptionLevel>(
      context: context,
      builder: (dialogContext) {
        AiConsumptionLevel selectedLevel = currentLevel;
        return StatefulBuilder(
          builder: (context, setState) {
            final dialogL10n = context.l10n;
            return AlertDialog(
              title: Text(
                dialogL10n.literal(es: 'Consumo de IA', en: 'AI consumption'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<AiConsumptionLevel>(
                    value: selectedLevel,
                    isExpanded: true,
                    dropdownColor: Colors.black87,
                    iconEnabledColor: Colors.white,
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: AiConsumptionLevel.values
                        .map(
                          (level) => DropdownMenuItem<AiConsumptionLevel>(
                                value: level,
                                child: Text(_labelForLevel(context, level)),
                              ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedLevel = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    dialogL10n.literal(
                      es:
                          'Frecuencia: cada ${_durationForLevel(selectedLevel).inSeconds}s',
                      en:
                          'Frequency: every ${_durationForLevel(selectedLevel).inSeconds}s',
                    ),
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    dialogL10n.literal(es: 'Cancelar', en: 'Cancel'),
                  ),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedLevel),
                  child: Text(
                    dialogL10n.literal(es: 'Guardar', en: 'Save'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Locale?> _showLanguageDialog(
    BuildContext context,
    Locale selectedLocale,
  ) {
    final l10n = context.l10n;
    final locales = [
      const Locale('es'),
      const Locale('en'),
    ];
    return showDialog<Locale>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(l10n.t('control_menu_language')),
          children: locales.map((locale) {
            final label = locale.languageCode == 'es'
                ? l10n.t('language_spanish')
                : l10n.t('language_english');
            final isSelected =
                locale.languageCode == selectedLocale.languageCode;
            return ListTile(
              leading: Icon(
                Icons.flag,
                color: isSelected ? Colors.tealAccent : Colors.white70,
              ),
              title: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.tealAccent)
                  : null,
              onTap: () => Navigator.of(dialogContext).pop(locale),
            );
          }).toList(),
        );
      },
    );
  }

  static Duration _durationForLevel(AiConsumptionLevel level) {
    switch (level) {
      case AiConsumptionLevel.high:
        return const Duration(seconds: 10);
      case AiConsumptionLevel.medium:
        return const Duration(seconds: 15);
      case AiConsumptionLevel.low:
        return const Duration(seconds: 25);
    }
  }

  static String _labelForLevel(BuildContext context, AiConsumptionLevel level) {
    final l10n = context.l10n;
    switch (level) {
      case AiConsumptionLevel.high:
        return l10n.literal(es: 'Alto (cada 10s)', en: 'High (every 10s)');
      case AiConsumptionLevel.medium:
        return l10n.literal(es: 'Medio (cada 15s)', en: 'Medium (every 15s)');
      case AiConsumptionLevel.low:
        return l10n.literal(es: 'Bajo (cada 25s)', en: 'Low (every 25s)');
    }
  }
}
class _SensorOverview extends StatelessWidget {
  const _SensorOverview({
    required this.data,
    required this.isBright,
    required this.isCompact,
  });

  final SensorData data;
  final bool isBright;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final temperatureLabel =
        l10n.literal(es: 'Temperatura', en: 'Temperature');
    final humidityLabel = l10n.literal(es: 'Humedad', en: 'Humidity');
    final double spacing = isCompact ? 16.0 : 32.0;
    final double runSpacing = isCompact ? 16.0 : 32.0;
    final double indicatorSpacing = isCompact ? 24.0 : 36.0;
    final double gaugeScale = isCompact ? 0.9 : 1.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.center,
          children: [
            _buildGaugeWithHalo(
              title: temperatureLabel,
              value: data.temperature,
              maxValue: 50,
              unit: '\u00B0C',
              color: Colors.orangeAccent,
              icon: Icons.thermostat,
              haloColor: adjustOpacity(Colors.orangeAccent, 0.35),
              scale: gaugeScale,
            ),
            _buildGaugeWithHalo(
              title: humidityLabel,
              value: data.humidity,
              maxValue: 100,
              unit: '%',
              color: isBright ? Colors.blue.shade800 : Colors.blueAccent,
              icon: Icons.water_drop,
              haloColor: isBright
                  ? adjustOpacity(Colors.white, 0.25)
                  : adjustOpacity(Colors.blueAccent, 0.3),
              scale: gaugeScale,
            ),
          ],
        ),
        SizedBox(height: indicatorSpacing),
        _buildLightIndicator(
          context,
          data.light,
          isCompact: isCompact,
        ),
      ],
    );
  }
}

class _WaitingData extends StatelessWidget {
  const _WaitingData();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.literal(
          es: 'Esperando datos del sensor...',
          en: 'Waiting for sensor data...',
        ),
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.isAutoMode,
    required this.isCompact,
    required this.onToggleAuto,
    this.onLedOn,
    this.onLedOff,
    this.onFanOn,
    this.onFanOff,
    required this.onHistory,
    required this.onAiChat,
    required this.onVoiceControl,
  });

  final bool isAutoMode;
  final bool isCompact;
  final ValueChanged<bool> onToggleAuto;
  final VoidCallback? onLedOn;
  final VoidCallback? onLedOff;
  final VoidCallback? onFanOn;
  final VoidCallback? onFanOff;
  final VoidCallback onHistory;
  final VoidCallback onAiChat;
  final VoidCallback onVoiceControl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manualLabel = l10n.literal(es: 'Manual', en: 'Manual');
    final autoLabel = l10n.literal(es: 'Auto', en: 'Auto');
    final aiHint = l10n.literal(
      es: 'La IA controla los actuadores automáticamente.',
      en: 'AI is controlling the actuators automatically.',
    );
    final lightOnLabel =
        l10n.literal(es: 'Encender Bombillo', en: 'Turn light on');
    final lightOffLabel =
        l10n.literal(es: 'Apagar Bombillo', en: 'Turn light off');
    final fanOnLabel =
        l10n.literal(es: 'Encender FAN', en: 'Turn fan on');
    final fanOffLabel =
        l10n.literal(es: 'Apagar FAN', en: 'Turn fan off');
    final historyLabel =
        l10n.literal(es: 'Ver Historial', en: 'View history');
    final assistantLabel =
        l10n.literal(es: 'Asistente IA', en: 'AI assistant');
    final voiceLabel =
        l10n.literal(es: 'Control por Voz', en: 'Voice control');
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12.0 : 20.0,
        vertical: isCompact ? 12.0 : 16.0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(manualLabel, style: const TextStyle(color: Colors.white)),
              Switch(
                value: isAutoMode,
                onChanged: onToggleAuto,
                thumbColor: const WidgetStatePropertyAll(Colors.greenAccent),
                trackColor: WidgetStatePropertyAll(
                  adjustOpacity(Colors.greenAccent, 0.3),
                ),
              ),
              Text(autoLabel, style: const TextStyle(color: Colors.white)),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isAutoMode
                ? Text(
                    aiHint,
                    key: const ValueKey('auto-hint'),
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms)
                : const SizedBox.shrink(key: ValueKey('manual-hint')),
          ),
          if (!isAutoMode) ...[
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final double spacing = isCompact ? 12.0 : 16.0;
                final buttonWidth = isCompact
                    ? maxWidth
                    : (maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        icon: Icons.lightbulb,
                        label: lightOnLabel,
                        color: Colors.greenAccent,
                        onPressed: onLedOn,
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        icon: Icons.lightbulb_outline,
                        label: lightOffLabel,
                        color: Colors.redAccent,
                        onPressed: onLedOff,
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        icon: Icons.air,
                        label: fanOnLabel,
                        color: Colors.blueAccent,
                        onPressed: onFanOn,
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        icon: Icons.air_outlined,
                        label: fanOffLabel,
                        color: Colors.orangeAccent,
                        onPressed: onFanOff,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final double spacing = isCompact ? 12.0 : 16.0;
              final buttonWidth = isCompact
                  ? maxWidth
                  : (maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _buildActionButton(
                      icon: Icons.history,
                      label: historyLabel,
                      color: Colors.purpleAccent,
                      onPressed: onHistory,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildActionButton(
                      icon: Icons.chat,
                      label: assistantLabel,
                      color: Colors.tealAccent,
                      onPressed: onAiChat,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildActionButton(
                      icon: Icons.mic,
                      label: voiceLabel,
                      color: Colors.pinkAccent,
                      onPressed: onVoiceControl,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _buildGaugeWithHalo({
  required String title,
  required double value,
  required double maxValue,
  required String unit,
  required Color color,
  required IconData icon,
  required Color haloColor,
  double scale = 1.0,
}) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: haloColor,
          blurRadius: 40 * scale,
          spreadRadius: 12 * scale,
        ),
      ],
    ),
    child: _buildGauge(
      title: title,
      value: value,
      maxValue: maxValue,
      unit: unit,
      color: color,
      icon: icon,
      scale: scale,
    ),
  );
}

Widget _buildGauge({
  required String title,
  required double value,
  required double maxValue,
  required String unit,
  required Color color,
  required IconData icon,
  double scale = 1.0,
}) {
  final double width = 170 * scale;
  final double height = 220 * scale;
  final double iconSize = 36 * scale;
  final double valueFontSize = 24 * scale;
  final double titleFontSize = 16 * scale;
  return SizedBox(
    height: height,
    width: width,
    child: SfRadialGauge(
      enableLoadingAnimation: true,
      animationDuration: 1000,
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: maxValue,
          showLabels: false,
          showTicks: false,
          axisLineStyle: const AxisLineStyle(
            thickness: 0.2,
            color: Colors.white24,
            thicknessUnit: GaugeSizeUnit.factor,
          ),
          pointers: [
            RangePointer(
              value: value.clamp(0, maxValue),
              width: 0.25,
              sizeUnit: GaugeSizeUnit.factor,
              color: color,
              cornerStyle: CornerStyle.bothCurve,
            ),
          ],
          annotations: [
            GaugeAnnotation(
              widget: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: iconSize),
                  SizedBox(height: 10 * scale),
                  Text(
                    '${value.toStringAsFixed(1)}$unit',
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: titleFontSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback? onPressed,
}) {
  final bool isEnabled = onPressed != null;
  final Color effectiveColor = isEnabled ? color : adjustOpacity(color, 0.35);
  final Color foreground = isEnabled ? Colors.white : Colors.white54;

  return Opacity(
    opacity: isEnabled ? 1 : 0.7,
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            adjustOpacity(effectiveColor, 0.3),
            adjustOpacity(effectiveColor, 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: adjustOpacity(effectiveColor, 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: adjustOpacity(effectiveColor, 0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: adjustOpacity(effectiveColor, 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: effectiveColor, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(duration: 400.ms),
  );
}

enum _ControlMenuAction { settings, language, logout }

Widget _buildLightIndicator(
  BuildContext context,
  int light, {
  required bool isCompact,
}) {
  final l10n = context.l10n;
  final bool isBright = light == 0;
  final Color color = isBright ? Colors.yellowAccent : Colors.indigoAccent;
  final String status = isBright
      ? l10n.literal(es: 'Mucha luz', en: 'Lots of light')
      : l10n.literal(es: 'Poca luz', en: 'Low light');
  final IconData icon = isBright
      ? Icons.wb_sunny_rounded
      : Icons.nightlight_round;
  final double scale = isCompact ? 0.82 : 1.0;
  final double size = 220 * scale;

  return Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          adjustOpacity(color, isBright ? 0.65 : 0.4),
          adjustOpacity(color, isBright ? 0.15 : 0.1),
        ],
      ),
      border: Border.all(
        color: adjustOpacity(Colors.white, 0.12),
        width: 2 * scale,
      ),
      boxShadow: [
        BoxShadow(
          color: adjustOpacity(color, 0.5),
          blurRadius: (isBright ? 30 : 10) * scale,
          spreadRadius: (isBright ? 10 : 2) * scale,
        ),
      ],
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 60 * scale)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 1200.ms,
              ),
          SizedBox(height: 12 * scale),
          Text(
            status,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 22 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            l10n.literal(es: 'Luz ambiental', en: 'Ambient light'),
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16 * scale,
            ),
          ),
        ],
      ),
    ),
  );
}
