// lib/models/cow_data.dart
import 'dart:typed_data';
import 'dart:convert';

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
  final String status;
  final String? notes;
  final String? remoteCowId;
  final String? imagePath;                  // Caminho da imagem salva no device
  final Uint8List? imageBytes;              // Imagem utilizada no Web/App

  CowPrediction({
    required this.id,
    required this.data,
    required this.result,
    required this.timestamp,
    required this.status,
    this.notes,
    this.remoteCowId,
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
       'status': status,
       'notes': notes,
       'remoteCowId': remoteCowId,
      'imagePath': imagePath,
      'imageBytes': imageBytes?.toList(), // Pode ser null
    };
  }

  factory CowPrediction.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num
        ? rawId.toInt()
        : (rawId != null ? int.tryParse(rawId.toString()) ?? 0 : 0);

    final rawData = json['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    final rawResult = json['result'];
    final result = rawResult is Map
        ? Map<String, dynamic>.from(rawResult)
        : <String, dynamic>{};

    final rawTimestamp = json['timestamp'];
    final timestamp = rawTimestamp is String
        ? (DateTime.tryParse(rawTimestamp) ?? DateTime.now())
        : DateTime.now();

    final rawStatus = json['status'];
    final status = rawStatus?.toString() ?? 'completed';

    final rawNotes = json['notes'];
    final notes = rawNotes?.toString();

    final rawRemoteCowId = json['remoteCowId'];
    final remoteCowId = rawRemoteCowId?.toString();

    final rawImagePath = json['imagePath'];
    final imagePath = rawImagePath?.toString();

    return CowPrediction(
      id: id,
      data: data,
      result: result,
      timestamp: timestamp,
      status: status,
      notes: notes,
      remoteCowId: remoteCowId,
      imagePath: imagePath,
      imageBytes: _decodeImageBytes(json['imageBytes']),
    );
  }

  factory CowPrediction.fromApi(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final payload = rawPayload is Map
        ? Map<String, dynamic>.from(rawPayload)
        : <String, dynamic>{};

    final rawProbability = json['probability'];
    final probability = rawProbability is num
        ? rawProbability.toDouble()
        : (rawProbability != null ? double.tryParse(rawProbability.toString()) ?? 0.0 : 0.0);

    final rawPredictionLabel = json['prediction_label'];
    final predictionLabel = rawPredictionLabel?.toString() ?? 'N/A';

    final rawPrediction = json['prediction'];
    final prediction = rawPrediction is num
        ? rawPrediction.toInt()
        : (rawPrediction != null ? int.tryParse(rawPrediction.toString()) ?? 0 : 0);

    final resultMap = {
      'prenhez': predictionLabel,
      'prediction': prediction,
      'confidence': probability,
      'probability': probability,
      'confidence_percent': (probability * 100),
      'status': 'success',
    };

    final rawId = json['id'];
    final id = rawId is num
        ? rawId.toInt()
        : (rawId != null ? int.tryParse(rawId.toString()) ?? 0 : 0);

    final rawCreatedAt = json['created_at'];
    final createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
        : DateTime.now();

    final rawStatus = json['status'];
    final status = rawStatus?.toString() ?? 'completed';

    final rawNotes = json['notes'];
    final notes = rawNotes?.toString();

    final rawCowId = json['cow_id'];
    final cowId = rawCowId?.toString();

    final rawImagePath = payload['imagePath'];
    final imagePath = rawImagePath?.toString();
    
    final rawImageBase64 = payload['imageBase64'];
    Uint8List? imageBytes;
    if (rawImageBase64 is String && rawImageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(rawImageBase64);
        print('📸 fromApi - ImageBase64 decodificado: ${imageBytes.length} bytes');
      } catch (e) {
        print('❌ Erro ao decodificar imageBase64: $e');
      }
    }
    
    print('📸 fromApi - ImagePath: $imagePath');
    print('📸 fromApi - ImageBytes: ${imageBytes != null}');

    return CowPrediction(
      id: id,
      data: payload,
      result: resultMap,
      timestamp: createdAt,
      status: status,
      notes: notes,
      remoteCowId: cowId,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
  }

  factory CowPrediction.fromApiResponse(
    Map<String, dynamic> response,
    Map<String, dynamic> originalInput,
  ) {
    if (response.containsKey('analysis')) {
      final analysisData = response['analysis'];
      if (analysisData is Map) {
        return CowPrediction.fromApi(
          Map<String, dynamic>.from(analysisData),
        );
      }
    }

    final rawConfidence = response['confidence'];
    final probability = rawConfidence is num
        ? rawConfidence.toDouble()
        : (rawConfidence != null ? double.tryParse(rawConfidence.toString()) ?? 0.0 : 0.0);

    final sanitizedInput = Map<String, dynamic>.from(originalInput);
    final resultMap = Map<String, dynamic>.from(response);
    resultMap['probability'] = probability;
    resultMap['confidence_percent'] = (probability * 100);

    final rawAnalysisId = response['analysis_id'];
    final analysisId = rawAnalysisId is num
        ? rawAnalysisId.toInt()
        : (rawAnalysisId != null
            ? int.tryParse(rawAnalysisId.toString())
            : null) ??
        DateTime.now().millisecondsSinceEpoch;

    final rawCowId = sanitizedInput['cowId'];
    final cowId = rawCowId?.toString();

    final rawImagePath = sanitizedInput['imagePath'];
    final imagePath = rawImagePath?.toString();
    
    Uint8List? imageBytes;
    final rawImageBase64 = sanitizedInput['imageBase64'];
    if (rawImageBase64 is String && rawImageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(rawImageBase64);
        print('📸 fromApiResponse - ImageBase64 decodificado: ${imageBytes.length} bytes');
      } catch (e) {
        print('❌ Erro ao decodificar imageBase64: $e');
      }
    }
    
    if (imageBytes == null) {
      imageBytes = _decodeImageBytes(sanitizedInput['imageBytes']);
    }

    return CowPrediction(
      id: analysisId,
      data: sanitizedInput,
      result: resultMap,
      timestamp: DateTime.now(),
      status: 'completed',
      remoteCowId: cowId,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
  }

  String? get cowId => remoteCowId ?? data['cowId']?.toString();

  static Uint8List? _decodeImageBytes(dynamic bytes) {
    if (bytes == null) return null;
    if (bytes is Uint8List) return bytes;
    if (bytes is List) {
      return Uint8List.fromList(List<int>.from(bytes));
    }
    return null;
  }
}
