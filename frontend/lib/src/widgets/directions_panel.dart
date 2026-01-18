import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';
import '../localization/app_localizations.dart';
import '../constants/error_strings.dart';
import '../constants/button_strings.dart';
import '../screens/model_info_screen.dart';

class DirectionsPanel extends StatelessWidget {
  const DirectionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();
    final direction = provider.selectedDirection;
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: provider.selectedModel,
            decoration: const InputDecoration(
              labelText: 'YOLO 11 version',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const ['yolo11n', 'yolo11s', 'yolo11m', 'yolo11l', 'yolo11xl']
                .map(
                  (model) => DropdownMenuItem(
                    value: model,
                    child: Text(model.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (model) {
              if (model != null) {
                provider.setSelectedModel(model);
              }
            },
          ),

          const SizedBox(height: 4),

          const SizedBox(height: 6),

          Tooltip(
            message: localizations!.modelInfoTooltip,
            waitDuration: const Duration(milliseconds: 300),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                localizations.translate('How to choose the right version?'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ModelInfoScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: direction == null
                ? const SizedBox.shrink()
                : _DirectionCard(localizations: localizations),
          ),

          ElevatedButton(
            onPressed: () => provider.startNewDirection(),
            child: Text(localizations.addDirection),
          ),
        ],
      ),
    );
  }
}

class _DirectionCard extends StatefulWidget {
  final AppLocalizations? localizations;

  const _DirectionCard({super.key, required this.localizations});

  @override
  State<_DirectionCard> createState() => _DirectionCardState();
}

class _DirectionCardState extends State<_DirectionCard> {
  late TextEditingController _fromController;
  late TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    final direction = context.read<DirectionsProvider>().selectedDirection!;
    _fromController = TextEditingController(text: direction.labelFrom);
    _toController = TextEditingController(text: direction.labelTo);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();
    final direction = provider.selectedDirection!;
    final localizations = widget.localizations;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: direction.isLocked ? null : () => _pickColor(context),
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
                Text(direction.isLocked ? localizations!.locked : localizations!.editable),
              ],
            ),

            TextField(
              decoration: InputDecoration(
                labelText: localizations.from,
              ),
              controller: _fromController,
              onChanged: (v) => provider.updateLabels(v, _toController.text),
            ),

            TextField(
              decoration: InputDecoration(
                labelText: localizations.to,
              ),
              controller: _toController,
              onChanged: (v) => provider.updateLabels(_fromController.text, v),
            ),

            Row(
              children: [
                TextButton(
                  onPressed: !direction.isLocked
                      ? () => _saveDirection(context, provider)
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
    );
  }

  void _pickColor(BuildContext context) {
    final provider = context.read<DirectionsProvider>();
    final direction = provider.selectedDirection!;
    final localizations = widget.localizations;
    Color tempColor = direction.color;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations!.pickAColor),
        content: ColorPicker(
          pickerColor: direction.color,
          onColorChanged: (Color color) {
            tempColor = color;
          },
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

  void _saveDirection(BuildContext context, DirectionsProvider provider) {
    final currentDirection = provider.selectedDirection;
    final localizations = widget.localizations;

    if (currentDirection == null) {
      _showErrorDialog(
        context,
        localizations!.error,
        localizations.noDirectionSelected ??
            ErrorStrings.noDirectionSelected,
      );
      return;
    }

    if (currentDirection.points.length < 2) {
      _showErrorDialog(
        context,
        localizations!.directionError ??
            ErrorStrings.directionErrorTitle,
        ErrorStrings.minimumTwoPoints,
      );
      return;
    }

    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      _showErrorDialog(
        context,
        localizations!.error,
        ErrorStrings.emptyFromLocation,
      );
      return;
    }

    provider.lockSelectedDirection();
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(ButtonStrings.okButton),
          ),
        ],
      ),
    );
  }
}