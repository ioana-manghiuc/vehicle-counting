// lib/src/utils/backend_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;

class BackendService {
  static const backendUrl = 'http://YOUR_BACKEND_URL_HERE';

  /// Upload video and get a single frame URL for drawing
  static Future<String?> uploadVideoAndGetThumbnail(String videoPath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/upload_frame'));
    request.files.add(await http.MultipartFile.fromPath('video', videoPath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      return body; // backend returns the URL of the frame
    } else {
      print('Upload failed: ${response.statusCode}');
      return null;
    }
  }

  /// Send directions + video to backend for counting
  static Future<bool> sendDirections(String videoPath, List<List<double>> directions) async {
    final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/count_vehicles'));
    request.files.add(await http.MultipartFile.fromPath('video', videoPath));
    request.fields['directions'] = directions.toString(); // serialize your coordinates

    final response = await request.send();
    return response.statusCode == 200;
  }
}
