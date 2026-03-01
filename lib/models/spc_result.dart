class SpcResult {
  final double mean;
  final double std;
  final double sigE;
  final double mrMean;
  final double ucl;
  final double lcl;
  final double uclMR;
  final List<double> mrs;

  const SpcResult({
    required this.mean,
    required this.std,
    required this.sigE,
    required this.mrMean,
    required this.ucl,
    required this.lcl,
    required this.uclMR,
    required this.mrs,
  });

  @override
  String toString() {
    return 'SpcResult(mean: $mean, sigE: $sigE, ucl: $ucl, lcl: $lcl)';
  }
}