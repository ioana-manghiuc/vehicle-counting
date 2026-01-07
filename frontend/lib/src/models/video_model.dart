// lib/src/models/video_model.dart
class VideoModel {
  final String path; // local path of the video (optional)
  final String? thumbnailUrl; // URL returned by backend for the frame

  VideoModel({required this.path, this.thumbnailUrl});
}
