import 'package:pi_com/features/recommendation/domain/entities/spec_profile_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_entity.dart';

/// SpecProfile Model (Domain Entity + UI용 추천 텍스트 포함)
class SpecProfileModel extends SpecProfileEntity {
  final RecommendationEntity? recommendationText;

  const SpecProfileModel({
    super.cpuSocket,
    super.ramType,
    super.motherboardFormFactor,
    super.cpuPerformanceTier,
    super.gpuPerformanceTier,
    super.recommendedPsuWattage,
    this.recommendationText,
  });

  /// Entity를 Model로 변환
  factory SpecProfileModel.fromEntity(
    SpecProfileEntity entity, {
    RecommendationEntity? recommendationText,
  }) {
    return SpecProfileModel(
      cpuSocket: entity.cpuSocket,
      ramType: entity.ramType,
      motherboardFormFactor: entity.motherboardFormFactor,
      cpuPerformanceTier: entity.cpuPerformanceTier,
      gpuPerformanceTier: entity.gpuPerformanceTier,
      recommendedPsuWattage: entity.recommendedPsuWattage,
      recommendationText: recommendationText,
    );
  }

  /// Entity로 변환
  SpecProfileEntity toEntity() {
    return SpecProfileEntity(
      cpuSocket: cpuSocket,
      ramType: ramType,
      motherboardFormFactor: motherboardFormFactor,
      cpuPerformanceTier: cpuPerformanceTier,
      gpuPerformanceTier: gpuPerformanceTier,
      recommendedPsuWattage: recommendedPsuWattage,
    );
  }

  @override
  SpecProfileModel copyWith({
    String? cpuSocket,
    String? ramType,
    String? motherboardFormFactor,
    String? cpuPerformanceTier,
    String? gpuPerformanceTier,
    int? recommendedPsuWattage,
    RecommendationEntity? recommendationText,
  }) {
    return SpecProfileModel(
      cpuSocket: cpuSocket ?? this.cpuSocket,
      ramType: ramType ?? this.ramType,
      motherboardFormFactor: motherboardFormFactor ?? this.motherboardFormFactor,
      cpuPerformanceTier: cpuPerformanceTier ?? this.cpuPerformanceTier,
      gpuPerformanceTier: gpuPerformanceTier ?? this.gpuPerformanceTier,
      recommendedPsuWattage: recommendedPsuWattage ?? this.recommendedPsuWattage,
      recommendationText: recommendationText ?? this.recommendationText,
    );
  }
}
