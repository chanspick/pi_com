import 'dart:math' as math;
import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_criteria_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/pc_build_entity.dart';
import 'package:pi_com/features/recommendation/domain/services/recommendation_engine_service.dart';
import 'package:pi_com/features/recommendation/data/datasources/compatibility_remote_datasource.dart';

/// 규칙 기반 추천 엔진 구현 (Phase 2)
///
/// 호환성 체크, 점수 계산 알고리즘을 통해 최적의 PC 구성을 추천
class RecommendationEngineServiceImpl implements RecommendationEngineService {
  final CompatibilityRemoteDataSource _dataSource;

  RecommendationEngineServiceImpl({
    required CompatibilityRemoteDataSource dataSource,
  }) : _dataSource = dataSource;
  /// 사용자 요구사항에 맞는 PC 구성 추천
  @override
  Future<List<PcBuildEntity>> recommendBuilds({
    required RecommendationCriteriaEntity criteria,
    required Map<String, List<BasePart>> availableParts,
    int topK = 3,
  }) async {
    final List<PcBuildEntity> candidates = [];

    // 케이스/쿨러/파워/SSD 가상 상품 추가 (고정 상품)
    // PSU는 실제 base_parts에서 가져오기 (listingCount 무관)
    if (availableParts['psu'] == null || availableParts['psu']!.isEmpty) {
      availableParts['psu'] = await _dataSource.getAvailableBaseParts('psu');
    }
    availableParts['cooler'] = [_createVirtualCoolerPart()];
    availableParts['case'] = [_createVirtualCasePart()];
    availableParts['ssd'] = [_createVirtualSsdPart()];

    // 예산을 3단계로 나누기 (저가형, 중급형, 고급형)
    final budgetRanges = _getBudgetRanges(criteria.minBudget, criteria.maxBudget);

    for (final budgetRange in budgetRanges) {
      // 각 예산 범위에서 최적 조합 찾기
      final build = await _findBestBuildForBudget(
        criteria: criteria,
        availableParts: availableParts,
        minBudget: budgetRange['min']!,
        maxBudget: budgetRange['max']!,
      );

      if (build != null) {
        candidates.add(build);
      }
    }

    // 점수 순으로 정렬하고 상위 K개 반환
    candidates.sort((a, b) => b.overallScore.compareTo(a.overallScore));
    return candidates.take(topK).toList();
  }

  /// 예산을 3단계로 나누기
  List<Map<String, int>> _getBudgetRanges(int minBudget, int maxBudget) {
    final range = maxBudget - minBudget;
    final step = range ~/ 3;

    return [
      {'min': minBudget, 'max': minBudget + step},           // 저가형
      {'min': minBudget + step, 'max': maxBudget - step},    // 중급형
      {'min': maxBudget - step, 'max': maxBudget},           // 고급형
    ];
  }

  /// 특정 예산 범위에서 최적 빌드 찾기
  Future<PcBuildEntity?> _findBestBuildForBudget({
    required RecommendationCriteriaEntity criteria,
    required Map<String, List<BasePart>> availableParts,
    required int minBudget,
    required int maxBudget,
  }) async {
    // 각 카테고리별로 점수 계산하여 상위 부품 선정
    final cpus = await _getTopParts(availableParts['cpu'] ?? [], criteria, 5);
    final gpus = await _getTopParts(availableParts['gpu'] ?? [], criteria, 5);
    final mainboards = availableParts['mainboard'] ?? [];
    final rams = availableParts['ram'] ?? [];
    final ssds = availableParts['ssd'] ?? [];
    final psus = availableParts['psu'] ?? [];
    final coolers = availableParts['cooler'] ?? [];
    final cases = availableParts['case'] ?? [];

    // 고정 부품 선택 (루프 밖에서 한 번만 선택)
    if (ssds.isEmpty || coolers.isEmpty || cases.isEmpty) return null;

    final ssd = ssds.first; // 고정 500GB SSD
    final cooler = coolers.first; // 고정 쿨러 (20,000원)
    final pcCase = cases.first; // 고정 케이스 (20,000원)

    // 고정 부품 listing 조회 (한 번만 조회)
    final ssdListing = await _selectBestListing(ssd, maxBudget);
    final coolerListing = await _selectBestListing(cooler, maxBudget);
    final pcCaseListing = await _selectBestListing(pcCase, maxBudget);

    if (ssdListing == null || coolerListing == null || pcCaseListing == null) return null;

    // 고정 부품 가격 합계
    final fixedPartsPrice = ssdListing.price + coolerListing.price + pcCaseListing.price;

    PcBuildEntity? bestBuild;
    double bestScore = 0.0;

    // PSU listing 캐시 (wattage별로 한 번만 조회)
    final Map<int, ListingEntity> psuCache = {};

    // 조합 탐색 (전체 조합은 너무 많으므로 상위 부품들로 제한)
    for (final cpu in cpus) {
      for (final gpu in gpus) {
        // 호환 가능한 메인보드 찾기
        final compatibleMainboards = mainboards
            .where((mb) => mb.socket == cpu.socket)
            .toList();

        for (final mb in compatibleMainboards) {
          // 호환 가능한 RAM 찾기
          final compatibleRams = rams
              .where((ram) => ram.memoryType == mb.memoryType)
              .where((ram) => ram.capacity != null && ram.capacity! >= 8) // 최소 8GB
              .toList();

          if (compatibleRams.isEmpty) continue;

          // RAM 선택
          final ram = _selectBestForBudget(compatibleRams, criteria);

          // 실제 구매 가능한 listing 조회 (CPU, GPU, Mainboard, RAM)
          final cpuListing = await _selectBestListing(cpu, maxBudget);
          if (cpuListing == null) continue;

          final gpuListing = await _selectBestListing(gpu, maxBudget);
          if (gpuListing == null) continue;

          final mbListing = await _selectBestListing(mb, maxBudget);
          if (mbListing == null) continue;

          final ramListing = await _selectBestListing(ram, maxBudget);
          if (ramListing == null) continue;

          // 가변 부품 가격 합계
          final variablePartsPrice = cpuListing.price +
              gpuListing.price +
              mbListing.price +
              ramListing.price;

          // 필요 전력 계산 (CPU + GPU TDP + 기타 부품 50W)
          // RAM/SSD/메인보드/쿨러 등 기타 부품은 합쳐서 약 50W
          // _selectPsu에서 1.2~1.5배 여유를 두어 선택
          final requiredWattage = (cpu.tdp ?? 100) + (gpu.tdp ?? 150) + 50;
          final psu = _selectPsu(psus, requiredWattage, maxBudget);

          if (psu == null) continue;

          // PSU listing 조회 (캐시 활용)
          ListingEntity? psuListing;
          if (psuCache.containsKey(psu.wattage)) {
            psuListing = psuCache[psu.wattage!];
          } else {
            psuListing = await _selectBestListing(psu, maxBudget);
            if (psuListing != null && psu.wattage != null) {
              psuCache[psu.wattage!] = psuListing;
            }
          }

          if (psuListing == null) continue;

          // 총 가격 계산
          final totalPrice = variablePartsPrice + fixedPartsPrice + psuListing.price;

          // 예산 범위 체크
          if (totalPrice < minBudget || totalPrice > maxBudget) continue;

          // PC 빌드 생성 (listing 정보 포함)
          final build = PcBuildEntity(
            cpu: cpu,
            gpu: gpu,
            mainboard: mb,
            ram: ram,
            ssd: ssd,
            psu: psu,
            cooler: cooler,
            pcCase: pcCase,
            cpuListing: cpuListing,
            gpuListing: gpuListing,
            mainboardListing: mbListing,
            ramListing: ramListing,
            ssdListing: ssdListing,
            psuListing: psuListing,
            coolerListing: coolerListing,
            pcCaseListing: pcCaseListing,
            totalPrice: totalPrice,
            compatibilityScore: 0.0,
            performanceScore: 0.0,
            valueScore: 0.0,
            overallScore: 0.0,
          );

          // 호환성 체크
          final compatibilityResult = checkCompatibility(build: build);
          if (!compatibilityResult.isCompatible) continue;

          // 점수 계산
          final compatibilityScore = 1.0; // 호환성 통과
          final performanceScore = calculatePerformanceScore(
            build: build,
            criteria: criteria,
          );
          final valueScore = calculateValueScore(
            build: build,
            criteria: criteria,
          );

          final overallScore = compatibilityScore * 0.4 +
              performanceScore * 0.3 +
              valueScore * 0.3;

          final scoredBuild = PcBuildEntity(
            cpu: cpu,
            gpu: gpu,
            mainboard: mb,
            ram: ram,
            ssd: ssd,
            psu: psu,
            cooler: cooler,
            pcCase: pcCase,
            cpuListing: cpuListing,
            gpuListing: gpuListing,
            mainboardListing: mbListing,
            ramListing: ramListing,
            ssdListing: ssdListing,
            psuListing: psuListing,
            coolerListing: coolerListing,
            pcCaseListing: pcCaseListing,
            totalPrice: totalPrice,
            compatibilityScore: compatibilityScore,
            performanceScore: performanceScore,
            valueScore: valueScore,
            overallScore: overallScore,
          );

          // 최고 점수 갱신
          if (overallScore > bestScore) {
            bestScore = overallScore;
            bestBuild = scoredBuild;
          }
        }
      }
    }

    return bestBuild;
  }

  /// 부품 리스트에서 점수 기반 상위 N개 선택
  Future<List<BasePart>> _getTopParts(
    List<BasePart> parts,
    RecommendationCriteriaEntity criteria,
    int count,
  ) async {
    final scored = await Future.wait(parts.map((part) async {
      final score = await _scorePartWithDetails(
        part: part,
        criteria: criteria,
      );
      return {'part': part, 'score': score};
    }));

    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return scored.take(count).map((e) => e['part'] as BasePart).toList();
  }

  /// 부품 점수 계산 (BasePart 스펙 활용)
  Future<double> _scorePartWithDetails({
    required BasePart part,
    required RecommendationCriteriaEntity criteria,
  }) async {
    double score = 0.0;

    // 카테고리별 점수 계산 (BasePart의 TDP 등 기본 스펙 사용)
    switch (part.category) {
      case 'cpu':
        score = _scoreCpu(part, criteria);
        break;
      case 'gpu':
        score = _scoreGpu(part, criteria);
        break;
      case 'ram':
        score = _scoreRam(part, criteria);
        break;
      case 'ssd':
        score = _scoreSsd(part, criteria);
        break;
      default:
        score = 0.5; // 기본 점수
    }

    return score.clamp(0.0, 1.0);
  }

  /// CPU 점수 계산 (BasePart TDP 기반)
  double _scoreCpu(
    BasePart cpu,
    RecommendationCriteriaEntity criteria,
  ) {
    double score = 0.5;

    // 용도별 기본 가중치
    if (criteria.usage == 'G') {
      score = 0.6; // 게임: 중요도 중간
    } else if (criteria.usage == 'C') {
      score = 0.9; // 창작: 매우 중요
    } else {
      score = 0.7; // 사무: 중요도 높음
    }

    // TDP 기반 성능 추정
    if (cpu.tdp != null) {
      final performance = cpu.tdp! / math.max(cpu.lowestPrice / 10000, 1);
      score *= (1.0 + performance / 10.0).clamp(0.8, 1.2);
    }

    return score;
  }

  /// GPU 점수 계산 (BasePart TDP 기반)
  double _scoreGpu(
    BasePart gpu,
    RecommendationCriteriaEntity criteria,
  ) {
    double score = 0.5;

    // 용도별 기본 가중치
    if (criteria.usage == 'G') {
      score = 1.0; // 게임: 매우 중요
      if (criteria.graphicsQuality == '최고' || criteria.graphicsQuality == '울트라') {
        score *= 1.2;
      }
    } else if (criteria.usage == 'C') {
      score = 0.9; // 창작: 매우 중요
      if (criteria.resolution == '4K' || criteria.resolution == '8K') {
        score *= 1.3;
      }
    } else {
      score = 0.3; // 사무: 중요도 낮음
    }

    // TDP 기반 성능 추정
    if (gpu.tdp != null) {
      final performance = gpu.tdp! / math.max(gpu.lowestPrice / 10000, 1);
      score *= (1.0 + performance / 10.0).clamp(0.8, 1.2);
    }

    return score;
  }

  /// 예산 내에서 최적 부품 선택
  BasePart _selectBestForBudget(
    List<BasePart> parts,
    RecommendationCriteriaEntity criteria,
  ) {
    // 가성비 기준으로 정렬 (용량/가격)
    parts.sort((a, b) {
      final aValue = (a.capacity ?? 1) / math.max(a.lowestPrice, 1);
      final bValue = (b.capacity ?? 1) / math.max(b.lowestPrice, 1);
      return bValue.compareTo(aValue);
    });

    return parts.first;
  }

  /// 부품에 대한 최적 listing 선택 (conditionScore와 가격 고려)
  Future<ListingEntity?> _selectBestListing(BasePart part, int maxPrice) async {
    // 가상 상품인 경우 가상 listing 반환
    if (part.basePartId.startsWith('virtual_')) {
      return _createVirtualListing(part, part.lowestPrice);
    }

    // 실제 상품인 경우 Firestore에서 조회
    final listings = await _dataSource.getAvailableListings(
      basePartId: part.basePartId,
      status: 'available',
    );

    if (listings.isEmpty) return null;

    // 예산 내 listing만 필터링
    final affordableListings = listings.where((l) => l.price <= maxPrice).toList();
    if (affordableListings.isEmpty) return null;

    // 가성비 계산: conditionScore / price
    affordableListings.sort((a, b) {
      final aValue = a.conditionScore / a.price;
      final bValue = b.conditionScore / b.price;
      return bValue.compareTo(aValue);
    });

    return affordableListings.first;
  }

  /// PSU 선택 (적당한~여유로운 사이 추천)
  BasePart? _selectPsu(List<BasePart> psus, int requiredWattage, int maxPrice) {
    // 적당한 파워: requiredWattage * 1.2
    // 여유로운 파워: requiredWattage * 1.5
    final minRecommendedWattage = (requiredWattage * 1.2).round();
    final maxRecommendedWattage = (requiredWattage * 1.5).round();

    // 권장 범위 내 파워 찾기
    final suitable = psus
        .where((psu) =>
            psu.wattage != null &&
            psu.wattage! >= minRecommendedWattage &&
            psu.wattage! <= maxRecommendedWattage &&
            psu.lowestPrice <= maxPrice)
        .toList();

    if (suitable.isEmpty) {
      // 범위 내 없으면 최소 요구사항만 만족하는 것 선택
      final fallback = psus
          .where((psu) =>
              psu.wattage != null &&
              psu.wattage! >= requiredWattage &&
              psu.lowestPrice <= maxPrice)
          .toList();

      if (fallback.isEmpty) return null;

      // 가장 저렴한 것 선택
      fallback.sort((a, b) => a.lowestPrice.compareTo(b.lowestPrice));
      return fallback.first;
    }

    // 권장 범위 내에서 가장 저렴한 것 선택
    suitable.sort((a, b) => a.lowestPrice.compareTo(b.lowestPrice));
    return suitable.first;
  }

  /// 쿨러 선택 (가상 상품 리스트에서 첫 번째 항목 = 인텔 기본 쿨러 5,000원)
  BasePart? _selectCooler(
    List<BasePart> coolers,
    String? cpuSocket,
    int cpuTdp,
    int maxPrice,
  ) {
    // 가상 쿨러 리스트가 비어있지 않으면 첫 번째 반환
    if (coolers.isNotEmpty) {
      return coolers.first;
    }
    return null;
  }

  /// 케이스 선택 (가상 상품 리스트에서 첫 번째 항목 = 임의 배송 케이스 10,000원)
  BasePart? _selectCase(
    List<BasePart> cases,
    String? mbFormFactor,
    int maxPrice,
  ) {
    // 가상 케이스 리스트가 비어있지 않으면 첫 번째 반환
    if (cases.isNotEmpty) {
      return cases.first;
    }
    return null;
  }

  /// 부품 점수 계산 (동기 버전 - Part 상세 스펙 없이 계산)
  ///
  /// 참고: 이 메서드는 인터페이스 호환성을 위해 동기로 유지됩니다.
  /// 상위 부품 선택 시에는 _scorePartWithDetails (비동기)를 사용하여
  /// Part 상세 스펙을 활용한 정확한 점수 계산이 이루어집니다.
  @override
  double scorePartForCriteria({
    required BasePart part,
    required RecommendationCriteriaEntity criteria,
    Map<String, BasePart>? currentBuild,
  }) {
    double score = 0.0;

    // 카테고리별 점수 계산
    switch (part.category) {
      case 'cpu':
        score = _scoreCpu(part, criteria);
        break;
      case 'gpu':
        score = _scoreGpu(part, criteria);
        break;
      case 'ram':
        score = _scoreRam(part, criteria);
        break;
      case 'ssd':
        score = _scoreSsd(part, criteria);
        break;
      default:
        score = 0.5; // 기본 점수
    }

    return score.clamp(0.0, 1.0);
  }

  /// RAM 점수 계산
  double _scoreRam(BasePart ram, RecommendationCriteriaEntity criteria) {
    double score = 0.5;

    // 용량 체크
    if (ram.capacity != null) {
      if (criteria.usage == 'G') {
        // 게임: 16GB 이상 권장
        score = ram.capacity! >= 16 ? 0.8 : 0.5;
      } else if (criteria.usage == 'C') {
        // 창작: 32GB 이상 권장
        score = ram.capacity! >= 32 ? 1.0 : (ram.capacity! >= 16 ? 0.7 : 0.4);
      } else {
        // 사무: 8GB 이상 권장
        score = ram.capacity! >= 8 ? 0.7 : 0.4;
      }
    }

    // DDR5 보너스
    if (ram.memoryType == 'DDR5') {
      score *= 1.1;
    }

    return score;
  }

  /// SSD 점수 계산
  double _scoreSsd(BasePart ssd, RecommendationCriteriaEntity criteria) {
    double score = 0.5;

    // 용량 체크
    if (ssd.capacity != null) {
      if (ssd.capacity! >= criteria.ssdCapacity) {
        score = 0.8;
      } else {
        score = 0.3;
      }
    }

    // NVMe 보너스
    if (ssd.interface == 'NVMe') {
      score *= 1.2;
    }

    return score;
  }

  /// 호환성 체크
  @override
  ({bool isCompatible, String? reason}) checkCompatibility({
    required PcBuildEntity build,
  }) {
    // 1. CPU-메인보드 소켓 호환성
    if (build.cpu != null && build.mainboard != null) {
      if (build.cpu!.socket != build.mainboard!.socket) {
        return (
          isCompatible: false,
          reason: 'CPU 소켓(${build.cpu!.socket})과 메인보드 소켓(${build.mainboard!.socket})이 호환되지 않습니다.'
        );
      }
    }

    // 2. RAM-메인보드 타입 호환성
    if (build.ram != null && build.mainboard != null) {
      if (build.ram!.memoryType != build.mainboard!.memoryType) {
        return (
          isCompatible: false,
          reason: 'RAM 타입(${build.ram!.memoryType})과 메인보드 RAM 타입(${build.mainboard!.memoryType})이 호환되지 않습니다.'
        );
      }
    }

    // 3. 전력 충분성 체크
    if (build.psu != null && build.cpu != null && build.gpu != null) {
      final requiredWattage = (build.cpu!.tdp ?? 100) +
                             (build.gpu!.tdp ?? 150) +
                             100; // 여유분

      if (build.psu!.wattage != null && build.psu!.wattage! < requiredWattage) {
        return (
          isCompatible: false,
          reason: 'PSU 용량(${build.psu!.wattage}W)이 필요 전력(${requiredWattage}W)보다 부족합니다.'
        );
      }
    }

    // 4. 쿨러-CPU 소켓 호환성
    if (build.cooler != null && build.cpu != null) {
      if (build.cooler!.socket != build.cpu!.socket) {
        return (
          isCompatible: false,
          reason: '쿨러 소켓(${build.cooler!.socket})과 CPU 소켓(${build.cpu!.socket})이 호환되지 않습니다.'
        );
      }
    }

    // 5. 케이스-메인보드 폼팩터 호환성
    if (build.pcCase != null && build.mainboard != null) {
      if (build.pcCase!.formFactor != build.mainboard!.formFactor) {
        // ATX 케이스는 mATX, ITX도 지원
        if (!(build.pcCase!.formFactor == 'ATX' &&
              (build.mainboard!.formFactor == 'mATX' || build.mainboard!.formFactor == 'ITX'))) {
          return (
            isCompatible: false,
            reason: '케이스 폼팩터(${build.pcCase!.formFactor})와 메인보드 폼팩터(${build.mainboard!.formFactor})가 호환되지 않습니다.'
          );
        }
      }
    }

    return (isCompatible: true, reason: null);
  }

  /// 성능 점수 계산
  @override
  double calculatePerformanceScore({
    required PcBuildEntity build,
    required RecommendationCriteriaEntity criteria,
  }) {
    double score = 0.0;
    int componentCount = 0;

    // 각 부품의 성능 점수 합산
    if (build.cpu != null) {
      score += scorePartForCriteria(part: build.cpu!, criteria: criteria);
      componentCount++;
    }

    if (build.gpu != null) {
      score += scorePartForCriteria(part: build.gpu!, criteria: criteria);
      componentCount++;
    }

    if (build.ram != null) {
      score += scorePartForCriteria(part: build.ram!, criteria: criteria);
      componentCount++;
    }

    if (build.ssd != null) {
      score += scorePartForCriteria(part: build.ssd!, criteria: criteria);
      componentCount++;
    }

    return componentCount > 0 ? score / componentCount : 0.0;
  }

  /// 가성비 점수 계산
  @override
  double calculateValueScore({
    required PcBuildEntity build,
    required RecommendationCriteriaEntity criteria,
  }) {
    // 성능 점수
    final performanceScore = calculatePerformanceScore(
      build: build,
      criteria: criteria,
    );

    // 가격 점수: 저렴할수록 높은 점수
    // 예산 범위 내에서 minBudget에 가까울수록 점수 높음
    final budgetRange = criteria.maxBudget - criteria.minBudget;
    final pricePosition = (build.totalPrice - criteria.minBudget) / budgetRange;
    // 0.0 (minBudget) → 1.0점, 1.0 (maxBudget) → 0.7점
    final priceScore = (1.0 - pricePosition * 0.3).clamp(0.0, 1.0);

    // 가성비 = 성능 70% + 가격 30%
    // 성능이 좋으면서도 저렴할수록 높은 점수
    return (performanceScore * 0.7 + priceScore * 0.3).clamp(0.0, 1.0);
  }

  // ==========================================
  // 가상 상품 생성 헬퍼 메서드
  // ==========================================

  /// 가상 파워 BasePart 리스트 생성
  List<BasePart> _createVirtualPsuList() {
    final psuOptions = [
      {'wattage': 450, 'price': 30000},
      {'wattage': 500, 'price': 35000},
      {'wattage': 650, 'price': 60000},
      {'wattage': 750, 'price': 80000},
      {'wattage': 850, 'price': 130000},
      {'wattage': 1000, 'price': 170000},
    ];

    return psuOptions.map((option) {
      final wattage = option['wattage']!;
      final price = option['price']!;
      return BasePart(
        basePartId: 'virtual_psu_${wattage}w',
        modelName: '${wattage}W 파워',
        category: 'PSU',
        brand: '기본',
        lowestPrice: price,
        averagePrice: price.toDouble(),
        listingCount: 999, // 무한 재고
        wattage: wattage,
      );
    }).toList();
  }

  /// 가상 쿨러 BasePart 생성
  BasePart _createVirtualCoolerPart() {
    return BasePart(
      basePartId: 'virtual_cooler_intel',
      modelName: '임의 매집 쿨러',
      category: 'COOLER',
      brand: '기본',
      lowestPrice: 20000,
      averagePrice: 20000.0,
      listingCount: 999,
      socket: 'LGA1700', // 범용
      tdp: 65,
    );
  }

  /// 가상 케이스 BasePart 생성
  BasePart _createVirtualCasePart() {
    return BasePart(
      basePartId: 'virtual_case_standard',
      modelName: '임의 매집 케이스',
      category: 'CASE',
      brand: '기본',
      lowestPrice: 20000,
      averagePrice: 20000.0,
      listingCount: 999,
      formFactor: 'ATX', // 범용
    );
  }

  /// 가상 SSD BasePart 생성 (고정 500GB)
  BasePart _createVirtualSsdPart() {
    return BasePart(
      basePartId: 'virtual_ssd_500gb',
      modelName: '기본 SSD 500GB',
      category: 'SSD',
      brand: '기본',
      lowestPrice: 40000,
      averagePrice: 40000.0,
      listingCount: 999,
      capacity: 500,
      interface: 'SATA',
    );
  }

  /// 가상 Listing 생성
  ListingEntity _createVirtualListing(BasePart part, int price) {
    return ListingEntity(
      listingId: 'virtual_${part.basePartId}',
      basePartId: part.basePartId,
      sellerId: 'picom_system',
      brand: part.brand,
      modelName: part.modelName,
      price: price,
      conditionScore: 100.0,
      imageUrls: [],
      status: ListingStatus.available,
      createdAt: DateTime.now(),
      category: part.category,
    );
  }
}
