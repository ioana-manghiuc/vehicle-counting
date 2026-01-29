import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/direction_model.dart';
import '../models/line_model.dart';
import '../utils/file_picker_helper.dart';
import '../models/intersection_model.dart';
import 'dart:io';
import 'package:hive/hive.dart';

class DirectionsViewModel extends ChangeNotifier {
    final List<DirectionModel> _directions = [];
    DirectionModel? _active;    
    DirectionModel? _selected;  
    Color _currentColor = Colors.red;
    String _selectedModel = 'yolo11s';
    bool _isDrawingLine = false;
    String? _selectedLineId;

    List<DirectionModel> get directions => _directions;
    DirectionModel? get activeDirection => _active;
    DirectionModel? get selectedDirection => _selected;
    Color get currentColor => _currentColor;
    String get selectedModel => _selectedModel;
    String? get selectedLineId => _selectedLineId;

    bool get canSend => _directions.any((d) => d.isLocked);
    bool get canDraw => _selected != null && !_selected!.isLocked;

    IntersectionModel? file;

  void reset() {
      _directions.clear();
      _active = null;
      _selected = null;
      _currentColor = Colors.red;
      _isDrawingLine = false;
      _selectedLineId = null;
      notifyListeners();
  }

  void startNewDirection({Color? color}) {
      final direction = DirectionModel(
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
      DirectionModel? target = _selected;
      
      if (target == null || target.isLocked) return;

      final normalizedX = point.dx / canvasSize.width;
      final normalizedY = point.dy / canvasSize.height;

      if (!_isDrawingLine) {
        if (target.lines.length >= 2) {
          final newDirection = DirectionModel(
            labelFrom: '',
            labelTo: '',
            color: _currentColor,
          );
          _directions.add(newDirection);
          _selected = newDirection;
          _active = newDirection;
          target = newDirection;
        }

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

  void selectDirection(DirectionModel direction) {
    _selected = direction;
    _isDrawingLine = false;
    _selectedLineId = null;
    if (!direction.isLocked) {
      _active = direction;
    }
    notifyListeners();    
  }

  void unlockForEditing(DirectionModel direction) {
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

  void deleteDirection(DirectionModel d) {
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


  void toggleLock(DirectionModel direction) {
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

  void setLineAsEntry(DirectionModel direction, int lineIndex) {
    if (!_directions.contains(direction) || direction.isLocked) return;
    if (lineIndex < 0 || lineIndex >= direction.lines.length) return;
    
    for (final line in direction.lines) {
      line.isEntry = false;
    }
    direction.lines[lineIndex].isEntry = true;
    notifyListeners();
  }

  void deleteLineAtIndex(DirectionModel direction, int lineIndex) {
    if (!_directions.contains(direction) || direction.isLocked) return;
    if (lineIndex < 0 || lineIndex >= direction.lines.length) return;
    
    direction.lines.removeAt(lineIndex);
    notifyListeners();
  }

  void updateLineCoordinates(DirectionModel direction, int lineIndex, double x1, double y1, double x2, double y2) {
    if (!_directions.contains(direction)) return;
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
      _directions.add(DirectionModel.fromJson(d));
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
      _directions.add(DirectionModel.fromJson(d));
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

  Future<IntersectionModel?> pickIntersectionFile() async{
    final pickedFile = await FilePickerHelper.pickIntersectionJson();
    if (pickedFile == null) return null;

    file = pickedFile;
    loadIntersectionFromData(pickedFile.toJson());
    notifyListeners();
    return pickedFile;
  }
  void selectLine(String? lineId) {
    _selectedLineId = lineId;
    notifyListeners();
  }

  void adjustSelectedLineCoordinate({
    double? dx1,
    double? dy1,
    double? dx2,
    double? dy2,
  }) {
    if (_selectedLineId == null || _selected == null) return;
    
    final lineIndex = _selected!.lines.indexWhere((line) => line.id == _selectedLineId);
    if (lineIndex == -1) return;
    
    final line = _selected!.lines[lineIndex];
    
    _selected!.lines[lineIndex] = line.copyWith(
      x1: dx1 != null ? (line.x1 + dx1).clamp(0.0, 1.0) : line.x1,
      y1: dy1 != null ? (line.y1 + dy1).clamp(0.0, 1.0) : line.y1,
      x2: dx2 != null ? (line.x2 + dx2).clamp(0.0, 1.0) : line.x2,
      y2: dy2 != null ? (line.y2 + dy2).clamp(0.0, 1.0) : line.y2,
    );
    notifyListeners();
  }


}