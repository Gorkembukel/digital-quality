class ActionStat {
  int count;
  int resolved;
  int improved;

  ActionStat({
    this.count = 0,
    this.resolved = 0,
    this.improved = 0,
  });

  // Toplam başarılı müdahale (resolved + improved)
  int get totalSuccess => resolved + improved;

  // Başarı oranı (resolved + improved) / count
  double get successRate {
    if (count == 0) return 0;
    return totalSuccess / count;
  }

  // Tam çözüm oranı (resolved / count)
  double get resolveRate {
    if (count == 0) return 0;
    return resolved / count;
  }

  // İyileşme oranı (improved / count)
  double get improveRate {
    if (count == 0) return 0;
    return improved / count;
  }

  // Başarısızlık oranı (count - totalSuccess) / count
  double get failureRate {
    if (count == 0) return 0;
    return (count - totalSuccess) / count;
  }

  // İstatistikleri artırma metodları
  void incrementCount() => count++;
  void incrementResolved() => resolved++;
  void incrementImproved() => improved++;

  // Toplu artırma
  void add({
    int count = 0,
    int resolved = 0,
    int improved = 0,
  }) {
    this.count += count;
    this.resolved += resolved;
    this.improved += improved;
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'count': count,
    'resolved': resolved,
    'improved': improved,
  };

  factory ActionStat.fromJson(Map<String, dynamic> json) {
    return ActionStat(
      count: json['count'] as int? ?? 0,
      resolved: json['resolved'] as int? ?? 0,
      improved: json['improved'] as int? ?? 0,
    );
  }

  // Kopyalama
  ActionStat copyWith({
    int? count,
    int? resolved,
    int? improved,
  }) {
    return ActionStat(
      count: count ?? this.count,
      resolved: resolved ?? this.resolved,
      improved: improved ?? this.improved,
    );
  }

  // Sıfırlama
  void reset() {
    count = 0;
    resolved = 0;
    improved = 0;
  }

  // String gösterimi
  @override
  String toString() {
    return 'ActionStat(count: $count, resolved: $resolved, improved: $improved, successRate: ${(successRate * 100).toStringAsFixed(1)}%)';
  }

  // İki ActionStat'i birleştirme
  ActionStat operator +(ActionStat other) {
    return ActionStat(
      count: count + other.count,
      resolved: resolved + other.resolved,
      improved: improved + other.improved,
    );
  }

  // Ortalama alma (birden fazla istatistiğin ortalaması için)
  static ActionStat average(List<ActionStat> stats) {
    if (stats.isEmpty) return ActionStat();
    
    final total = stats.reduce((a, b) => a + b);
    final divisor = stats.length;
    
    return ActionStat(
      count: total.count ~/ divisor,
      resolved: total.resolved ~/ divisor,
      improved: total.improved ~/ divisor,
    );
  }
}

// ActionStat koleksiyonu için yardımcı sınıf
class ActionStatCollection {
  final Map<String, ActionStat> _stats = {};

  ActionStatCollection();

  // Belirtilen key için ActionStat getir (yoksa oluştur)
  ActionStat get(String key) {
    return _stats.putIfAbsent(key, () => ActionStat());
  }

  // Müdahale kaydet
  void recordIntervention(String key, bool resolved, bool improved) {
    final stat = get(key);
    stat.incrementCount();
    if (resolved) stat.incrementResolved();
    if (improved) stat.incrementImproved();
  }

  // Tüm istatistikler
  Map<String, ActionStat> get all => Map.unmodifiable(_stats);

  // En başarılı aksiyonlar
  List<MapEntry<String, ActionStat>> getTopSuccess({int limit = 5}) {
    final entries = _stats.entries.toList();
    entries.sort((a, b) => b.value.successRate.compareTo(a.value.successRate));
    return entries.take(limit).toList();
  }

  // En çok kullanılan aksiyonlar
  List<MapEntry<String, ActionStat>> getMostUsed({int limit = 5}) {
    final entries = _stats.entries.toList();
    entries.sort((a, b) => b.value.count.compareTo(a.value.count));
    return entries.take(limit).toList();
  }

  // Temizle
  void clear() => _stats.clear();

  // JSON serialization
  Map<String, dynamic> toJson() {
    return _stats.map((key, value) => MapEntry(key, value.toJson()));
  }

  factory ActionStatCollection.fromJson(Map<String, dynamic> json) {
    final collection = ActionStatCollection();
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        collection._stats[key] = ActionStat.fromJson(value);
      }
    });
    return collection;
  }

  @override
  String toString() => 'ActionStatCollection(count: ${_stats.length})';
}