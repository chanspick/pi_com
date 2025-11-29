/// 정가제 부품 상수
///
/// 케이스, 쿨러, PSU는 우리 재고로 정가 판매
/// TDP 기반 자동 추천 배지 표시

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
// PSU 옵션 (에너지옵티머스 EXCEL II 시리즈)
// ==========================================

/// PSU 정보 클래스
class FixedPsuInfo {
  final String id;
  final String modelName;
  final int wattage;
  final int price;
  final String brand;

  const FixedPsuInfo({
    required this.id,
    required this.modelName,
    required this.wattage,
    required this.price,
    required this.brand,
  });
}

/// 500W PSU
const FixedPsuInfo kPsu500W = FixedPsuInfo(
  id: 'fixed_psu_500w',
  modelName: '에너지옵티머스 EXCEL II 500W 80PLUS STANDARD 230V EU',
  wattage: 500,
  price: 37000,
  brand: '에너지옵티머스',
);

/// 600W PSU
const FixedPsuInfo kPsu600W = FixedPsuInfo(
  id: 'fixed_psu_600w',
  modelName: '에너지옵티머스 EXCEL II 600W 80PLUS STANDARD 230V EU',
  wattage: 600,
  price: 42000,
  brand: '에너지옵티머스',
);

/// 700W PSU
const FixedPsuInfo kPsu700W = FixedPsuInfo(
  id: 'fixed_psu_700w',
  modelName: '에너지옵티머스 EXCEL II 700W 80PLUS STANDARD 230V EU',
  wattage: 700,
  price: 50000,
  brand: '에너지옵티머스',
);

/// PSU 옵션 리스트 (wattage 오름차순)
const List<FixedPsuInfo> kPsuOptions = [
  kPsu500W,
  kPsu600W,
  kPsu700W,
];

/// 권장 wattage 이상인 가장 저렴한 PSU 찾기
FixedPsuInfo getRecommendedPsu(int recommendedWattage) {
  for (final psu in kPsuOptions) {
    if (psu.wattage >= recommendedWattage) {
      return psu;
    }
  }
  // 권장 wattage를 만족하는 게 없으면 가장 높은 wattage 선택
  return kPsu700W;
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

  /// 선택된 PSU
  final FixedPsuInfo psu;

  const FixedPartsSelection({
    this.casePrice = kFixedCasePrice,
    required this.coolerType,
    required this.coolerPrice,
    required this.psu,
  });

  /// 정가제 부품 총합
  int get totalFixedPrice => casePrice + coolerPrice + psu.price;

  /// 쿨러 정보
  FixedCoolerInfo get coolerInfo => getCoolerInfo(coolerType);

  /// PSU 가격 (편의용)
  int get psuPrice => psu.price;

  /// PSU 모델명 (편의용)
  String get psuModelName => psu.modelName;

  /// PSU wattage (편의용)
  int get psuWattage => psu.wattage;

  FixedPartsSelection copyWith({
    int? casePrice,
    CoolerType? coolerType,
    int? coolerPrice,
    FixedPsuInfo? psu,
  }) {
    return FixedPartsSelection(
      casePrice: casePrice ?? this.casePrice,
      coolerType: coolerType ?? this.coolerType,
      coolerPrice: coolerPrice ?? this.coolerPrice,
      psu: psu ?? this.psu,
    );
  }
}
