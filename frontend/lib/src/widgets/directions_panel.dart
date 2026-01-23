import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/directions_view_model.dart';
import '../localization/app_localizations.dart';
import '../screens/model_info_screen.dart';
import 'direction_card.dart';
import 'intersection_dialogs.dart';

class DirectionsPanel extends StatelessWidget {
  const DirectionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),  
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: provider.selectedModel,
            decoration: InputDecoration(
              labelText: localizations.yolo11VersionLabel,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            items: const ['yolo11n', 'yolo11s', 'yolo11m', 'yolo11l']
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (model) =>
                model != null ? provider.setSelectedModel(model) : null,
          ),

          const SizedBox(height: 8),

          Tooltip(
            message: localizations.modelInfoTooltip,
            waitDuration: const Duration(milliseconds: 300),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                localizations.howToChooseModel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ModelInfoScreen()),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: provider.directions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) => DirectionCard(
                direction: provider.directions[i],
                localizations: localizations,
              ),
            ),
          ),

          if (provider.directions.isNotEmpty) ...[
            ElevatedButton(
              onPressed: () => showSaveIntersectionDialog(context, provider, MediaQuery.of(context).size, localizations),
              child: Text(localizations.saveIntersection),
            ),
            const SizedBox(height: 8),
          ],

          ElevatedButton(
            onPressed: () => showLoadIntersectionDialog(context, provider, localizations),
            child: Text(localizations.loadIntersection),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () => provider.startNewDirection(),
            child: Text(localizations.addDirection),
          ),
        ],
      ),
    );
  }
}