import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../widgets/draw_on_image.dart';
import '../widgets/directions_panel.dart';
import '../widgets/app_bar.dart';
import '../view_models/directions_view_model.dart';
import '../view_models/results_view_model.dart';
import '../utils/backend_service.dart';
import '../localization/app_localizations.dart';

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

  const _DirectionsScreenBody({required this.video});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DrawOnImage(imageUrl: video.thumbnailUrl!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _DirectionsPanelWithSendButton(video: video),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionsPanelWithSendButton extends StatelessWidget {
  final VideoModel video;

  const _DirectionsPanelWithSendButton({required this.video});

  @override
  Widget build(BuildContext context) {
    final directionsProvider = context.watch<DirectionsViewModel>();
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        const Expanded(child: DirectionsPanel()),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: directionsProvider.canSend
                ? () async {
                    await _sendDirections(context, directionsProvider);
                  }
                : null,
            child: Text(localizations?.translate('sendToBackend') ?? 'Send to Backend'),
          ),
        ),
      ],
    );
  }

  Future<void> _sendDirections(
    BuildContext context,
    DirectionsViewModel directionsProvider,
  ) async {
    final resultsViewModel = context.read<ResultsViewModel>();

    resultsViewModel.setLoading(true);

    if (context.mounted) {
      Navigator.of(context).pushNamed('/results');
    }

    final results = await BackendService.sendDirections(
      video.path,
      directionsProvider.serializeDirections(),
      directionsProvider.selectedModel,
    );

    if (context.mounted) {
      if (results != null) {
        resultsViewModel.setResults(results);
      } else {
        resultsViewModel.setError('Failed to process vehicle counting');
      }
      resultsViewModel.setLoading(false);
    }
  }
}