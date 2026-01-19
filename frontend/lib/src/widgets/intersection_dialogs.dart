import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/src/localization/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/directions_provider.dart';

Future<void> showSaveIntersectionDialog(
  BuildContext context,
  DirectionsProvider provider,
  Size canvasSize,
  AppLocalizations localizations,
) async {
  final nameController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(localizations.saveIntersection),
        content: TextField(
          controller: nameController,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: localizations.intersectionName,
            hintText: localizations.intersectionNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: nameController.text.trim().isEmpty ? null : () async {
              final name = nameController.text.trim();

              final dir = await getApplicationDocumentsDirectory();
              final intersectionsDir = Directory('${dir.path}/intersections');

              if (!intersectionsDir.existsSync()) {
                intersectionsDir.createSync(recursive: true);
              }

              final filePath = '${intersectionsDir.path}/$name.json';
              final data = provider.serializeIntersection(name, canvasSize);
              final file = File(filePath);
              await file.writeAsString(jsonEncode(data));

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.intersectionSaved(name))),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showLoadIntersectionDialog(
  BuildContext context,
  DirectionsProvider provider,
  AppLocalizations localizations,
) async {

  final dir = await getApplicationDocumentsDirectory();
  final intersectionsDir = Directory('${dir.path}/intersections');

  if (!intersectionsDir.existsSync()) {
    intersectionsDir.createSync(recursive: true);
  }

  final files = intersectionsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  if (files.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.noSavedIntersectionsFound)),
    );
    return;
  }

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(localizations.loadIntersection),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: files.length,
          itemBuilder: (_, index) {
            final file = files[index];
            final name = file.uri.pathSegments.last.replaceAll('.json', '');
            return ListTile(
              title: Text(name),
              subtitle: Text(file.path),
              leading: const Icon(Icons.alt_route),
              onTap: () async {
                final jsonString = await file.readAsString();
                final data = jsonDecode(jsonString);
                provider.loadIntersectionFromData(data);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.intersectionLoaded(name))),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.close),
        ),
      ],
    ),
  );
}