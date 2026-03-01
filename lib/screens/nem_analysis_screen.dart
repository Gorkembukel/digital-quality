import 'dart:math';

import 'package:dashbord/cards/reaction_card.dart';
import 'package:dashbord/charts/i_chart_painter.dart';
import 'package:dashbord/charts/mr_chart_painter.dart';
import 'package:dashbord/models/enums.dart';
import 'package:dashbord/util/constant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/parameter.dart';


class NemAnalysisScreen extends StatefulWidget {
  const NemAnalysisScreen({super.key});

  @override
  State<NemAnalysisScreen> createState() => _NemAnalysisScreenState();
}

class _NemAnalysisScreenState extends State<NemAnalysisScreen> {
  final TextEditingController _nemController = TextEditingController();

  @override
  void dispose() {
    _nemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final nemParam = provider.parameters['nem'];
        if (nemParam == null) {
          return const Center(child: Text('Parametre bulunamadı'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInputCard(provider, nemParam),
              const SizedBox(height: 16),
              _buildIMRCharts(provider, nemParam),
              const SizedBox(height: 16),
              _buildStatisticsAndReaction(provider, nemParam),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputCard(AppProvider provider, Parameter nemParam) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💧 Nem Ölçümü Gir — Spray Dryer Çıkış',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nemController,
                    decoration: InputDecoration(
                      labelText: 'Nem (%rH)',
                      border: const OutlineInputBorder(),
                      helperText: 'Limit: ${nemParam.lsl} - ${nemParam.usl}',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(_nemController.text);
                    if (value != null) {
                      provider.processMeasurement('nem', value);
                      _nemController.clear();
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIMRCharts(AppProvider provider, Parameter nemParam) {
    final spc = nemParam.spc;
    
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bireysel Değer (I) Kartı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: _buildIChart(nemParam),
                  ),
                  if (spc != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'X̄=${spc.mean.toStringAsFixed(3)}  σ̂=${spc.sigE.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hareketli Aralık (MR) Kartı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: _buildMRChart(nemParam),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIChart(Parameter param) {
    final spc = param.spc;
    if (spc == null || param.data.isEmpty) {
      return const Center(child: Text('Yeterli veri yok'));
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

  Widget _buildMRChart(Parameter param) {
    final spc = param.spc;
    if (spc == null || spc.mrs.isEmpty) {
      return const Center(child: Text('Yeterli veri yok'));
    }

    final maxValue = spc.mrs.reduce(max);
    final padding = maxValue * 0.1;

    return CustomPaint(
      painter: MRChartPainter(
        mrs: spc.mrs,
        mrMean: spc.mrMean,
        uclMR: spc.uclMR,
        minY: 0,
        maxY: maxValue + padding,
      ),
    );
  }

  Widget _buildStatisticsAndReaction(AppProvider provider, Parameter nemParam) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İstatistik Özeti',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildStatisticsTable(nemParam),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Anlık Reaksiyon Rehberi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildReactionGuide(provider, nemParam),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTable(Parameter param) {
    final spc = param.spc;
    final cpk = param.cpk;
    
    if (spc == null) {
      return const Text('Yeterli veri yok');
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
      },
      children: [
        _buildStatRow('Ölçüm Sayısı', '${param.data.length}'),
        _buildStatRow('Ortalama (X̄)', '${spc.mean.toStringAsFixed(5)} %rH'),
        _buildStatRow('Set Point', '${param.sp} %rH'),
        _buildStatRow('Std Sapma (σ̂)', '${spc.sigE.toStringAsFixed(5)}'),
        _buildStatRow('UCL (3σ)', '${spc.ucl.toStringAsFixed(4)} %rH'),
        _buildStatRow('LCL (3σ)', '${spc.lcl.toStringAsFixed(4)} %rH'),
        _buildStatRow('UCL(MR)', '${spc.uclMR.toStringAsFixed(4)}'),
        _buildStatRow('Cp', cpk != null ? cpk.cp.toStringAsFixed(3) : '—'),
        _buildStatRow('Cpk', cpk != null ? cpk.cpk.toStringAsFixed(3) : '—'),
        _buildStatRow('Limit Dışı', '${param.outOfSpecCount}'),
      ],
    );
  }

  TableRow _buildStatRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactionGuide(AppProvider provider, Parameter param) {
    if (param.data.isEmpty) {
      return const Text('Henüz ölçüm yok');
    }

    final lastValue = param.lastValue!;
    final violations = param.weViolations;

    if (lastValue < param.lsl) {
      return ReactionCard.danger(
        title: '❌ ALT LİMİT DIŞI (${lastValue.toStringAsFixed(3)} %rH)',
        steps: [
          provider.getBestSuggestion('nem', AlarmType.danger) ?? 
              'Spray sıcaklığını artır',
          '5 dk bekle, ölçümü tekrarla',
          'Düzelmezse vardiya şefini bilgilendir',
        ],
      );
    } else if (lastValue > param.usl) {
      return ReactionCard.danger(
        title: '❌ ÜST LİMİT DIŞI (${lastValue.toStringAsFixed(3)} %rH)',
        steps: [
          'Spray sıcaklığını düşür',
          '5 dk bekle, ölçümü tekrarla',
        ],
      );
    } else if (violations.isNotEmpty) {
      return ReactionCard.warn(
        title: '⚠️ Kural ${violations.join(', ')} İhlali',
        steps: [
          'Eğilim veya dalgalanma tespit edildi',
          'Spray parametrelerini kontrol et',
          'Sonraki 3 ölçümü yakından izle',
        ],
      );
    } else {
      return ReactionCard.ok(
        title: '✅ Normal — Müdahale Gerekmez',
        steps: ['Rutin izlemeye devam et'],
      );
    }
  }
}