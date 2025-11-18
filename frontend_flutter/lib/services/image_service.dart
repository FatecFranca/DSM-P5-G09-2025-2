// lib/services/image_service.dart - ATUALIZADO PARA WEB
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        return bytes;
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao capturar imagem: $e');
    }
  }

  static Future<Uint8List?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        return bytes;
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  static Future<List<Uint8List>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      final List<Uint8List> bytesList = [];
      for (final image in images) {
        final bytes = await image.readAsBytes();
        bytesList.add(bytes);
      }
      return bytesList;
    } catch (e) {
      throw Exception('Erro ao selecionar múltiplas imagens: $e');
    }
  }
}