import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';

/// PC 조립 구성 엔티티
class PcBuildEntity {
  final BasePart? cpu;
  final BasePart? gpu;
  final BasePart? mainboard;
  final BasePart? ram;
  final BasePart? ssd;
  final BasePart? psu;
  final BasePart? cooler;
  final BasePart? pcCase;

  // 실제 구매 가능한 listing 정보 (추천 시 선택된 실제 상품)
  final ListingEntity? cpuListing;
  final ListingEntity? gpuListing;
  final ListingEntity? mainboardListing;
  final ListingEntity? ramListing;
  final ListingEntity? ssdListing;
  final ListingEntity? psuListing;
  final ListingEntity? coolerListing;
  final ListingEntity? pcCaseListing;

  final int totalPrice;          // 총 가격 (실제 listing 가격 합산)
  final double compatibilityScore; // 호환성 점수 (0.0 ~ 1.0)
  final double performanceScore;   // 성능 점수 (0.0 ~ 1.0)
  final double valueScore;         // 가성비 점수 (0.0 ~ 1.0)
  final double overallScore;       // 종합 점수 (0.0 ~ 1.0)

  final String? incompatibilityReason; // 비호환 이유 (있는 경우)
  final List<String> warnings;         // 경고 메시지 목록

  const PcBuildEntity({
    this.cpu,
    this.gpu,
    this.mainboard,
    this.ram,
    this.ssd,
    this.psu,
    this.cooler,
    this.pcCase,
    this.cpuListing,
    this.gpuListing,
    this.mainboardListing,
    this.ramListing,
    this.ssdListing,
    this.psuListing,
    this.coolerListing,
    this.pcCaseListing,
    required this.totalPrice,
    required this.compatibilityScore,
    required this.performanceScore,
    required this.valueScore,
    required this.overallScore,
    this.incompatibilityReason,
    this.warnings = const [],
  });

  bool get isComplete =>
      cpu != null &&
      gpu != null &&
      mainboard != null &&
      ram != null &&
      ssd != null &&
      psu != null;

  bool get isCompatible => compatibilityScore >= 0.8 && incompatibilityReason == null;

  Map<String, BasePart?> toMap() {
    return {
      'cpu': cpu,
      'gpu': gpu,
      'mainboard': mainboard,
      'ram': ram,
      'ssd': ssd,
      'psu': psu,
      'cooler': cooler,
      'case': pcCase,
    };
  }
}
