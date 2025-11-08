import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../domain/sensor_data.dart';
import '../controllers/sensor_controller.dart';
import '../widgets/particle_field.dart';
import '../theme/color_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _updateTimer;
  final List<_ChartData> _temperatureData = [];
  final List<_ChartData> _humidityData = [];
  final List<_ChartData> _lightData = [];
  final int _maxDataPoints = 20;

  @override
  void initState() {
    super.initState();
    _loadChartData();
    _startPeriodicUpdate();
  }

  void _loadChartData() {
    if (!mounted) return;

    final controller = context.read<SensorController>();
    final allData = controller.repository.allSensorData;

    // Tomar los últimos 20 registros guardados en Hive
    final recentData = allData.length > _maxDataPoints
        ? allData.sublist(allData.length - _maxDataPoints)
        : allData;

    // Limpiar las listas actuales
    _temperatureData.clear();
    _humidityData.clear();
    _lightData.clear();

    // Cargar los datos desde Hive
    for (var i = 0; i < recentData.length; i++) {
      final data = recentData[i];

      // Validar datos antes de agregarlos
      if (_isValidData(data)) {
        _temperatureData.add(_ChartData(i.toDouble(), data.temperature));
        _humidityData.add(_ChartData(i.toDouble(), data.humidity));
        _lightData.add(_ChartData(i.toDouble(), data.light.toDouble()));
      }
    }
  }

  bool _isValidData(SensorData data) {
    final temp = data.temperature;
    final humidity = data.humidity;
    final light = data.light;

    if (temp.isNaN || temp.isInfinite || temp < -50 || temp > 100) {
      debugPrint('⚠️ Temperatura inválida: $temp');
      return false;
    }
    if (humidity.isNaN || humidity.isInfinite || humidity < 0 || humidity > 100) {
      debugPrint('⚠️ Humedad inválida: $humidity');
      return false;
    }
    if (light < 0 || light > 1) {
      debugPrint('⚠️ Luz inválida: $light');
      return false;
    }
    return true;
  }

  void _startPeriodicUpdate() {
    // Actualizar cada 2.5 segundos leyendo desde Hive
    _updateTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) return;

      setState(() {
        _loadChartData();
      });
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

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
    final bool isBright = data == null ? true : data.light == 0;
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
                          'Dashboard en Tiempo Real',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(duration: 700.ms),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ConnectionStatus(connected: connected),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _CurrentValuesCard(data: data, isBright: isBright),
                          const SizedBox(height: 20),
                          _ChartCard(
                            title: 'Temperatura (°C)',
                            data: _temperatureData,
                            color: Colors.orangeAccent,
                            isBright: isBright,
                          ),
                          const SizedBox(height: 20),
                          _ChartCard(
                            title: 'Humedad (%)',
                            data: _humidityData,
                            color: Colors.blueAccent,
                            isBright: isBright,
                          ),
                          const SizedBox(height: 20),
                          _ChartCard(
                            title: 'Luminosidad',
                            data: _lightData,
                            color: Colors.yellowAccent,
                            isBright: isBright,
                            isLight: true,
                          ),
                          const SizedBox(height: 20),
                          _StatisticsCard(
                            allData: controller.repository.allSensorData,
                            isBright: isBright,
                          ),
                          const SizedBox(height: 24),
                        ],
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
          size: 20,
        ).animate().scale(duration: 800.ms),
        const SizedBox(width: 8),
        Text(
          connected ? 'Conectado' : 'Desconectado',
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(duration: 700.ms),
      ],
    );
  }
}

class _CurrentValuesCard extends StatelessWidget {
  const _CurrentValuesCard({
    required this.data,
    required this.isBright,
  });

  final SensorData? data;
  final bool isBright;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Card(
        color: adjustOpacity(Colors.white, 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Esperando datos...',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 600.ms);
    }

    return Card(
      color: adjustOpacity(Colors.white, 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valores Actuales',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ValueItem(
                  icon: Icons.thermostat,
                  value: '${data!.temperature.toStringAsFixed(1)}°C',
                  label: 'Temperatura',
                  color: Colors.orangeAccent,
                ),
                _ValueItem(
                  icon: Icons.water_drop,
                  value: '${data!.humidity.toStringAsFixed(1)}%',
                  label: 'Humedad',
                  color: Colors.blueAccent,
                ),
                _ValueItem(
                  icon: data!.light == 0 ? Icons.wb_sunny : Icons.nightlight,
                  value: data!.light == 0 ? 'Mucha' : 'Poca',
                  label: 'Luz',
                  color: data!.light == 0 ? Colors.yellowAccent : Colors.indigoAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

class _ValueItem extends StatelessWidget {
  const _ValueItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.data,
    required this.color,
    required this.isBright,
    this.isLight = false,
  });

  final String title;
  final List<_ChartData> data;
  final Color color;
  final bool isBright;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: adjustOpacity(Colors.white, 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? Center(
                      child: Text(
                        'Sin datos disponibles',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      primaryXAxis: const NumericAxis(
                        isVisible: false,
                        majorGridLines: MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        majorGridLines: MajorGridLines(
                          width: 0.5,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        axisLine: const AxisLine(width: 0),
                      ),
                      series: <CartesianSeries>[
                        SplineAreaSeries<_ChartData, double>(
                          dataSource: data,
                          xValueMapper: (_ChartData d, _) => d.x,
                          yValueMapper: (_ChartData d, _) => d.y,
                          color: color.withValues(alpha: 0.3),
                          borderColor: color,
                          borderWidth: 3,
                          animationDuration: 0,
                          markerSettings: const MarkerSettings(
                            isVisible: false,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.4),
                              color.withValues(alpha: 0.1),
                              color.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({
    required this.allData,
    required this.isBright,
  });

  final List<SensorData> allData;
  final bool isBright;

  Map<String, dynamic> _calculateStats() {
    if (allData.isEmpty) {
      return {
        'avgTemp': 0.0,
        'avgHumidity': 0.0,
        'maxTemp': 0.0,
        'minTemp': 0.0,
        'maxHumidity': 0.0,
        'minHumidity': 0.0,
      };
    }

    // Obtener datos de las últimas 24 horas
    final now = DateTime.now();
    final last24h = allData.where((data) {
      final dateTime = DateTime.tryParse(data.timestamp);
      if (dateTime == null) return false;
      return now.difference(dateTime).inHours <= 24;
    }).toList();

    if (last24h.isEmpty) {
      return {
        'avgTemp': 0.0,
        'avgHumidity': 0.0,
        'maxTemp': 0.0,
        'minTemp': 0.0,
        'maxHumidity': 0.0,
        'minHumidity': 0.0,
      };
    }

    final temps = last24h.map((d) => d.temperature).toList();
    final humidities = last24h.map((d) => d.humidity).toList();

    return {
      'avgTemp': temps.reduce((a, b) => a + b) / temps.length,
      'avgHumidity': humidities.reduce((a, b) => a + b) / humidities.length,
      'maxTemp': temps.reduce((a, b) => a > b ? a : b),
      'minTemp': temps.reduce((a, b) => a < b ? a : b),
      'maxHumidity': humidities.reduce((a, b) => a > b ? a : b),
      'minHumidity': humidities.reduce((a, b) => a < b ? a : b),
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Card(
      color: adjustOpacity(Colors.white, 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas (Últimas 24h)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Temp. Promedio:',
              value: '${stats['avgTemp'].toStringAsFixed(1)}°C',
              color: Colors.orangeAccent,
            ),
            _StatRow(
              label: 'Temp. Máxima:',
              value: '${stats['maxTemp'].toStringAsFixed(1)}°C',
              color: Colors.redAccent,
            ),
            _StatRow(
              label: 'Temp. Mínima:',
              value: '${stats['minTemp'].toStringAsFixed(1)}°C',
              color: Colors.cyanAccent,
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: 'Humedad Promedio:',
              value: '${stats['avgHumidity'].toStringAsFixed(1)}%',
              color: Colors.blueAccent,
            ),
            _StatRow(
              label: 'Humedad Máxima:',
              value: '${stats['maxHumidity'].toStringAsFixed(1)}%',
              color: Colors.lightBlueAccent,
            ),
            _StatRow(
              label: 'Humedad Mínima:',
              value: '${stats['minHumidity'].toStringAsFixed(1)}%',
              color: Colors.indigoAccent,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final double x;
  final double y;
}
