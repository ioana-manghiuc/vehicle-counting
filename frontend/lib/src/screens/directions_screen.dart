import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../widgets/draw_on_image.dart';
import '../widgets/directions_panel.dart';
import '../widgets/app_bar.dart';

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
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const DirectionsPanel(),
              ),
            ),
          ),

        ],
      ),
    );
  }
}