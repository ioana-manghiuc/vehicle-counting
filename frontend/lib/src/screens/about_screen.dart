import 'package:flutter/material.dart';
import '../widgets/app_bar.dart';
import '../localization/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWidget(titleKey: 'userManual'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              localizations!.userManualIntro,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            _StepRow(
              number: '1',
              text: localizations.userManualStepUpload,
            ),
            _StepRow(
              number: '2',
              text: localizations.userManualStepWait,
            ),
            _StepRow(
              number: '3',
              text: localizations.userManualStepDraw,
            ),
            _StepRow(
              number: '4',
              text: localizations.userManualStepSend,
            ),
            const SizedBox(height: 16),
            Card(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.secondary,
                ),
                child: Text(
                  localizations.userManualTip,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.secondary,
                ),
                child: Text(
                  localizations.userManualEditingLine,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(number, style: TextStyle(color: theme.colorScheme.onPrimary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
