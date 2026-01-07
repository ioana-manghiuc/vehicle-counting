import 'package:flutter/material.dart';
import '../models/direction_model.dart';
import '../models/point_model.dart';

class DirectionsViewModel extends ChangeNotifier {
  final List<DirectionModel> directions = [];
  List<PointModel> currentPoints = [];

  void addPoint(Offset offset) {
    currentPoints.add(PointModel(offset.dx, offset.dy));
    notifyListeners();
  }

  void saveDirection(String label, String colorHex) {
    directions.add(
      DirectionModel(
        label: label,
        colorHex: colorHex,
        points: List.from(currentPoints),
      ),
    );
    currentPoints.clear();
    notifyListeners();
  }
}