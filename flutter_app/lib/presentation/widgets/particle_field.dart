import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/color_utils.dart';

/// Animated particle field reused across auth, control, and history pages.
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    this.particleCount = 25,
    this.maxSpeed = 0.5,
    this.animationDuration = const Duration(seconds: 20),
    this.blurSigma = 4,
  });

  /// Amount of particles to render on screen.
  final int particleCount;

  /// Maximum horizontal/vertical speed for each particle.
  final double maxSpeed;

  /// Duration of the looping animation controller.
  final Duration animationDuration;

  /// Blur intensity for each particle glow.
  final double blurSigma;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle(
        random: _random,
        maxSpeed: widget.maxSpeed,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              blurSigma: widget.blurSigma,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.random,
    required this.maxSpeed,
  })  : velocity = Offset(
          (random.nextDouble() - 0.5) * maxSpeed,
          (random.nextDouble() - 0.5) * maxSpeed,
        ),
        radius = random.nextDouble() * 2 + 1,
        color = adjustOpacity(Colors.white, random.nextDouble() * 0.3 + 0.2);

  final Random random;
  final double maxSpeed;
  final double radius;
  final Color color;
  Offset? _position;
  Offset velocity;

  Offset get position => _position ?? Offset.zero;

  void update(Size size) {
    if (size.isEmpty) return;

    final maxWidth = size.width;
    final maxHeight = size.height;

    final current = _position ??
        Offset(random.nextDouble() * maxWidth, random.nextDouble() * maxHeight);

    var next = current + velocity;

    if (next.dx <= 0 || next.dx >= maxWidth) {
      velocity = Offset(-velocity.dx, velocity.dy);
      next = Offset(next.dx.clamp(0.0, maxWidth), next.dy);
    }

    if (next.dy <= 0 || next.dy >= maxHeight) {
      velocity = Offset(velocity.dx, -velocity.dy);
      next = Offset(next.dx, next.dy.clamp(0.0, maxHeight));
    }

    _position = next;
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.blurSigma,
  });

  final List<_Particle> particles;
  final double blurSigma;

  @override
  void paint(Canvas canvas, Size size) {
    final blur =
        blurSigma > 0 ? MaskFilter.blur(BlurStyle.normal, blurSigma) : null;
    for (final particle in particles) {
      particle.update(size);
      final paint = Paint()
        ..color = particle.color
        ..maskFilter = blur;
      canvas.drawCircle(particle.position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
