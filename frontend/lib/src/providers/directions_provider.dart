import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/direction.dart';
import '../models/line_model.dart';
import 'package:hive/hive.dart';
import 'dart:io';

class DirectionsProvider extends ChangeNotifier {
    final List<Direction> _directions = [];
    Direction? _active;    
    Direction? _selected;  
    Color _currentColor = Colors.red;
    String _selectedModel = 'yolo11n';
    bool _isDrawingLine = false;

    List<Direction> get directions => _directions;
    Direction? get activeDirection => _active;
    Direction? get selectedDirection => _selected;
    Color get currentColor => _currentColor;
    String get selectedModel => _selectedModel;

    bool get canSend => _directions.any((d) => d.isLocked);
    bool get canDraw => _selected != null && !_selected!.isLocked;

  void reset() {
      _directions.clear();
      _active = null;
      _selected = null;
      _currentColor = Colors.red;
      _isDrawingLine = false;
      notifyListeners();
  }

  void startNewDirection({Color? color}) {
      final direction = Direction(
        labelFrom: '',
        labelTo: '',
        color: color ?? _currentColor,
      );

      _directions.add(direction);
      _active = direction;
      _selected = direction;
      _isDrawingLine = false;
      notifyListeners();
  }

  void addPoint(Offset point, Size canvasSize) {
      Direction? target = _selected;
      
      if (target == null || target.isLocked) return;

      final normalizedX = point.dx / canvasSize.width;
      final normalizedY = point.dy / canvasSize.height;

      if (!_isDrawingLine) {
        final newLine = LineModel(
          x1: normalizedX,
          y1: normalizedY,
          x2: normalizedX,
          y2: normalizedY,
          isEntry: target.lines.isEmpty, 
        );
        target.lines.add(newLine);
        _isDrawingLine = true;
      } else {
        target.lines.last = target.lines.last.copyWith(
          x2: normalizedX,
          y2: normalizedY,
        );
        _isDrawingLine = false;
      }
      
      notifyListeners();
  }

  void selectDirection(Direction direction) {
    _selected = direction;
    _isDrawingLine = false;
    if (!direction.isLocked) {
      _active = direction;
    }
    notifyListeners();    
  }

  void unlockForEditing(Direction direction) {
      if (!_directions.contains(direction)) return;
      _selected = direction;
      _active = direction;
      _isDrawingLine = false;
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

  void deleteDirection(Direction d) {
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


  void toggleLock(Direction direction) {
    if (!_directions.contains(direction)) return;

    direction.isLocked = !direction.isLocked;
    if (direction.isLocked) {
      if (_active == direction) _active = null;
      _selected = null;
      _isDrawingLine = false;
    } else {
      _active = direction;
      _selected = direction;
      _isDrawingLine = false;
    }
    notifyListeners();
  }

  void setLineAsEntry(Direction direction, int lineIndex) {
    if (!_directions.contains(direction) || direction.isLocked) return;
    if (lineIndex < 0 || lineIndex >= direction.lines.length) return;
    
    for (final line in direction.lines) {
      line.isEntry = false;
    }
    direction.lines[lineIndex].isEntry = true;
    notifyListeners();
  }

  void deleteLineAtIndex(Direction direction, int lineIndex) {
    if (!_directions.contains(direction) || direction.isLocked) return;
    if (lineIndex < 0 || lineIndex >= direction.lines.length) return;
    
    direction.lines.removeAt(lineIndex);
    notifyListeners();
  }

  void updateLineCoordinates(Direction direction, int lineIndex, double x1, double y1, double x2, double y2) {
    if (!_directions.contains(direction) || direction.isLocked) return;
    if (lineIndex < 0 || lineIndex >= direction.lines.length) return;
    
    direction.lines[lineIndex] = direction.lines[lineIndex].copyWith(
      x1: x1.clamp(0.0, 1.0),
      y1: y1.clamp(0.0, 1.0),
      x2: x2.clamp(0.0, 1.0),
      y2: y2.clamp(0.0, 1.0),
    );
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
      _directions.add(Direction.fromJson(d));
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
      _directions.add(Direction.fromJson(d));
    }

    _selected = null;
    _active = null;
    notifyListeners();
  }

  Future<void> deleteIntersection(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}