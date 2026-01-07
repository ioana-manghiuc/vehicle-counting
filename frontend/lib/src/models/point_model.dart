class PointModel {
  final double x;
  final double y;

  PointModel(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}
