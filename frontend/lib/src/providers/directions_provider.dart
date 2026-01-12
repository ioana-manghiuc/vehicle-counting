import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/direction_line.dart';

class DirectionsProvider extends ChangeNotifier {
  final List<DirectionLine> _directions = [];
  DirectionLine? _active;    // currently being drawn
  DirectionLine? _selected;  // currently selected in panel
  Color _currentColor = Colors.red; // Track the current drawing color

  List<DirectionLine> get directions => _directions;
  DirectionLine? get activeDirection => _active;
  DirectionLine? get selectedDirection => _selected;
  Color get currentColor => _currentColor;

  bool get canSend => _directions.any((d) => d.isLocked);

  /// Start a new direction and select it
  void startNewDirection({Color? color}) {
    // If there is an active undrawn direction, don't create another
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
    _selected = line; // panel now works on this line
    notifyListeners();
  }

  /// Add a point to the active or selected direction (canvas)
  void addPoint(Offset point, Size canvasSize) {
    // Use selected direction if no active direction
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

  /// Select a direction for panel editing
  void selectDirection(DirectionLine direction) {
    if (direction.isLocked) return; // cannot select locked direction
    _selected = direction;
    notifyListeners();
  }

  /// Update labels on the selected direction
  void updateLabels(String from, String to) {
    if (_selected == null || _selected!.isLocked) return;
    _selected!
      ..labelFrom = from
      ..labelTo = to;
    notifyListeners();
  }

  /// Update color on the selected direction
  void updateColor(Color color) {
    if (_selected == null || _selected!.isLocked) return;
    _selected!.color = color;
    _currentColor = color; // Remember this color for next direction
    notifyListeners();
  }

  /// Lock the selected direction
  void lockSelectedDirection() {
    if (_selected == null) return;
    if (!_selected!.canLock) return;

    _selected!.isLocked = true;
    if (_active == _selected) _active = null;
    _selected = null;
    notifyListeners();
  }

  /// Unlock a direction and select it
  void unlockDirection(DirectionLine d) {
    d.isLocked = false;
    _selected = d;
    _active = d;
    notifyListeners();
  }

  /// Delete a direction
  void deleteDirection(DirectionLine d) {
    _directions.remove(d);
    if (_active == d) _active = null;
    if (_selected == d) _selected = null;
    notifyListeners();
  }

  /// Serialize locked directions for sending
  List<Map<String, dynamic>> serializeDirections() {
    return _directions
        .where((d) => d.isLocked)
        .map((d) => d.toJson())
        .toList();
  }
}