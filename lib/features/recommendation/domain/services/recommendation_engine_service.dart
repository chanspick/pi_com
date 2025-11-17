import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_criteria_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/pc_build_entity.dart';

/// 추천 엔진 서비스 인터페이스
///
/// AI/ML 모델을 활용한 동적 추천 시스템의 핵심
/// 현재는 규칙 기반이지만, 향후 ML 모델로 교체 가능하도록 설계
abstract class RecommendationEngineService {
  /// 사용자 요구사항에 맞는 PC 구성 추천
  ///
  /// [criteria] 사용자 요구사항
  /// [availableParts] 현재 재고가 있는 부품 목록
  /// [topK] 상위 K개 추천 (기본값: 3)
  ///
  /// Returns: 추천 PC 구성 목록 (점수 높은 순)
  Future<List<PcBuildEntity>> recommendBuilds({
    required RecommendationCriteriaEntity criteria,
    required Map<String, List<BasePart>> availableParts,
    int topK = 3,
  });

  /// 특정 부품에 대한 점수 계산
  ///
  /// [part] 평가할 부품
  /// [criteria] 사용자 요구사항
  /// [currentBuild] 현재 선택된 부품들
  ///
  /// Returns: 점수 (0.0 ~ 1.0)
  double scorePartForCriteria({
    required BasePart part,
    required RecommendationCriteriaEntity criteria,
    Map<String, BasePart>? currentBuild,
  });

  /// PC 구성의 호환성 체크
  ///
  /// Returns: (호환 여부, 비호환 이유)
  ({bool isCompatible, String? reason}) checkCompatibility({
    required PcBuildEntity build,
  });

  /// PC 구성의 성능 점수 계산
  ///
  /// Returns: 성능 점수 (0.0 ~ 1.0)
  double calculatePerformanceScore({
    required PcBuildEntity build,
    required RecommendationCriteriaEntity criteria,
  });

  /// PC 구성의 가성비 점수 계산
  ///
  /// Returns: 가성비 점수 (0.0 ~ 1.0)
  double calculateValueScore({
    required PcBuildEntity build,
    required RecommendationCriteriaEntity criteria,
  });
}
