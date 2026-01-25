import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_bar.dart';
import '../view_models/results_view_model.dart';
import '../localization/app_localizations.dart';
import '../utils/backend_service.dart';
import '../widgets/results_widgets/loading_state.dart';
import '../widgets/results_widgets/error_state.dart';
import '../widgets/results_widgets/results_content.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onBackPressed(context);
        }
      },
      child: Scaffold(
        appBar: const AppBarWidget(titleKey: 'resultsTitle'),
        body: Consumer<ResultsViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const ResultsLoading();
            }

            if (viewModel.error != null) {
              return ResultsError(error: viewModel.error!);
            }

            if (viewModel.resultsData == null) {
              final localizations = AppLocalizations.of(context);
              return Center(
                child: Text(
                  localizations?.translate('noResultsAvailable') ??
                      'No results available',
                ),
              );
            }

            return ResultsContent(viewModel: viewModel);
          },
        ),
      ),
    );
  }

  void _onBackPressed(BuildContext context) {
    final viewModel = context.read<ResultsViewModel>();
    
    if (!viewModel.isLoading) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final localizations = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            localizations?.translate('confirmCancel') ?? 'Cancel Processing?',
          ),
          content: Text(
            localizations?.translate('cancelProcessingMessage') ??
                'Video processing is in progress. Are you sure you want to cancel it and go back?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                localizations?.translate('no') ?? 'No',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                localizations?.translate('yes') ?? 'Yes',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    ).then((shouldCancel) {
      if (shouldCancel == true) {
        BackendService.cancelProcessing();
        viewModel.setLoading(false);
        viewModel.setError(
          localizations?.translate('processingCancelled') ?? 'Processing cancelled by user',
        );

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

}
