import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';
import '../localization/app_localizations.dart';
import '../models/direction.dart';

class DirectionCard extends StatefulWidget {
  final Direction direction;
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
        color: isSelected
            ? Theme.of(context).colorScheme.onSecondaryFixed
            : Theme.of(context).colorScheme.secondaryContainer,
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
                          ? Theme.of(context).colorScheme.tertiary
                          : direction.isLocked
                              ? Theme.of(context).colorScheme.onTertiary
                              : Theme.of(context).colorScheme.primary,
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

              if (direction.lines.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  localizations.linesCount(direction.lines.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: direction.lines.indexWhere((l) => l.isEntry).clamp(0, direction.lines.length - 1),
                        items: List.generate(
                          direction.lines.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(localizations.lineWithNumber(i + 1)),
                          ),
                        ),
                        decoration: InputDecoration(
                          labelText: localizations.entryLineLabel(
                            direction.lines.indexWhere((l) => l.isEntry).clamp(0, direction.lines.length - 1) + 1,
                          ),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: !isSelected
                            ? null
                            : (v) {
                                if (v != null) {
                                  provider.setLineAsEntry(direction, v);
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              if (direction.lines.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...List.generate(direction.lines.length, (lineIndex) {
                  return _buildLineCoordinates(
                    context,
                    provider,
                    direction,
                    lineIndex,
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
    Direction direction,
    int lineIndex,
    bool isSelected,
    AppLocalizations localizations
  ) {
    final line = direction.lines[lineIndex];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
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
                  onPressed: () => provider.deleteLineAtIndex(direction, lineIndex),
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
                  line.x1,
                  (value) {
                    final x = double.tryParse(value);
                    if (x != null) {
                      provider.updateLineCoordinates(direction, lineIndex, x, line.y1, line.x2, line.y2);
                    }
                  },
                  isSelected,
                  lineIndex,
                  'x1',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildCoordinateField(
                  context,
                  'Y1',
                  line.y1,
                  (value) {
                    final y = double.tryParse(value);
                    if (y != null) {
                      provider.updateLineCoordinates(direction, lineIndex, line.x1, y, line.x2, line.y2);
                    }
                  },
                  isSelected,
                  lineIndex,
                  'y1',
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
                  line.x2,
                  (value) {
                    final x = double.tryParse(value);
                    if (x != null) {
                      provider.updateLineCoordinates(direction, lineIndex, line.x1, line.y1, x, line.y2);
                    }
                  },
                  isSelected,
                  lineIndex,
                  'x2',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildCoordinateField(
                  context,
                  'Y2',
                  line.y2,
                  (value) {
                    final y = double.tryParse(value);
                    if (y != null) {
                      provider.updateLineCoordinates(direction, lineIndex, line.x1, line.y1, line.x2, y);
                    }
                  },
                  isSelected,
                  lineIndex,
                  'y2',
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
    int lineIndex,
    String coord,
  ) {
    final key = '$lineIndex-$coord';
    
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