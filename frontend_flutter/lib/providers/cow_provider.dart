// lib/providers/cow_provider.dart
import 'package:flutter/foundation.dart';
import '../models/cow_data.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';

class CowProvider with ChangeNotifier {
  List<CowPrediction> _predictions = [];
  bool _loading = false;
  String? _error;

  List<CowPrediction> get predictions => _predictions;
  bool get loading => _loading;
  String? get error => _error;

  CowProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await LocalStorage.getPredictionsHistory();
      _predictions = history;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> predictPregnancy(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.predictPregnancy(data);
      
      final prediction = CowPrediction(
        id: DateTime.now().millisecondsSinceEpoch,
        data: data,
        result: Map<String, dynamic>.from(result), 
        timestamp: DateTime.now(),
        imagePath: data['imagePath'],
        imageBytes: data['imageBytes'], 
      );

      _predictions.insert(0, prediction);
      await LocalStorage.savePrediction(prediction);
      
      notifyListeners();
    } catch (e) {
      _error = 'Erro na predição: $e';
      notifyListeners();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deletePrediction(int id) async {
    _predictions.removeWhere((pred) => pred.id == id);
    await LocalStorage.deletePrediction(id);
    notifyListeners();
  }

  // ✅ MÉTODO clearHistory ADICIONADO
  Future<void> clearHistory() async {
    _predictions.clear();
    await LocalStorage.clearHistory();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPredictions() {}
}