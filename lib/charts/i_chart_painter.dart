import 'package:flutter/material.dart';

class IChartPainter extends CustomPainter {
  final List<double> values;
  final double mean;
  final double ucl;
  final double lcl;
  final double usl;
  final double lsl;
  final double minY;
  final double maxY;
  final Color color;

  IChartPainter({
    required this.values,
    required this.mean,
    required this.ucl,
    required this.lcl,
    required this.usl,
    required this.lsl,
    required this.minY,
    required this.maxY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.stroke;
    final xStep = size.width / (values.length - 1);
    final yScale = size.height / (maxY - minY);

    double mapY(double y) => size.height - (y - minY) * yScale;

    // Draw grid lines
    _drawGrid(canvas, size, paint);

    // Draw specification limits
    _drawSpecLimits(canvas, size, paint, mapY);

    // Draw control limits
    _drawControlLimits(canvas, size, paint, mapY);

    // Draw mean line
    _drawMeanLine(canvas, size, paint, mapY);

    // Draw data line and points
    _drawDataLine(canvas, size, paint, mapY, xStep);
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 0.5;

    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawSpecLimits(Canvas canvas, Size size, Paint paint, double Function(double) mapY) {
    paint.color = Colors.orange;
    paint.strokeWidth = 1;
    paint.strokeCap = StrokeCap.round;

    // USL
    final uslY = mapY(usl);
    canvas.drawLine(Offset(0, uslY), Offset(size.width, uslY), paint);

    // LSL
    final lslY = mapY(lsl);
    canvas.drawLine(Offset(0, lslY), Offset(size.width, lslY), paint);
  }

  void _drawControlLimits(Canvas canvas, Size size, Paint paint, double Function(double) mapY) {
    paint.color = Colors.red;
    paint.strokeWidth = 1;
    paint.strokeCap = StrokeCap.round;

    // UCL
    final uclY = mapY(ucl);
    canvas.drawLine(Offset(0, uclY), Offset(size.width, uclY), paint);

    // LCL
    final lclY = mapY(lcl);
    canvas.drawLine(Offset(0, lclY), Offset(size.width, lclY), paint);
  }

  void _drawMeanLine(Canvas canvas, Size size, Paint paint, double Function(double) mapY) {
    paint.color = Colors.green;
    paint.strokeWidth = 1;
    paint.strokeCap = StrokeCap.round;

    final meanY = mapY(mean);
    canvas.drawLine(Offset(0, meanY), Offset(size.width, meanY), paint);
  }

  void _drawDataLine(Canvas canvas, Size size, Paint paint, double Function(double) mapY, double xStep) {
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = i * xStep;
      final y = mapY(values[i]);
      points.add(Offset(x, y));
    }

    // Draw line
    paint.color = color;
    paint.strokeWidth = 2;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw points
    paint.style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant IChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.mean != mean ||
        oldDelegate.ucl != ucl ||
        oldDelegate.lcl != lcl;
  }
}