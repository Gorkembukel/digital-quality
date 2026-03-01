class Measurement {
  final double value;
  final String time;

  const Measurement({
    required this.value,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'time': time,
  };

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      value: (json['value'] as num).toDouble(),
      time: json['time'] as String,
    );
  }

  @override
  String toString() => 'Measurement(value: $value, time: $time)';
}