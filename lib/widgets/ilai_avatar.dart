import 'dart:math' as math;
import 'package:flutter/material.dart';

/// PhytoSense's leaf character, drawn as vectors at every size.
class IlaiAvatar extends StatefulWidget {
  final double size;
  final bool active;
  const IlaiAvatar({super.key, this.size = 64, this.active = false});
  @override
  State<IlaiAvatar> createState() => _IlaiAvatarState();
}
class _IlaiAvatarState extends State<IlaiAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 1800));
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _sync(); }
  @override
  void didUpdateWidget(IlaiAvatar oldWidget) { super.didUpdateWidget(oldWidget); _sync(); }
  void _sync() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!motion.isAnimating) motion.repeat(reverse: true);
    } else { motion.stop(); motion.value = 0; }
  }
  @override
  void dispose() { motion.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Semantics(label: 'Ilai', image: true,
      child: AnimatedBuilder(animation: motion, builder: (_, __) => Transform.rotate(
        angle: math.sin(motion.value * math.pi) * .045,
        child: CustomPaint(size: Size.square(widget.size), painter: _IlaiPainter(motion.value)),
      )));
}
class _IlaiPainter extends CustomPainter {
  final double pulse;
  _IlaiPainter(this.pulse);
  @override
  void paint(Canvas c, Size size) {
    c.save(); c.scale(size.width / 100, size.height / 100);
    final p = Paint()..isAntiAlias = true;
    c.drawCircle(const Offset(50, 53), 46 + pulse * 2, p..color = const Color(0xFFD8EADD));
    final leaf = Path()..moveTo(24, 68)..cubicTo(7, 26, 44, 12, 81, 20)
      ..cubicTo(91, 62, 65, 87, 24, 68)..close();
    c.drawPath(leaf, p..color = const Color(0xFF256F50));
    c.drawPath(Path()..moveTo(28, 80)..quadraticBezierTo(37, 67, 63, 43),
      p..color = const Color(0xFF80B98B)..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
    p.style = PaintingStyle.fill;
    c.drawCircle(const Offset(40, 43), 3.4, p..color = Colors.white);
    c.drawCircle(const Offset(61, 40), 3.4, p);
    c.drawPath(Path()..moveTo(44, 54)..quadraticBezierTo(53, 61, 61, 51),
      p..style = PaintingStyle.stroke..strokeWidth = 3);
    p.style = PaintingStyle.fill;
    c.drawCircle(const Offset(81, 76), 8, p..color = const Color(0xFFE4B35D));
    c.restore();
  }
  @override
  bool shouldRepaint(_IlaiPainter oldDelegate) => oldDelegate.pulse != pulse;
}
