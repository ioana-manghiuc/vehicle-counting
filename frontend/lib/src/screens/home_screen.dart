import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../view_models/directions_view_model.dart';
import '../view_models/results_view_model.dart';
import '../utils/backend_service.dart';
import '../view_models/home_view_model.dart';
import '../widgets/app_bar.dart';
import '../widgets/directions_panel.dart';
import '../widgets/draw_on_image.dart';
import '../localization/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handlePick(BuildContext context, HomeViewModel vm) async {
    context.read<DirectionsViewModel>().reset();
    await vm.pickVideo();
  }

  Future<void> _handleSendDirections(
    BuildContext context,
    HomeViewModel homeViewModel,
    DirectionsViewModel directionsViewModel,
  ) async {
    final resultsViewModel = context.read<ResultsViewModel>();

    resultsViewModel.setLoading(true);

    if (context.mounted) {
      Navigator.of(context).pushNamed('/results');
    }

    final results = await BackendService.sendDirections(
      homeViewModel.video!.path,
      directionsViewModel.serializeDirections(),
      directionsViewModel.selectedModel,
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (localizations == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          final directionsProvider = context.watch<DirectionsViewModel>();

          return Scaffold(
            appBar: const AppBarWidget(titleKey: 'appTitle'),
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _CanvasArea(
                        viewModel: vm,
                        localizations: localizations,
                        onPick: () => _handlePick(context, vm),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: vm.video != null && !vm.isLoading
                        ? Column(
                            children: [
                              const Expanded(child: DirectionsPanel()),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                  onPressed: directionsProvider.canSend
                                      ? () async {
                                          await _handleSendDirections(context, vm, directionsProvider);
                                        }
                                      : null,
                                  child: Text(localizations.sendToBackend),
                                ),
                              ),
                            ],
                          )
                        : _DirectionsPlaceholder(localizations: localizations),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CanvasArea extends StatelessWidget {
  final HomeViewModel viewModel;
  final AppLocalizations localizations;
  final VoidCallback onPick;

  const _CanvasArea({
    required this.viewModel,
    required this.localizations,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (viewModel.video?.thumbnailUrl != null && !viewModel.isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: DrawOnImage(imageUrl: viewModel.video!.thumbnailUrl!),
      );
    }

    return GestureDetector(
      onTap: viewModel.isLoading ? null : onPick,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(),
              ),
            ),
            if (viewModel.isLoading)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimationWidget.waveDots(
                    color: theme.colorScheme.primary,
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.waitingForServer,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 42,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      textStyle: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: viewModel.isLoading ? null : onPick,
                    child: Text(localizations.pickVideo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.tapCanvasToUpload,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DirectionsPlaceholder extends StatelessWidget {
  final AppLocalizations localizations;
  const _DirectionsPlaceholder({required this.localizations});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            localizations.uploadVideoToStartDrawingDirections,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}