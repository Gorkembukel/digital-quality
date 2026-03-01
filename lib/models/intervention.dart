import 'enums.dart';

class Intervention {
  final String action;
  final EffectType effect;
  final String operatorName;
  final DateTime timestamp;
  final String parameterName;
  final String problem;
  final String alarmType;
  final String parameterKey;

  const Intervention({
    required this.action,
    required this.effect,
    required this.operatorName,
    required this.timestamp,
    required this.parameterName,
    required this.problem,
    required this.alarmType,
    required this.parameterKey,
  });

  String get effectDescription {
    switch (effect) {
      case EffectType.resolved:
        return '✅ Düzeldi';
      case EffectType.improved:
        return '↗ İyileşti';
      case EffectType.nochange:
        return '— Değişmedi';
      case EffectType.worsened:
        return '↘ Kötüleşti';
    }
  }

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toJson() => {
    'action': action,
    'effect': effect.index,
    'operatorName': operatorName,
    'timestamp': timestamp.toIso8601String(),
    'parameterName': parameterName,
    'problem': problem,
    'alarmType': alarmType,
    'parameterKey': parameterKey,
  };

  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      action: json['action'] as String,
      effect: EffectType.values[json['effect'] as int],
      operatorName: json['operatorName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      parameterName: json['parameterName'] as String,
      problem: json['problem'] as String,
      alarmType: json['alarmType'] as String,
      parameterKey: json['parameterKey'] as String,
    );
  }
}