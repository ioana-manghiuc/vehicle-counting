import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cancel_token.dart';
import 'package:uuid/uuid.dart';

class BackendService {
  static const backendUrl = 'http://127.0.0.1:8000';
  static http.Client? _httpClient;
  static CancelToken _cancelToken = CancelToken();
  static String? _currentProcessingId;

  static void cancelProcessing() {
    debugPrint('Cancelling processing request...');
    _cancelToken.cancel();

    if (_currentProcessingId != null) {
      _sendCancelRequest(_currentProcessingId!).then((_) {
        if (_httpClient != null) {
          _httpClient!.close();
          _httpClient = null;
          debugPrint('Closed HTTP client connection');
        }
      });
    } else {
      if (_httpClient != null) {
        _httpClient!.close();
        _httpClient = null;
        debugPrint('Closed HTTP client connection');
      }
    }
  }

  static Future<void> _sendCancelRequest(String processingId) async {
    try {
      debugPrint('Sending cancel request to backend for ID: $processingId');
      final response = await http.post(
        Uri.parse('$backendUrl/cancel_processing/$processingId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        debugPrint('Backend acknowledged cancellation');
      } else {
        debugPrint('Backend cancel response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Could not send cancel request to backend: $e');
    }
  }

  static void resetCancelToken() {
    _cancelToken = CancelToken();
  }

  static Future<String?> uploadVideoAndGetThumbnail(String videoPath) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$backendUrl/upload_frame'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('video', videoPath),
    );

    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Backend did not respond');
      },
    );

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      final thumbnailUrl = '$backendUrl${json['thumbnail_url']}';
      return thumbnailUrl;
    } else {
      final errorBody = await response.stream.bytesToString();
      debugPrint('upload_frame failed (${response.statusCode}): $errorBody');
      return null;
    }
  } catch (e, stackTrace) {
    debugPrint('Error uploading video: $e');
    debugPrint(stackTrace.toString());
    return null;
  }
}

  static Future<Map<String, dynamic>?> sendDirections(
    String videoPath,
    List<Map<String, dynamic>> directions,
    String modelName,
    String intersectionName,
  ) async {
    try {
      final directionsJson = jsonEncode(directions);
      
      debugPrint('\n=== SENDING TO BACKEND ===');
      debugPrint('Intersection: $intersectionName');
      debugPrint('Video Path: $videoPath');
      debugPrint('Model: $modelName');
      debugPrint('Directions JSON:');
      debugPrint(directionsJson);
      debugPrint('\nDirections Detail:');
      for (final dir in directions) {
        debugPrint('  Direction: ${dir['from']} - ${dir['to']}');
        debugPrint('    ID: ${dir['id']}');
        debugPrint('    Color: ${dir['color']}');
        debugPrint('    Lines (${(dir['lines'] as List).length} total):');
        for (int i = 0; i < (dir['lines'] as List).length; i++) {
          final line = (dir['lines'] as List)[i];
          debugPrint('      Line $i: x1=${line['x1']}, y1=${line['y1']}, x2=${line['x2']}, y2=${line['y2']}, isEntry=${line['isEntry']}');
        }
      }
      debugPrint('========================\n');

      resetCancelToken();
      _currentProcessingId = const Uuid().v4();
      debugPrint('📝 Processing ID: $_currentProcessingId');
      
      _httpClient = http.Client();
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/count_vehicles'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('video', videoPath),
      );

      request.fields['directions'] = directionsJson;
      request.fields['model_name'] = modelName;
      request.fields['intersection_name'] = intersectionName;
      request.fields['processing_id'] = _currentProcessingId!;

      final requestFuture = _httpClient!.send(request).timeout(
        const Duration(seconds: 7200),
        onTimeout: () {
          throw TimeoutException('Vehicle counting did not complete');
        },
      );

      final response = await Future.any([
        requestFuture,
        _cancelToken.cancellationFuture.then((_) => throw _RequestCancelledException()),
      ]);

      if (_cancelToken.isCancelled) {
        debugPrint('⚠️ Video processing was cancelled by user');
        _httpClient?.close();
        _httpClient = null;
        _currentProcessingId = null;
        return null;
      }

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final resultsJson = jsonDecode(body) as Map<String, dynamic>;
        _httpClient?.close();
        _httpClient = null;
        _currentProcessingId = null;
        return resultsJson;
      } else {
        debugPrint('❌ Backend returned status code: ${response.statusCode}');
        _httpClient?.close();
        _httpClient = null;
        _currentProcessingId = null;
        return null;
      }
    } on _RequestCancelledException {
      debugPrint('⚠️ Request was cancelled by user');
      _httpClient?.close();
      _httpClient = null;
      _currentProcessingId = null;
      return null;
    } catch (e, stackTrace) {
      if (_cancelToken.isCancelled) {
        debugPrint('⚠️ Request was cancelled');
        _httpClient?.close();
        _httpClient = null;
        _currentProcessingId = null;
        return null;
      }
      debugPrint('❌ Error sending directions: $e');
      debugPrint(stackTrace.toString());
      _currentProcessingId = null;
      return null;
    }
  }
}

class _RequestCancelledException implements Exception {
  @override
  String toString() => 'Request was cancelled by user';
}