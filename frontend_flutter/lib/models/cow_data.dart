// lib/models/cow_data.dart
import 'dart:typed_data';

class CowData {
  final int cow;
  final int lactationNumber;
  final String time;
  final String date;

  CowData({
    required this.cow,
    required this.lactationNumber,
    required this.time,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      "cow": cow,
      "lactation_number_in_data": lactationNumber,
      "time": time,
      "date": date,
    };
  }
}

class CowPrediction {
  final int id;
  final Map<String, dynamic> data;          // Dados enviados ao backend
  final Map<String, dynamic> result;        // Resposta do backend
  final DateTime timestamp;
  final String? imagePath;                  // Caminho da imagem salva no device
  final Uint8List? imageBytes;              // Imagem utilizada no Web/App

  CowPrediction({
    required this.id,
    required this.data,
    required this.result,
    required this.timestamp,
    this.imagePath,
    this.imageBytes,
  });

  /// Retorna confiança em formato double (0.0 a 1.0)
  double get confidence =>
      (result['confidence'] ?? 0.0).toDouble();

  /// Retorna confiança já multiplicada por 100
  double get confidencePercent =>
      (result['confidence_percent'] ?? 0.0).toDouble();

  /// Se existe qualquer imagem associada
  bool get hasImage => imagePath != null || imageBytes != null;

  /// Retorna os dados enviados → útil no histórico
  Map<String, dynamic> get inputData => data;

  // ========= SERIALIZAÇÃO ========= //

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'imageBytes': imageBytes, // Pode ser null
    };
  }

  factory CowPrediction.fromJson(Map<String, dynamic> json) {
    return CowPrediction(
      id: json['id'],
      data: Map<String, dynamic>.from(json['data']),
      result: Map<String, dynamic>.from(json['result']),
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
      imageBytes: json['imageBytes'], // pode ser null
    );
  }

  get cowId => null;
}
