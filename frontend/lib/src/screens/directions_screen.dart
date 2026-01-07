// lib/src/screens/directions_screen.dart
import 'package:flutter/material.dart';
import '../widgets/draw_on_image.dart';
import '../models/video_model.dart';
import '../utils/backend_service.dart';

class DirectionsScreen extends StatefulWidget {
  final VideoModel video;

  const DirectionsScreen({super.key, required this.video});

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  final GlobalKey<DrawOnImageState> drawKey = GlobalKey<DrawOnImageState>();

  @override
  Widget build(BuildContext context) {
    if (widget.video.thumbnailUrl == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Draw Directions')),
      body: Column(
        children: [
          Expanded(
            child: DrawOnImage(
              key: drawKey,
              imageUrl: widget.video.thumbnailUrl!,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final coordinates = drawKey.currentState!.getCoordinates();
              final success = await BackendService.sendDirections(
                  widget.video.path, coordinates);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uploaded directions successfully')),
                );
              }
            },
            child: const Text('Send to Backend'),
          ),
        ],
      ),
    );
  }
}
