import 'package:pi_com/features/recommendation/domain/entities/spec_profile_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_entity.dart';
import 'package:pi_com/features/recommendation/domain/repositories/recommendation_repository.dart';

/// 추천 견적 가져오기 Use Case
class GetRecommendationUseCase {
  final RecommendationRepository _repository;

  GetRecommendationUseCase({
    required RecommendationRepository repository,
  }) : _repository = repository;

  /// 사용자 답변을 기반으로 추천 견적을 가져옵니다
  ///
  /// [userAnswers] 사용자의 질문 답변 맵
  ///
  /// Returns: SpecProfileEntity와 RecommendationEntity를 포함한 추천 결과
  ///
  /// Throws:
  /// - Exception: 추천 견적을 찾지 못한 경우
  /// - Exception: 비현실적인 조합인 경우
  Future<({SpecProfileEntity profile, RecommendationEntity recommendation})> call({
    required Map<String, dynamic> userAnswers,
  }) async {
    // 유효성 검사
    if (userAnswers.isEmpty) {
      throw Exception('사용자 답변이 필요합니다');
    }

    if (!userAnswers.containsKey('Q1')) {
      throw Exception('주 용도 선택이 필요합니다');
    }

    if (!userAnswers.containsKey('Q2')) {
      throw Exception('예산 범위가 필요합니다');
    }

    return await _repository.getRecommendation(userAnswers: userAnswers);
  }
}
