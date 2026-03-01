import 'dart:math';

import 'package:dashbord/cards/alarm_tile.dart';
import 'package:dashbord/cards/kpi_card.dart';
import 'package:dashbord/charts/i_chart_painter.dart';
import 'package:dashbord/charts/multi_line_chart_painter.dart';
import 'package:dashbord/models/parameter.dart';
import 'package:dashbord/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKpiRow(provider),
              const SizedBox(height: 16),
              _buildMainCharts(provider),
              const SizedBox(height: 16),
              _buildDeformationChart(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiRow(AppProvider provider) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['nem', 'uk1', 'uk2', 'm1', 'm2']
            .map((key) {
              final param = provider.parameters[key];
              if (param == null) return const SizedBox.shrink();
              return KpiCard(
                parameter: param,
                onTap: () {
                  // Navigate to detail
                },
              );
            })
            .toList(),
      ),
    );
  }

  Widget _buildMainCharts(AppProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildNemChart(provider),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildRecentAlarms(provider),
        ),
      ],
    );
  }

  Widget _buildNemChart(AppProvider provider) {
    final nemParam = provider.parameters['nem'];
    if (nemParam == null) return const SizedBox.shrink();

    final spc = nemParam.spc;
    if (spc == null || nemParam.data.isEmpty) {
      return _buildEmptyChart('Nem verisi yok');
    }

    final values = nemParam.data.map((m) => m.value).toList();
    final maxValue = values.reduce(max);
    final minValue = values.reduce(min);
    final range = maxValue - minValue;
    final padding = range * 0.1;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💧 Nem Kontrol Kartı',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: IChartPainter(
                  values: values,
                  mean: spc.mean,
                  ucl: spc.ucl,
                  lcl: spc.lcl,
                  usl: nemParam.usl,
                  lsl: nemParam.lsl,
                  minY: minValue - padding,
                  maxY: maxValue + padding,
                  color: nemParam.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlarms(AppProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔔 Son Alarmlar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${provider.alarms.length} kayıt',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: provider.alarms.length > 3 ? 3 : provider.alarms.length,
                itemBuilder: (context, index) {
                  final alarm = provider.alarms[index];
                  return AlarmTile(
                    alarm: alarm,
                    provider: provider,
                    showResponseButton: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeformationChart(AppProvider provider) {
    final params = ['uk1', 'uk2', 'm1', 'm2']
        .map((key) => provider.parameters[key])
        .whereType<Parameter>()
        .toList();

    if (params.isEmpty || params.any((p) => p.data.isEmpty)) {
      return _buildEmptyChart('Deformasyon verisi yok');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📐 Deformasyon — 4 Parametre',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'VitrA Tol: +1.0 / −0.7 mm | 60×120 cm',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: CustomPaint(
                painter: MultiLineChartPainter(
                  parameters: params,
                  usl: 1.0,
                  lsl: -0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Card(
      elevation: 2,
      child: SizedBox(
        height: 140,
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}