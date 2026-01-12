import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';

class DrawingCanvas extends StatelessWidget {
  final String imageUrl;

  const DrawingCanvas({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();

    return GestureDetector(
      onPanStart: (details) {
        final box = context.findRenderObject() as RenderBox;
        provider.addPoint(details.localPosition, box.size);
      },
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        provider.addPoint(details.localPosition, box.size);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DirectionsPainter(provider.directions),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionsPainter extends CustomPainter {
  final List directions;

  _DirectionsPainter(this.directions);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in directions) {
      final paint = Paint()
        ..color = d.color
        ..strokeWidth = d.isLocked ? 3 : 4
        ..style = PaintingStyle.stroke;

      if (d.points.length < 2) continue;

      final path = Path()..moveTo(d.points.first.dx * size.width, d.points.first.dy * size.height);
      for (final p in d.points.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}