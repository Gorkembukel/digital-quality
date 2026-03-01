import 'dart:math';
import 'package:flutter/material.dart';
import 'enums.dart';
import 'measurement.dart';
import 'spc_result.dart';
import 'cpk_result.dart';
import 'western_electric_rule.dart';

class Parameter {
  final String key;
  final String label;
  final String unit;
  final double lsl; // Lower Specification Limit
  final double usl; // Upper Specification Limit
  final double sp; // Set Point
  final Color color;
  final List<Measurement> _data;

  Parameter({
    required this.key,
    required this.label,
    required this.unit,
    required this.lsl,
    required this.usl,
    required this.sp,
    required this.color,
    List<Measurement>? data,
  }) : _data = data ?? [];

  // Data getter - immutable view
  List<Measurement> get data => List.unmodifiable(_data);

  // Last value
  double? get lastValue {
    if (_data.isEmpty) return null;
    return _data.last.value;
  }

  // Add measurement
  void addMeasurement({required double value, required String time}) {
    _data.add(Measurement(value: value, time: time));
  }

  // Remove first measurement (for trimming)
  void removeFirst() {
    if (_data.isNotEmpty) {
      _data.removeAt(0);
    }
  }

  // Clear all data
  void clear() {
    _data.clear();
  }

  // SPC Calculation
  SpcResult? get spc {
    if (_data.length < 2) return null;

    final values = _data.map((m) => m.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;

    // Standard deviation
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    final sumSquaredDiffs = squaredDiffs.reduce((a, b) => a + b);
    final variance = sumSquaredDiffs / (values.length - 1);
    final std = sqrt(variance);

    // Moving ranges
    final mrs = <double>[];
    for (int i = 0; i < values.length - 1; i++) {
      mrs.add((values[i + 1] - values[i]).abs());
    }

    final mrMean = mrs.isEmpty ? 0 : mrs.reduce((a, b) => a + b) / mrs.length;
    final sigE = mrMean / 1.128; // Unbiasing constant for n=2

    return SpcResult(
      mean: mean,
      std: std,
      sigE: sigE,
      mrMean: mrMean.toDouble(),
      ucl: mean + 3 * sigE,
      lcl: mean - 3 * sigE,
      uclMR: 3.267 * mrMean,
      mrs: mrs,
    );
  }

  // Cp/Cpk Calculation
  CpkResult? get cpk {
    final s = spc;
    if (s == null || s.sigE == 0) return null;

    final cp = (usl - lsl) / (6 * s.sigE);
    final cpu = (usl - s.mean) / (3 * s.sigE);
    final cpl = (s.mean - lsl) / (3 * s.sigE);
    final cpkValue = min(cpu, cpl);

    return CpkResult(cp: cp, cpk: cpkValue);
  }

  // Cpk Status
  StatusType get cpkStatus {
    final c = cpk;
    if (c == null) return StatusType.warn;
    if (c.cpk >= 1.33) return StatusType.ok;
    if (c.cpk >= 1.0) return StatusType.warn;
    return StatusType.danger;
  }

  // Western Electric Rules Violations
  List<int> get weViolations {
    final s = spc;
    if (s == null || _data.length < 3) return [];

    final values = _data.map((m) => m.value).toList();
    final violations = <int>[];

    for (final rule in WesternElectricRules.all) {
      if (rule.check(values, s.mean, s.sigE)) {
        violations.add(rule.id);
      }
    }

    return violations;
  }

  // Out of spec count
  int get outOfSpecCount {
    return _data.where((m) => m.value < lsl || m.value > usl).length;
  }

  // Out of spec percentage
  double get outOfSpecPercentage {
    if (_data.isEmpty) return 0;
    return (outOfSpecCount / _data.length) * 100;
  }

  // Process capability index interpretation
  String get cpkInterpretation {
    final c = cpk;
    if (c == null) return 'Yetersiz veri';

    if (c.cpk >= 1.67) {
      return 'Mükemmel proses';
    } else if (c.cpk >= 1.33) {
      return 'Yeterli proses';
    } else if (c.cpk >= 1.0) {
      return 'Kabul edilebilir (yakın takip gerekli)';
    } else if (c.cpk >= 0.67) {
      return 'Yetersiz (iyileştirme gerekli)';
    } else {
      return 'Kritik (acil müdahale gerekli)';
    }
  }

  // Create a copy with new data
  Parameter copyWith({List<Measurement>? data}) {
    return Parameter(
      key: key,
      label: label,
      unit: unit,
      lsl: lsl,
      usl: usl,
      sp: sp,
      color: color,
      data: data ?? _data,
    );
  }

  @override
  String toString() {
    return 'Parameter(key: $key, label: $label, data: ${_data.length} points)';
  }
}