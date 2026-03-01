import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/measurement.dart';
import '../models/parameter.dart';
import '../models/alarm.dart';
import '../models/intervention.dart';
import '../models/action_stat.dart';
import '../models/western_electric_rule.dart';

class AppProvider extends ChangeNotifier {
  // Parameters
  final Map<String, Parameter> _parameters = {};

  // Lists
  final List<Alarm> _alarms = [];
  final List<Intervention> _interventions = [];
  final Map<String, ActionStat> _actionStats = {};

  // UI State
  String _activeTab = 'dashboard';
  bool _simRunning = false;
  Timer? _simTimer;
  int _simStep = 0;

  // Current alarm for modal
  Alarm? _currentAlarmForModal;

  // Recipients for email notifications
  final Map<String, bool> _recipients = {
    'Vardiya Şefi': true,
    'Kalite Kontrol': true,
    'Üretim Müdürü': false,
  };

  // Constructor
  AppProvider() {
    _initializeParameters();
    _loadSeedData();
  }

  // ============== GETTERS ==============

  Map<String, Parameter> get parameters => Map.unmodifiable(_parameters);
  List<Alarm> get alarms => List.unmodifiable(_alarms);
  List<Intervention> get interventions => List.unmodifiable(_interventions);
  Map<String, ActionStat> get actionStats => Map.unmodifiable(_actionStats);
  String get activeTab => _activeTab;
  bool get simRunning => _simRunning;
  Alarm? get currentAlarmForModal => _currentAlarmForModal;
  Map<String, bool> get recipients => Map.unmodifiable(_recipients);

  int get criticalAlarmCount => _alarms.where((a) => a.isCritical).length;

  // ============== INITIALIZATION ==============

  void _initializeParameters() {
    _parameters['nem'] = Parameter(
      key: 'nem',
      label: 'Nem',
      unit: '%rH',
      lsl: 5.80,
      usl: 6.30,
      sp: 6.05,
      color: const Color(0xFF2356A4),
    );

    _parameters['uk1'] = Parameter(
      key: 'uk1',
      label: 'UK 1',
      unit: 'mm',
      lsl: -0.7,
      usl: 1.0,
      sp: 0.0,
      color: const Color(0xFF1A7A4A),
    );

    _parameters['uk2'] = Parameter(
      key: 'uk2',
      label: 'UK 2',
      unit: 'mm',
      lsl: -0.7,
      usl: 1.0,
      sp: 0.0,
      color: const Color(0xFF2E9B61),
    );

    _parameters['m1'] = Parameter(
      key: 'm1',
      label: 'Merkez 1',
      unit: 'mm',
      lsl: -0.7,
      usl: 1.0,
      sp: 0.0,
      color: const Color(0xFF98312A),
    );

    _parameters['m2'] = Parameter(
      key: 'm2',
      label: 'Merkez 2',
      unit: 'mm',
      lsl: -0.7,
      usl: 1.0,
      sp: 0.0,
      color: const Color(0xFFC0443C),
    );
  }

  void _loadSeedData() {
    // Nem seed data
    final nemSeed = [5.93, 5.92, 5.90, 5.87, 5.86, 5.84, 5.86, 5.88, 5.91, 5.90, 5.88, 5.92, 5.90, 5.89, 5.95, 5.95, 5.94, 5.90, 5.89, 5.86];
    for (int i = 0; i < nemSeed.length; i++) {
      _parameters['nem']!.addMeasurement(
        value: nemSeed[i],
        time: '09:${(32 + i).toString().padLeft(2, '0')}',
      );
    }

    // Deformation seed data
    final uk1Seed = [-0.62, -0.51, -0.42, -0.70, -0.52, -0.38, -0.45, -0.60, -0.33, -0.48];
    final uk2Seed = [-0.51, -0.46, 0.30, -0.45, -0.44, -0.22, -0.30, -0.55, -0.25, -0.40];
    final m1Seed = [-0.87, -0.72, -0.57, -0.88, -0.65, -0.50, -0.74, -0.62, -0.80, -0.55];
    final m2Seed = [-0.80, -0.63, -0.49, -0.75, -0.70, -0.45, -0.68, -0.55, -0.75, -0.58];

    for (int i = 0; i < uk1Seed.length; i++) {
      final time = '${(i + 1).toString().padLeft(2, '0')}:00';
      _parameters['uk1']!.addMeasurement(value: uk1Seed[i], time: time);
      _parameters['uk2']!.addMeasurement(value: uk2Seed[i], time: time);
      _parameters['m1']!.addMeasurement(value: m1Seed[i], time: time);
      _parameters['m2']!.addMeasurement(value: m2Seed[i], time: time);
    }

    // Seed intervention data for learning demo
    _seedInterventionData();
  }

  void _seedInterventionData() {
    // Örnek müdahale verileri - learning sisteminin çalıştığını göstermek için
    final now = DateTime.now();
    
    final interventions = [
      Intervention(
        action: 'Spray sıcaklığı artırıldı',
        effect: EffectType.resolved,
        operatorName: 'Ahmet Yılmaz',
        timestamp: now.subtract(const Duration(days: 2, hours: 3)),
        parameterName: 'Nem',
        problem: 'ALT LİMİT AŞILDI',
        alarmType: 'danger',
        parameterKey: 'nem',
      ),
      Intervention(
        action: 'Spray sıcaklığı düşürüldü',
        effect: EffectType.resolved,
        operatorName: 'Mehmet Demir',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        parameterName: 'Nem',
        problem: 'ÜST LİMİT AŞILDI',
        alarmType: 'danger',
        parameterKey: 'nem',
      ),
      Intervention(
        action: 'Fırın profili ayarlandı',
        effect: EffectType.resolved,
        operatorName: 'Ali Kaya',
        timestamp: now.subtract(const Duration(hours: 12)),
        parameterName: 'Merkez 1',
        problem: 'ALT LİMİT AŞILDI',
        alarmType: 'danger',
        parameterKey: 'm1',
      ),
      Intervention(
        action: 'Pres basıncı düşürüldü',
        effect: EffectType.improved,
        operatorName: 'Ayşe Yıldız',
        timestamp: now.subtract(const Duration(hours: 6)),
        parameterName: 'UK 1',
        problem: 'ÜST LİMİT AŞILDI',
        alarmType: 'danger',
        parameterKey: 'uk1',
      ),
      Intervention(
        action: 'İzlemeye devam edildi',
        effect: EffectType.nochange,
        operatorName: 'Fatma Şahin',
        timestamp: now.subtract(const Duration(hours: 2)),
        parameterName: 'UK 2',
        problem: 'Kural 4 İhlali',
        alarmType: 'warn',
        parameterKey: 'uk2',
      ),
    ];

    for (final intervention in interventions) {
      _interventions.add(intervention);
      _updateActionStats(intervention);
    }
  }

  // ============== MEASUREMENT PROCESSING ==============

  void processMeasurement(String key, double value) {
    final parameter = _parameters[key];
    if (parameter == null) return;

    // Add measurement
    parameter.addMeasurement(
      value: value,
      time: _formatTimeShort(DateTime.now()),
    );

    // Trim if too many
    if (parameter.data.length > 100) {
      parameter.removeFirst();
    }

    // Check limits
    _checkLimits(parameter, value);

    // Check Western Electric rules
    _checkWesternElectricRules(parameter);

    notifyListeners();
  }

  void _checkLimits(Parameter parameter, double value) {
    if (value < parameter.lsl) {
      final action = _getDefaultAction(parameter.key, isBelowLimit: true);
      _createAlarm(
        type: AlarmType.danger,
        parameter: parameter,
        message: 'ALT LİMİT AŞILDI: ${value.toStringAsFixed(3)} < ${parameter.lsl} ${parameter.unit}',
        suggestedAction: _getBestSuggestion(parameter.key) ?? action,
      );
    } else if (value > parameter.usl) {
      final action = _getDefaultAction(parameter.key, isBelowLimit: false);
      _createAlarm(
        type: AlarmType.danger,
        parameter: parameter,
        message: 'ÜST LİMİT AŞILDI: ${value.toStringAsFixed(3)} > ${parameter.usl} ${parameter.unit}',
        suggestedAction: _getBestSuggestion(parameter.key) ?? action,
      );
    }
  }

  void _checkWesternElectricRules(Parameter parameter) {
    final violations = parameter.weViolations;
    
    if (violations.contains(4)) {
      _createAlarm(
        type: AlarmType.warn,
        parameter: parameter,
        message: 'Kural 4: Eğilim — 8 ardışık nokta aynı yönde',
        suggestedAction: 'Proses kaymasını önce müdahale et',
      );
    }
    
    if (violations.contains(2)) {
      _createAlarm(
        type: AlarmType.warn,
        parameter: parameter,
        message: 'Kural 2: 3\'ten 2 nokta 2σ dışında',
        suggestedAction: 'Yakında limit ihlali olabilir — kontrol et',
      );
    }
  }

  void _createAlarm({
    required AlarmType type,
    required Parameter parameter,
    required String message,
    required String suggestedAction,
  }) {
    final alarm = Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      parameterKey: parameter.key,
      parameterName: parameter.label,
      message: message,
      suggestedAction: suggestedAction,
      timestamp: DateTime.now(),
    );

    _alarms.insert(0, alarm);
    
    if (_alarms.length > 80) {
      _alarms.removeLast();
    }

    notifyListeners();
  }

  String _getDefaultAction(String key, {required bool isBelowLimit}) {
    if (key == 'nem') {
      return isBelowLimit
          ? 'Spray sıcaklığını artır → Vardiya şefini bilgilendir'
          : 'Spray sıcaklığını düşür';
    } else if (key.startsWith('m')) {
      return 'Fırın profili kontrol et';
    } else {
      return isBelowLimit
          ? 'Pres ayarlarını gözden geçir'
          : 'Pres basıncını düşür';
    }
  }

  // ============== LEARNING SYSTEM ==============

  String? _getBestSuggestion(String key) {
    try {
      // İlgili parametre için tüm aksiyonları bul
      final relevant = <MapEntry<String, ActionStat>>[];
      
      for (final entry in _actionStats.entries) {
        if (entry.key.startsWith('${key}__')) {
          relevant.add(entry);
        }
      }

      // Eğer hiç veri yoksa varsayılan öneriyi döndür
      if (relevant.isEmpty) {
        if (key == 'nem') {
          return 'Spray Dryer sıcaklığını kontrol et ve ayarla';
        } else if (key.startsWith('m')) {
          return 'Fırın profilini kontrol et';
        } else {
          return 'Pres ayarlarını gözden geçir';
        }
      }

      // Başarı oranına göre sırala (önce en yüksek)
      relevant.sort((a, b) {
        final rateA = a.value.resolveRate;
        final rateB = b.value.resolveRate;
        
        // Aynı oran varsa kullanım sayısına bak
        if (rateA == rateB) {
          return b.value.count.compareTo(a.value.count);
        }
        
        return rateB.compareTo(rateA);
      });

      // En iyi aksiyonu al
      final best = relevant.first;
      
      // Aksiyon adını ayır (key__action formatından)
      final parts = best.key.split('__');
      if (parts.length < 2) {
        return best.key;
      }
      
      final action = parts[1];
      final rate = (best.value.resolveRate * 100).round();
      final count = best.value.count;
      
      // Başarı oranına göre emoji ekle
      String emoji;
      if (best.value.resolveRate >= 0.7) {
        emoji = '✅';
      } else if (best.value.resolveRate >= 0.4) {
        emoji = '⚠️';
      } else {
        emoji = '❓';
      }
      
      return '$emoji $action (%$rate başarı, $count kullanım)';
      
    } catch (e) {
      debugPrint('Error in _getBestSuggestion: $e');
      return null;
    }
  }

  // Public version of getBestSuggestion for external use
  String? getBestSuggestion(String key, [AlarmType? type]) {
    return _getBestSuggestion(key);
  }

  void _updateActionStats(Intervention intervention) {
    final statKey = '${intervention.parameterKey}__${intervention.action}';
    
    if (!_actionStats.containsKey(statKey)) {
      _actionStats[statKey] = ActionStat();
    }
    
    _actionStats[statKey]!.incrementCount();
    
    if (intervention.effect == EffectType.resolved) {
      _actionStats[statKey]!.incrementResolved();
    }
    
    if (intervention.effect == EffectType.improved) {
      _actionStats[statKey]!.incrementImproved();
    }
  }

  List<MapEntry<String, ActionStat>> getTopSuggestions({int limit = 4}) {
    final sorted = _actionStats.entries.toList()
      ..sort((a, b) => b.value.resolveRate.compareTo(a.value.resolveRate));
    
    return sorted.take(limit).toList();
  }

  List<Map<String, dynamic>> getLearningInsights() {
    final insights = <Map<String, dynamic>>[];
    
    for (final entry in _actionStats.entries) {
      final parts = entry.key.split('__');
      if (parts.length != 2) continue;
      
      final paramKey = parts[0];
      final action = parts[1];
      final stat = entry.value;
      
      final param = _parameters[paramKey];
      final paramName = param?.label ?? paramKey;
      
      insights.add({
        'parameter': paramName,
        'action': action,
        'stat': stat,
        'successRate': stat.successRate,
        'resolveRate': stat.resolveRate,
        'usageCount': stat.count,
      });
    }
    
    insights.sort((a, b) => b['resolveRate'].compareTo(a['resolveRate']));
    return insights;
  }

  // ============== INTERVENTIONS ==============

  void addIntervention(Intervention intervention) {
    _interventions.insert(0, intervention);
    _updateActionStats(intervention);
    notifyListeners();
  }

  void markAlarmResponded(String alarmId, Intervention intervention) {
    final index = _alarms.indexWhere((a) => a.id == alarmId);
    if (index >= 0) {
      _alarms[index].isResponded = true;
      _alarms[index].intervention = intervention;
      notifyListeners();
    }
  }

  // ============== ALARM MANAGEMENT ==============

  void clearOldAlarms() {
    if (_alarms.length > 10) {
      _alarms.removeRange(10, _alarms.length);
      notifyListeners();
    }
  }

  void setCurrentAlarmForModal(Alarm? alarm) {
    _currentAlarmForModal = alarm;
    notifyListeners();
  }

  // ============== UI STATE ==============

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  // ============== SIMULATION ==============

  void toggleSimulation() {
    _simRunning = !_simRunning;
    
    if (_simRunning) {
      _simTimer?.cancel();
      _simTimer = Timer.periodic(
        const Duration(milliseconds: 1400),
        (_) => _simulationTick(),
      );
    } else {
      _simTimer?.cancel();
    }
    
    notifyListeners();
  }

  void _simulationTick() {
    _simStep++;

    // Generate nem value
    double nemValue;
    if (_simStep % 22 == 0) {
      nemValue = 5.74 + Random().nextDouble() * 0.06;
    } else if (_simStep % 38 == 0) {
      nemValue = 6.32 + Random().nextDouble() * 0.08;
    } else if (_simStep % 15 == 0 && _simStep % 15 < 8) {
      nemValue = _normalDistribution(5.84, 0.04);
    } else {
      nemValue = _normalDistribution(5.90, 0.055);
    }
    
    processMeasurement('nem', double.parse(nemValue.toStringAsFixed(3)));

    // Generate deformation values every 3 ticks
    if (_simStep % 3 == 0) {
      final spike = _simStep % 28 == 0;
      
      processMeasurement(
        'uk1',
        double.parse(_normalDistribution(spike ? -0.78 : -0.18, 0.22).toStringAsFixed(3)),
      );
      processMeasurement(
        'uk2',
        double.parse(_normalDistribution(spike ? -0.82 : -0.19, 0.24).toStringAsFixed(3)),
      );
      processMeasurement(
        'm1',
        double.parse(_normalDistribution(spike ? -0.82 : -0.42, 0.28).toStringAsFixed(3)),
      );
      processMeasurement(
        'm2',
        double.parse(_normalDistribution(spike ? -0.85 : -0.45, 0.29).toStringAsFixed(3)),
      );
    }
  }

  double _normalDistribution(double mean, double std) {
    final u1 = Random().nextDouble();
    final u2 = Random().nextDouble();
    return mean + std * sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  // ============== RECIPIENTS ==============

  void toggleRecipient(String key) {
    if (_recipients.containsKey(key)) {
      _recipients[key] = !_recipients[key]!;
      notifyListeners();
    }
  }

  // ============== UTILITY METHODS ==============

  String _formatTimeShort(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  // Get interventions for a specific parameter
  List<Intervention> getInterventionsForParameter(String parameterKey) {
    return _interventions
        .where((i) => i.parameterKey == parameterKey)
        .toList();
  }

  // Get recent interventions
  List<Intervention> getRecentInterventions({int limit = 10}) {
    return _interventions.take(limit).toList();
  }

  // Calculate success rate for a parameter
  double getParameterSuccessRate(String parameterKey) {
    final paramInterventions = getInterventionsForParameter(parameterKey);
    if (paramInterventions.isEmpty) return 0;
    
    final successful = paramInterventions.where((i) => 
        i.effect == EffectType.resolved || i.effect == EffectType.improved).length;
    
    return successful / paramInterventions.length;
  }

  // Get most effective actions for a parameter
  List<MapEntry<String, ActionStat>> getBestActionsForParameter(String parameterKey) {
    final relevant = <MapEntry<String, ActionStat>>[];
    
    for (final entry in _actionStats.entries) {
      if (entry.key.startsWith('${parameterKey}__')) {
        relevant.add(entry);
      }
    }
    
    relevant.sort((a, b) => b.value.resolveRate.compareTo(a.value.resolveRate));
    return relevant;
  }

  // Reset all data (for testing)
  void resetAllData() {
    _parameters.clear();
    _alarms.clear();
    _interventions.clear();
    _actionStats.clear();
    _initializeParameters();
    _loadSeedData();
    notifyListeners();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }
}