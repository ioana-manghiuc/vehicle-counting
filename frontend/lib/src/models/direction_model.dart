import 'point_model.dart';

class DirectionModel {
  String label;
  List<PointModel> points;
  String colorHex;

  DirectionModel({
    required this.label,
    required this.points,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'color': colorHex,
        'points': points.map((p) => p.toJson()).toList(),
      };
}
