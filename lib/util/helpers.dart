import 'dart:math';
import 'package:dashbord/models/enums.dart';
import 'package:dashbord/util/constant.dart';
import 'package:flutter/material.dart';

class Helpers {
  // Format time as HH:MM
  static String formatTimeShort(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Format time as HH:MM:SS
  static String formatTimeFull(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  // Format date as DD.MM.YYYY
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day.$month.$year';
  }

  // Format datetime as DD.MM HH:MM
  static String formatDateTime(DateTime dateTime) {
    final date = formatDate(dateTime);
    final time = formatTimeShort(dateTime);
    return '$date $time';
  }

  // Generate normal distribution random number (Box-Muller)
  static double normalDistribution(double mean, double std) {
    final u1 = Random().nextDouble();
    final u2 = Random().nextDouble();
    return mean + std * sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  // Calculate moving average
  static List<double> movingAverage(List<double> values, int window) {
    if (values.length < window) return [];
    
    final result = <double>[];
    for (int i = 0; i <= values.length - window; i++) {
      final sum = values.sublist(i, i + window).reduce((a, b) => a + b);
      result.add(sum / window);
    }
    return result;
  }

  // Check if value is within spec limits
  static bool isWithinSpec(double value, double lsl, double usl) {
    return value >= lsl && value <= usl;
  }

  // Get color based on status
  static Color getStatusColor(StatusType status) {
    switch (status) {
      case StatusType.ok:
        return AppConstants.ok;
      case StatusType.warn:
        return AppConstants.warn;
      case StatusType.danger:
        return AppConstants.danger;
    }
  }

  // Get light color based on status
  static Color getStatusLightColor(StatusType status) {
    switch (status) {
      case StatusType.ok:
        return AppConstants.okLight;
      case StatusType.warn:
        return AppConstants.warnLight;
      case StatusType.danger:
        return AppConstants.dangerLight;
    }
  }

  // Format number with fixed decimals
  static String formatNumber(double value, {int decimals = 3}) {
    return value.toStringAsFixed(decimals);
  }

  // Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  // Calculate percentage
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  // Safe division
  static double safeDivide(double a, double b) {
    if (b == 0) return 0;
    return a / b;
  }
}