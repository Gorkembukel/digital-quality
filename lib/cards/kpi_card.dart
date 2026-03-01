import 'package:dashbord/models/cpk_result.dart';
import 'package:flutter/material.dart';
import '../../models/parameter.dart';
import '../../models/enums.dart';

class KpiCard extends StatelessWidget {
  final Parameter parameter;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.parameter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cpk = parameter.cpk;
    final lastValue = parameter.lastValue;
    final outOfSpec = parameter.outOfSpecCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildValue(lastValue),
            const SizedBox(height: 4),
            _buildFooter(cpk, outOfSpec),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          parameter.label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildValue(double? lastValue) {
    return Text(
      lastValue != null ? lastValue.toStringAsFixed(3) : '—',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _getStatusColor(),
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildFooter(CpkResult? cpk, int outOfSpec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cpk: ${cpk != null ? cpk.cpk.toStringAsFixed(2) : '—'}',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Text(
          'n=${parameter.data.length} | dışı: $outOfSpec',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (parameter.lastValue == null) return Colors.grey;
    
    final lastValue = parameter.lastValue!;
    if (lastValue < parameter.lsl || lastValue > parameter.usl) {
      return Colors.red;
    }
    
    final cpk = parameter.cpk;
    if (cpk == null) return Colors.orange;
    if (cpk.cpk >= 1.33) return Colors.green;
    if (cpk.cpk >= 1.0) return Colors.orange;
    return Colors.red;
  }
}