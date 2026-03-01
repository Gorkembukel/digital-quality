import 'package:flutter/material.dart';

class MRChartPainter extends CustomPainter {
  final List<double> mrs;
  final double mrMean;
  final double uclMR;
  final double minY;
  final double maxY;

  MRChartPainter({
    required this.mrs,
    required this.mrMean,
    required this.uclMR,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mrs.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.stroke;
    final xStep = size.width / (mrs.length - 1);
    final yScale = size.height / (maxY - minY);

    double mapY(double y) => size.height - (y - minY) * yScale;

    // Draw grid lines
    _drawGrid(canvas, size, paint);

    // Draw UCL
    _drawUCLLine(canvas, size, paint, mapY);

    // Draw mean line
    _drawMeanLine(canvas, size, paint, mapY);

    // Draw MR data
    _drawMRData(canvas, size, paint, mapY, xStep);
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawUCLLine(Canvas canvas, Size size, Paint paint, double Function(double) mapY) {
    paint.color = Colors.red;
    paint.strokeWidth = 1;
    paint.strokeCap = StrokeCap.round;

    final uclY = mapY(uclMR);
    canvas.drawLine(Offset(0, uclY), Offset(size.width, uclY), paint);
  }

  void _drawMeanLine(Canvas canvas, Size size, Paint paint, double Function(double) mapY) {
    paint.color = Colors.green;
    paint.strokeWidth = 1;
    paint.strokeCap = StrokeCap.round;

    final meanY = mapY(mrMean);
    canvas.drawLine(Offset(0, meanY), Offset(size.width, meanY), paint);
  }

  void _drawMRData(Canvas canvas, Size size, Paint paint, double Function(double) mapY, double xStep) {
    final points = <Offset>[];
    for (int i = 0; i < mrs.length; i++) {
      final x = i * xStep;
      final y = mapY(mrs[i]);
      points.add(Offset(x, y));
    }

    // Draw line
    paint.color = const Color(0xFF6B48C8);
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
  bool shouldRepaint(covariant MRChartPainter oldDelegate) {
    return oldDelegate.mrs != mrs ||
        oldDelegate.mrMean != mrMean ||
        oldDelegate.uclMR != uclMR;
  }
}