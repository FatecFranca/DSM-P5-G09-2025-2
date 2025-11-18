// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  static const String baseUrl = 'http://localhost:5000';

  // Predição de parto (original)
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
    } else {
      throw Exception('Erro ao buscar predição: ${response.statusCode}');
    }
  }

  // Nova predição de prenhez
  static Future<Map<String, dynamic>> predictPregnancy(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/predict');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro na predição de prenhez: ${response.statusCode}');
    }
  }

  // Upload de imagem
  static Future<Map<String, dynamic>> uploadImage(File image) async {
    final url = Uri.parse('$baseUrl/upload-image');
    
    var request = http.MultipartRequest('POST', url);
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        image.path,
      ),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseData);
    } else {
      throw Exception('Erro no upload da imagem: ${response.statusCode}');
    }
  }

  // GET para histórico (exemplo)
  static Future<List<dynamic>> getCowHistory(int cowId) async {
    final url = Uri.parse('$baseUrl/cows/$cowId/history');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar histórico: ${response.statusCode}');
    }
  }
}