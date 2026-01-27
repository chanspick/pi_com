/// 스코어 계산 서비스
/// 벤치마크 → 스코어 → 등급 → 기본 AS 기간 계산
library;

import '../../../warranty/data/models/verification_transaction_model.dart';

/// 벤치마크 설정
class BenchmarkConfig {
  final int maxScore;   // 100점 기준
  final int minScore;   // 50점 기준
  final String unit;

  const BenchmarkConfig({
    required this.maxScore,
    required this.minScore,
    required this.unit,
  });
}

/// 카테고리별 벤치마크 기준
const Map<String, BenchmarkConfig> benchmarkConfigs = {
  'cpu': BenchmarkConfig(maxScore: 40000, minScore: 10000, unit: 'PassMark'),
  'gpu': BenchmarkConfig(maxScore: 20000, minScore: 5000, unit: '3DMark'),
  'storage': BenchmarkConfig(maxScore: 7000, minScore: 500, unit: 'MB/s'),
  'memory': BenchmarkConfig(maxScore: 50000, minScore: 20000, unit: 'MB/s'),
};

/// 등급별 설정
class GradeConfig {
  final int min;
  final int max;
  final int baseWarrantyMonths;
  final String label;

  const GradeConfig({
    required this.min,
    required this.max,
    required this.baseWarrantyMonths,
    required this.label,
  });
}

const Map<ConditionGrade, GradeConfig> gradeConfigs = {
  ConditionGrade.S: GradeConfig(min: 90, max: 100, baseWarrantyMonths: 24, label: '최상급'),
  ConditionGrade.A: GradeConfig(min: 80, max: 89, baseWarrantyMonths: 18, label: '우수'),
  ConditionGrade.B: GradeConfig(min: 70, max: 79, baseWarrantyMonths: 12, label: '양호'),
  ConditionGrade.C: GradeConfig(min: 60, max: 69, baseWarrantyMonths: 6, label: '보통'),
  ConditionGrade.D: GradeConfig(min: 0, max: 59, baseWarrantyMonths: 3, label: '불량'),
};

/// 스코어 계산 결과
class ScoreCalculationResult {
  final int conditionScore;
  final ConditionGrade conditionGrade;
  final int baseWarrantyMonths;
  final String gradeLabel;
  final BenchmarkScores? benchmarkScores;

  ScoreCalculationResult({
    required this.conditionScore,
    required this.conditionGrade,
    required this.baseWarrantyMonths,
    required this.gradeLabel,
    this.benchmarkScores,
  });
}

class ScoreCalculator {
  /// 벤치마크 점수 → 0-100 스코어 변환
  static int benchmarkToScore(String category, int benchmarkScore) {
    final config = benchmarkConfigs[category.toLowerCase()];
    if (config == null) return 50;

    if (benchmarkScore >= config.maxScore) return 100;
    if (benchmarkScore <= config.minScore) {
      return (benchmarkScore / config.minScore * 50).round().clamp(0, 50);
    }

    final ratio = (benchmarkScore - config.minScore) /
                  (config.maxScore - config.minScore);
    return (50 + ratio * 50).round();
  }

  /// 벤치마크 점수들로 종합 스코어 계산
  static int calculateOverallScore(BenchmarkScores benchmarks) {
    const weights = {
      'cpu': 0.35,
      'gpu': 0.35,
      'storage': 0.15,
      'memory': 0.15,
    };

    double totalWeight = 0;
    double weightedSum = 0;

    if (benchmarks.cpu != null) {
      final score = benchmarkToScore('cpu', benchmarks.cpu!);
      weightedSum += score * weights['cpu']!;
      totalWeight += weights['cpu']!;
    }

    if (benchmarks.gpu != null) {
      final score = benchmarkToScore('gpu', benchmarks.gpu!);
      weightedSum += score * weights['gpu']!;
      totalWeight += weights['gpu']!;
    }

    if (benchmarks.storage != null) {
      final score = benchmarkToScore('storage', benchmarks.storage!);
      weightedSum += score * weights['storage']!;
      totalWeight += weights['storage']!;
    }

    if (benchmarks.memory != null) {
      final score = benchmarkToScore('memory', benchmarks.memory!);
      weightedSum += score * weights['memory']!;
      totalWeight += weights['memory']!;
    }

    if (totalWeight == 0) return 50;
    return (weightedSum / totalWeight).round();
  }

  /// 스코어로 등급 결정
  static ConditionGrade determineGrade(int conditionScore) {
    if (conditionScore >= 90) return ConditionGrade.S;
    if (conditionScore >= 80) return ConditionGrade.A;
    if (conditionScore >= 70) return ConditionGrade.B;
    if (conditionScore >= 60) return ConditionGrade.C;
    return ConditionGrade.D;
  }

  /// 등급으로 기본 AS 기간 결정
  static int getBaseWarrantyMonths(ConditionGrade grade) {
    return gradeConfigs[grade]!.baseWarrantyMonths;
  }

  /// 벤치마크로 모든 정보 계산
  static ScoreCalculationResult calculateFromBenchmarks(BenchmarkScores benchmarks) {
    final conditionScore = calculateOverallScore(benchmarks);
    final conditionGrade = determineGrade(conditionScore);
    final baseWarrantyMonths = getBaseWarrantyMonths(conditionGrade);
    final gradeLabel = gradeConfigs[conditionGrade]!.label;

    return ScoreCalculationResult(
      conditionScore: conditionScore,
      conditionGrade: conditionGrade,
      baseWarrantyMonths: baseWarrantyMonths,
      gradeLabel: gradeLabel,
      benchmarkScores: BenchmarkScores(
        cpu: benchmarks.cpu,
        gpu: benchmarks.gpu,
        storage: benchmarks.storage,
        memory: benchmarks.memory,
        overall: conditionScore,
      ),
    );
  }

  /// 풀세트 아이템들로 종합 스코어 계산
  static ScoreCalculationResult calculateFromBundle(
    List<TransactionItem> items, {
    BenchmarkScores? benchmarks,
  }) {
    // 벤치마크가 있으면 벤치마크 기반 계산
    if (benchmarks != null &&
        (benchmarks.cpu != null || benchmarks.gpu != null)) {
      return calculateFromBenchmarks(benchmarks);
    }

    // 없으면 부품 개별 스코어 평균
    if (items.isEmpty) {
      return ScoreCalculationResult(
        conditionScore: 50,
        conditionGrade: ConditionGrade.B,
        baseWarrantyMonths: 12,
        gradeLabel: '양호',
      );
    }

    // 카테고리별 가중치
    const categoryWeights = {
      'cpu': 0.30,
      'gpu': 0.30,
      'ram': 0.10,
      'memory': 0.10,
      'storage': 0.10,
      'ssd': 0.10,
      'mainboard': 0.10,
      'motherboard': 0.10,
      'psu': 0.05,
      'power': 0.05,
      'case': 0.03,
      'cooler': 0.05,
    };

    double totalWeight = 0;
    double weightedSum = 0;

    for (final item in items) {
      final category = item.partCategory.toLowerCase();
      final weight = categoryWeights[category] ?? 0.05;
      final score = item.conditionScore;

      weightedSum += score * weight;
      totalWeight += weight;
    }

    final conditionScore = totalWeight > 0
        ? (weightedSum / totalWeight).round()
        : 50;
    final conditionGrade = determineGrade(conditionScore);
    final baseWarrantyMonths = getBaseWarrantyMonths(conditionGrade);
    final gradeLabel = gradeConfigs[conditionGrade]!.label;

    return ScoreCalculationResult(
      conditionScore: conditionScore,
      conditionGrade: conditionGrade,
      baseWarrantyMonths: baseWarrantyMonths,
      gradeLabel: gradeLabel,
    );
  }

  /// 단일 부품 스코어 계산
  static ScoreCalculationResult calculateSinglePartScore(
    String partCategory, {
    int? benchmarkScore,
    int? manualScore,
  }) {
    int conditionScore;

    if (benchmarkScore != null) {
      conditionScore = benchmarkToScore(partCategory, benchmarkScore);
    } else if (manualScore != null) {
      conditionScore = manualScore.clamp(0, 100);
    } else {
      conditionScore = 50;
    }

    final conditionGrade = determineGrade(conditionScore);
    final baseWarrantyMonths = getBaseWarrantyMonths(conditionGrade);
    final gradeLabel = gradeConfigs[conditionGrade]!.label;

    return ScoreCalculationResult(
      conditionScore: conditionScore,
      conditionGrade: conditionGrade,
      baseWarrantyMonths: baseWarrantyMonths,
      gradeLabel: gradeLabel,
    );
  }

  /// 마진율 계산
  static double calculateProfitMargin(int purchaseCost, int salePrice) {
    if (salePrice <= 0) return 0;
    return ((salePrice - purchaseCost) / salePrice * 100);
  }

  /// 총 매입원가 계산 (풀세트)
  static int calculateTotalPurchaseCost(List<TransactionItem> items) {
    return items.fold(0, (sum, item) => sum + item.purchaseCost);
  }
}
