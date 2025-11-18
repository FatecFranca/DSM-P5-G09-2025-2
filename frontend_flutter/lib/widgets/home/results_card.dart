import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/cow_data.dart';

class ResultsCard extends StatelessWidget {
  final CowPrediction prediction;
  final VoidCallback? onNewAnalysis;

  const ResultsCard({super.key, required this.prediction, this.onNewAnalysis});

  Widget _buildRecommendationCard(bool isPregnant) {
    String recomendacao = isPregnant
        ? '✅ Prenhez confirmada! Continue o monitoramento regular e mantenha a nutrição ideal.\n\n📅 Agende uma verificação veterinária para confirmar e acompanhar o desenvolvimento.\n\n🍎 Mantenha dieta balanceada e verifique condições de manejo.'
        : '🔍 Prenhez não detectada. Considere repetir a inseminação e verificar a saúde geral do animal.\n\n💊 Avalie condições nutricionais e sanitárias.\n\n📊 Monitore os sinais de cio para nova tentativa.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isPregnant ? const Color(0xFFE8F5E8) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPregnant ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: isPregnant ? Colors.green[800] : Colors.red[800],
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recomendações',
                  style: GoogleFonts.interTight(
                    color: isPregnant
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recomendacao,
              style: GoogleFonts.inter(
                color: isPregnant
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultado = prediction.result['prenhez'] ?? 'N/A';
    final isPregnant = resultado == 'SIM';
    final confidenceValue = (prediction.result['confidence_percent'] ?? 0.0)
        .toDouble();
    final confidence = confidenceValue.toStringAsFixed(1);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resultado da Análise',
                    style: GoogleFonts.interTight(
                      color: const Color(0xFF2E7D32),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
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
                      'Confiança: $confidence%',
                      style: GoogleFonts.inter(
                        color: isPregnant ? Colors.green[800] : Colors.red[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPregnant
                        ? [Colors.green[50]!, Colors.lightGreen[50]!]
                        : [Colors.red[50]!, Colors.orange[50]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPregnant ? Colors.green[200]! : Colors.red[200]!,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isPregnant
                              ? Colors.green[100]
                              : Colors.red[100],
                          shape: BoxShape.circle,
                        ),
                        child: isPregnant
                            ? Image.network(
                                'https://cdn-icons-png.flaticon.com/512/1998/1998610.png', // Vaca grávida
                                width:40, // Ajuste o tamanho conforme necessário
                                height: 40,
                              // Ou a cor que você quiser
                              )
                            : Image.network(
                                'https://cdn-icons-png.flaticon.com/512/4661/4661589.png', // Vaca não grávida
                                width: 40,
                                height: 40,
                               // Ou a cor que você quiser
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPregnant
                            ? 'Prenhez Detectada!'
                            : 'Prenhez Não Detectada',
                        style: GoogleFonts.inter(
                          color: isPregnant
                              ? Colors.green[800]
                              : Colors.red[800],
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resultado,
                        style: GoogleFonts.interTight(
                          color: isPregnant ? Colors.green : Colors.red,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confiança do modelo: $confidence%',
                        style: GoogleFonts.inter(
                          color: isPregnant
                              ? Colors.green[600]
                              : Colors.red[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildRecommendationCard(isPregnant),
              if (onNewAnalysis != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onNewAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Nova Análise',
                          style: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
