typedef RuleFunction = bool Function(List<double> values, double mean, double sigma);

class WesternElectricRule {
  final int id;
  final String name;
  final String description;
  final RuleFunction check;

  const WesternElectricRule({
    required this.id,
    required this.name,
    required this.description,
    required this.check,
  });

  @override
  String toString() => 'Rule $id: $name';
}

class WesternElectricRules {
  static const List<WesternElectricRule> all = [
    WesternElectricRule(
      id: 1,
      name: 'Tek Nokta 3σ Dışı',
      description: '1 nokta kontrol limitinin dışında',
      check: _rule1,
    ),
    WesternElectricRule(
      id: 2,
      name: '2/3 Kuralı — 2σ',
      description: '3\'ten 2 nokta aynı tarafta >2σ',
      check: _rule2,
    ),
    WesternElectricRule(
      id: 3,
      name: '4/5 Kuralı — 1σ',
      description: '5\'ten 4 nokta aynı tarafta >1σ',
      check: _rule3,
    ),
    WesternElectricRule(
      id: 4,
      name: 'Eğilim (8 Nokta)',
      description: '8 ardışık nokta aynı tarafta',
      check: _rule4,
    ),
    WesternElectricRule(
      id: 5,
      name: 'Merkez Kaçışı',
      description: '8 nokta ortadan >1σ uzakta',
      check: _rule5,
    ),
    WesternElectricRule(
      id: 6,
      name: 'Tabakalaşma',
      description: '15 nokta ±1σ içinde',
      check: _rule6,
    ),
    WesternElectricRule(
      id: 7,
      name: 'Zikzak',
      description: '14 ardışık nokta dönüşümlü',
      check: _rule7,
    ),
    WesternElectricRule(
      id: 8,
      name: 'Karma Örüntü',
      description: '8 nokta ±1σ dışında',
      check: _rule8,
    ),
  ];

  static bool _rule1(List<double> values, double mean, double sigma) {
    if (values.isEmpty) return false;
    final last = values.last;
    return last > mean + 3 * sigma || last < mean - 3 * sigma;
  }

  static bool _rule2(List<double> values, double mean, double sigma) {
    if (values.length < 3) return false;
    final last3 = values.sublist(values.length - 3);
    return last3.where((x) => x > mean + 2 * sigma).length >= 2 ||
           last3.where((x) => x < mean - 2 * sigma).length >= 2;
  }

  static bool _rule3(List<double> values, double mean, double sigma) {
    if (values.length < 5) return false;
    final last5 = values.sublist(values.length - 5);
    return last5.where((x) => x > mean + sigma).length >= 4 ||
           last5.where((x) => x < mean - sigma).length >= 4;
  }

  static bool _rule4(List<double> values, double mean, double sigma) {
    if (values.length < 8) return false;
    final last8 = values.sublist(values.length - 8);
    return last8.every((x) => x > mean) || last8.every((x) => x < mean);
  }

  static bool _rule5(List<double> values, double mean, double sigma) {
    if (values.length < 8) return false;
    final last8 = values.sublist(values.length - 8);
    return last8.every((x) => (x - mean).abs() > sigma);
  }

  static bool _rule6(List<double> values, double mean, double sigma) {
    if (values.length < 15) return false;
    final last15 = values.sublist(values.length - 15);
    return last15.every((x) => (x - mean).abs() < sigma);
  }

  static bool _rule7(List<double> values, double mean, double sigma) {
    if (values.length < 14) return false;
    final last14 = values.sublist(values.length - 14);
    int count = 0;
    for (int i = 1; i < last14.length - 1; i++) {
      if ((last14[i] > last14[i - 1] && last14[i] > last14[i + 1]) ||
          (last14[i] < last14[i - 1] && last14[i] < last14[i + 1])) {
        count++;
      }
    }
    return count >= 8;
  }

  static bool _rule8(List<double> values, double mean, double sigma) {
    if (values.length < 8) return false;
    final last8 = values.sublist(values.length - 8);
    return last8.every((x) => (x - mean).abs() > sigma);
  }
}