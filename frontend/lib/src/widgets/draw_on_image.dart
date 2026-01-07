// lib/src/widgets/draw_on_image.dart
import 'package:flutter/material.dart';

class DrawOnImage extends StatefulWidget {
  final String imageUrl;

  const DrawOnImage({super.key, required this.imageUrl});

  @override
  State<DrawOnImage> createState() => DrawOnImageState();
}

class DrawOnImageState extends State<DrawOnImage> {
  List<Offset> points = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final renderBox = context.findRenderObject() as RenderBox;
          points.add(renderBox.globalToLocal(details.globalPosition));
        });
      },
      onPanEnd: (details) => points.add(Offset.infinite),
      child: Stack(
        children: [
          Image.network(widget.imageUrl),
          CustomPaint(
            size: Size.infinite,
            painter: _DrawPainter(points: points),
          ),
        ],
      ),
    );
  }

  List<List<double>> getCoordinates() {
    return points
        .where((p) => p != Offset.infinite)
        .map((p) => [p.dx, p.dy])
        .toList();
  }
}

class _DrawPainter extends CustomPainter {
  final List<Offset> points;

  _DrawPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawPainter oldDelegate) => true;
}
