import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import '../models/video_model.dart';
import '../models/intersection_model.dart';
class FilePickerHelper {
  static Future<VideoModel?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return null;

    final videoPath = result.files.single.path!;

    return VideoModel(path: videoPath);
  }

  static bool _isValidIntersectionJson(Map<String, dynamic> json) {
    try {
      if (!json.containsKey('id') || (json['id'] is! String && json['id'] is! int)) return false;
      if (!json.containsKey('name') || json['name'] is! String) return false;
      if (!json.containsKey('canvasSize') || json['canvasSize'] is! Map) return false;

      final directionsOrLines = json.containsKey('directions')
          ? json['directions']
          : json['lines'];
      if (directionsOrLines is! List) return false;

      final canvasSize = json['canvasSize'] as Map<String, dynamic>;
      if (!canvasSize.containsKey('w') || canvasSize['w'] is! num) return false;
      if (!canvasSize.containsKey('h') || canvasSize['h'] is! num) return false;

      final directions = directionsOrLines;
      if (directions.isEmpty) return false;

      for (final dir in directions) {
        if (dir is! Map<String, dynamic>) return false;
        if (!dir.containsKey('id') || (dir['id'] is! String && dir['id'] is! int)) return false;
        if (!dir.containsKey('from') || dir['from'] is! String) return false;
        if (!dir.containsKey('to') || dir['to'] is! String) return false;
        if (!dir.containsKey('color') || dir['color'] is! num) return false;
        if (!dir.containsKey('lines') || dir['lines'] is! List) return false;

        final lines = dir['lines'] as List;
        if (lines.isEmpty) return false;

        for (final line in lines) {
          if (line is! Map<String, dynamic>) return false;
          if (!line.containsKey('id') || (line['id'] is! String && line['id'] is! int)) return false;
          if (!line.containsKey('x1') || line['x1'] is! num) return false;
          if (!line.containsKey('y1') || line['y1'] is! num) return false;
          if (!line.containsKey('x2') || line['x2'] is! num) return false;
          if (!line.containsKey('y2') || line['y2'] is! num) return false;
          if (!line.containsKey('isEntry') || line['isEntry'] is! bool) return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<IntersectionModel?> pickIntersectionJson() async{
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return null;
    
    try {
      final filePath = result.files.single.path!;
      final fileContent = await File(filePath).readAsString();
      final jsonData = jsonDecode(fileContent) as Map<String, dynamic>;

      if (!jsonData.containsKey('directions') && jsonData.containsKey('lines')) {
        jsonData['directions'] = jsonData['lines'];
      }
      
      if (!_isValidIntersectionJson(jsonData)) {
        return null;
      }
      
      return IntersectionModel.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  

}