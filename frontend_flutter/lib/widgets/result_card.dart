// lib/widgets/result_card.dart
import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final Map<String, dynamic> result; // O JSON completo do backend

  const ResultCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final confidence = (result['confidence_percent'] ?? 0).toDouble();

    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predição de Parto: ${result['prenhez'] ?? '-'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Confiança: ${confidence.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
