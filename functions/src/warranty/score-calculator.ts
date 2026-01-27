/**
 * Score Calculator Service
 * 벤치마크 → 스코어 → 등급 → 기본 AS 기간 계산
 */

import {
  BenchmarkScores,
  ConditionGrade,
  TransactionItem,
  GRADE_THRESHOLDS,
  BENCHMARK_CONFIG,
  GradeConfig,
} from "./types";

// ============================================================================
// 벤치마크 → 스코어 변환
// ============================================================================

/**
 * 개별 벤치마크 점수를 0-100 점수로 변환
 * @param category 부품 카테고리 (cpu, gpu, storage, memory)
 * @param benchmarkScore 벤치마크 점수
 * @returns 0-100 스코어
 */
export function benchmarkToScore(category: string, benchmarkScore: number): number {
  const config = BENCHMARK_CONFIG[category.toLowerCase()];
  if (!config) {
    // 알 수 없는 카테고리는 50점 기본값
    return 50;
  }

  // 선형 보간법으로 점수 계산
  // minScore -> 50점, maxScore -> 100점
  const { maxScore, minScore } = config;

  if (benchmarkScore >= maxScore) {
    return 100;
  }

  if (benchmarkScore <= minScore) {
    // minScore 이하면 비례 계산 (0-50 범위)
    return Math.max(0, Math.round((benchmarkScore / minScore) * 50));
  }

  // minScore ~ maxScore 사이는 50-100 범위
  const ratio = (benchmarkScore - minScore) / (maxScore - minScore);
  return Math.round(50 + ratio * 50);
}

/**
 * 벤치마크 점수 객체로부터 종합 스코어 계산
 * @param benchmarks 벤치마크 점수 객체
 * @returns 종합 스코어 (0-100)
 */
export function calculateOverallScore(benchmarks: BenchmarkScores): number {
  const scores: number[] = [];
  const weights: Record<string, number> = {
    cpu: 0.35,      // CPU 비중 35%
    gpu: 0.35,      // GPU 비중 35%
    storage: 0.15,  // 스토리지 비중 15%
    memory: 0.15,   // 메모리 비중 15%
  };

  let totalWeight = 0;
  let weightedSum = 0;

  if (benchmarks.cpu !== undefined) {
    const score = benchmarkToScore("cpu", benchmarks.cpu);
    weightedSum += score * weights.cpu;
    totalWeight += weights.cpu;
    scores.push(score);
  }

  if (benchmarks.gpu !== undefined) {
    const score = benchmarkToScore("gpu", benchmarks.gpu);
    weightedSum += score * weights.gpu;
    totalWeight += weights.gpu;
    scores.push(score);
  }

  if (benchmarks.storage !== undefined) {
    const score = benchmarkToScore("storage", benchmarks.storage);
    weightedSum += score * weights.storage;
    totalWeight += weights.storage;
    scores.push(score);
  }

  if (benchmarks.memory !== undefined) {
    const score = benchmarkToScore("memory", benchmarks.memory);
    weightedSum += score * weights.memory;
    totalWeight += weights.memory;
    scores.push(score);
  }

  // 입력된 벤치마크가 없으면 기본값 50
  if (totalWeight === 0) {
    return 50;
  }

  // 가중 평균 계산
  return Math.round(weightedSum / totalWeight);
}

// ============================================================================
// 스코어 → 등급 결정
// ============================================================================

/**
 * 스코어로 등급 결정
 * @param conditionScore 1-100 스코어
 * @returns 등급 (S/A/B/C/D)
 */
export function determineGrade(conditionScore: number): ConditionGrade {
  if (conditionScore >= GRADE_THRESHOLDS.S.min) return "S";
  if (conditionScore >= GRADE_THRESHOLDS.A.min) return "A";
  if (conditionScore >= GRADE_THRESHOLDS.B.min) return "B";
  if (conditionScore >= GRADE_THRESHOLDS.C.min) return "C";
  return "D";
}

/**
 * 등급 정보 조회
 * @param grade 등급
 * @returns 등급 설정 정보
 */
export function getGradeConfig(grade: ConditionGrade): GradeConfig {
  return GRADE_THRESHOLDS[grade];
}

// ============================================================================
// 등급 → 기본 AS 기간 결정
// ============================================================================

/**
 * 등급 기반 기본 AS 기간 결정
 * @param grade 등급
 * @returns 기본 AS 기간 (개월)
 */
export function getBaseWarrantyMonths(grade: ConditionGrade): number {
  return GRADE_THRESHOLDS[grade].baseWarrantyMonths;
}

/**
 * 스코어로 바로 기본 AS 기간 결정
 * @param conditionScore 1-100 스코어
 * @returns 기본 AS 기간 (개월)
 */
export function calculateBaseWarrantyMonths(conditionScore: number): number {
  const grade = determineGrade(conditionScore);
  return getBaseWarrantyMonths(grade);
}

// ============================================================================
// 풀세트 종합 스코어 계산
// ============================================================================

/**
 * 풀세트 아이템들의 종합 스코어 계산
 * @param items 풀세트 부품 목록
 * @returns 종합 스코어 (0-100)
 */
export function calculateBundleScore(items: TransactionItem[]): number {
  if (!items || items.length === 0) {
    return 50;
  }

  // 부품 카테고리별 가중치
  const categoryWeights: Record<string, number> = {
    cpu: 0.30,
    gpu: 0.30,
    ram: 0.10,
    memory: 0.10,
    storage: 0.10,
    ssd: 0.10,
    hdd: 0.05,
    mainboard: 0.10,
    motherboard: 0.10,
    psu: 0.05,
    power: 0.05,
    case: 0.03,
    cooler: 0.05,
    // 기타 부품은 0.05
  };

  let totalWeight = 0;
  let weightedSum = 0;

  for (const item of items) {
    const category = item.partCategory.toLowerCase();
    const weight = categoryWeights[category] || 0.05;
    const score = item.conditionScore || 50;

    weightedSum += score * weight;
    totalWeight += weight;
  }

  if (totalWeight === 0) {
    return 50;
  }

  return Math.round(weightedSum / totalWeight);
}

// ============================================================================
// 통합 계산 함수
// ============================================================================

export interface ScoreCalculationResult {
  conditionScore: number;
  conditionGrade: ConditionGrade;
  baseWarrantyMonths: number;
  gradeLabel: string;
  gradeLabelKo: string;
  benchmarkScores?: BenchmarkScores;
}

/**
 * 벤치마크 점수로 모든 정보 계산
 * @param benchmarks 벤치마크 점수 객체
 * @returns 계산 결과 (스코어, 등급, 기본 AS 기간)
 */
export function calculateFromBenchmarks(benchmarks: BenchmarkScores): ScoreCalculationResult {
  const conditionScore = calculateOverallScore(benchmarks);
  const conditionGrade = determineGrade(conditionScore);
  const baseWarrantyMonths = getBaseWarrantyMonths(conditionGrade);
  const gradeConfig = getGradeConfig(conditionGrade);

  return {
    conditionScore,
    conditionGrade,
    baseWarrantyMonths,
    gradeLabel: gradeConfig.label,
    gradeLabelKo: gradeConfig.labelKo,
    benchmarkScores: {
      ...benchmarks,
      overall: conditionScore,
    },
  };
}

/**
 * 풀세트 부품들로 모든 정보 계산
 * @param items 풀세트 부품 목록
 * @param benchmarks 추가 벤치마크 점수 (선택)
 * @returns 계산 결과
 */
export function calculateFromBundle(
  items: TransactionItem[],
  benchmarks?: BenchmarkScores
): ScoreCalculationResult {
  // 벤치마크가 있으면 벤치마크 기반 계산
  if (benchmarks && Object.keys(benchmarks).length > 0) {
    return calculateFromBenchmarks(benchmarks);
  }

  // 없으면 부품 개별 스코어 평균으로 계산
  const conditionScore = calculateBundleScore(items);
  const conditionGrade = determineGrade(conditionScore);
  const baseWarrantyMonths = getBaseWarrantyMonths(conditionGrade);
  const gradeConfig = getGradeConfig(conditionGrade);

  return {
    conditionScore,
    conditionGrade,
    baseWarrantyMonths,
    gradeLabel: gradeConfig.label,
    gradeLabelKo: gradeConfig.labelKo,
  };
}

/**
 * 단일 부품 스코어 계산
 * @param partCategory 부품 카테고리
 * @param benchmarkScore 벤치마크 점수
 * @param manualScore 수동 입력 스코어 (선택, 1-100)
 * @returns 계산 결과
 */
export function calculateSinglePartScore(
  partCategory: string,
  benchmarkScore?: number,
  manualScore?: number
): ScoreCalculationResult {
  let conditionScore: number;

  if (benchmarkScore !== undefined) {
    conditionScore = benchmarkToScore(partCategory, benchmarkScore);
  } else if (manualScore !== undefined) {
    // 수동 입력 스코어 사용 (1-100 범위로 클램프)
    conditionScore = Math.max(0, Math.min(100, manualScore));
  } else {
    // 기본값 50
    conditionScore = 50;
  }

  const conditionGrade = determineGrade(conditionScore);
  const baseWarrantyMonths = getBaseWarrantyMonths(conditionGrade);
  const gradeConfig = getGradeConfig(conditionGrade);

  return {
    conditionScore,
    conditionGrade,
    baseWarrantyMonths,
    gradeLabel: gradeConfig.label,
    gradeLabelKo: gradeConfig.labelKo,
  };
}

// ============================================================================
// 마진 계산 헬퍼
// ============================================================================

/**
 * 마진율 계산
 * @param purchaseCost 매입원가
 * @param salePrice 판매가
 * @returns 마진율 (0-100%)
 */
export function calculateProfitMargin(purchaseCost: number, salePrice: number): number {
  if (salePrice <= 0) return 0;
  return Math.round(((salePrice - purchaseCost) / salePrice) * 100 * 10) / 10;
}

/**
 * 총 매입원가 계산 (풀세트)
 * @param items 풀세트 부품 목록
 * @returns 총 매입원가
 */
export function calculateTotalPurchaseCost(items: TransactionItem[]): number {
  return items.reduce((sum, item) => sum + (item.purchaseCost || 0), 0);
}
