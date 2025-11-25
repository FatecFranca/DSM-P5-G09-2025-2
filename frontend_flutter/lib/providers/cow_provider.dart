// lib/providers/cow_provider.dart
import 'package:flutter/foundation.dart';
import '../models/cow_data.dart';
import '../services/api_service.dart';

class CowProvider with ChangeNotifier {
  List<CowPrediction> _predictions = [];
  bool _loading = false;
  bool _historyLoading = true;
  String? _error;

  List<CowPrediction> get predictions => _predictions;
  bool get loading => _loading;
  bool get historyLoading => _historyLoading;
  String? get error => _error;

  CowProvider() {
    _syncRemoteHistory();
  }

  Future<void> _syncRemoteHistory({bool showLoader = true}) async {
    if (showLoader) {
      _historyLoading = true;
      notifyListeners();
    }
    try {
      final history = await ApiService.fetchAnalyses();
      _predictions = <CowPrediction>[];
      for (final analysis in history) {
        try {
          _predictions.add(CowPrediction.fromApi(analysis));
        } catch (e) {
          print('Erro ao processar análise: $e');
          print('Dados da análise: $analysis');
        }
      }
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar histórico: $e';
      print('Erro completo: $e');
    } finally {
      if (showLoader) {
        _historyLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> refreshHistory({bool showLoader = true}) async {
    await _syncRemoteHistory(showLoader: showLoader);
  }

  Future<void> predictPregnancy(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.predictPregnancy(data);
      
      final prediction = CowPrediction.fromApiResponse(result, data);

      _predictions.insert(0, prediction);
      
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
    try {
      await ApiService.deleteAnalysis(id);
      _predictions.removeWhere((pred) => pred.id == id);
      notifyListeners();
      await refreshHistory(showLoader: false);
    } catch (e) {
      _error = 'Erro ao remover análise: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ✅ MÉTODO clearHistory ADICIONADO
  Future<void> clearHistory() async {
    try {
      await ApiService.deleteAllAnalyses();
      await refreshHistory();
    } catch (e) {
      _error = 'Erro ao limpar histórico: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> clearPredictions() async {
    await clearHistory();
  }
}