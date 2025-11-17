import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pi_com/features/recommendation/data/datasources/recommendation_local_datasource.dart';
import 'package:pi_com/features/recommendation/data/models/estimate_sample_model.dart';

/// 추천 Local DataSource 구현체
class RecommendationLocalDataSourceImpl implements RecommendationLocalDataSource {
  EstimateSamples? _cachedData;

  @override
  Future<EstimateSamples> loadEstimateData() async {
    // 캐시된 데이터가 있으면 반환
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      // assets에서 JSON 파일 로드
      final jsonString = await rootBundle.loadString('assets/data/estimate_full.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // EstimateSamples로 파싱
      _cachedData = EstimateSamples.fromJson(jsonData);

      return _cachedData!;
    } catch (e) {
      throw Exception('견적 데이터 로드 실패: $e');
    }
  }
}
