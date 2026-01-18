import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';
import '../models/direction_line.dart';

class DrawOnImage extends StatefulWidget {
  final String imageUrl;

  const DrawOnImage({super.key, required this.imageUrl});

  @override
  State<DrawOnImage> createState() => _DrawOnImageState();
}

class _DrawOnImageState extends State<DrawOnImage> {
  Offset? _cursorPosition;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  @override
  void didUpdateWidget(covariant DrawOnImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageSize = null;
      _loadImageDimensions();
    }
  }

  void _loadImageDimensions() {
    final stream = NetworkImage(widget.imageUrl).resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_imageSize == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final scale = math.min(
          constraints.maxWidth / _imageSize!.width,
          constraints.maxHeight / _imageSize!.height,
        );
        final width = _imageSize!.width * scale;
        final height = _imageSize!.height * scale;
        final canvasSize = Size(width, height);

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: MouseRegion(
              onHover: (event) {
                setState(() {
                  _cursorPosition = event.localPosition;
                });
              },
              onExit: (_) {
                setState(() {
                  _cursorPosition = null;
                });
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  provider.addPoint(details.localPosition, canvasSize);
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DirectionsPainter(
                          directions: provider.directions,
                          currentColor: provider.currentColor,
                          cursorPosition: _cursorPosition,
                          canvasSize: canvasSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DirectionsPainter extends CustomPainter {
  final List<DirectionLine> directions;
  final Color currentColor;
  final Offset? cursorPosition;
  final Size canvasSize;

  _DirectionsPainter({
    required this.directions,
    required this.currentColor,
    required this.canvasSize,
    this.cursorPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Enforce painting using the exact canvas size we normalized against
    final effectiveSize = canvasSize;

    for (final d in directions) {
      final paint = Paint()
        ..color = d.color
        ..strokeWidth = d.isLocked ? 3 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (d.points.isEmpty) continue;

      for (int i = 0; i < d.points.length - 1; i++) {
        final p1 = d.points[i];
        final p2 = d.points[i + 1];
        canvas.drawLine(
          Offset(p1.dx * effectiveSize.width, p1.dy * effectiveSize.height),
          Offset(p2.dx * effectiveSize.width, p2.dy * effectiveSize.height),
          paint,
        );
      }

      final pointPaint = Paint()
        ..color = d.color
        ..style = PaintingStyle.fill;

      for (final p in d.points) {
        canvas.drawCircle(
          Offset(p.dx * effectiveSize.width, p.dy * effectiveSize.height),
          4,
          pointPaint,
        );
      }
    }

    if (cursorPosition != null && directions.isNotEmpty) {
      final activeDir = directions.firstWhereOrNull(
        (d) => !d.isLocked && d.points.isNotEmpty,
      );

      if (activeDir != null) {
        final previewPaint = Paint()
          ..color = activeDir.color.withValues(alpha: 0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        final lastPoint = activeDir.points.last;
        canvas.drawLine(
          Offset(lastPoint.dx * effectiveSize.width, lastPoint.dy * effectiveSize.height),
          cursorPosition!,
          previewPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DirectionsPainter oldDelegate) => true;
}

extension on List<DirectionLine> {
  DirectionLine? firstWhereOrNull(bool Function(DirectionLine) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
