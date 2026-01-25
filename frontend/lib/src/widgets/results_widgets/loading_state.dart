import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../localization/app_localizations.dart';

class ResultsLoading extends StatelessWidget {
  const ResultsLoading({super.key});

  @override
  Widget build(BuildContext context) {
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
}
