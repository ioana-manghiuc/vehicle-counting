import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/directions_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../models/direction_model.dart';

class EntryLineSelector extends StatelessWidget {
  final DirectionModel direction;
  final bool enabled;

  const EntryLineSelector({
    super.key,
    required this.direction,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            dropdownColor: Theme.of(context).colorScheme.secondaryContainer,
            iconEnabledColor: Theme.of(context).colorScheme.primary,
            iconDisabledColor: Theme.of(context).colorScheme.onSecondaryFixed,
            value: direction.lines.indexWhere((l) => l.isEntry).clamp(0, direction.lines.length - 1),
            items: List.generate(
              direction.lines.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  localizations.lineWithNumber(i + 1),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            decoration: InputDecoration(
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  localizations.entryLineLabel(
                    direction.lines.indexWhere((l) => l.isEntry).clamp(0, direction.lines.length - 1) + 1,
                  ),
                ),
              ),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: !enabled
                ? null
                : (v) {
                    if (v != null) {
                      provider.setLineAsEntry(direction, v);
                    }
                  },
          ),
        ),
      ],
    );
  }
}
