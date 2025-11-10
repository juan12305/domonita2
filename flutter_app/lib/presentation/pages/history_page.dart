import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/sensor_data.dart';
import '../../l10n/l10n_extensions.dart';
import '../controllers/sensor_controller.dart';
import '../theme/color_utils.dart';
import '../widgets/particle_field.dart';
import 'dashboard_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
    final controller = context.watch<SensorController>();
    final data = controller.sensorData;
    final connected = controller.connected;
    final allData = controller.repository.allSensorData;
    final isBright = data == null ? true : data.light == 0;
    final gradient = isBright ? _dayGradient : _nightGradient;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ParticleField(),
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(gradient: gradient),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 32),
                        ).animate().scale(duration: 400.ms),
                        Text(
                          context.l10n.literal(
                            es: 'Historial de Datos',
                            en: 'Data history',
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(duration: 700.ms),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DashboardPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bar_chart_rounded,
                              color: Colors.white, size: 32),
                        ).animate().scale(duration: 400.ms),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HistoryConnectionStatus(connected: connected),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: allData.isEmpty
                            ? _EmptyHistoryMessage(isBright: isBright)
                            : _HistoryList(
                                isBright: isBright,
                                entries: allData,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryConnectionStatus extends StatelessWidget {
  const _HistoryConnectionStatus({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.greenAccent : Colors.redAccent;
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          connected ? Icons.wifi : Icons.wifi_off,
          color: color,
          size: 24,
        ).animate().scale(duration: 800.ms),
        const SizedBox(width: 8),
        Text(
          connected
              ? l10n.literal(es: 'Conectado', en: 'Connected')
              : l10n.literal(es: 'Desconectado', en: 'Disconnected'),
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(duration: 700.ms),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.entries,
    required this.isBright,
  });

  final List<SensorData> entries;
  final bool isBright;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final l10n = context.l10n;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final reverseIndex = entries.length - 1 - index;
        final item = entries[reverseIndex];
        final dateTime = DateTime.tryParse(item.timestamp);
        final formattedDate =
            dateTime != null ? formatter.format(dateTime) : item.timestamp;
        final recordNumber = entries.length - reverseIndex;
        final temperature = item.temperature.toStringAsFixed(1);
        final humidity = item.humidity.toStringAsFixed(1);
        final lightLabel = item.light == 0
            ? l10n.literal(es: 'Mucha', en: 'Bright')
            : l10n.literal(es: 'Poca', en: 'Low');

        return Card(
          color: adjustOpacity(Colors.white, 0.12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              l10n.literal(
                es: 'Registro $recordNumber',
                en: 'Entry $recordNumber',
              ),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.literal(
                    es: 'Temperatura: $temperature °C',
                    en: 'Temperature: $temperature °C',
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.orangeAccent,
                    fontSize: 14,
                  ),
                ),
                Text(
                  l10n.literal(
                    es: 'Humedad: $humidity %',
                    en: 'Humidity: $humidity %',
                  ),
                  style: GoogleFonts.poppins(
                    color:
                        isBright ? Colors.blue.shade800 : Colors.blueAccent,
                    fontSize: 14,
                  ),
                ),
                Text(
                  l10n.literal(
                    es: 'Luz: $lightLabel',
                    en: 'Light: $lightLabel',
                  ),
                  style: GoogleFonts.poppins(
                    color: item.light == 0
                        ? Colors.yellowAccent
                        : Colors.indigoAccent,
                    fontSize: 14,
                  ),
                ),
                Text(
                  l10n.literal(
                    es: 'Fecha: $formattedDate',
                    en: 'Date: $formattedDate',
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: (index * 100).ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _EmptyHistoryMessage extends StatelessWidget {
  const _EmptyHistoryMessage({required this.isBright});

  final bool isBright;

  @override
  Widget build(BuildContext context) {
    final color = isBright ? Colors.white : Colors.white70;
    return Center(
      child: Text(
        context.l10n.literal(
          es: 'Sin registros aún.\nLos datos aparecerán aquí.',
          en: 'No entries yet.\nData will appear here.',
        ),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ).animate().fadeIn(duration: 1000.ms),
    );
  }
}
