import 'package:dashbord/models/intervention.dart';

import 'enums.dart';

class Alarm {
  final String id;
  final AlarmType type;
  final String parameterKey;
  final String parameterName;
  final String message;
  final String suggestedAction;
  final DateTime timestamp;
  bool isResponded;
  Intervention? intervention;

  Alarm({
    required this.id,
    required this.type,
    required this.parameterKey,
    required this.parameterName,
    required this.message,
    required this.suggestedAction,
    required this.timestamp,
    this.isResponded = false,
    this.intervention,
  });

  bool get isCritical {
    if (isResponded) return false;
    if (type != AlarmType.danger) return false;
    final minutesSinceAlarm = DateTime.now().difference(timestamp).inMinutes;
    return minutesSinceAlarm < 3;
  }

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDateTime {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'parameterKey': parameterKey,
    'parameterName': parameterName,
    'message': message,
    'suggestedAction': suggestedAction,
    'timestamp': timestamp.toIso8601String(),
    'isResponded': isResponded,
    'intervention': intervention?.toJson(),
  };

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      type: AlarmType.values[json['type'] as int],
      parameterKey: json['parameterKey'] as String,
      parameterName: json['parameterName'] as String,
      message: json['message'] as String,
      suggestedAction: json['suggestedAction'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isResponded: json['isResponded'] as bool? ?? false,
      intervention: json['intervention'] != null
          ? Intervention.fromJson(json['intervention'] as Map<String, dynamic>)
          : null,
    );
  }
}