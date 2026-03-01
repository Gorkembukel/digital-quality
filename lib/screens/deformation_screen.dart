import 'dart:math';

import 'package:dashbord/charts/i_chart_painter.dart';
import 'package:dashbord/models/enums.dart';
import 'package:dashbord/util/constant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/parameter.dart';

class DeformationScreen extends StatefulWidget {
  const DeformationScreen({super.key});

  @override
  State<DeformationScreen> createState() => _DeformationScreenState();
}

class _DeformationScreenState extends State<DeformationScreen> {
  final Map<String, TextEditingController> _controllers = {
    'uk1': TextEditingController(),
    'uk2': TextEditingController(),
    'm1': TextEditingController(),
    'm2': TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInputCard(provider),
              const SizedBox(height: 16),
              _buildParameterGrid(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputCard(AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📐 Deformasyon Ölçümü Gir — 60×120 cm Karo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInputField('Uzun Kenar 1', 'uk1'),
                _buildInputField('Uzun Kenar 2', 'uk2'),
                _buildInputField('Merkez 1', 'm1'),
                _buildInputField('Merkez 2', 'm2'),
                _buildSubmitButton(provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String key) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: '$label (mm)',
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildSubmitButton(AppProvider provider) {
    return ElevatedButton(
      onPressed: () {
        for (final entry in _controllers.entries) {
          final value = double.tryParse(entry.value.text);
          if (value != null) {
            provider.processMeasurement(entry.key, value);
            entry.value.clear();
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.vitraRed,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      child: const Text('✓ EKLE'),
    );
  }

  Widget _buildParameterGrid(AppProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: ['uk1', 'uk2', 'm1', 'm2'].map((key) {
        final param = provider.parameters[key];
        if (param == null) return const SizedBox.shrink();
        return _buildParameterCard(param);
      }).toList(),
    );
  }

  Widget _buildParameterCard(Parameter param) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(param),
            const SizedBox(height: 8),
            Expanded(
              child: _buildParameterChart(param),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Parameter param) {
    final cpk = param.cpk;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          param.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getCpkColor(param.cpkStatus),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Cpk ${cpk != null ? cpk.cpk.toStringAsFixed(2) : '—'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (param.lastValue != null)
              Text(
                '${param.lastValue!.toStringAsFixed(3)} mm',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildParameterChart(Parameter param) {
    final spc = param.spc;
    if (spc == null || param.data.isEmpty) {
      return const Center(
        child: Text(
          'Veri yok',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      );
    }

    final values = param.data.map((m) => m.value).toList();
    final maxValue = values.reduce(max);
    final minValue = values.reduce(min);
    final range = maxValue - minValue;
    final padding = range * 0.1;

    return CustomPaint(
      painter: IChartPainter(
        values: values,
        mean: spc.mean,
        ucl: spc.ucl,
        lcl: spc.lcl,
        usl: param.usl,
        lsl: param.lsl,
        minY: minValue - padding,
        maxY: maxValue + padding,
        color: param.color,
      ),
    );
  }

  Color _getCpkColor(StatusType status) {
    switch (status) {
      case StatusType.ok:
        return Colors.green;
      case StatusType.warn:
        return Colors.orange;
      case StatusType.danger:
        return Colors.red;
    }
  }
}