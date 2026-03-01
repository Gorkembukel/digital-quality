enum AlarmType { 
  danger, 
  warn, 
  ok, 
  info 
}

enum EffectType { 
  resolved,      // ✅ Düzeldi
  improved,      // ↗ İyileşti
  nochange,      // — Değişmedi
  worsened       // ↘ Kötüleşti
}

enum StatusType { 
  ok,            // Yeşil
  warn,          // Turuncu
  danger         // Kırmızı
}

enum ParameterKey {
  nem,
  uk1,
  uk2,
  m1,
  m2;

  String get displayName {
    switch (this) {
      case ParameterKey.nem:
        return 'Nem';
      case ParameterKey.uk1:
        return 'UK 1';
      case ParameterKey.uk2:
        return 'UK 2';
      case ParameterKey.m1:
        return 'Merkez 1';
      case ParameterKey.m2:
        return 'Merkez 2';
    }
  }

  String get unit {
    switch (this) {
      case ParameterKey.nem:
        return '%rH';
      default:
        return 'mm';
    }
  }
}