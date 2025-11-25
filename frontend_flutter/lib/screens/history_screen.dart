// lib/screens/history_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/cow_provider.dart';
import '../models/cow_data.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHistory(context, showLoader: true);
    });
  }

  Future<void> _refreshHistory(BuildContext context,
      {bool showLoader = false}) async {
    final provider = Provider.of<CowProvider>(context, listen: false);
    await provider.refreshHistory(showLoader: showLoader);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Histórico de Predições',
          style: GoogleFonts.interTight(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CowProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.historyLoading
                    ? null
                    : () => _refreshHistory(context, showLoader: true),
              );
            },
          ),
          Consumer<CowProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: provider.historyLoading
                    ? null
                    : () => _showClearHistoryDialog(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<CowProvider>(
        builder: (context, provider, child) {
          if (provider.historyLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!, context);
          }

          if (provider.predictions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: Colors.green,
            onRefresh: () => _refreshHistory(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.predictions.length,
              itemBuilder: (context, index) {
                final prediction = provider.predictions[index];
                return _buildPredictionCard(prediction, context, index);
              },
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // SEÇÃO: TELA VAZIA / ERRO
  // -------------------------------------------------------------
  Widget _buildErrorState(String message, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar o histórico',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _refreshHistory(context, showLoader: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma predição realizada',
            style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'As predições aparecerão aqui',
            style: GoogleFonts.inter(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD DO HISTÓRICO (COMPLETO COM DADOS E IMAGEM)
  // -------------------------------------------------------------
  Widget _buildPredictionCard(
    CowPrediction prediction,
    BuildContext context,
    int index,
  ) {
    final isPregnant = prediction.result['prenhez'] == 'SIM';
    final confidence = prediction.confidencePercent.toStringAsFixed(1);
    final hasImage = prediction.hasImage;
    final imageBytes = prediction.imageBytes;
    final imagePath = prediction.imagePath;
    final statusLabel = prediction.status.toUpperCase();

    print('🖼️ History - Predição $index - Tem imagem: $hasImage');
    print('🖼️ History - Bytes: ${imageBytes != null}');
    print('🖼️ History - Path: $imagePath');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + Ícone
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise #${index + 1}',
                      style: GoogleFonts.interTight(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPregnant ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPregnant ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    '$confidence%',
                    style: GoogleFonts.inter(
                      color: isPregnant ? Colors.green[800] : Colors.red[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              'Data: ${_formatDate(prediction.timestamp)}',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),

            const SizedBox(height: 12),

            // ✅ IMAGEM DA VACA (SE EXISTIR)
            if (hasImage) ...[
              _buildImagePreview(prediction),
              const SizedBox(height: 12),
            ],

            // RESULTADO PRINCIPAL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPregnant ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPregnant ? Colors.green[100]! : Colors.red[100]!,
                ),
              ),
              child: Row(
                children: [
                  isPregnant
                      ? Image.network(
                          'https://cdn-icons-png.flaticon.com/512/2913/2913469.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            );
                          },
                        )
                      : Icon(Icons.not_interested, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPregnant
                              ? 'Prenhez Detectada'
                              : 'Prenhez Não Detectada',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isPregnant
                                ? Colors.green[800]
                                : Colors.red[800],
                          ),
                        ),
                        Text(
                          'Confiança: $confidence%',
                          style: GoogleFonts.inter(
                            color: isPregnant
                                ? Colors.green[600]
                                : Colors.red[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    prediction.result['prenhez'] ?? 'N/A',
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPregnant ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // DADOS RESUMIDOS
            _buildDataSummary(prediction.inputData),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showPredictionDetails(prediction, context),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Ver Detalhes Completos'),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // PREVIEW DA IMAGEM (COMPATÍVEL COM WEB E MOBILE)
  // -------------------------------------------------------------
  Widget _buildImagePreview(CowPrediction prediction) {
    if (!prediction.hasImage) {
      return _buildImagePlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto da Vaca:',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImageContent(prediction), // ✅ Método unificado
          ),
        ),
      ],
    );
  }

  // ✅ NOVO: Método unificado para construir imagem
  Widget _buildImageContent(CowPrediction prediction) {
    // Prioridade 1: imageBytes (funciona em web e mobile)
    if (prediction.imageBytes != null) {
      return Image.memory(
        prediction.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }

    // Prioridade 2: imagePath (apenas mobile)
    if (prediction.imagePath != null && !kIsWeb) {
      try {
        final file = File(prediction.imagePath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Erro ao carregar imagem do arquivo: $error');
              return _buildImagePlaceholder();
            },
          );
        } else {
          print('⚠️ Arquivo de imagem não encontrado: ${prediction.imagePath}');
          print('📸 ImagePath existe mas arquivo não está mais disponível');
        }
      } catch (e) {
        print('❌ Erro ao carregar imagem do arquivo: $e');
        print('📸 ImagePath: ${prediction.imagePath}');
      }
    } else if (prediction.imagePath != null && kIsWeb) {
      print('⚠️ ImagePath disponível mas estamos no Web (não suportado): ${prediction.imagePath}');
    }

    // Fallback
    return _buildImagePlaceholder();
  }

  // Placeholder quando não tem imagem
  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Sem foto',
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // RESUMO DOS DADOS
  // -------------------------------------------------------------
  Widget _buildDataSummary(Map<String, dynamic> inputData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados Inseridos:',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildDataChip('Idade: ${inputData['age']} anos'),
              _buildDataChip('Peso: ${inputData['weight']} kg'),
              _buildDataChip('Gestações: ${inputData['previous_pregnancies']}'),
              _buildDataChip('Condição: ${inputData['body_condition']}'),
              _buildDataChip('Dias: ${inputData['days_since_insemination']}'),
              _buildDataChip('Leite: ${inputData['milk_production']}L'),
              _buildDataChip('Temp: ${inputData['body_temperature']}°C'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.blue[800]),
      ),
    );
  }

  // -------------------------------------------------------------
  // FORMATAÇÃO DA DATA
  // -------------------------------------------------------------
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // -------------------------------------------------------------
  // DIALOG DE DETALHES COMPLETOS
  // -------------------------------------------------------------
  void _showPredictionDetails(CowPrediction prediction, BuildContext context) {
    final isPregnant = prediction.result['prenhez'] == 'SIM';
    final confidence = prediction.confidencePercent.toStringAsFixed(1);
    final hasImage =
        prediction.imagePath != null || prediction.imageBytes != null;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    isPregnant
                        ? Image.network(
                            'https://cdn-icons-png.flaticon.com/512/2913/2913469.png',
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 28,
                              );
                            },
                          )
                        : Icon(
                            Icons.not_interested,
                            color: Colors.red,
                            size: 28,
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detalhes da Análise',
                        style: GoogleFonts.interTight(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ IMAGEM (SE EXISTIR)
                if (hasImage) ...[
                  Text(
                    'Foto da Vaca:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageContent(
                        prediction,
                      ), // ✅ Método unificado
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // DADOS COMPLETOS
                _buildDetailSection('Dados da Vaca', [
                  _buildDetailRow(
                    'Idade',
                    '${prediction.inputData['age']} anos',
                  ),
                  _buildDetailRow(
                    'Peso',
                    '${prediction.inputData['weight']} kg',
                  ),
                  _buildDetailRow(
                    'Gestações anteriores',
                    '${prediction.inputData['previous_pregnancies']}',
                  ),
                  _buildDetailRow(
                    'Condição corporal',
                    '${prediction.inputData['body_condition']}',
                  ),
                  _buildDetailRow(
                    'Dias desde inseminação',
                    '${prediction.inputData['days_since_insemination']}',
                  ),
                  _buildDetailRow(
                    'Produção de leite',
                    '${prediction.inputData['milk_production']} L/dia',
                  ),
                  _buildDetailRow(
                    'Temperatura',
                    '${prediction.inputData['body_temperature']}°C',
                  ),
                ]),

                const SizedBox(height: 20),

                // RESULTADO
                _buildDetailSection('Resultado da Análise', [
                  _buildDetailRow(
                    'Prenhez',
                    prediction.result['prenhez'] ?? 'N/A',
                    isHighlighted: true,
                    highlightColor: isPregnant ? Colors.green : Colors.red,
                  ),
                  _buildDetailRow('Confiança do modelo', '$confidence%'),
                ]),

                const SizedBox(height: 20),

                // RECOMENDAÇÕES
                _buildRecommendationSection(isPregnant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? highlightColor : Colors.grey[800],
                fontSize: isHighlighted ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(bool isPregnant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPregnant ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPregnant ? Colors.green[100]! : Colors.orange[100]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: isPregnant ? Colors.green[800] : Colors.orange[800],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recomendações',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: isPregnant ? Colors.green[800] : Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPregnant
                ? '✅ Prenhez confirmada! Continue o monitoramento regular e mantenha a nutrição ideal.\n\n📅 Agende uma verificação veterinária para confirmar e acompanhar o desenvolvimento.\n\n🍎 Mantenha dieta balanceada e verifique condições de manejo.'
                : '🔍 Prenhez não detectada. Considere repetir a inseminação e verificar a saúde geral do animal.\n\n💊 Avalie condições nutricionais e sanitárias.\n\n📊 Monitore os sinais de cio para nova tentativa.',
            style: GoogleFonts.inter(
              color: isPregnant ? Colors.green[700] : Colors.orange[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG LIMPAR HISTÓRICO
  // -------------------------------------------------------------
  void _showClearHistoryDialog(BuildContext context) {
    final provider = Provider.of<CowProvider>(context, listen: false);

    if (provider.predictions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há histórico para limpar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text(
          'Tem certeza que deseja limpar todo o histórico de predições? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.clearPredictions();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Histórico limpo com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao limpar histórico: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Limpar Tudo',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
