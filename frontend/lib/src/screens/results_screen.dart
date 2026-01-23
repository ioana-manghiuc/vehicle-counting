import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../widgets/app_bar.dart';
import '../view_models/results_view_model.dart';
import '../localization/app_localizations.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(titleKey: 'resultsTitle'),
      body: Consumer<ResultsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return _buildLoadingState(context);
          }

          if (viewModel.error != null) {
            return _buildErrorState(context, viewModel.error!);
          }

          if (viewModel.resultsData == null) {
            return const Center(child: Text('No results available'));
          }

          return _buildResultsView(context, viewModel);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingAnimationWidget.waveDots(
            color: theme.colorScheme.primary,
            size: 72,
          ),
          const SizedBox(height: 24),
          Text(
            localizations?.translate('processingVideo') ?? 'Processing video...',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error Processing Results',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(
    BuildContext context,
    ResultsViewModel viewModel,
  ) {
    final data = viewModel.resultsData!;
    final results = data['results'] as Map<String, dynamic>?;
    final metadata = data['metadata'] as Map<String, dynamic>?;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () async {
              viewModel.setLoading(true);
              final success = await viewModel.downloadResults();
              viewModel.setLoading(false);

              if (context.mounted) {
                final localizations = AppLocalizations.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? localizations?.translate('resultsDownloaded') ??
                              'Results downloaded successfully'
                          : 'Failed to download results',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.download),
            label: Text(
              AppLocalizations.of(context)?.translate('downloadResults') ??
                  'Download Results',
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (metadata != null) ...[
                _buildSectionCard(
                  context,
                  title: 'Processing Information',
                  children: [
                    _buildMetadataItem(
                      context,
                      'Video',
                      metadata['video_file'] ?? 'Unknown',
                    ),
                    _buildMetadataItem(
                      context,
                      'Model',
                      metadata['model'] ?? 'Unknown',
                    ),
                    _buildMetadataItem(
                      context,
                      'Processing Time',
                      '${metadata['processing_time_seconds']?.toString() ?? '0'}s',
                    ),
                    _buildMetadataItem(
                      context,
                      'Total Frames',
                      metadata['total_frames_processed']?.toString() ?? '0',
                    ),
                    _buildMetadataItem(
                      context,
                      'Video Dimensions',
                      '${metadata['video_dimensions']?['width']}x${metadata['video_dimensions']?['height']}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (results != null) ...[
                _buildSectionCard(
                  context,
                  title: 'Vehicle Counts by Direction',
                  children: [
                    ..._buildResultsItems(context, results),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResultsItems(
    BuildContext context,
    Map<String, dynamic> results,
  ) {
    final theme = Theme.of(context);
    final items = <Widget>[];

    results.forEach((directionId, counts) {
      if (counts is Map<String, dynamic>) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direction: ${_extractDirectionLabel(directionId, counts)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCountItem(context, 'Cars', counts['cars'] ?? 0),
                  _buildCountItem(context, 'Bikes', counts['bikes'] ?? 0),
                  _buildCountItem(context, 'Buses', counts['buses'] ?? 0),
                  _buildCountItem(context, 'Trucks', counts['trucks'] ?? 0),
                  const Divider(height: 12),
                  _buildCountItem(
                    context,
                    'Total',
                    (counts['cars'] ?? 0) +
                        (counts['bikes'] ?? 0) +
                        (counts['buses'] ?? 0) +
                        (counts['trucks'] ?? 0),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    return items;
  }

  Widget _buildCountItem(
    BuildContext context,
    String label,
    dynamic count, {
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            count.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  String _extractDirectionLabel(String id, Map<String, dynamic> counts) {
    if (counts.containsKey('from') && counts.containsKey('to')) {
      return '${counts['from']} → ${counts['to']}';
    }
    return id.length > 8 ? id.substring(0, 8) : id;
  }
}
