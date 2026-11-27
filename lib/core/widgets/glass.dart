import 'dart:ui';
import 'package:material_ui/material_ui.dart';

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.padding, this.radius = 22, this.opacity = .075, this.border = true});
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final double opacity;
  final bool border;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(radius),
          border: border ? Border.all(color: Colors.white.withValues(alpha: .12), width: 1) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: child,
      ),
    ),
  );
}

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned.fill(child: DecoratedBox(decoration: const BoxDecoration(color: Color(0xFF080B14)))),
    Positioned(top: -140, left: -90, child: _orb(const Color(0xFF6957D8), 330)),
    Positioned(top: 260, right: -170, child: _orb(const Color(0xFF145B88), 330)),
    Positioned(bottom: -180, left: 80, child: _orb(const Color(0xFF9A416E), 280)),
    Positioned.fill(child: child),
  ]);
  Widget _orb(Color color, double size) => Container(width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: .22), color.withValues(alpha: 0)])));
}
