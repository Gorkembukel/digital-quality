import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';



class AppConstants {
  // Colors
  static const Color vitraRed = Color(0xFF98312A);
  static const Color vitraRedLight = Color(0xFFC0443C);
  static const Color vitraRedExtraLight = Color(0xFFF5E8E7);
  
  static const Color eczaNavy = Color(0xFF1A2B4A);
  static const Color eczaBlue = Color(0xFF2356A4);
  
  static const Color ok = Color(0xFF1A7A4A);
  static const Color okLight = Color(0xFFE8F5EE);
  static const Color warn = Color(0xFFB45309);
  static const Color warnLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFF98312A);
  static const Color dangerLight = Color(0xFFFEE9E8);

  // Parameter limits
  static const double nemLsl = 5.80;
  static const double nemUsl = 6.30;
  static const double nemSp = 6.05;

  static const double defLsl = -0.7;
  static const double defUsl = 1.0;

  // Chart dimensions
  static const double chartHeight = 200;
  static const double smallChartHeight = 120;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  
  // Max data points
  static const int maxDataPoints = 100;
  static const int maxAlarms = 80;
}

class AppStrings {
  static const String appTitle = 'VitrA SPC - Kalite Kontrol Sistemi';
  static const String systemNormal = 'SİSTEM NORMAL';
  static const String warning = 'UYARI VAR';
  static const String criticalAlarm = 'KRİTİK ALARM';
  
  static const String simulationStart = '▶ Simülasyon Başlat';
  static const String simulationStop = '⏹ Durdur';
  
  static const String emailNotification = '✉️ E-posta bildirim gönderildi';
  static const String interventionRecorded = '✓ Müdahale Kaydedildi';
  static const String addIntervention = '+ Müdahale Gir';
}

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