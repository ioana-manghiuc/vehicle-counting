import 'dart:ui';

class DirectionLine {
  final String id;
  final List<Offset> points;
  String labelFrom;
  String labelTo;
  Color color;
  bool isLocked;

  DirectionLine({
    required this.id,
    required this.points,
    required this.labelFrom,
    required this.labelTo,
    required this.color,
    this.isLocked = false,
  });

  bool get canLock =>
      points.length >= 2 &&
      labelFrom.isNotEmpty &&
      labelTo.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': labelFrom,
      'to': labelTo,
      'color': color.toARGB32(),
      'points': points
          .map((p) => {'x': p.dx, 'y': p.dy})
          .toList(),
    };
  }
}