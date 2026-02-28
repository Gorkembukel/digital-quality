import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

final Color? defaultBacground = Color.fromARGB(213, 224, 245, 175);
final Color? defaultAppbarColor =  Color.fromARGB(255, 178, 206, 113);
final Color? defaultPrimaryColor = Colors.blue;
final Color defaultAscentColor = Colors.blueAccent;




class XBarChartWidget extends StatelessWidget {
  final List<double> measurements; // örnek deformasyon değerleri
  final double lowerSpec;
  final double upperSpec;

  const XBarChartWidget({
    super.key,
    required this.measurements,
    required this.lowerSpec,
    required this.upperSpec,
  });

  @override
  Widget build(BuildContext context) {
    // X-bar chart için LineChartData
    List<FlSpot> spots = [];
    for (int i = 0; i < measurements.length; i++) {
      spots.add(FlSpot(i.toDouble(), measurements[i]));
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "X-bar Chart - Deformasyon",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minY: measurements.reduce((a, b) => a < b ? a : b) - 1,
                  maxY: measurements.reduce((a, b) => a > b ? a : b) + 1,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  lineBarsData: [
                    // Ölçüm değerleri
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 3,
                      color: Colors.blue,
                      dotData: FlDotData(show: true),
                    ),
                    // Upper spec line
                    LineChartBarData(
                      spots: [
                        FlSpot(0, upperSpec),
                        FlSpot(measurements.length.toDouble() - 1, upperSpec),
                      ],
                      isCurved: false,
                      barWidth: 2,
                      color: Colors.red,
                      dashArray: [5, 5],
                      dotData: FlDotData(show: false),
                    ),
                    // Lower spec line
                    LineChartBarData(
                      spots: [
                        FlSpot(0, lowerSpec),
                        FlSpot(measurements.length.toDouble() - 1, lowerSpec),
                      ],
                      isCurved: false,
                      barWidth: 2,
                      color: Colors.red,
                      dashArray: [5, 5],
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}