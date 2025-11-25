import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../providers/cow_provider.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';
import '../widgets/home/intro_card.dart';
import '../widgets/home/cow_info_card.dart';
import '../widgets/home/results_card.dart';
import '../widgets/home/validation_error_card.dart';
import '../widgets/home/error_card.dart';
import '../widgets/shared/custom_dialogs.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final Map<TextEditingController, String> controllers = {
    TextEditingController(): 'Idade (anos)',
    TextEditingController(): 'Peso (kg)',
    TextEditingController(): 'Gestações Anteriores',
    TextEditingController(): 'Condição Corporal (1-5)',
    TextEditingController(): 'Dias desde a Inseminação',
    TextEditingController(): 'Produção de Leite (L/dia)',
    TextEditingController(): 'Temperatura (°C)',
  };

  Uint8List? _selectedImageBytes;
  String? _imagePath;
  String? _validationError;
  bool _showingValidationDialog = false; // ✅ NOVO: Controlar estado do diálogo

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.initialize();
  }

  @override
  void dispose() {
    for (var controller in controllers.keys) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final Uint8List? imageBytes = await ImageService.pickImageFromGallery();
      if (imageBytes != null) {
        setState(() {
          _selectedImageBytes = imageBytes;
          _imagePath = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final Uint8List? imageBytes = await ImageService.pickImageFromCamera();
      if (imageBytes != null) {
        setState(() {
          _selectedImageBytes = imageBytes;
          _imagePath = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
      }
    } catch (e) {
      _showError('Erro ao capturar foto: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _imagePath = null;
    });
  }

  bool _validateFields() {
    setState(() {
      _validationError = null;
    });

    // Verificar campos vazios
    for (var entry in controllers.entries) {
      if (entry.key.text.isEmpty) {
        _showValidationPopup(
          'Campo Obrigatório',
          'O campo "${entry.value}" é obrigatório.',
        );
        return false;
      }
    }

    // Converter e validar cada campo
    final age = double.tryParse(controllers.keys.elementAt(0).text);
    final weight = double.tryParse(controllers.keys.elementAt(1).text);
    final pregnancies = int.tryParse(controllers.keys.elementAt(2).text);
    final bodyCondition = double.tryParse(controllers.keys.elementAt(3).text);
    final daysSinceInsemination = int.tryParse(
      controllers.keys.elementAt(4).text,
    );
    final milkProduction = double.tryParse(controllers.keys.elementAt(5).text);
    final temperature = double.tryParse(controllers.keys.elementAt(6).text);

    // Validar conversões numéricas
    if (age == null) {
      _showValidationPopup(
        'Valor Inválido',
        'Idade deve ser um número válido (ex: 3.5)',
      );
      return false;
    }

    if (weight == null) {
      _showValidationPopup(
        'Valor Inválido',
        'Peso deve ser um número válido (ex: 450)',
      );
      return false;
    }

    if (pregnancies == null) {
      _showValidationPopup(
        'Valor Inválido',
        'Número de gestações deve ser um número inteiro (ex: 2)',
      );
      return false;
    }

    if (bodyCondition == null) {
      _showValidationPopup(
        'Valor Inválido',
        'Condição corporal deve ser um número válido (ex: 3.5)',
      );
      return false;
    }

    if (daysSinceInsemination == null) {
      _showValidationPopup(
        'Valor Inválido',
        'Dias desde inseminação deve ser um número inteiro (ex: 45)',
      );
      return false;
    }

    if (milkProduction == null) {
      _showValidationPopup(
        'Valor Inválido',
        'Produção de leite deve ser um número válido (ex: 25)',
      );
      return false;
    }

    if (temperature == null) {
      _showValidationPopup(
        'Valor Inválido',
        'Temperatura deve ser um número válido (ex: 38.5)',
      );
      return false;
    }

    // Validar faixas de valores
    if (age < 1 || age > 15) {
      _showValidationPopup(
        'Idade Inválida',
        'A idade deve estar entre 1 e 15 anos.\n\nValor informado: $age anos',
      );
      return false;
    }

    if (weight < 100 || weight > 1000) {
      _showValidationPopup(
        'Peso Inválido',
        'O peso deve estar entre 100 e 1000 kg.\n\nValor informado: $weight kg',
      );
      return false;
    }

    if (pregnancies < 0 || pregnancies > 20) {
      _showValidationPopup(
        'Gestações Inválidas',
        'O número de gestações deve estar entre 0 e 20.\n\nValor informado: $pregnancies',
      );
      return false;
    }

    if (bodyCondition < 1 || bodyCondition > 5) {
      _showValidationPopup(
        'Condição Corporal Inválida',
        'A condição corporal deve estar entre 1 (magra) e 5 (gorda).\n\nValor informado: $bodyCondition',
      );
      return false;
    }

    if (daysSinceInsemination < 0 || daysSinceInsemination > 300) {
      _showValidationPopup(
        'Dias Inválidos',
        'Os dias desde inseminação devem estar entre 0 e 300.\n\nValor informado: $daysSinceInsemination dias',
      );
      return false;
    }

    if (milkProduction < 0 || milkProduction > 60) {
      _showValidationPopup(
        'Produção de Leite Inválida',
        'A produção de leite deve estar entre 0 e 60 L/dia.\n\nValor informado: $milkProduction L/dia',
      );
      return false;
    }

    if (temperature < 35 || temperature > 42) {
      _showValidationPopup(
        'Temperatura Inválida',
        'A temperatura deve estar entre 35°C e 42°C.\n\nValor informado: $temperature°C',
      );
      return false;
    }

    return true;
  }

  void _showValidationPopup(String title, String message) {
    setState(() {
      _showingValidationDialog = true; // ✅ Marcar que está mostrando diálogo
    });

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
                style: TextStyle(
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
                style: TextStyle(color: Colors.grey[700], height: 1.5),
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
                        style: TextStyle(
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
                setState(() {
                  _showingValidationDialog = false; // ✅ Resetar estado
                });
                _focusOnProblematicField(title);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'CORRIGIR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _showingValidationDialog =
            false; // ✅ Garantir reset se diálogo for fechado de outra forma
      });
    });
  }

  void _focusOnProblematicField(String title) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (title.contains('Idade')) {
        _selectText(controllers.keys.elementAt(0));
      } else if (title.contains('Peso')) {
        _selectText(controllers.keys.elementAt(1));
      } else if (title.contains('Gestação')) {
        _selectText(controllers.keys.elementAt(2));
      } else if (title.contains('Condição')) {
        _selectText(controllers.keys.elementAt(3));
      } else if (title.contains('Dias')) {
        _selectText(controllers.keys.elementAt(4));
      } else if (title.contains('Leite')) {
        _selectText(controllers.keys.elementAt(5));
      } else if (title.contains('Temperatura')) {
        _selectText(controllers.keys.elementAt(6));
      }
    });
  }

  void _selectText(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> analyzeChances() async {
    if (_showingValidationDialog) {
      return; // ✅ Prevenir múltiplos cliques durante validação
    }

    FocusScope.of(context).unfocus();

    if (!_validateFields()) {
      print('❌ Validação falhou');
      return;
    }

    print('✅ Validação passou, preparando dados...');
    final cowProvider = Provider.of<CowProvider>(context, listen: false);

    String? imageBase64;
    if (_selectedImageBytes != null) {
      final maxSize = 500 * 1024;
      if (_selectedImageBytes!.lengthInBytes <= maxSize) {
        imageBase64 = base64Encode(_selectedImageBytes!);
        print('📸 Imagem convertida para base64: ${imageBase64.length} caracteres (${_selectedImageBytes!.lengthInBytes} bytes)');
      } else {
        print('⚠️ Imagem muito grande (${_selectedImageBytes!.lengthInBytes} bytes > ${maxSize} bytes), não será enviada');
        _showError('Imagem muito grande. Por favor, use uma imagem menor que 500KB.');
      }
    }

    final Map<String, dynamic> requestData = {
      'age': double.parse(controllers.keys.elementAt(0).text),
      'weight': double.parse(controllers.keys.elementAt(1).text),
      'previous_pregnancies': int.parse(controllers.keys.elementAt(2).text),
      'body_condition': double.parse(controllers.keys.elementAt(3).text),
      'days_since_insemination': int.parse(controllers.keys.elementAt(4).text),
      'milk_production': double.parse(controllers.keys.elementAt(5).text),
      'body_temperature': double.parse(controllers.keys.elementAt(6).text),
      'imagePath': _imagePath,
      'imageBase64': imageBase64,
      'cowId': DateTime.now().millisecondsSinceEpoch,
    };
    
    print('📸 Enviando dados - ImageBase64: ${imageBase64 != null}');
    print('📁 Caminho da imagem: $_imagePath');
    try {
      await cowProvider.predictPregnancy(requestData);

      if (cowProvider.predictions.isNotEmpty) {
        final resultado =
            cowProvider.predictions.first.result['prenhez'] ?? 'N/A';
        final isPregnant = resultado == 'SIM';

        await NotificationService.showPredictionNotification(
          'Predição de Prenhez',
          'Resultado: $resultado',
          isPregnant,
        );

        _showSuccess('Análise concluída com sucesso!');

        setState(() {});
      } else {
        _showError('Nenhum resultado recebido da API');
      }
    } catch (e) {
      _showError('Erro na predição: $e');
      print('Erro detalhado: $e');
    }
  }

  void resetForm() {
    for (var controller in controllers.keys) {
      controller.clear();
    }

    setState(() {
      _selectedImageBytes = null;
      _imagePath = null;
      _validationError = null;
    });

    final cowProvider = Provider.of<CowProvider>(context, listen: false);
    cowProvider.clearError();

    FocusScope.of(context).unfocus();

    _showSuccess('Formulário limpo com sucesso!');
  }

  void _showQuickStats(BuildContext context, CowProvider cowProvider) {
    if (cowProvider.predictions.isEmpty) {
      _showError('Nenhuma análise realizada ainda');
      return;
    }

    CustomDialogs.showQuickStats(context, cowProvider);
  }

  void _showInfoDialog(BuildContext context) {
    CustomDialogs.showInfoDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CowProvider>(
      builder: (context, cowProvider, child) {
        // ✅ CORREÇÃO: Garantir que sempre retorne um Scaffold válido
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.green,
            automaticallyImplyLeading: false,
            title: const _AppBarTitle(),
            actions: [
              if (cowProvider.predictions.isNotEmpty)
                IconButton(
                  onPressed: () => _showQuickStats(context, cowProvider),
                  icon: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              IconButton(
                onPressed: () => _showInfoDialog(context),
                icon: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
            elevation: 0,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Column(
                  children: _buildContent(
                    cowProvider,
                  ), // ✅ Método separado para construir conteúdo
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ NOVO: Método separado para construir o conteúdo
  List<Widget> _buildContent(CowProvider cowProvider) {
    final List<Widget> content = [
      const SizedBox(height: 20),
      const IntroCard(),
      const SizedBox(height: 16),
      CowInfoCard(
        controllers: controllers,
        onAnalyze: analyzeChances,
        onReset: resetForm,
        selectedImageBytes: _selectedImageBytes,
        imagePath: _imagePath,
        onPickImage: _pickImage,
        onTakePhoto: _takePhoto,
        onRemoveImage: _removeImage,
      ),
    ];

    // Adicionar widgets condicionais
    if (_validationError != null) {
      content.addAll([
        const SizedBox(height: 16),
        ValidationErrorCard(error: _validationError!),
      ]);
    }

    if (cowProvider.predictions.isNotEmpty) {
      content.addAll([
        const SizedBox(height: 16),
        ResultsCard(
          prediction: cowProvider.predictions.first,
          onNewAnalysis: resetForm,
        ),
      ]);
    }

    if (cowProvider.error != null) {
      content.addAll([
        const SizedBox(height: 16),
        ErrorCard(error: cowProvider.error!),
      ]);
    }

    content.add(const SizedBox(height: 20));

    return content;
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Image.network(
          'https://cdn-icons-png.flaticon.com/512/9287/9287260.png',
          width: 28,
          height: 28,
          
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.pets, color: Colors.white, size: 28); // Fallback
          },
        ),
        const SizedBox(width: 12),
        Text(
          'AgroTech AI Predictor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
