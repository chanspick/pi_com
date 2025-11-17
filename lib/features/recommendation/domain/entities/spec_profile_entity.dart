/// 사용자의 PC 사양 프로필 엔티티
class SpecProfileEntity {
  final String? cpuSocket;
  final String? ramType;
  final String? motherboardFormFactor;
  final String? cpuPerformanceTier;
  final String? gpuPerformanceTier;
  final int? recommendedPsuWattage;

  const SpecProfileEntity({
    this.cpuSocket,
    this.ramType,
    this.motherboardFormFactor,
    this.cpuPerformanceTier,
    this.gpuPerformanceTier,
    this.recommendedPsuWattage,
  });

  SpecProfileEntity copyWith({
    String? cpuSocket,
    String? ramType,
    String? motherboardFormFactor,
    String? cpuPerformanceTier,
    String? gpuPerformanceTier,
    int? recommendedPsuWattage,
  }) {
    return SpecProfileEntity(
      cpuSocket: cpuSocket ?? this.cpuSocket,
      ramType: ramType ?? this.ramType,
      motherboardFormFactor: motherboardFormFactor ?? this.motherboardFormFactor,
      cpuPerformanceTier: cpuPerformanceTier ?? this.cpuPerformanceTier,
      gpuPerformanceTier: gpuPerformanceTier ?? this.gpuPerformanceTier,
      recommendedPsuWattage: recommendedPsuWattage ?? this.recommendedPsuWattage,
    );
  }
}
