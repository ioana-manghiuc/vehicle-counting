import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';
import '../localization/app_localizations.dart';
import '../screens/model_info_screen.dart';
import 'direction_card.dart';
import 'intersection_dialogs.dart';

class DirectionsPanel extends StatelessWidget {
  const DirectionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();
    final localizations = AppLocalizations.of(context)!;

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