import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/parameter.dart';

class MultiLineChartPainter extends CustomPainter {
  final List<Parameter> parameters;
  final double usl;
  final double lsl;

  MultiLineChartPainter({
    required this.parameters,
    required this.usl,
    required this.lsl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (parameters.isEmpty || parameters.any((p) => p.data.isEmpty)) return;

    final paint = Paint()..style = PaintingStyle.stroke;

    // Find Y range
    final allValues = parameters.expand((p) => p.data.map((m) => m.value)).toList();
    final maxY = allValues.reduce(max);
    final minY = allValues.reduce(min);
    final range = maxY - minY;
    final padding = range * 0.1;
    final yMin = minY - padding;
    final yMax = maxY + padding;
    final yScale = size.height / (yMax - yMin);

    double mapY(double y) => size.height - (y - yMin) * yScale;

    // Draw grid lines
    _drawGrid(canvas, size, paint);

    // Draw specification limits
    _drawSpecLimits(canvas, size, paint, mapY);

    // Draw parameter lines
    _drawParameterLines(canvas, size, paint, mapY);
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawSpecLimits(Canvas canvas, Size size, Paint paint, double Function(double) mapY) {
    paint.color = Colors.orange;
    paint.strokeWidth = 1;

    final uslY = mapY(usl);
    canvas.drawLine(Offset(0, uslY), Offset(size.width, uslY), paint);

    final lslY = mapY(lsl);
    canvas.drawLine(Offset(0, lslY), Offset(size.width, lslY), paint);
  }

  void _drawParameterLines(Canvas canvas, Size size, Paint paint, double Function(double) mapY) {
    for (final parameter in parameters) {
      if (parameter.data.isEmpty) continue;

      final values = parameter.data.map((m) => m.value).toList();
      final xStep = size.width / (values.length - 1);

      final points = <Offset>[];
      for (int i = 0; i < values.length; i++) {
        final x = i * xStep;
        final y = mapY(values[i]);
        points.add(Offset(x, y));
      }

      paint.color = parameter.color;
      paint.strokeWidth = 1.5;

      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MultiLineChartPainter oldDelegate) {
    return oldDelegate.parameters != parameters;
  }
}