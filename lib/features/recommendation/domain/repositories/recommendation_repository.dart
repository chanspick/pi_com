import 'package:pi_com/features/recommendation/domain/entities/spec_profile_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/pc_build_entity.dart';

/// 추천 Repository 인터페이스
abstract class RecommendationRepository {
  /// [Phase 1] 사용자 답변을 기반으로 추천 견적을 가져옵니다 (정적 JSON 기반)
  ///
  /// [userAnswers] 사용자의 질문 답변 맵
  ///
  /// Returns: SpecProfileEntity와 RecommendationEntity를 포함한 추천 결과
  ///
  /// Throws:
  /// - Exception: 추천 견적을 찾지 못한 경우
  /// - Exception: 비현실적인 조합인 경우
  Future<({SpecProfileEntity profile, RecommendationEntity recommendation})> getRecommendation({
    required Map<String, dynamic> userAnswers,
  });

  /// [Phase 2] 사용자 답변을 기반으로 동적 추천을 가져옵니다 (실시간 재고 기반)
  ///
  /// [userAnswers] 사용자의 질문 답변 맵
  /// [topK] 추천할 PC 구성 개수 (기본값: 3)
  ///
  /// Returns: 추천 PC 구성 목록 (저가형, 중급형, 고급형)
  ///
  /// Throws:
  /// - Exception: 재고가 부족한 경우
  /// - Exception: 비현실적인 조합인 경우
  Future<List<PcBuildEntity>> getDynamicRecommendations({
    required Map<String, dynamic> userAnswers,
    int topK = 3,
  });
}
