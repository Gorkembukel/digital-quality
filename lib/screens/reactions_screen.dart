import 'package:dashbord/cards/reaction_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/western_electric_rule.dart';


class ReactionsScreen extends StatelessWidget {
  const ReactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildWesternElectricRules(provider),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReactionGuides(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWesternElectricRules(AppProvider provider) {
    final nemParam = provider.parameters['nem'];
    final violations = nemParam?.weViolations ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚖ Western Electric Kuralları — Durum',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...WesternElectricRules.all.map((rule) {
              final isViolated = violations.contains(rule.id);
              return _buildRuleTile(rule, isViolated);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTile(WesternElectricRule rule, bool isViolated) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isViolated ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isViolated ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isViolated ? Colors.red.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'R${rule.id}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isViolated ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  rule.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isViolated ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isViolated ? 'İHLAL' : 'OK',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionGuides(AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Reaksiyon Rehberi — Nem',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ReactionCard.danger(
              title: '❌ Nem < 5.80 %rH (Alt Limit)',
              steps: const [
                'Spray Dryer sıcaklığını +2–5°C artır',
                '5 dk bekle, ölçümü tekrarla',
                'Düzelmediyse vardiya şefini bilgilendir',
                'Üretim hattını geçici durdur',
              ],
            ),
            const SizedBox(height: 12),
            ReactionCard.danger(
              title: '❌ Nem > 6.30 %rH (Üst Limit)',
              steps: const [
                'Spray sıcaklığını −2–5°C düşür',
                'Hava debisi ve nem odasını kontrol et',
                '5 dk bekle, tekrar ölç',
              ],
            ),
            const SizedBox(height: 12),
            ReactionCard.warn(
              title: '⚠ Eğilim / Kural İhlali',
              steps: const [
                'Spray parametrelerini kaydet',
                'Kayma başlamadan proaktif ayar yap',
                'Bir sonraki 3 ölçümü yakından izle',
              ],
            ),
            const SizedBox(height: 12),
            ReactionCard.ok(
              title: '✅ Normal Çalışma',
              steps: const [
                'Rutin kontrollere devam et',
                'Her 30 dakikada bir ölçüm al',
                'Parametreleri kaydet',
              ],
            ),
          ],
        ),
      ),
    );
  }
}