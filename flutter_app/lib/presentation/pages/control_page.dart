import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../domain/sensor_data.dart';
import '../controllers/sensor_controller.dart';
import '../widgets/particle_field.dart';
import '../theme/color_utils.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  static const LinearGradient _dayGradient = LinearGradient(
    colors: [
      Color(0xFF56CCF2),
      Color(0xFF2F80ED),
      Color(0xFF6DD5FA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _nightGradient = LinearGradient(
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SensorController>();
    final sensorData =
        context.select<SensorController, SensorData?>((c) => c.sensorData);
    final connected =
        context.select<SensorController, bool>((c) => c.connected);
    final isAutoMode =
        context.select<SensorController, bool>((c) => c.isAutoMode);
    final isBright = sensorData?.light == 0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
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
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _ConnectionStatus(connected: connected),
                      const SizedBox(height: 30),
                      Expanded(
                        child: sensorData != null
                            ? _SensorOverview(
                                data: sensorData,
                                isBright: isBright,
                                isCompact: isCompact,
                              )
                            : const _WaitingData(),
                      ),
                      _ActionPanel(
                        isAutoMode: isAutoMode,
                        isCompact: isCompact,
                        onToggleAuto: (_) => controller.toggleAutoMode(),
                        onLedOn: connected ? controller.turnLedOn : null,
                        onLedOff: connected ? controller.turnLedOff : null,
                        onFanOn: connected ? controller.turnFanOn : null,
                        onFanOff: connected ? controller.turnFanOff : null,
                        onHistory: () =>
                            Navigator.of(context).pushNamed('/history'),
                        onAiChat: () =>
                            Navigator.of(context).pushNamed('/ai_chat'),
                      ),
                    ],
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
          connected ? 'Conectado' : 'Desconectado',
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
    final spacing = isCompact ? 24.0 : 32.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: [
            _buildGaugeWithHalo(
              title: 'Temperatura',
              value: data.temperature,
              maxValue: 50,
              unit: '\u00B0C',
              color: Colors.orangeAccent,
              icon: Icons.thermostat,
              haloColor: adjustOpacity(Colors.orangeAccent, 0.35),
            ),
            _buildGaugeWithHalo(
              title: 'Humedad',
              value: data.humidity,
              maxValue: 100,
              unit: '%',
              color: isBright ? Colors.blue.shade800 : Colors.blueAccent,
              icon: Icons.water_drop,
              haloColor: isBright
                  ? adjustOpacity(Colors.white, 0.25)
                  : adjustOpacity(Colors.blueAccent, 0.3),
            ),
          ],
        ),
        const SizedBox(height: 36),
        _buildLightIndicator(data.light),
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
        'Esperando datos del sensor...',
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 16,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Manual', style: TextStyle(color: Colors.white)),
              Switch(
                value: isAutoMode,
                onChanged: onToggleAuto,
                thumbColor: const WidgetStatePropertyAll(Colors.greenAccent),
                trackColor: WidgetStatePropertyAll(
                  adjustOpacity(Colors.greenAccent, 0.3),
                ),
              ),
              const Text('Auto', style: TextStyle(color: Colors.white)),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isAutoMode
                ? Text(
                    'La IA controla los actuadores automáticamente.',
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
                final buttonWidth =
                    isCompact ? maxWidth : (maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        icon: Icons.lightbulb,
                        label: 'Encender Bombillo',
                        color: Colors.greenAccent,
                        onPressed: onLedOn,
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        icon: Icons.lightbulb_outline,
                        label: 'Apagar Bombillo',
                        color: Colors.redAccent,
                        onPressed: onLedOff,
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        icon: Icons.air,
                        label: 'Encender FAN',
                        color: Colors.blueAccent,
                        onPressed: onFanOn,
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        icon: Icons.air_outlined,
                        label: 'Apagar FAN',
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
              final buttonWidth = isCompact ? maxWidth : (maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _buildActionButton(
                      icon: Icons.history,
                      label: 'Ver Historial',
                      color: Colors.purpleAccent,
                      onPressed: onHistory,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildActionButton(
                      icon: Icons.chat,
                      label: 'Asistente IA',
                      color: Colors.tealAccent,
                      onPressed: onAiChat,
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
}) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: haloColor,
          blurRadius: 40,
          spreadRadius: 12,
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
}) {
  return SizedBox(
    height: 220,
    width: 170,
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
                  Icon(icon, color: color, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    '${value.toStringAsFixed(1)}$unit',
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
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
                Icon(
                  icon,
                  color: effectiveColor,
                  size: 24,
                ),
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

Widget _buildLightIndicator(int light) {
  final bool isBright = light == 0;
  final Color color = isBright ? Colors.yellowAccent : Colors.indigoAccent;
  final String status = isBright ? 'Mucha luz' : 'Poca luz';
  final IconData icon =
      isBright ? Icons.wb_sunny_rounded : Icons.nightlight_round;

  return Container(
    height: 220,
    width: 220,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          adjustOpacity(color, isBright ? 0.65 : 0.4),
          adjustOpacity(color, isBright ? 0.15 : 0.1),
        ],
      ),
      border: Border.all(color: adjustOpacity(Colors.white, 0.12), width: 2),
      boxShadow: [
        BoxShadow(
          color: adjustOpacity(color, 0.5),
          blurRadius: isBright ? 30 : 10,
          spreadRadius: isBright ? 10 : 2,
        ),
      ],
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 60)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 1200.ms,
              ),
          const SizedBox(height: 12),
          Text(
            status,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Luz ambiental',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}
