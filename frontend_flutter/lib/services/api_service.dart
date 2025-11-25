import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final String baseUrl = AppConfig.apiBaseUrl;
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>> predictParto(
    Map<String, dynamic> dados,
  ) async {
    final url = Uri.parse('$baseUrl/predict');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Erro ao buscar predição: ${response.statusCode}. Corpo: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> predictPregnancy(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/predict');
    final response = await http.post(
      url,
      headers: defaultHeaders,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Erro na predição de prenhez: ${response.statusCode}. Corpo: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> uploadImage(File image) async {
    final url = Uri.parse('$baseUrl/upload-image');

    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseData);
    }
    throw Exception(
      'Erro no upload da imagem: ${response.statusCode}. Corpo: $responseData',
    );
  }

  static Future<List<dynamic>> getCowHistory(int cowId) async {
    final url = Uri.parse('$baseUrl/cows/$cowId/history');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Erro ao buscar histórico: ${response.statusCode}. Corpo: ${response.body}',
    );
  }

  static Future<List<Map<String, dynamic>>> fetchAnalyses({
    String? cowId,
    String? status,
    int? limit,
    int? offset,
  }) async {
    final queryParameters = <String, String>{};
    if (cowId != null && cowId.isNotEmpty) {
      queryParameters['cow_id'] = cowId;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }
    if (offset != null) {
      queryParameters['offset'] = offset.toString();
    }

    final primary = _buildUri('/analises', queryParameters);
    final response = await http.get(primary);
    if (response.statusCode == 200) {
      return _decodeAnalysesResponse(response.body);
    }

    if (response.statusCode == 404) {
      final fallback = await http.get(_buildUri('/predict', queryParameters));
      if (fallback.statusCode == 200) {
        return _decodeAnalysesResponse(fallback.body);
      }
    }

    throw Exception(
      'Erro ao listar análises: ${response.statusCode}. Corpo: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> fetchAnalysis(int id) async {
    final response = await http.get(_buildUri('/analises/$id'));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    if (response.statusCode == 404) {
      final fallback = await http.get(_buildUri('/predict/$id'));
      if (fallback.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(fallback.body));
      }
    }

    throw Exception(
      'Erro ao buscar análise $id: ${response.statusCode}. Corpo: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> updateAnalysis(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      _buildUri('/analises/$id'),
      headers: defaultHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    if (response.statusCode == 404) {
      final fallback = await http.put(
        _buildUri('/predict/$id'),
        headers: defaultHeaders,
        body: jsonEncode(body),
      );
      if (fallback.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(fallback.body));
      }
    }

    throw Exception(
      'Erro ao atualizar análise $id: ${response.statusCode}. Corpo: ${response.body}',
    );
  }

  static Future<void> deleteAnalysis(int id) async {
    final response = await http.delete(_buildUri('/analises/$id'));
    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 404) {
      final fallback = await http.delete(_buildUri('/predict/$id'));
      if (fallback.statusCode == 200) {
        return;
      }
    }

    throw Exception(
      'Erro ao remover análise $id: ${response.statusCode}. Corpo: ${response.body}',
    );
  }

  static Future<void> deleteAllAnalyses() async {
    final response = await http.delete(_buildUri('/analises'));
    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 404) {
      final fallback = await http.delete(_buildUri('/predict'));
      if (fallback.statusCode == 200) {
        return;
      }
    }

    throw Exception(
      'Erro ao limpar análises: ${response.statusCode}. Corpo: ${response.body}',
    );
  }

  static Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParameters);
  }

  static List<Map<String, dynamic>> _decodeAnalysesResponse(String body) {
    final decoded = jsonDecode(body);

    if (decoded is Map && decoded.containsKey('data')) {
      final data = decoded['data'];
      if (data is List) {
        return data
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();
      }
    }

    if (decoded is List) {
      return decoded
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    }

    throw Exception('Formato inesperado ao processar análises');
  }
}
