// lib/services/local_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cow_data.dart';

class LocalStorage {
  static const String _predictionsKey = 'predictions_history';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> savePrediction(CowPrediction prediction) async {
    final List<String> predictions = _prefs.getStringList(_predictionsKey) ?? [];
    
    predictions.add(jsonEncode({
      'id': prediction.id,
      'data': prediction.data,
      'result': prediction.result,
      'timestamp': prediction.timestamp.toIso8601String(),
      'imagePath': prediction.imagePath,
    }));

    await _prefs.setStringList(_predictionsKey, predictions);
  }

  static Future<List<CowPrediction>> getPredictionsHistory() async {
    final List<String>? predictions = _prefs.getStringList(_predictionsKey);
    
    if (predictions == null) return [];

    return predictions.map((jsonString) {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return CowPrediction(
        id: data['id'],
        data: Map<String, dynamic>.from(data['data']),
        result: Map<String, dynamic>.from(data['result']),
        timestamp: DateTime.parse(data['timestamp']),
        imagePath: data['imagePath'],
      );
    }).toList();
  }

  static Future<void> deletePrediction(int id) async {
    final List<String> predictions = _prefs.getStringList(_predictionsKey) ?? [];
    
    predictions.removeWhere((jsonString) {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return data['id'] == id;
    });

    await _prefs.setStringList(_predictionsKey, predictions);
  }

  // ✅ MÉTODO clearHistory ADICIONADO
  static Future<void> clearHistory() async {
    await _prefs.remove(_predictionsKey);
  }
}