import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/video_model.dart';
import '../providers/directions_provider.dart';
import '../localization/app_localizations.dart';
import '../widgets/draw_on_image.dart';
import '../widgets/directions_panel.dart';
import '../widgets/app_bar.dart';
import '../utils/backend_service.dart';

class DirectionsScreen extends StatelessWidget {
  final VideoModel video;

  const DirectionsScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(titleKey: 'drawDirections'),
      body: video.thumbnailUrl == null
          ? const Center(child: CircularProgressIndicator())
          : _DirectionsScreenBody(video: video),
    );
  }
}

class _DirectionsScreenBody extends StatelessWidget {
  final VideoModel video;

  const _DirectionsScreenBody({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();
    final localizations = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: DrawOnImage(imageUrl: video.thumbnailUrl!),
        ),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const Expanded(child: DirectionsPanel()),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: provider.canSend
                      ? () async {
                          await BackendService.sendDirections(
                            video.path,
                            provider.serializeDirections(),
                          );
                        }
                      : null,
                  child: Text(
                      localizations?.translate('sendToBackend') ??
                          'Send to Backend'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}