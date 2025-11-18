// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/cow_data.dart';
import '../services/api_service.dart';
import '../widgets/result_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController cowController = TextEditingController();
  final TextEditingController lactationController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  Map<String, dynamic>? result;
  bool loading = false;

  void submit() async {
    setState(() {
      loading = true;
    });

    final cowData = CowData(
      cow: int.tryParse(cowController.text) ?? 0,
      lactationNumber: int.tryParse(lactationController.text) ?? 0,
      time: timeController.text,
      date: dateController.text,
    );

    try {
      final res = await ApiService.predictParto(cowData.toJson());
      setState(() {
        result = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Predição de Parto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: cowController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Número da vaca'),
            ),
            TextField(
              controller: lactationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Número da lactação'),
            ),
            TextField(
              controller: timeController,
              decoration: InputDecoration(labelText: 'Hora (ex: 08:00:00)'),
            ),
            TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Data (YYYY-MM-DD)'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : submit,
              child: Text(loading ? 'Carregando...' : 'Prever Parto'),
            ),
            SizedBox(height: 16),
            if (result != null) ResultCard(result: result!),
          ],
        ),
      ),
    );
  }
}
