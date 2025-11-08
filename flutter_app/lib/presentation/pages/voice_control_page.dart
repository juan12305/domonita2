import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/services/voice_command_service.dart';
import '../controllers/sensor_controller.dart';
import '../widgets/particle_field.dart';
import '../theme/color_utils.dart';

class VoiceControlPage extends StatefulWidget {
  final VoiceCommandService voiceService;

  const VoiceControlPage({
    super.key,
    required this.voiceService,
  });

  @override
  State<VoiceControlPage> createState() => _VoiceControlPageState();
}

class _VoiceControlPageState extends State<VoiceControlPage>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastCommand = '';
  String _lastResponse = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    final initialized = await widget.voiceService.initialize();
    if (!initialized && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo inicializar el reconocimiento de voz'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (!widget.voiceService.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El reconocimiento de voz no está disponible'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    await widget.voiceService.startListening(
      onResult: (command) {
        setState(() {
          _lastCommand = command;
          _isProcessing = true;
        });
        _processCommand(command);
      },
      onListening: () {
        setState(() {
          _isListening = true;
          _lastCommand = '';
          _lastResponse = '';
        });
      },
      onDone: () {
        setState(() {
          _isListening = false;
        });
      },
    );
  }

  void _stopListening() async {
    await widget.voiceService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processCommand(String command) async {
    final controller = context.read<SensorController>();
    final sensorData = controller.sensorData;

    final result = await widget.voiceService.processVoiceCommand(
      command,
      sensorData,
    );

    if (mounted) {
      setState(() {
        _lastResponse = result['reason'] ?? 'Sin respuesta';
        _isProcessing = false;
      });

      // Ejecutar las acciones
      if (result['success'] == true) {
        final lightAction = result['light_action'];
        final fanAction = result['fan_action'];

        if (lightAction == 'ON') {
          controller.turnLedOn();
        } else if (lightAction == 'OFF') {
          controller.turnLedOff();
        }

        if (fanAction == 'ON') {
          controller.turnFanOn();
        } else if (fanAction == 'OFF') {
          controller.turnFanOff();
        }

        if (lightAction != 'NO_CHANGE' || fanAction != 'NO_CHANGE') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lastResponse),
              backgroundColor: Colors.greenAccent.shade700,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lastResponse),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
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
                          'Control por Voz',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(duration: 700.ms),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ConnectionStatus(connected: connected),
                  const SizedBox(height: 40),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _VoiceButton(
                            isListening: _isListening,
                            isProcessing: _isProcessing,
                            onStart: _startListening,
                            onStop: _stopListening,
                            pulseController: _pulseController,
                          ),
                          const SizedBox(height: 40),
                          if (_lastCommand.isNotEmpty)
                            _CommandCard(
                              title: 'Tu comando:',
                              content: _lastCommand,
                              icon: Icons.mic,
                              color: Colors.blueAccent,
                            ),
                          if (_lastResponse.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _CommandCard(
                              title: 'Respuesta:',
                              content: _lastResponse,
                              icon: Icons.smart_toy,
                              color: Colors.greenAccent,
                            ),
                          ],
                          const SizedBox(height: 40),
                          _InstructionsCard(),
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

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.isListening,
    required this.isProcessing,
    required this.onStart,
    required this.onStop,
    required this.pulseController,
  });

  final bool isListening;
  final bool isProcessing;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : (isListening ? onStop : onStart),
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final scale = isListening ? 1.0 + (pulseController.value * 0.1) : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isListening
                      ? [Colors.redAccent, Colors.red.shade700]
                      : isProcessing
                          ? [Colors.orangeAccent, Colors.orange.shade700]
                          : [Colors.blueAccent, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isListening
                            ? Colors.redAccent
                            : Colors.blueAccent)
                        .withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                isProcessing
                    ? Icons.hourglass_bottom
                    : isListening
                        ? Icons.mic
                        : Icons.mic_none,
                size: 80,
                color: Colors.white,
              ),
            ),
          );
        },
      ).animate().scale(duration: 600.ms),
    );
  }
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  final String title;
  final String content;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

class _InstructionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Comandos disponibles:',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _InstructionItem(text: 'Enciende/Apaga la luz'),
            const _InstructionItem(text: 'Enciende/Apaga el ventilador'),
            const _InstructionItem(text: 'Enciende/Apaga el bombillo'),
            const _InstructionItem(text: 'Apaga todo'),
            const SizedBox(height: 12),
            Text(
              'Mantén presionado el botón y di tu comando claramente',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
