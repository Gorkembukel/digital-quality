// client_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ============== MODELLER ==============
enum AlarmType { danger, warn, ok, info }
enum EffectType { resolved, improved, nochange, worsened }
enum StatusType { ok, warn, danger }

class Measurement {
  final double value;
  final String time;
  Measurement({required this.value, required this.time});
}

class Parameter {
  final String key;
  final String label;
  final String unit;
  final double lsl;
  final double usl;
  final double sp;
  final Color color;
  List<Measurement> data;

  Parameter({
    required this.key,
    required this.label,
    required this.unit,
    required this.lsl,
    required this.usl,
    required this.sp,
    required this.color,
    List<Measurement>? data,
  }) : data = data ?? [];

  SpcResult? get spc {
    if (data.length < 2) return null;
    final values = data.map((m) => m.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final std = sqrt(values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / (values.length - 1));
    final mrs = List.generate(values.length - 1, (i) => (values[i + 1] - values[i]).abs());
    final mrMean = mrs.isEmpty ? 0 : mrs.reduce((a, b) => a + b) / mrs.length;
    final sigE = mrMean / 1.128;
    return SpcResult(
      mean: mean,
      std: std,
      sigE: sigE,
      mrMean: mrMean.toDouble(),
      ucl: mean + 3 * sigE,
      lcl: mean - 3 * sigE,
      uclMR: 3.267 * mrMean,
      mrs: mrs,
    );
  }

  CpkResult? get cpk {
    final s = spc;
    if (s == null || s.sigE == 0) return null;
    return CpkResult(
      cp: (usl - lsl) / (6 * s.sigE),
      cpk: min((usl - s.mean) / (3 * s.sigE), (s.mean - lsl) / (3 * s.sigE)),
    );
  }

  StatusType get cpkStatus {
    final c = cpk;
    if (c == null) return StatusType.warn;
    if (c.cpk >= 1.33) return StatusType.ok;
    if (c.cpk >= 1.0) return StatusType.warn;
    return StatusType.danger;
  }

  List<int> get weViolations {
    final s = spc;
    if (s == null || data.length < 3) return [];
    final values = data.map((m) => m.value).toList();
    return WesternElectric.rules.where((rule) => rule.fn(values, s.mean, s.sigE)).map((r) => r.id).toList();
  }
}

class SpcResult {
  final double mean;
  final double std;
  final double sigE;
  final double mrMean;
  final double ucl;
  final double lcl;
  final double uclMR;
  final List<double> mrs;
  SpcResult({required this.mean, required this.std, required this.sigE, required this.mrMean, required this.ucl, required this.lcl, required this.uclMR, required this.mrs});
}

class CpkResult {
  final double cp;
  final double cpk;
  CpkResult({required this.cp, required this.cpk});
}

class WesternElectricRule {
  final int id; final String name; final String desc; final bool Function(List<double> values, double mean, double sigma) fn;
  WesternElectricRule({required this.id, required this.name, required this.desc, required this.fn});
}

class WesternElectric {
  static final List<WesternElectricRule> rules = [
    WesternElectricRule(
      id: 1, name: 'Tek Nokta 3σ Dışı', desc: '1 nokta kontrol limitinin dışında',
      fn: (v, m, s) => v.isNotEmpty && (v.last > m + 3 * s || v.last < m - 3 * s),
    ),
    WesternElectricRule(
      id: 2, name: '2/3 Kural — 2σ', desc: '3\'ten 2 nokta aynı tarafta >2σ',
      fn: (v, m, s) {
        final l = v.length >= 3 ? v.sublist(v.length - 3) : v;
        return l.where((x) => x > m + 2 * s).length >= 2 || l.where((x) => x < m - 2 * s).length >= 2;
      },
    ),
    WesternElectricRule(
      id: 3, name: '4/5 Kural — 1σ', desc: '5\'ten 4 nokta aynı tarafta >1σ',
      fn: (v, m, s) {
        final l = v.length >= 5 ? v.sublist(v.length - 5) : v;
        return l.where((x) => x > m + s).length >= 4 || l.where((x) => x < m - s).length >= 4;
      },
    ),
    WesternElectricRule(
      id: 4, name: 'Eğilim (8 Nokta)', desc: '8 ardışık nokta aynı tarafta',
      fn: (v, m, s) {
        if (v.length < 8) return false;
        final l = v.sublist(v.length - 8);
        return l.every((x) => x > m) || l.every((x) => x < m);
      },
    ),
    WesternElectricRule(
      id: 5, name: 'Merkez Kaçışı', desc: '8 nokta ortadan >1σ uzakta',
      fn: (v, m, s) {
        if (v.length < 8) return false;
        final l = v.sublist(v.length - 8);
        return l.every((x) => (x - m).abs() > s);
      },
    ),
    WesternElectricRule(
      id: 6, name: 'Tabakalaşma', desc: '15 nokta ±1σ içinde',
      fn: (v, m, s) {
        if (v.length < 15) return false;
        final l = v.sublist(v.length - 15);
        return l.every((x) => (x - m).abs() < s);
      },
    ),
    WesternElectricRule(
      id: 7, name: 'Zikzak', desc: '14 ardışık nokta dönüşümlü yukarı-aşağı',
      fn: (v, m, s) {
        if (v.length < 14) return false;
        final l = v.sublist(v.length - 14);
        int count = 0;
        for (int i = 1; i < l.length - 1; i++) {
          if ((l[i] > l[i - 1] && l[i] > l[i + 1]) || (l[i] < l[i - 1] && l[i] < l[i + 1])) {
            count++;
          }
        }
        return count >= 8;
      },
    ),
    WesternElectricRule(
      id: 8, name: 'Karma Örüntü', desc: '8 nokta ±1σ dışında (karma taraf)',
      fn: (v, m, s) {
        if (v.length < 8) return false;
        final l = v.sublist(v.length - 8);
        return l.every((x) => (x - m).abs() > s);
      },
    ),
  ];
}

class Alarm {
  final String id; final AlarmType type; final String key; final String param; final String msg; final String action; final DateTime time;
  bool responded; Intervention? intervention;
  Alarm({required this.id, required this.type, required this.key, required this.param, required this.msg, required this.action, required this.time, this.responded = false, this.intervention});
  bool get isCritical => !responded && type == AlarmType.danger && DateTime.now().difference(time).inMinutes < 3;
}

class Intervention {
  final String action; final EffectType effect; final String operator; final DateTime time; final String param; final String problem; final String alarmType; final String key;
  Intervention({required this.action, required this.effect, required this.operator, required this.time, required this.param, required this.problem, required this.alarmType, required this.key});
}

class ActionStat {
  int count; int resolved; int improved;
  ActionStat({this.count = 0, this.resolved = 0, this.improved = 0});
  double get resolveRate => count > 0 ? resolved / count : 0;
}

// ============== ANA PROVIDER (State Management) ==============
class AppProvider extends ChangeNotifier {
  // Parameters
  final Map<String, Parameter> parameters = {
    'nem': Parameter(key: 'nem', label: 'Nem', unit: '%rH', lsl: 5.80, usl: 6.30, sp: 6.05, color: const Color(0xFF2356A4)),
    'uk1': Parameter(key: 'uk1', label: 'UK 1', unit: 'mm', lsl: -0.7, usl: 1.0, sp: 0.0, color: const Color(0xFF1A7A4A)),
    'uk2': Parameter(key: 'uk2', label: 'UK 2', unit: 'mm', lsl: -0.7, usl: 1.0, sp: 0.0, color: const Color(0xFF2E9B61)),
    'm1': Parameter(key: 'm1', label: 'Merkez 1', unit: 'mm', lsl: -0.7, usl: 1.0, sp: 0.0, color: const Color(0xFF98312A)),
    'm2': Parameter(key: 'm2', label: 'Merkez 2', unit: 'mm', lsl: -0.7, usl: 1.0, sp: 0.0, color: const Color(0xFFC0443C)),
  };

  List<Alarm> alarms = [];
  List<Intervention> interventions = [];
  final Map<String, ActionStat> actionStats = {};
  String activeTab = 'dashboard';
  bool simRunning = false;
  Timer? _simTimer;
  final Map<String, bool> recipients = {'Vardiya Şefi': true, 'Kalite Kontrol': true, 'Üretim Müdürü': false};
  Alarm? currentAlarmForModal;
  int _simStep = 0;

  AppProvider() { _initSeedData(); }

  void _initSeedData() {
    final nemSeed = [5.93, 5.92, 5.90, 5.87, 5.86, 5.84, 5.86, 5.88, 5.91, 5.90, 5.88, 5.92, 5.90, 5.89, 5.95, 5.95, 5.94, 5.90, 5.89, 5.86];
    for (int i = 0; i < nemSeed.length; i++) {
      parameters['nem']!.data.add(Measurement(value: nemSeed[i], time: '09:${(32 + i).toString().padLeft(2, '0')}'));
    }

    final uk1Seed = [-0.62, -0.51, -0.42, -0.70, -0.52, -0.38, -0.45, -0.60, -0.33, -0.48];
    final uk2Seed = [-0.51, -0.46, 0.30, -0.45, -0.44, -0.22, -0.30, -0.55, -0.25, -0.40];
    final m1Seed = [-0.87, -0.72, -0.57, -0.88, -0.65, -0.50, -0.74, -0.62, -0.80, -0.55];
    final m2Seed = [-0.80, -0.63, -0.49, -0.75, -0.70, -0.45, -0.68, -0.55, -0.75, -0.58];

    for (int i = 0; i < uk1Seed.length; i++) {
      final time = '${(i + 1).toString().padLeft(2, '0')}:00';
      parameters['uk1']!.data.add(Measurement(value: uk1Seed[i], time: time));
      parameters['uk2']!.data.add(Measurement(value: uk2Seed[i], time: time));
      parameters['m1']!.data.add(Measurement(value: m1Seed[i], time: time));
      parameters['m2']!.data.add(Measurement(value: m2Seed[i], time: time));
    }
  }

  void process(String key, double value) {
    final p = parameters[key];
    if (p == null) return;

    p.data.add(Measurement(value: value, time: _formatTimeShort(DateTime.now())));
    if (p.data.length > 100) p.data.removeAt(0);

    if (value < p.lsl) {
      final action = key == 'nem' ? 'Spray sıcaklığını artır → Vardiya şefini bilgilendir' : key.startsWith('m') ? 'Fırın profili kontrol et' : 'Pres ayarlarını gözden geçir';
      pushAlarm(AlarmType.danger, key, 'ALT LİMİT AŞILDI: ${value.toStringAsFixed(3)} < ${p.lsl} ${p.unit}', getBestSuggestion(key, AlarmType.danger) ?? action);
    } else if (value > p.usl) {
      final action = key == 'nem' ? 'Spray sıcaklığını düşür' : 'Pres basıncını düşür';
      pushAlarm(AlarmType.danger, key, 'ÜST LİMİT AŞILDI: ${value.toStringAsFixed(3)} > ${p.usl} ${p.unit}', getBestSuggestion(key, AlarmType.danger) ?? action);
    }

    final viol = p.weViolations;
    if (viol.contains(4)) pushAlarm(AlarmType.warn, key, 'Kural 4: Eğilim — 8 ardışık nokta aynı yönde', 'Proses kaymasını önce müdahale et');
    if (viol.contains(2)) pushAlarm(AlarmType.warn, key, 'Kural 2: 3\'ten 2 nokta 2σ dışında', 'Yakında limit ihlali olabilir — kontrol et');

    notifyListeners();
  }

  void pushAlarm(AlarmType type, String key, String msg, String action) {
    final alarm = Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type, key: key, param: parameters[key]!.label, msg: msg, action: action, time: DateTime.now(),
    );
    alarms.insert(0, alarm);
    if (alarms.length > 80) alarms.removeLast();
    notifyListeners();
  }

  String? getBestSuggestion(String key, AlarmType type) {
    if (type != AlarmType.danger) return null;
    final relevant = actionStats.entries.where((e) => e.key.startsWith('$key\_\_')).toList();
    if (relevant.isEmpty) {
      if (key == 'nem') return 'Spray Dryer sıcaklığını kontrol et ve ayarla';
      return null;
    }
    relevant.sort((a, b) => b.value.resolveRate.compareTo(a.value.resolveRate));
    final best = relevant.first;
    final action = best.key.split('__')[1];
    return '$action (${(best.value.resolveRate * 100).round()}% başarı oranı — ${best.value.count} kullanım)';
  }

  void addIntervention(Intervention intervention) {
    interventions.insert(0, intervention);
    final statKey = '${intervention.key}\_\_${intervention.action}';
    if (!actionStats.containsKey(statKey)) actionStats[statKey] = ActionStat();
    actionStats[statKey]!.count++;
    if (intervention.effect == EffectType.resolved) actionStats[statKey]!.resolved++;
    if (intervention.effect == EffectType.improved) actionStats[statKey]!.improved++;
    notifyListeners();
  }

  void markAlarmResponded(String alarmId, Intervention intervention) {
    final index = alarms.indexWhere((a) => a.id == alarmId);
    if (index >= 0) { alarms[index].responded = true; alarms[index].intervention = intervention; }
  }

  void clearOldAlarms() { alarms = alarms.take(10).toList(); notifyListeners(); }

  void toggleSimulation() {
    simRunning = !simRunning;
    if (simRunning) { _simTimer?.cancel(); _simTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) => _simTick()); } 
    else { _simTimer?.cancel(); }
    notifyListeners();
  }

  void _simTick() {
    _simStep++;
    double nemValue;
    if (_simStep % 22 == 0) { nemValue = 5.74 + Random().nextDouble() * 0.06; } 
    else if (_simStep % 38 == 0) { nemValue = 6.32 + Random().nextDouble() * 0.08; } 
    else if (_simStep % 15 == 0 && _simStep % 15 < 8) { nemValue = _norm(5.84, 0.04); } 
    else { nemValue = _norm(5.90, 0.055); }
    process('nem', double.parse(nemValue.toStringAsFixed(3)));

    if (_simStep % 3 == 0) {
      final spike = _simStep % 28 == 0;
      process('uk1', double.parse(_norm(spike ? -0.78 : -0.18, 0.22).toStringAsFixed(3)));
      process('uk2', double.parse(_norm(spike ? -0.82 : -0.19, 0.24).toStringAsFixed(3)));
      process('m1', double.parse(_norm(spike ? -0.82 : -0.42, 0.28).toStringAsFixed(3)));
      process('m2', double.parse(_norm(spike ? -0.85 : -0.45, 0.29).toStringAsFixed(3)));
    }
  }

  double _norm(double mean, double std) {
    double u1 = Random().nextDouble(); double u2 = Random().nextDouble();
    return mean + std * sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  String _formatTimeShort(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  String formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  int get criticalAlarmCount => alarms.where((a) => a.isCritical).length;

  @override void dispose() { _simTimer?.cancel(); super.dispose(); }
}

// ============== ANA SAYFA ==============
class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppProvider _provider;
  final List<String> _tabs = ['Dashboard', 'Nem Analizi', 'Deformasyon', 'Alarmlar', 'Reaksiyonlar'];
  
  // Input controllers
  final TextEditingController _nemController = TextEditingController();
  final TextEditingController _uk1Controller = TextEditingController();
  final TextEditingController _uk2Controller = TextEditingController();
  final TextEditingController _m1Controller = TextEditingController();
  final TextEditingController _m2Controller = TextEditingController();
  
  // Modal controllers
  final TextEditingController _modalOtherController = TextEditingController();
  String? _selectedActionType;
  String? _selectedEffect;
  final TextEditingController _modalOperatorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = AppProvider();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0: _provider.activeTab = 'dashboard'; break;
            case 1: _provider.activeTab = 'nem'; break;
            case 2: _provider.activeTab = 'deform'; break;
            case 3: _provider.activeTab = 'alarms'; break;
            case 4: _provider.activeTab = 'rules'; break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nemController.dispose();
    _uk1Controller.dispose();
    _uk2Controller.dispose();
    _m1Controller.dispose();
    _m2Controller.dispose();
    _modalOtherController.dispose();
    _modalOperatorController.dispose();
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (_provider.criticalAlarmCount > 0) return Colors.red;
    if (_provider.alarms.where((a) => a.type == AlarmType.warn).any((a) => DateTime.now().difference(a.time).inMinutes < 3)) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStatusText() {
    if (_provider.criticalAlarmCount > 0) return '${_provider.criticalAlarmCount} KRİTİK ALARM';
    if (_provider.alarms.where((a) => a.type == AlarmType.warn).any((a) => DateTime.now().difference(a.time).inMinutes < 3)) {
      return 'UYARI VAR';
    }
    return 'SİSTEM NORMAL';
  }

  Color _getCpkColor(StatusType status) {
    switch (status) {
      case StatusType.ok: return Colors.green;
      case StatusType.warn: return Colors.orange;
      case StatusType.danger: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('VitrA SPC - Kalite Kontrol Sistemi')),
        backgroundColor: const Color(0xFF98312A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
        actions: [
          // Simülasyon butonu
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _provider.simRunning ? Colors.amber : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton.icon(
              onPressed: () => setState(() => _provider.toggleSimulation()),
              icon: Icon(
                _provider.simRunning ? Icons.stop : Icons.play_arrow,
                color: _provider.simRunning ? Colors.black : const Color(0xFF98312A),
                size: 18,
              ),
              label: Text(
                _provider.simRunning ? 'DURDUR' : 'SİMÜLASYON',
                style: TextStyle(
                  fontSize: 12,
                  color: _provider.simRunning ? Colors.black : const Color(0xFF98312A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Sistem durumu rozeti
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor()),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _getStatusColor())),
                const SizedBox(width: 6),
                Text(_getStatusText(), style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
          // Bildirim butonu
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _showNotificationDrawer(),
              ),
              if (_provider.criticalAlarmCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(child: Text('${_provider.criticalAlarmCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Sol menü
          _buildDrawer(),
          // Ana içerik
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(),
                _buildNemAnalizi(),
                _buildDeformasyon(),
                _buildAlarmlar(),
                _buildReaksiyonlar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============== DRAWER ==============
  Widget _buildDrawer() {
    return Container(
      width: 220,
      color: Colors.grey.shade50,
      child: Column(
        children: [
          _buildNavItem('Dashboard', Icons.dashboard, 0),
          _buildNavItem('Nem Analizi', Icons.water_drop, 1),
          _buildNavItem('Deformasyon', Icons.straighten, 2),
          _buildNavItem('Alarmlar', Icons.notifications, 3, badge: _provider.criticalAlarmCount),
          _buildNavItem('Reaksiyonlar', Icons.rule, 4),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Parametreler', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...['nem', 'uk1', 'uk2', 'm1', 'm2'].map((key) => _buildParamTile(key)).toList(),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, int index, {int? badge}) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: badge != null && badge > 0
          ? Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11))),
            )
          : null,
      onTap: () => _tabController.animateTo(index),
    );
  }

  Widget _buildParamTile(String key) {
    final param = _provider.parameters[key]!;
    final cpk = param.cpk;
    final lastValue = param.data.isNotEmpty ? param.data.last.value : null;
    final percent = lastValue != null ? ((lastValue - param.lsl) / (param.usl - param.lsl) * 100).clamp(0, 100) : 50.0;

    return InkWell(
      onTap: () => _tabController.animateTo(key == 'nem' ? 1 : 2),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(param.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _getCpkColor(param.cpkStatus).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('Cpk ${cpk != null ? cpk.cpk.toStringAsFixed(2) : '—'}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getCpkColor(param.cpkStatus))),
              ),
            ]),
            const SizedBox(height: 4),
            Container(
              height: 3, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft, widthFactor: percent / 100,
                child: Container(decoration: BoxDecoration(color: _getCpkColor(param.cpkStatus), borderRadius: BorderRadius.circular(2))),
              ),
            ),
            const SizedBox(height: 4),
            Text(lastValue != null ? '${lastValue.toStringAsFixed(3)} ${param.unit}' : 'veri yok', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  void _showNotificationDrawer() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bildirimler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _provider.alarms.length,
                itemBuilder: (context, index) {
                  final alarm = _provider.alarms[index];
                  return Card(
                    color: alarm.type == AlarmType.danger ? Colors.red.shade50 : alarm.type == AlarmType.warn ? Colors.orange.shade50 : null,
                    child: ListTile(
                      leading: Icon(
                        alarm.type == AlarmType.danger ? Icons.error : alarm.type == AlarmType.warn ? Icons.warning : Icons.info,
                        color: alarm.type == AlarmType.danger ? Colors.red : alarm.type == AlarmType.warn ? Colors.orange : Colors.blue,
                      ),
                      title: Text('${alarm.param} - ${alarm.msg}', style: const TextStyle(fontSize: 12)),
                      subtitle: Text('${alarm.action} • ${_provider.formatTime(alarm.time)}', style: const TextStyle(fontSize: 10)),
                      trailing: alarm.type == AlarmType.danger && !alarm.responded
                          ? TextButton(onPressed: () => setState(() => _provider.currentAlarmForModal = alarm), child: const Text('Müdahale'))
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== DASHBOARD ==============
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Satırı
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['nem', 'uk1', 'uk2', 'm1', 'm2'].map((key) => _buildKpiCard(key)).toList(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Nem ve Alarm grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nem kartı
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💧 Nem Kontrol Kartı', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(height: 120, child: _buildIChart('nem')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Son alarmlar
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('🔔 Son Alarmlar', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${_provider.alarms.length} kayıt', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            itemCount: _provider.alarms.take(3).length,
                            itemBuilder: (context, index) {
                              final alarm = _provider.alarms[index];
                              return _buildAlarmTile(alarm);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Deformasyon kartı
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('📐 Deformasyon — 4 Parametre', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('VitrA Tol: +1.0 / −0.7 mm | 60×120 cm', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(height: 140, child: _buildMultiLineChart()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String key) {
    final param = _provider.parameters[key]!;
    final cpk = param.cpk;
    final lastValue = param.data.isNotEmpty ? param.data.last.value : null;
    final outCount = param.data.where((m) => m.value < param.lsl || m.value > param.usl).length;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(param.label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(lastValue != null ? lastValue.toStringAsFixed(3) : '—',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getCpkColor(param.cpkStatus), fontFamily: 'monospace'),
          ),
          const SizedBox(height: 4),
          Text('Cpk: ${cpk != null ? cpk.cpk.toStringAsFixed(2) : '—'} | n=${param.data.length} | dışı: $outCount',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTile(Alarm alarm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: alarm.type == AlarmType.danger ? Colors.red.shade50 : alarm.type == AlarmType.warn ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alarm.type == AlarmType.danger ? Colors.red.shade200 : alarm.type == AlarmType.warn ? Colors.orange.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            alarm.type == AlarmType.danger ? Icons.error : alarm.type == AlarmType.warn ? Icons.warning : Icons.info,
            size: 16,
            color: alarm.type == AlarmType.danger ? Colors.red : alarm.type == AlarmType.warn ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${alarm.param} — ${alarm.msg}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                Text(alarm.action, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Text('${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ============== CHART WIDGETS ==============
  Widget _buildIChart(String key) {
    final param = _provider.parameters[key]!;
    final spc = param.spc;
    if (spc == null || param.data.isEmpty) {
      return const Center(child: Text('Yeterli veri yok'));
    }

    final values = param.data.map((m) => m.value).toList();
    final maxValue = values.reduce(max);
    final minValue = values.reduce(min);
    final range = maxValue - minValue;
    final padding = range * 0.1;

    return CustomPaint(
      painter: _IChartPainter(
        values: values,
        mean: spc.mean,
        ucl: spc.ucl,
        lcl: spc.lcl,
        usl: param.usl,
        lsl: param.lsl,
        minY: minValue - padding,
        maxY: maxValue + padding,
        color: param.color,
      ),
      size: const Size(double.infinity, 120),
    );
  }

  Widget _buildMultiLineChart() {
    final params = ['uk1', 'uk2', 'm1', 'm2'].map((key) => _provider.parameters[key]!).toList();
    if (params.any((p) => p.data.isEmpty)) {
      return const Center(child: Text('Yeterli veri yok'));
    }

    return CustomPaint(
      painter: _MultiLineChartPainter(
        parameters: params,
        usl: 1.0,
        lsl: -0.7,
      ),
      size: const Size(double.infinity, 140),
    );
  }

  // ============== NEM ANALİZİ ==============
  Widget _buildNemAnalizi() {
    final param = _provider.parameters['nem']!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ölçüm giriş kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💧 Nem Ölçümü Gir — Spray Dryer Çıkış', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nemController,
                          decoration: const InputDecoration(
                            labelText: 'Nem (%rH)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final v = double.tryParse(_nemController.text);
                          if (v != null) {
                            setState(() => _provider.process('nem', v));
                            _nemController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF98312A), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                        child: const Text('✓ EKLE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // I-MR Kartları
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bireysel Değer (I) Kartı', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(height: 150, child: _buildIChart('nem')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hareketli Aralık (MR) Kartı', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(height: 150, child: _buildMRChart(param)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // İstatistik ve Reaksiyon
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('İstatistik Özeti', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildNemStatTable(param),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Anlık Reaksiyon Rehberi', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildNemReaction(param),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMRChart(Parameter param) {
    final spc = param.spc;
    if (spc == null || spc.mrs.isEmpty) {
      return const Center(child: Text('Yeterli veri yok'));
    }

    final maxValue = spc.mrs.reduce(max);
    final minValue = 0.0;
    final range = maxValue - minValue;
    final padding = range * 0.1;

    return CustomPaint(
      painter: _MRChartPainter(
        mrs: spc.mrs,
        mrMean: spc.mrMean,
        uclMR: spc.uclMR,
        minY: minValue,
        maxY: maxValue + padding,
      ),
      size: const Size(double.infinity, 150),
    );
  }

  Widget _buildNemStatTable(Parameter param) {
    final spc = param.spc;
    final cpk = param.cpk;
    final outLow = param.data.where((m) => m.value < param.lsl).length;
    final outHigh = param.data.where((m) => m.value > param.usl).length;
    
    if (spc == null) return const Center(child: Text('Yeterli veri yok'));
    
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
      children: [
        _buildStatRow('Ölçüm Sayısı', '${param.data.length}'),
        _buildStatRow('Ortalama (X̄)', '${spc.mean.toStringAsFixed(5)} %rH'),
        _buildStatRow('Set Point', '${param.sp} %rH'),
        _buildStatRow('Std Sapma (σ̂)', '${spc.sigE.toStringAsFixed(5)}'),
        _buildStatRow('UCL (3σ)', '${spc.ucl.toStringAsFixed(4)} %rH'),
        _buildStatRow('LCL (3σ)', '${spc.lcl.toStringAsFixed(4)} %rH'),
        _buildStatRow('UCL(MR)', '${spc.uclMR.toStringAsFixed(4)}'),
        _buildStatRow('Cp', cpk != null ? cpk.cp.toStringAsFixed(3) : '—'),
        _buildStatRow('Cpk', cpk != null ? cpk.cpk.toStringAsFixed(3) : '—'),
        _buildStatRow('Limit Dışı', '$outLow alt / $outHigh üst'),
      ],
    );
  }

  TableRow _buildStatRow(String label, String value) {
    return TableRow(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(label, style: const TextStyle(color: Colors.grey))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
    ]);
  }

  Widget _buildNemReaction(Parameter param) {
    if (param.data.isEmpty) return const Text('Henüz ölçüm yok');
    
    final lastValue = param.data.last.value;
    final violations = param.weViolations;
    
    if (lastValue < param.lsl) {
      return _buildReactionCard(
        title: '❌ ALT LİMİT DIŞI (${lastValue.toStringAsFixed(3)} %rH)',
        steps: [
          _provider.getBestSuggestion('nem', AlarmType.danger) ?? 'Spray sıcaklığını artır',
          '5 dk bekle, ölçümü tekrarla',
        ],
        color: Colors.red,
      );
    } else if (lastValue > param.usl) {
      return _buildReactionCard(
        title: '❌ ÜST LİMİT DIŞI (${lastValue.toStringAsFixed(3)} %rH)',
        steps: ['Spray sıcaklığını düşür', '5 dk bekle'],
        color: Colors.red,
      );
    } else if (violations.isNotEmpty) {
      return _buildReactionCard(
        title: '⚠️ Kural ${violations.join(', ')} İhlali',
        steps: ['Eğilim veya dalgalanma tespit edildi', 'Spray parametrelerini kontrol et'],
        color: Colors.orange,
      );
    } else {
      return _buildReactionCard(
        title: '✅ Normal — Müdahale Gerekmez',
        steps: ['Rutin izlemeye devam et'],
        color: Colors.green,
      );
    }
  }

  Widget _buildReactionCard({required String title, required List<String> steps, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('→', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Expanded(child: Text(step, style: const TextStyle(fontSize: 11))),
            ]),
          )),
        ],
      ),
    );
  }

  // ============== DEFORMASYON ==============
  Widget _buildDeformasyon() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ölçüm giriş kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📐 Deformasyon Ölçümü Gir — 60×120 cm Karo', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(width: 150, child: TextField(controller: _uk1Controller, decoration: const InputDecoration(labelText: 'Uzun Kenar 1 (mm)'), keyboardType: TextInputType.number)),
                      SizedBox(width: 150, child: TextField(controller: _uk2Controller, decoration: const InputDecoration(labelText: 'Uzun Kenar 2 (mm)'), keyboardType: TextInputType.number)),
                      SizedBox(width: 150, child: TextField(controller: _m1Controller, decoration: const InputDecoration(labelText: 'Merkez 1 (mm)'), keyboardType: TextInputType.number)),
                      SizedBox(width: 150, child: TextField(controller: _m2Controller, decoration: const InputDecoration(labelText: 'Merkez 2 (mm)'), keyboardType: TextInputType.number)),
                      ElevatedButton(
                        onPressed: () {
                          final v1 = double.tryParse(_uk1Controller.text);
                          final v2 = double.tryParse(_uk2Controller.text);
                          final v3 = double.tryParse(_m1Controller.text);
                          final v4 = double.tryParse(_m2Controller.text);
                          if (v1 != null) { setState(() => _provider.process('uk1', v1)); _uk1Controller.clear(); }
                          if (v2 != null) { setState(() => _provider.process('uk2', v2)); _uk2Controller.clear(); }
                          if (v3 != null) { setState(() => _provider.process('m1', v3)); _m1Controller.clear(); }
                          if (v4 != null) { setState(() => _provider.process('m2', v4)); _m2Controller.clear(); }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF98312A), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                        child: const Text('✓ EKLE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 4 parametre için kartlar
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: ['uk1', 'uk2', 'm1', 'm2'].map((key) {
              final param = _provider.parameters[key]!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(param.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _getCpkColor(param.cpkStatus), borderRadius: BorderRadius.circular(12)),
                            child: Text('Cpk ${param.cpk != null ? param.cpk!.cpk.toStringAsFixed(2) : '—'}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          if (param.data.isNotEmpty) Text('${param.data.last.value.toStringAsFixed(3)} mm', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                        ]),
                      ]),
                      const SizedBox(height: 8),
                      Expanded(child: _buildIChart(key)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============== ALARMLAR ==============
  Widget _buildAlarmlar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('🔔 Alarm & Müdahale Günlüğü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [Icon(Icons.school, size: 16, color: Colors.blue), SizedBox(width: 4), Text('Öğreniyor', style: TextStyle(fontSize: 11))]),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => setState(() => _provider.clearOldAlarms()), child: const Text('Eski kayıtları temizle')),
                ]),
              ]),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _provider.alarms.length,
                itemBuilder: (context, index) {
                  final alarm = _provider.alarms[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alarm.type == AlarmType.danger ? Colors.red.shade50 : alarm.type == AlarmType.warn ? Colors.orange.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: alarm.type == AlarmType.danger ? Colors.red.shade200 : alarm.type == AlarmType.warn ? Colors.orange.shade200 : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          alarm.type == AlarmType.danger ? Icons.error : alarm.type == AlarmType.warn ? Icons.warning : Icons.info,
                          color: alarm.type == AlarmType.danger ? Colors.red : alarm.type == AlarmType.warn ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${alarm.param} — ${alarm.msg}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(alarm.action, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (alarm.type == AlarmType.danger) const Text('✉️ E-posta bildirim gönderildi', style: TextStyle(fontSize: 11, color: Colors.blue)),
                              if (!alarm.responded && alarm.type == AlarmType.danger)
                                TextButton(onPressed: () => setState(() => _provider.currentAlarmForModal = alarm), child: const Text('+ Müdahale Gir'))
                              else if (alarm.responded)
                                const Text('✓ Müdahale Kaydedildi', style: TextStyle(color: Colors.green, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== REAKSİYONLAR ==============
  Widget _buildReaksiyonlar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚖ Western Electric Kuralları — Durum', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...WesternElectric.rules.map((rule) {
                          final violated = _provider.parameters['nem']!.weViolations.contains(rule.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: violated ? Colors.red.shade50 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: violated ? Colors.red.shade200 : Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(color: violated ? Colors.red.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                    child: Center(child: Text('R${rule.id}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: violated ? Colors.red : Colors.grey.shade600))),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text(rule.desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: violated ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(12)),
                                    child: Text(violated ? 'İHLAL' : 'OK', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📋 Reaksiyon Rehberi — Nem', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildReactionCard(
                          title: '❌ Nem < 5.80 %rH (Alt Limit)',
                          steps: ['Spray Dryer sıcaklığını +2–5°C artır', '5 dk bekle, ölçümü tekrarla', 'Düzelmediyse vardiya şefini bilgilendir', 'Üretim hattını geçici durdur'],
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildReactionCard(
                          title: '❌ Nem > 6.30 %rH (Üst Limit)',
                          steps: ['Spray sıcaklığını −2–5°C düşür', 'Hava debisi ve nem odasını kontrol et', '5 dk bekle, tekrar ölç'],
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildReactionCard(
                          title: '⚠ Eğilim / Kural İhlali',
                          steps: ['Spray parametrelerini kaydet', 'Kayma başlamadan proaktif ayar yap', 'Bir sonraki 3 ölçümü yakından izle'],
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============== CHART PAINTERS ==============
class _IChartPainter extends CustomPainter {
  final List<double> values;
  final double mean;
  final double ucl;
  final double lcl;
  final double usl;
  final double lsl;
  final double minY;
  final double maxY;
  final Color color;

  _IChartPainter({
    required this.values,
    required this.mean,
    required this.ucl,
    required this.lcl,
    required this.usl,
    required this.lsl,
    required this.minY,
    required this.maxY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    
    final xStep = size.width / (values.length - 1);
    final yScale = size.height / (maxY - minY);

    double mapY(double y) => size.height - (y - minY) * yScale;

    // Grid çiz
    paint.color = Colors.grey.shade300;
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Limit çizgileri
    paint.color = Colors.orange;
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    
    // USL
    final uslY = mapY(usl);
    canvas.drawLine(Offset(0, uslY), Offset(size.width, uslY), paint);
    
    // LSL
    final lslY = mapY(lsl);
    canvas.drawLine(Offset(0, lslY), Offset(size.width, lslY), paint);
    
    // UCL
    paint.color = Colors.red;
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    final uclY = mapY(ucl);
    canvas.drawLine(Offset(0, uclY), Offset(size.width, uclY), paint);
    
    // LCL
    final lclY = mapY(lcl);
    canvas.drawLine(Offset(0, lclY), Offset(size.width, lclY), paint);
    
    // Mean
    paint.color = Colors.green;
    final meanY = mapY(mean);
    canvas.drawLine(Offset(0, meanY), Offset(size.width, meanY), paint);

    // Data points
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = i * xStep;
      final y = mapY(values[i]);
      points.add(Offset(x, y));
    }

    // Çizgi
    paint.color = color;
    paint.strokeWidth = 2;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Noktalar
    paint.color = color;
    paint.style = PaintingStyle.fill;
    for (var point in points) {
      canvas.drawCircle(point, 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MRChartPainter extends CustomPainter {
  final List<double> mrs;
  final double mrMean;
  final double uclMR;
  final double minY;
  final double maxY;

  _MRChartPainter({
    required this.mrs,
    required this.mrMean,
    required this.uclMR,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    
    final xStep = size.width / (mrs.length - 1);
    final yScale = size.height / (maxY - minY);

    double mapY(double y) => size.height - (y - minY) * yScale;

    // Grid
    paint.color = Colors.grey.shade300;
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // UCL
    paint.color = Colors.red;
    final uclY = mapY(uclMR);
    canvas.drawLine(Offset(0, uclY), Offset(size.width, uclY), paint);
    
    // MR Mean
    paint.color = Colors.green;
    final meanY = mapY(mrMean);
    canvas.drawLine(Offset(0, meanY), Offset(size.width, meanY), paint);

    // Data points
    final points = <Offset>[];
    for (int i = 0; i < mrs.length; i++) {
      final x = i * xStep;
      final y = mapY(mrs[i]);
      points.add(Offset(x, y));
    }

    // Çizgi
    paint.color = const Color(0xFF6B48C8);
    paint.strokeWidth = 2;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Noktalar
    paint.style = PaintingStyle.fill;
    for (var point in points) {
      canvas.drawCircle(point, 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MultiLineChartPainter extends CustomPainter {
  final List<Parameter> parameters;
  final double usl;
  final double lsl;

  _MultiLineChartPainter({required this.parameters, required this.usl, required this.lsl});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    
    if (parameters.isEmpty || parameters.any((p) => p.data.isEmpty)) return;

    // Tüm değerleri bul
    final allValues = parameters.expand((p) => p.data.map((m) => m.value)).toList();
    final maxY = allValues.reduce(max);
    final minY = allValues.reduce(min);
    final range = maxY - minY;
    final padding = range * 0.1;
    final yMin = minY - padding;
    final yMax = maxY + padding;
    final yScale = size.height / (yMax - yMin);

    double mapY(double y) => size.height - (y - yMin) * yScale;

    // Grid
    paint.color = Colors.grey.shade300;
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Limitler
    paint.color = Colors.orange;
    paint.strokeWidth = 1;
    final uslY = mapY(usl);
    canvas.drawLine(Offset(0, uslY), Offset(size.width, uslY), paint);
    final lslY = mapY(lsl);
    canvas.drawLine(Offset(0, lslY), Offset(size.width, lslY), paint);

    // Her parametre için
    for (var param in parameters) {
      if (param.data.isEmpty) continue;
      
      final values = param.data.map((m) => m.value).toList();
      final xStep = size.width / (values.length - 1);
      
      final points = <Offset>[];
      for (int i = 0; i < values.length; i++) {
        final x = i * xStep;
        final y = mapY(values[i]);
        points.add(Offset(x, y));
      }

      // Çizgi
      paint.color = param.color;
      paint.strokeWidth = 1.5;
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}