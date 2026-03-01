import 'package:dashbord/cards/alarm_tile.dart';
import 'package:dashbord/util/constant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/alarm.dart';
import '../models/intervention.dart';
import '../models/enums.dart';


class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  String? _selectedActionType;
  String? _selectedEffect;
  final TextEditingController _modalOtherController = TextEditingController();
  final TextEditingController _modalOperatorController = TextEditingController();

  @override
  void dispose() {
    _modalOtherController.dispose();
    _modalOperatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            _buildAlarmList(provider),
            if (provider.currentAlarmForModal != null)
              _buildInterventionModal(provider),
          ],
        );
      },
    );
  }

  Widget _buildAlarmList(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              const SizedBox(height: 16),
              if (provider.alarms.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Henüz alarm kaydı yok'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = provider.alarms[index];
                    return AlarmTile(
                      alarm: alarm,
                      provider: provider,
                      showResponseButton: true,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '🔔 Alarm & Müdahale Günlüğü',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('Öğreniyor', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: provider.alarms.length > 10
                  ? () => provider.clearOldAlarms()
                  : null,
              child: const Text('Eski kayıtları temizle'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterventionModal(AppProvider provider) {
    final alarm = provider.currentAlarmForModal!;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => provider.setCurrentAlarmForModal(null),
          child: Container(color: Colors.black54),
        ),
        Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModalHeader(provider),
                    const SizedBox(height: 16),
                    _buildModalAlarmInfo(alarm),
                    const SizedBox(height: 12),
                    _buildModalSuggestedAction(provider, alarm),
                    const SizedBox(height: 16),
                    _buildModalForm(provider, alarm),
                    const SizedBox(height: 16),
                    _buildModalActions(provider, alarm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModalHeader(AppProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '✅ Müdahale Kaydı Gir',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => provider.setCurrentAlarmForModal(null),
        ),
      ],
    );
  }

  Widget _buildModalAlarmInfo(Alarm alarm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text('${alarm.parameterName}: ${alarm.message}'),
    );
  }

  Widget _buildModalSuggestedAction(AppProvider provider, Alarm alarm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Önerilen Aksiyon',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            provider.getBestSuggestion(alarm.parameterKey, alarm.type) ??
                alarm.suggestedAction,
          ),
        ),
      ],
    );
  }

  Widget _buildModalForm(AppProvider provider, Alarm alarm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yaptığınız Müdahale',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedActionType,
          hint: const Text('Müdahale türünü seçin...'),
          items: const [
            DropdownMenuItem(
              value: 'Spray sıcaklığı artırıldı',
              child: Text('Spray sıcaklığı artırıldı'),
            ),
            DropdownMenuItem(
              value: 'Spray sıcaklığı düşürüldü',
              child: Text('Spray sıcaklığı düşürüldü'),
            ),
            DropdownMenuItem(
              value: 'Fırın profili ayarlandı',
              child: Text('Fırın profili ayarlandı'),
            ),
            DropdownMenuItem(
              value: 'Pres basıncı değiştirildi',
              child: Text('Pres basıncı değiştirildi'),
            ),
            DropdownMenuItem(
              value: 'Üretim durduruldu',
              child: Text('Üretim durduruldu'),
            ),
            DropdownMenuItem(
              value: 'Malzeme değiştirildi',
              child: Text('Malzeme değiştirildi'),
            ),
            DropdownMenuItem(
              value: 'İzlemeye devam edildi',
              child: Text('İzlemeye devam edildi'),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Text('Diğer (açıkla)'),
            ),
          ],
          onChanged: (value) => setState(() => _selectedActionType = value),
        ),
        if (_selectedActionType == 'other') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _modalOtherController,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Etki',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedEffect,
          hint: const Text('Seçin...'),
          items: const [
            DropdownMenuItem(
              value: 'resolved',
              child: Text('✅ Düzeldi — değer limite girdi'),
            ),
            DropdownMenuItem(
              value: 'improved',
              child: Text('↗ İyileşti ama henüz limitte değil'),
            ),
            DropdownMenuItem(
              value: 'nochange',
              child: Text('— Değişmedi'),
            ),
            DropdownMenuItem(
              value: 'worsened',
              child: Text('↘ Daha da kötüleşti'),
            ),
          ],
          onChanged: (value) => setState(() => _selectedEffect = value),
        ),
        const SizedBox(height: 12),
        const Text(
          'Operatör Adı',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _modalOperatorController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildModalActions(AppProvider provider, Alarm alarm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            provider.setCurrentAlarmForModal(null);
            _resetModalFields();
          },
          child: const Text('İptal'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _submitIntervention(provider, alarm),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.vitraRed,
          ),
          child: const Text('💾 Kaydet & Sistemi Öğret'),
        ),
      ],
    );
  }

  void _resetModalFields() {
    setState(() {
      _selectedActionType = null;
      _selectedEffect = null;
      _modalOtherController.clear();
      _modalOperatorController.clear();
    });
  }

  void _submitIntervention(AppProvider provider, Alarm alarm) {
    if (_selectedActionType == null || _selectedEffect == null) return;

    final action = _selectedActionType == 'other'
        ? _modalOtherController.text
        : _selectedActionType!;

    EffectType effect;
    switch (_selectedEffect) {
      case 'resolved':
        effect = EffectType.resolved;
        break;
      case 'improved':
        effect = EffectType.improved;
        break;
      case 'nochange':
        effect = EffectType.nochange;
        break;
      case 'worsened':
        effect = EffectType.worsened;
        break;
      default:
        effect = EffectType.nochange;
    }

    final intervention = Intervention(
      action: action,
      effect: effect,
      operatorName: _modalOperatorController.text.isEmpty
          ? 'Anonim'
          : _modalOperatorController.text,
      timestamp: DateTime.now(),
      parameterName: alarm.parameterName,
      problem: alarm.message,
      alarmType: alarm.type.toString(),
      parameterKey: alarm.parameterKey,
    );

    provider.addIntervention(intervention);
    provider.markAlarmResponded(alarm.id, intervention);
    provider.setCurrentAlarmForModal(null);
    
    _resetModalFields();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Müdahale kaydedildi'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}