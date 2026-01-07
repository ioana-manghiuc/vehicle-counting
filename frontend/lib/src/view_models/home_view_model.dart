// lib/src/view_models/home_view_model.dart
import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../utils/file_picker_helper.dart';
import '../utils/backend_service.dart';

class HomeViewModel extends ChangeNotifier {
  VideoModel? video;
  bool isLoading = false;

  Future<void> pickVideo() async {
    video = await FilePickerHelper.pickVideo();
    if (video == null) return;

    isLoading = true;
    notifyListeners();

    // Send the video to backend and get a thumbnail URL
    final thumbnailUrl = await BackendService.uploadVideoAndGetThumbnail(video!.path);

    video = VideoModel(path: video!.path, thumbnailUrl: thumbnailUrl);

    isLoading = false;
    notifyListeners();
  }
}
