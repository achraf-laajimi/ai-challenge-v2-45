import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double value;

  _ParticlePainter({required this.particles, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      final x = (p.x + value * p.speed) % 1.0;
      final y = (p.y + value * p.speed * 0.5) % 1.0;
      paint.color = AppColors.primaryColor.withValues(
        alpha: p.opacity * (0.5 + 0.5 * math.sin(value * 2 * math.pi)),
      );
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class ParticleBackground extends StatefulWidget {
  final int particleCount;
  final Widget child;

  const ParticleBackground({
    super.key,
    this.particleCount = 10,
    required this.child,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    final r = math.Random();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(Particle(
        x: r.nextDouble(),
        y: r.nextDouble(),
        size: r.nextDouble() * 3 + 1.5,
        speed: r.nextDouble() * 0.3 + 0.1,
        opacity: r.nextDouble() * 0.4 + 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              value: _controller.value,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
