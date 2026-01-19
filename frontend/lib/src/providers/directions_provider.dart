import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/direction_line.dart';
import 'package:hive/hive.dart';

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
    bool get canDraw => _selected != null && !_selected!.isLocked;

  void reset() {
      _directions.clear();
      _active = null;
      _selected = null;
      _currentColor = Colors.red;
      notifyListeners();
  }

  void startNewDirection({Color? color}) {
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
      DirectionLine? target;
      if (_active != null) {
        target = _active;
      } else if (_selected != null && !_selected!.isLocked && _selected!.points.length % 2 == 0) {
        target = _selected;
      }
      
      if (target == null) return;

      target.points.add(
        Offset(
          point.dx / canvasSize.width,
          point.dy / canvasSize.height,
        ),
      );
      
      if (target.points.length % 2 == 0) {
        _active = null;
        _selected = target;
      } else {
        _active = target;
        _selected = target;
      }
      
      notifyListeners();
  }

  void selectDirection(DirectionLine direction) {
    _selected = direction;
    if (!direction.isLocked && direction.points.length % 2 == 0) {
      _active = direction;
    }
    notifyListeners();    
  }

  void unlockForEditing(DirectionLine direction) {
      if (!_directions.contains(direction)) return;
      _selected = direction;
      if (direction.points.length % 2 == 0) {
        _active = direction;
      }
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

  Map<String, dynamic> serializeIntersection(String name, Size canvasSize) {
    return {
      'id': const Uuid().v4(),
      'name': name,
      'canvasSize': {
        'w': canvasSize.width,
        'h': canvasSize.height,
      },
      'directions': serializeDirections(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }


  void toggleLock(DirectionLine direction) {
    if (!_directions.contains(direction)) return;

    direction.isLocked = !direction.isLocked;
    if (direction.isLocked) {
      if (_active == direction) _active = null;
      _selected = null;
    } else {
      if (direction.points.length % 2 == 0) {
        _active = direction;
      }
      _selected = direction;
    }
    notifyListeners();
  }

  void updatePointCoordinate(DirectionLine direction, int pointIndex, double x, double y) {
    if (!_directions.contains(direction) || direction.isLocked) return;
    if (pointIndex < 0 || pointIndex >= direction.points.length) return;
    
    direction.points[pointIndex] = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
    notifyListeners();
  }

  void deletePointPair(DirectionLine direction, int lineIndex) {
    if (!_directions.contains(direction) || direction.isLocked) return;
    final startIndex = lineIndex * 2;
    if (startIndex < 0 || startIndex >= direction.points.length - 1) return;
    
    direction.points.removeRange(startIndex, startIndex + 2);
    notifyListeners();
  }

  Future<void> saveIntersection(String name, Size canvasSize) async {
    final box = await Hive.openBox('intersections');

    final data = serializeIntersection(name, canvasSize);
    await box.put(data['id'], data);
  }

  Future<void> loadIntersection(String id) async {
    final box = await Hive.openBox('intersections');
    final data = box.get(id);

    _directions.clear();

    for (final d in data['directions']) {
      _directions.add(DirectionLine.fromJson(d));
    }

    _selected = null;
    _active = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> listIntersections() async {
    final box = await Hive.openBox('intersections');
    return box.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

void loadIntersectionFromData(Map<String, dynamic> data) {
  _directions.clear();

  for (final d in data['directions']) {
    _directions.add(DirectionLine.fromJson(d));
  }

  _selected = null;
  _active = null;
  notifyListeners();
}


}