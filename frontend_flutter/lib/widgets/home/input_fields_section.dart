import 'package:flutter/material.dart';
import '../shared/custom_input_field.dart';

class InputFieldsSection extends StatelessWidget {
  final Map<TextEditingController, String> controllers;

  const InputFieldsSection({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomInputField(
                controller: controllers.keys.first,
                label: 'Idade (anos)',
                hint: 'ex: 3.5',
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomInputField(
                controller: controllers.keys.elementAt(1),
                label: 'Peso (kg)',
                hint: 'ex: 450',
                icon: Icons.monitor_weight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomInputField(
                controller: controllers.keys.elementAt(2),
                label: 'Gestações Anteriores',
                hint: 'ex: 2',
                icon: Icons.child_care,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomInputField(
                controller: controllers.keys.elementAt(3),
                label: 'Condição Corporal (1-5)',
                hint: 'ex: 3.5',
                icon: Icons.health_and_safety,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomInputField(
          controller: controllers.keys.elementAt(4),
          label: 'Dias desde a Inseminação',
          hint: 'ex: 45',
          icon: Icons.event,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomInputField(
                controller: controllers.keys.elementAt(5),
                label: 'Produção de Leite (L/dia)',
                hint: 'ex: 25',
                icon: Icons.local_drink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomInputField(
                controller: controllers.keys.elementAt(6),
                label: 'Temperatura (°C)',
                hint: 'ex: 38.5',
                icon: Icons.thermostat,
              ),
            ),
          ],
        ),
      ],
    );
  }
}