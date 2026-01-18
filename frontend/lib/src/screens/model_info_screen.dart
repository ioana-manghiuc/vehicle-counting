import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class ModelInfoScreen extends StatelessWidget {
  const ModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.modelInfoTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModelCard(
              context: context,
              model: localizations.modelYolo11n,
              speed: localizations.speedFastest,
              accuracy: localizations.accuracyGood,
              hardwareReq: localizations.hardwareMinimal,
              description: localizations.descriptionYolo11n,
            ),
            const SizedBox(height: 16),
            _buildModelCard(
              context: context,
              model: localizations.modelYolo11s,
              speed: localizations.speedFast,
              accuracy: localizations.accuracyBetter,
              hardwareReq: localizations.hardwareLow,
              description: localizations.descriptionYolo11s,
            ),
            const SizedBox(height: 16),
            _buildModelCard(
              context: context,
              model: localizations.modelYolo11m,
              speed: localizations.speedMedium,
              accuracy: localizations.accuracyVeryGood,
              hardwareReq: localizations.hardwareMedium,
              description: localizations.descriptionYolo11m,
            ),
            const SizedBox(height: 16),
            _buildModelCard(
              context: context,
              model: localizations.modelYolo11l,
              speed: localizations.speedSlow,
              accuracy: localizations.accuracyExcellent,
              hardwareReq: localizations.hardwareHigh,
              description: localizations.descriptionYolo11l,
            ),
            const SizedBox(height: 16),
            _buildModelCard(
              context: context,
              model: localizations.modelYolo11xl,
              speed: localizations.speedVerySlow,
              accuracy: localizations.accuracyOutstanding,
              hardwareReq: localizations.hardwareVeryHigh,
              description: localizations.descriptionYolo11xl,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(90, 33, 149, 243),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.recommendationsTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(localizations.recommendation1),
                  const SizedBox(height: 8),
                  Text(localizations.recommendation2),
                  const SizedBox(height: 8),
                  Text(localizations.recommendation3),
                  const SizedBox(height: 8),
                  Text(localizations.recommendation4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard({
    required BuildContext context,
    required String model,
    required String speed,
    required String accuracy,
    required String hardwareReq,
    required String description,
  }) {
    final localizations = AppLocalizations.of(context)!;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(localizations.speedLabel, speed),
                ),
                Expanded(
                  child: _buildInfoRow(localizations.accuracyLabel, accuracy),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(localizations.hardwareLabel, hardwareReq),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
