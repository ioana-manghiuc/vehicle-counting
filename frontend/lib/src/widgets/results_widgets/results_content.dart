import 'package:flutter/material.dart';
import '../annotated_video_player.dart';
import '../../view_models/results_view_model.dart';
import '../../localization/app_localizations.dart';

class ResultsContent extends StatelessWidget {
  const ResultsContent({super.key, required this.viewModel});

  final ResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final data = viewModel.resultsData!;
    debugPrint('Results data keys: ${data.keys.toList()}');
    debugPrint('Full results data: $data');

    final results = data['results'] as Map<String, dynamic>?;
    final metadata = data['metadata'] as Map<String, dynamic>?;
    debugPrint('Metadata: $metadata');
    final annotatedVideoUrl = metadata?['annotated_video'] as String?;
    debugPrint('Annotated video URL: $annotatedVideoUrl');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: annotatedVideoUrl != null
                          ? _buildVideoPlayer(context, annotatedVideoUrl)
                          : Center(
                              child: Text(
                                AppLocalizations.of(context)?.translate('noVideoAvailable') ??
                                    'No annotated video available',
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: results != null
                          ? _buildResultsList(context, results)
                          : Center(
                              child: Text(
                                AppLocalizations.of(context)?.translate('noResultsAvailable') ??
                                    'No results available',
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildSummaryAndDownloads(context, viewModel, metadata),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context, String videoUrl) {
    return AnnotatedVideoPlayer(videoUrl: videoUrl);
  }

  Widget _buildResultsList(
    BuildContext context,
    Map<String, dynamic> results,
  ) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            localizations?.translate('vehicleCountsByDirection') ?? 'Vehicle Counts by Direction',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ..._buildResultsItems(context, results),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryAndDownloads(
    BuildContext context,
    ResultsViewModel viewModel,
    Map<String, dynamic>? metadata,
  ) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.translate('summary') ?? 'Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (metadata != null) ...[
                  _buildSummaryItem(
                    context,
                    localizations?.translate('intersection') ?? 'Intersection',
                    metadata['intersection_name'] ?? 'N/A',
                  ),
                  _buildSummaryItem(
                    context,
                    localizations?.translate('video') ?? 'Video',
                    metadata['video_file'] ?? 'Unknown',
                  ),
                  _buildSummaryItem(
                    context,
                    localizations?.translate('model') ?? 'Model',
                    metadata['model'] ?? 'Unknown',
                  ),
                  _buildSummaryItem(
                    context,
                    localizations?.translate('processingTime') ?? 'Processing Time',
                    '${metadata['processing_time_seconds']?.toString() ?? '0'}s',
                  ),
                  _buildSummaryItem(
                    context,
                    localizations?.translate('totalFrames') ?? 'Total Frames',
                    metadata['total_frames_processed']?.toString() ?? '0',
                  ),
                  _buildSummaryItem(
                    context,
                    localizations?.translate('directionsCount') ?? 'Directions Count',
                    metadata['directions_count']?.toString() ?? '0',
                  ),
                  _buildSummaryItem(
                    context,
                    localizations?.translate('videoDimensions') ?? 'Video Dimensions',
                    '${metadata['video_dimensions']?['width']}x${metadata['video_dimensions']?['height']}',
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations?.translate('downloadResults') ?? 'Download Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    viewModel.setLoading(true);
                    final success = await viewModel.downloadResults();
                    viewModel.setLoading(false);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? localizations?.translate('resultsDownloaded') ?? 'Results downloaded successfully'
                                : localizations?.translate('failedToDownloadJSON') ?? 'Failed to download JSON',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: Text(
                    localizations?.translate('downloadJSON') ?? 'Download JSON',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    viewModel.setLoading(true);
                    final success = await viewModel.downloadResultsAsCSV();
                    viewModel.setLoading(false);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? localizations?.translate('resultsDownloaded') ?? 'Results downloaded successfully'
                                : localizations?.translate('failedToDownloadCSV') ?? 'Failed to download CSV',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: Text(
                    localizations?.translate('downloadCSV') ?? 'Download CSV',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
    final localizations = AppLocalizations.of(context);
    final items = <Widget>[];

    results.forEach((directionId, counts) {
      if (counts is Map<String, dynamic>) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
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
                    '${localizations?.translate('direction') ?? 'Direction'}: ${_extractDirectionLabel(directionId, counts)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCountItem(context, localizations?.translate('cars') ?? 'Cars', counts['cars'] ?? 0),
                  _buildCountItem(context, localizations?.translate('bikes') ?? 'Bikes', counts['bikes'] ?? 0),
                  _buildCountItem(context, localizations?.translate('buses') ?? 'Buses', counts['buses'] ?? 0),
                  _buildCountItem(context, localizations?.translate('trucks') ?? 'Trucks', counts['trucks'] ?? 0),
                  const Divider(height: 12),
                  _buildCountItem(
                    context,
                    localizations?.translate('total') ?? 'Total',
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
      return '${counts['from']} - ${counts['to']}';
    }
    return id.length > 8 ? id.substring(0, 8) : id;
  }
}
