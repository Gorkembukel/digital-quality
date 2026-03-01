import 'package:dashbord/models/enums.dart';

class CpkResult {
  final double cp;
  final double cpk;

  const CpkResult({
    required this.cp,
    required this.cpk,
  });

  StatusType get status {
    if (cpk >= 1.33) return StatusType.ok;
    if (cpk >= 1.0) return StatusType.warn;
    return StatusType.danger;
  }

  @override
  String toString() => 'CpkResult(cp: $cp, cpk: $cpk)';
}