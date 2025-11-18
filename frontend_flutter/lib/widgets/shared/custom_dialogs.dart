import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/cow_provider.dart';
import '../stat_item.dart';
class CustomDialogs {
  static void showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Como usar o App',
                        style: GoogleFonts.interTight(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoItem(
                    '📝',
                    'Preencha todos os campos com informações precisas da vaca',
                  ),
                  _buildInfoItem('🎯', 'Idade: 1-15 anos | Peso: 100-1000 kg'),
                  _buildInfoItem(
                    '🔢',
                    'Condição corporal: escala de 1 (magra) a 5 (gorda)',
                  ),
                  _buildInfoItem('📅', 'Dias desde inseminação: 0-300 dias'),
                  _buildInfoItem('🥛', 'Produção de leite: 0-60 L/dia'),
                  _buildInfoItem('🌡️', 'Temperatura: 35°C - 42°C'),
                  _buildInfoItem(
                    '📸',
                    'Foto opcional para identificação do animal',
                  ),
                  _buildInfoItem('💾', 'Histórico salvo automaticamente'),
                  _buildInfoItem(
                    '🔔',
                    'Notificações para resultados importantes',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dicas para melhores resultados:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Meça a temperatura sempre no mesmo horário\n'
                    '• Use balança calibrada para o peso\n'
                    '• Registre dados consistentemente\n'
                    '• Consulte o veterinário para confirmação',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Entendi',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showQuickStats(BuildContext context, CowProvider cowProvider) {
    final totalPredictions = cowProvider.predictions.length;
    final pregnantCount = cowProvider.predictions
        .where((p) => p.result['prenhez'] == 'SIM')
        .length;
    final successRate = totalPredictions > 0
        ? (pregnantCount / totalPredictions * 100)
        : 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Estatísticas Rápidas',
                style: GoogleFonts.interTight(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 20),
              StatItem(
                label: 'Total de Análises',
                value: totalPredictions.toString(),
                icon: Icons.assessment,
              ),
              StatItem(
                label: 'Prenhezes Detectadas',
                value: pregnantCount.toString(),
                icon: Icons.monitor_heart,
              ),
              StatItem(
                label: 'Taxa de Sucesso',
                value: '${successRate.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showValidationPopup({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onCorrect,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[800], size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.interTight(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.inter(color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.orange[800], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Corrija o valor para continuar',
                        style: GoogleFonts.inter(
                          color: Colors.orange[800],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCorrect();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'CORRIGIR',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(color: Colors.grey[700], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
