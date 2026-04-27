import 'package:flutter/material.dart';

class AnimatedSymbolsBackground extends StatefulWidget {
  const AnimatedSymbolsBackground({super.key});

  @override
  State<AnimatedSymbolsBackground> createState() =>
      _AnimatedSymbolsBackgroundState();
}

class _AnimatedSymbolsBackgroundState extends State<AnimatedSymbolsBackground>
    with TickerProviderStateMixin {
  // Componentes RGB do AppTheme.primary (0xFFD2693A) — laranja-terra.
  static const int _r = 210;
  static const int _g = 105;
  static const int _b = 58;

  // Patinhas espalhadas pela tela. dx/dy são posições relativas (0..1)
  // escolhidas pra evitar o miolo central onde o form de 640px vive.
  // driftX/driftY definem a amplitude de movimento (px).
  static const List<_Paw> _paws = [
    _Paw(size: 22, dx: 0.04, dy: 0.12, driftX: 70, driftY: 30, period: 7000, opacity: 0.18),
    _Paw(size: 28, dx: 0.13, dy: 0.32, driftX: -50, driftY: 60, period: 9500, opacity: 0.16),
    _Paw(size: 20, dx: 0.07, dy: 0.55, driftX: 60, driftY: -40, period: 8500, opacity: 0.20),
    _Paw(size: 26, dx: 0.15, dy: 0.78, driftX: -70, driftY: 50, period: 10500, opacity: 0.15),
    _Paw(size: 18, dx: 0.05, dy: 0.92, driftX: 80, driftY: -30, period: 7500, opacity: 0.22),
    _Paw(size: 24, dx: 0.88, dy: 0.08, driftX: -60, driftY: 70, period: 8000, opacity: 0.18),
    _Paw(size: 30, dx: 0.95, dy: 0.28, driftX: 50, driftY: 40, period: 11000, opacity: 0.14),
    _Paw(size: 22, dx: 0.86, dy: 0.50, driftX: -80, driftY: -50, period: 9000, opacity: 0.18),
    _Paw(size: 26, dx: 0.93, dy: 0.72, driftX: 60, driftY: 60, period: 10000, opacity: 0.16),
    _Paw(size: 20, dx: 0.90, dy: 0.94, driftX: -70, driftY: -40, period: 8200, opacity: 0.20),
    _Paw(size: 16, dx: 0.42, dy: 0.04, driftX: 90, driftY: 30, period: 9200, opacity: 0.20),
    _Paw(size: 18, dx: 0.58, dy: 0.96, driftX: -90, driftY: -30, period: 9800, opacity: 0.18),
  ];

  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _paws
        .map(
          (p) => AnimationController(
            vsync: this,
            duration: Duration(milliseconds: p.period),
          )..repeat(reverse: true),
        )
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.of(context).disableAnimations;
    for (final c in _controllers) {
      if (disable && c.isAnimating) {
        c.stop();
        c.value = 0.5;
      } else if (!disable && !c.isAnimating) {
        c.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              for (var i = 0; i < _paws.length; i++)
                _AnimatedPaw(
                  paw: _paws[i],
                  controller: _controllers[i],
                  width: w,
                  height: h,
                  color: Color.fromRGBO(_r, _g, _b, _paws[i].opacity),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Paw {
  final double size;
  final double dx;
  final double dy;
  final double driftX;
  final double driftY;
  final int period;
  final double opacity;

  const _Paw({
    required this.size,
    required this.dx,
    required this.dy,
    required this.driftX,
    required this.driftY,
    required this.period,
    required this.opacity,
  });
}

class _AnimatedPaw extends StatelessWidget {
  final _Paw paw;
  final Animation<double> controller;
  final double width;
  final double height;
  final Color color;

  const _AnimatedPaw({
    required this.paw,
    required this.controller,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseLeft = paw.dx * width - paw.size / 2;
    final baseTop = paw.dy * height - paw.size / 2;

    return Positioned(
      left: baseLeft.clamp(0.0, width - paw.size),
      top: baseTop.clamp(0.0, height - paw.size),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(controller.value);
          // Deslocamento bidirecional usando driftX/driftY como amplitude.
          final dx = (t - 0.5) * paw.driftX;
          final dy = (t - 0.5) * paw.driftY;
          // Leve oscilação rotacional (±3°) pra dar naturalidade.
          final rotation = (t - 0.5) * 0.10;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: rotation,
              child: Icon(Icons.pets, size: paw.size, color: color),
            ),
          );
        },
      ),
    );
  }
}
