import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/direction_line.dart';

class DirectionsProvider extends ChangeNotifier {
  final List<DirectionLine> _directions = [];
  DirectionLine? _active;    
  DirectionLine? _selected;  
  Color _currentColor = Colors.red;
  String _selectedModel = 'yolo11n';

  List<DirectionLine> get directions => _directions;
  DirectionLine? get activeDirection => _active;
  DirectionLine? get selectedDirection => _selected;
  Color get currentColor => _currentColor;
  String get selectedModel => _selectedModel;

  bool get canSend => _directions.any((d) => d.isLocked);

  void reset() {
    _directions.clear();
    _active = null;
    _selected = null;
    _currentColor = Colors.red;
    notifyListeners();
  }

  void startNewDirection({Color? color}) {
    if (_active != null && !_active!.isLocked) return;

    final line = DirectionLine(
      id: const Uuid().v4(),
      points: [],
      labelFrom: '',
      labelTo: '',
      color: color ?? _currentColor,
    );

    _directions.add(line);
    _active = line;
    _selected = line;
    notifyListeners();
  }

  void addPoint(Offset point, Size canvasSize) {
    final target = _active ?? _selected;
    if (target == null || target.isLocked) return;

    target.points.add(
      Offset(
        point.dx / canvasSize.width,
        point.dy / canvasSize.height,
      ),
    );
    notifyListeners();
  }

  void selectDirection(DirectionLine direction) {
    if (direction.isLocked) return;
    _selected = direction;
    notifyListeners();
  }

  void updateLabels(String from, String to) {
    if (_selected == null || _selected!.isLocked) return;
    _selected!
      ..labelFrom = from
      ..labelTo = to;
    notifyListeners();
  }

  void updateColor(Color color) {
    if (_selected == null || _selected!.isLocked) return;
    _selected!.color = color;
    _currentColor = color; 
    notifyListeners();
  }

  void lockSelectedDirection() {
    if (_selected == null) return;
    if (!_selected!.canLock) return;

    _selected!.isLocked = true;
    if (_active == _selected) _active = null;
    _selected = null;
    notifyListeners();
  }

  void unlockDirection(DirectionLine d) {
    d.isLocked = false;
    _selected = d;
    _active = d;
    notifyListeners();
  }

  void deleteDirection(DirectionLine d) {
    _directions.remove(d);
    if (_active == d) _active = null;
    if (_selected == d) _selected = null;
    notifyListeners();
  }

  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  List<Map<String, dynamic>> serializeDirections() {
    return _directions
        .where((d) => d.isLocked)
        .map((d) => d.toJson())
        .toList();
  }
}