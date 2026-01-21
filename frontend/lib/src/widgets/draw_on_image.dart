import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';
import '../models/direction.dart';

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
                          selectedDirection: provider.selectedDirection,
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
  final List<Direction> directions;
  final Direction? selectedDirection;
  final Color currentColor;
  final Offset? cursorPosition;
  final Size canvasSize;

  _DirectionsPainter({
    required this.directions,
    required this.selectedDirection,
    required this.currentColor,
    required this.canvasSize,
    this.cursorPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveSize = canvasSize;

    for (final d in directions) {
      late Color lineColor;
      if (d.isLocked && selectedDirection != d) {
        lineColor = Colors.black;
      } else {
        lineColor = d.color;
      }

      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = d.isLocked ? 3 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (d.lines.isEmpty) continue;

      for (final line in d.lines) {
        final p1 = Offset(line.x1 * effectiveSize.width, line.y1 * effectiveSize.height);
        final p2 = Offset(line.x2 * effectiveSize.width, line.y2 * effectiveSize.height);
        canvas.drawLine(p1, p2, paint);
      }

      if (d.isLocked && selectedDirection != d) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        for (final line in d.lines) {
          final p1 = Offset(line.x1 * effectiveSize.width, line.y1 * effectiveSize.height);
          final p2 = Offset(line.x2 * effectiveSize.width, line.y2 * effectiveSize.height);
          canvas.drawLine(p1, p2, borderPaint);
        }
      }

      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      for (int idx = 0; idx < d.lines.length; idx++) {
        final line = d.lines[idx];
        canvas.drawCircle(
          Offset(line.x1 * effectiveSize.width, line.y1 * effectiveSize.height),
          4,
          pointPaint,
        );
        canvas.drawCircle(
          Offset(line.x2 * effectiveSize.width, line.y2 * effectiveSize.height),
          4,
          pointPaint,
        );

        final isLineComplete = !(line.x1 == line.x2 && line.y1 == line.y2);
        if (isLineComplete) {
          final start = Offset(line.x1 * effectiveSize.width, line.y1 * effectiveSize.height);
          final end = Offset(line.x2 * effectiveSize.width, line.y2 * effectiveSize.height);
          final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
          final lineNumber = idx + 1;

          final textPainter = TextPainter(
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.text = TextSpan(
            text: '$lineNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          final badgeRadius = (textPainter.width > textPainter.height
                  ? textPainter.width
                  : textPainter.height) /
              2 +
              2;

          final badgeBg = Paint()
            ..color = Colors.black.withValues(alpha: 0.7)
            ..style = PaintingStyle.fill;

          final badgeBorder = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;

          canvas.drawCircle(midPoint, badgeRadius, badgeBg);
          canvas.drawCircle(midPoint, badgeRadius, badgeBorder);

          textPainter.paint(
            canvas,
            Offset(
              midPoint.dx - textPainter.width / 2,
              midPoint.dy - textPainter.height / 2,
            ),
          );
        }
      }
    }

    if (cursorPosition != null && directions.isNotEmpty) {
      final activeDir = directions.firstWhereOrNull(
        (d) => !d.isLocked && d.lines.length == 1 && (d.lines.first.x1 == d.lines.first.x2 && d.lines.first.y1 == d.lines.first.y2),
      );

      if (activeDir != null) {
        final previewPaint = Paint()
          ..color = activeDir.color.withValues(alpha: 0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        final lastLine = activeDir.lines.last;
        canvas.drawLine(
          Offset(lastLine.x1 * effectiveSize.width, lastLine.y1 * effectiveSize.height),
          cursorPosition!,
          previewPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DirectionsPainter oldDelegate) => true;
}

extension on List<Direction> {
  Direction? firstWhereOrNull(bool Function(Direction) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
