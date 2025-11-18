import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/cow_provider.dart';
import 'input_fields_section.dart';
import 'image_card.dart';
import 'action_buttons.dart';

class CowInfoCard extends StatelessWidget {
  final Map<TextEditingController, String> controllers;
  final VoidCallback onAnalyze;
  final VoidCallback onReset;
  final Uint8List? selectedImageBytes;
  final String? imagePath;
  final VoidCallback onPickImage;
  final VoidCallback onTakePhoto;
  final VoidCallback onRemoveImage;

  const CowInfoCard({
    super.key,
    required this.controllers,
    required this.onAnalyze,
    required this.onReset,
    required this.selectedImageBytes,
    required this.imagePath,
    required this.onPickImage,
    required this.onTakePhoto,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final cowProvider = Provider.of<CowProvider>(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.network(
                    'https://cdn-icons-png.flaticon.com/512/5371/5371097.png', // Vaca alternativa
                    width: 24,
                    height: 24,
                    
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Informações da Vaca',
                    style: GoogleFonts.interTight(
                      color: const Color(0xFF2E7D32),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InputFieldsSection(controllers: controllers),
              const SizedBox(height: 20),
              ImageCard(
                selectedImageBytes: selectedImageBytes,
                imagePath: imagePath,
                onPickImage: onPickImage,
                onTakePhoto: onTakePhoto,
                onRemoveImage: onRemoveImage,
              ),
              const SizedBox(height: 24),
              ActionButtons(
                loading: cowProvider.loading,
                onAnalyze: onAnalyze,
                onReset: onReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
