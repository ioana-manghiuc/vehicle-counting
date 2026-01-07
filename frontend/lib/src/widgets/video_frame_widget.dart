import 'dart:io';
import 'package:flutter/material.dart';

class VideoFrameWidget extends StatelessWidget {
  final File frameFile;

  const VideoFrameWidget({super.key, required this.frameFile});

  @override
  Widget build(BuildContext context) {
    return Image.file(frameFile);
  }
}
