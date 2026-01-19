import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';
import '../localization/app_localizations.dart';
import '../models/direction_line.dart';

class DirectionCard extends StatefulWidget {
  final DirectionLine direction;
  final AppLocalizations? localizations;

  const DirectionCard({required this.direction, required this.localizations, super.key});

  @override
  State<DirectionCard> createState() => _DirectionCardState();
}

class _DirectionCardState extends State<DirectionCard> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  final Map<String, TextEditingController> _coordinateControllers = {};

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.direction.labelFrom);
    _toController = TextEditingController(text: widget.direction.labelTo);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    for (final controller in _coordinateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();
    final direction = widget.direction;
    final localizations = widget.localizations;
    final isSelected = provider.selectedDirection == direction;

    return InkWell(
      onTap: () { 
        provider.selectDirection(direction);
        if (direction.isLocked) {
          provider.unlockForEditing(direction);
      }},
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: !isSelected ? null : () => _pickColor(context),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: direction.color,
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSelected
                        ? localizations!.editable
                        : direction.isLocked
                            ? localizations!.locked
                            : localizations!.editable,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.green
                          : direction.isLocked
                              ? Colors.grey[700]
                              : Colors.black,
                    ),
                  ),
                ],
              ),

              TextField(
                decoration: InputDecoration(labelText: localizations.from),
                controller: _fromController,
                onChanged: (v) => provider.updateLabels(v, _toController.text),
                enabled: isSelected,
              ),
              TextField(
                decoration: InputDecoration(labelText: localizations.to),
                controller: _toController,
                onChanged: (v) => provider.updateLabels(_fromController.text, v),
                enabled: isSelected,
              ),
              
              if (direction.points.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  localizations.linesCount((direction.points.length / 2).floor()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ...List.generate((direction.points.length / 2).floor(), (lineIndex) {
                  final p1Index = lineIndex * 2;
                  final p2Index = lineIndex * 2 + 1;
                  if (p2Index >= direction.points.length) return const SizedBox.shrink();
                  
                  return _buildLineCoordinates(
                    context,
                    provider,
                    direction,
                    lineIndex,
                    p1Index,
                    p2Index,
                    isSelected,
                    localizations,
                  );
                }),
              ],
              
              Row(
                children: [
                  TextButton(
                    onPressed: isSelected
                        ? () {
                            if (!direction.canLock) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(localizations.directionError),
                                  content: Text(
                                    localizations.labelsAndLineRequired,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text(localizations.translate('ok') == '**ok**' ? 'OK' : localizations.translate('ok')),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            provider.lockSelectedDirection();
                          }
                        : null,
                    child: Text(localizations.save),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.deleteDirection(direction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineCoordinates(
    BuildContext context,
    DirectionsProvider provider,
    DirectionLine direction,
    int lineIndex,
    int p1Index,
    int p2Index,
    bool isSelected,
    AppLocalizations localizations
  ) {
    final p1 = direction.points[p1Index];
    final p2 = direction.points[p2Index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.lineNumber(lineIndex + 1),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isSelected)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => provider.deletePointPair(direction, lineIndex),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildCoordinateField(
                  context,
                  'X1',
                  p1.dx,
                  (value) {
                    final x = double.tryParse(value);
                    if (x != null) {
                      provider.updatePointCoordinate(direction, p1Index, x, p1.dy);
                    }
                  },
                  isSelected,
                  p1Index,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildCoordinateField(
                  context,
                  'Y1',
                  p1.dy,
                  (value) {
                    final y = double.tryParse(value);
                    if (y != null) {
                      provider.updatePointCoordinate(direction, p1Index, p1.dx, y);
                    }
                  },
                  isSelected,
                  p1Index,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildCoordinateField(
                  context,
                  'X2',
                  p2.dx,
                  (value) {
                    final x = double.tryParse(value);
                    if (x != null) {
                      provider.updatePointCoordinate(direction, p2Index, x, p2.dy);
                    }
                  },
                  isSelected,
                  p2Index,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildCoordinateField(
                  context,
                  'Y2',
                  p2.dy,
                  (value) {
                    final y = double.tryParse(value);
                    if (y != null) {
                      provider.updatePointCoordinate(direction, p2Index, p2.dx, y);
                    }
                  },
                  isSelected,
                  p2Index,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateField(
    BuildContext context,
    String label,
    double value,
    Function(String) onChanged,
    bool enabled,
    int pointIndex,
  ) {
    final key = '$pointIndex-$label';
    
    if (!_coordinateControllers.containsKey(key)) {
      _coordinateControllers[key] = TextEditingController(text: value.toStringAsFixed(3));
    } else {
      final controller = _coordinateControllers[key]!;
      if (controller.text != value.toStringAsFixed(3)) {
        controller.text = value.toStringAsFixed(3);
      }
    }

    return TextField(
      controller: _coordinateControllers[key],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: const OutlineInputBorder(),
      ),
      style: Theme.of(context).textTheme.bodySmall,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  void _pickColor(BuildContext context) {
    final provider = context.read<DirectionsProvider>();
    final direction = widget.direction;
    final localizations = widget.localizations;
    Color tempColor = direction.color;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations!.pickAColor),
        content: ColorPicker(
          pickerColor: direction.color,
          onColorChanged: (Color color) => tempColor = color,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateColor(tempColor);
              Navigator.of(context).pop();
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }
}