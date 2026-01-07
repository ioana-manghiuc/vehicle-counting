import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/directions_view_model.dart';

class DirectionCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DirectionsViewModel>();

    return GestureDetector(
      onPanUpdate: (details) {
        vm.addPoint(details.localPosition);
      },
      child: Container(
        color: Colors.black12,
        child: CustomPaint(
          painter: _DirectionPainter(vm.currentPoints),
        ),
      ),
    );
  }
}

class _DirectionPainter extends CustomPainter {
  final List points;

  _DirectionPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(
        Offset(points[i].x, points[i].y),
        Offset(points[i + 1].x, points[i + 1].y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
