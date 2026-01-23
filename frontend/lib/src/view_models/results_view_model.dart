import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class ResultsViewModel extends ChangeNotifier {
  Map<String, dynamic>? _resultsData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get resultsData => _resultsData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setResults(Map<String, dynamic> data) {
    _resultsData = data;
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    _resultsData = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> downloadResults() async {
    if (_resultsData == null) return false;

    try {
      final jsonString = jsonEncode(_resultsData);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'vehicle_counting_results_$timestamp.json';

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Results',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath == null) {
        return false;
      }

      final file = File(outputPath);
      await file.writeAsString(jsonString);

      return true;
    } catch (e) {
      _error = 'Failed to download results: $e';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _resultsData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
