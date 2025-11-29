/// 정가제 부품 상수
///
/// 케이스, 쿨러는 우리 재고로 정가 판매
/// PSU는 Firestore에서 조회하되 TDP 기반 자동 추천

// ==========================================
// 케이스 (고정)
// ==========================================

/// 케이스 모델명
const String kFixedCaseModelName = '아이구주 hatch 6';

/// 케이스 가격 (원)
const int kFixedCasePrice = 42000;

/// 케이스 브랜드
const String kFixedCaseBrand = '아이구주';

/// 케이스 폼팩터 (ATX는 mATX, ITX도 수용)
const String kFixedCaseFormFactor = 'ATX';

// ==========================================
// 쿨러 옵션
// ==========================================

/// 쿨러 타입 enum
enum CoolerType {
  /// 저가 공냉 - 사무/라이트 게임용
  budget,

  /// 대장 공냉 - 고사양 게임/창작용
  premium,
}

/// 쿨러 정보 클래스
class FixedCoolerInfo {
  final String id;
  final String modelName;
  final int price;
  final String description;
  final int maxTdp; // 냉각 가능한 최대 TDP

  const FixedCoolerInfo({
    required this.id,
    required this.modelName,
    required this.price,
    required this.description,
    required this.maxTdp,
  });
}

/// 저가 공냉 쿨러
const FixedCoolerInfo kBudgetCooler = FixedCoolerInfo(
  id: 'fixed_cooler_budget',
  modelName: '저가 공냉 쿨러',
  price: 20000,
  description: '사무/라이트 게임용',
  maxTdp: 65,
);

/// 대장 공냉 쿨러
const FixedCoolerInfo kPremiumCooler = FixedCoolerInfo(
  id: 'fixed_cooler_premium',
  modelName: '대장 공냉 쿨러',
  price: 40000,
  description: '고사양 게임/창작용',
  maxTdp: 150,
);

/// 쿨러 옵션 리스트
const List<FixedCoolerInfo> kCoolerOptions = [
  kBudgetCooler,
  kPremiumCooler,
];

/// 쿨러 타입으로 정보 가져오기
FixedCoolerInfo getCoolerInfo(CoolerType type) {
  switch (type) {
    case CoolerType.budget:
      return kBudgetCooler;
    case CoolerType.premium:
      return kPremiumCooler;
  }
}

// ==========================================
// 용도별 쿨러 추천
// ==========================================

/// 용도 코드로 권장 쿨러 타입 반환
/// - G (게임): 고사양 게임은 premium, 라이트 게임은 budget
/// - C (창작): premium 권장
/// - O (사무): budget 권장
CoolerType getRecommendedCoolerType({
  required String usage,
  String? graphicsQuality,
  String? resolution,
}) {
  switch (usage) {
    case 'G': // 게임
      // 고사양 그래픽 설정이면 premium
      if (graphicsQuality == '최고' || graphicsQuality == '울트라') {
        return CoolerType.premium;
      }
      return CoolerType.budget;

    case 'C': // 창작
      // 4K 이상이면 premium
      if (resolution == '4K' || resolution == '8K') {
        return CoolerType.premium;
      }
      return CoolerType.premium; // 창작은 기본 premium

    case 'O': // 사무
    default:
      return CoolerType.budget;
  }
}

// ==========================================
// 정가제 부품 총합 계산
// ==========================================

/// 정가제 부품 선택 결과
class FixedPartsSelection {
  /// 케이스 가격 (고정)
  final int casePrice;

  /// 선택된 쿨러 타입
  final CoolerType coolerType;

  /// 쿨러 가격
  final int coolerPrice;

  /// PSU 가격 (Firestore에서 조회된 값)
  final int psuPrice;

  /// PSU 모델명
  final String? psuModelName;

  /// PSU wattage
  final int? psuWattage;

  const FixedPartsSelection({
    this.casePrice = kFixedCasePrice,
    required this.coolerType,
    required this.coolerPrice,
    required this.psuPrice,
    this.psuModelName,
    this.psuWattage,
  });

  /// 정가제 부품 총합
  int get totalFixedPrice => casePrice + coolerPrice + psuPrice;

  /// 쿨러 정보
  FixedCoolerInfo get coolerInfo => getCoolerInfo(coolerType);

  FixedPartsSelection copyWith({
    int? casePrice,
    CoolerType? coolerType,
    int? coolerPrice,
    int? psuPrice,
    String? psuModelName,
    int? psuWattage,
  }) {
    return FixedPartsSelection(
      casePrice: casePrice ?? this.casePrice,
      coolerType: coolerType ?? this.coolerType,
      coolerPrice: coolerPrice ?? this.coolerPrice,
      psuPrice: psuPrice ?? this.psuPrice,
      psuModelName: psuModelName ?? this.psuModelName,
      psuWattage: psuWattage ?? this.psuWattage,
    );
  }
}
