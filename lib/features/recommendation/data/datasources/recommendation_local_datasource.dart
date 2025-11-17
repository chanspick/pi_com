import 'package:pi_com/features/recommendation/data/models/estimate_sample_model.dart';

/// 추천 Local DataSource 인터페이스
abstract class RecommendationLocalDataSource {
  /// estimate_full.json에서 견적 샘플 데이터를 로드합니다
  ///
  /// Returns: EstimateSamples
  ///
  /// Throws:
  /// - Exception: 파일을 찾을 수 없거나 파싱 실패 시
  Future<EstimateSamples> loadEstimateData();
}
