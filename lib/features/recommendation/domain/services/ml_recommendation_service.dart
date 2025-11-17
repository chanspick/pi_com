import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_criteria_entity.dart';

/// ML 기반 추천 서비스 인터페이스
///
/// 향후 TensorFlow Lite, Firebase ML 등을 활용한 AI 추천 시스템
/// 현재는 인터페이스만 정의하고, 구현은 단계적으로 진행
abstract class MlRecommendationService {
  /// ML 모델 초기화
  Future<void> initialize();

  /// 사용자 행동 데이터 학습
  ///
  /// [userId] 사용자 ID
  /// [selectedParts] 사용자가 선택한 부품들
  /// [purchaseCompleted] 구매 완료 여부
  Future<void> learnFromUserBehavior({
    required String userId,
    required List<BasePart> selectedParts,
    required bool purchaseCompleted,
  });

  /// ML 모델을 사용한 부품 점수 예측
  ///
  /// [part] 평가할 부품
  /// [criteria] 사용자 요구사항
  /// [context] 컨텍스트 정보 (현재 선택된 부품 등)
  ///
  /// Returns: 예측된 점수 (0.0 ~ 1.0)
  Future<double> predictPartScore({
    required BasePart part,
    required RecommendationCriteriaEntity criteria,
    Map<String, dynamic>? context,
  });

  /// 협업 필터링 기반 추천
  ///
  /// [userId] 사용자 ID
  /// [criteria] 사용자 요구사항
  ///
  /// Returns: 유사한 사용자들이 선택한 부품 목록
  Future<List<BasePart>> getCollaborativeRecommendations({
    required String userId,
    required RecommendationCriteriaEntity criteria,
  });

  /// 모델 업데이트 (주기적으로 실행)
  Future<void> updateModel();
}
