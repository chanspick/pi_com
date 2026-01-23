import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/core/utils/app_logger.dart';
import 'package:pi_com/core/repositories/base_part_repository.dart';
import 'package:pi_com/features/recommendation/data/datasources/recommendation_local_datasource.dart';
import 'package:pi_com/features/recommendation/data/models/estimate_sample_model.dart';
import 'package:pi_com/features/recommendation/domain/entities/spec_profile_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_criteria_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/pc_build_entity.dart';
import 'package:pi_com/features/recommendation/domain/repositories/recommendation_repository.dart';
import 'package:pi_com/features/recommendation/domain/services/recommendation_engine_service.dart';

/// 추천 Repository 구현체
class RecommendationRepositoryImpl implements RecommendationRepository {
  // ignore: unused_field
  final RecommendationLocalDataSource _localDataSource;
  // ignore: unused_field
  final FirebaseFirestore _firestore;
  final BasePartRepository _basePartRepository;
  final RecommendationEngineService _recommendationEngine;

  RecommendationRepositoryImpl({
    required RecommendationLocalDataSource localDataSource,
    required BasePartRepository basePartRepository,
    required RecommendationEngineService recommendationEngine,
    FirebaseFirestore? firestore,
  })  : _localDataSource = localDataSource,
        _basePartRepository = basePartRepository,
        _recommendationEngine = recommendationEngine,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<({SpecProfileEntity profile, RecommendationEntity recommendation})> getRecommendation({
    required Map<String, dynamic> userAnswers,
  }) async {
    // ✅ 이제 실제 RecommendationEngine을 사용합니다!

    // 1. 비현실적인 조합 체크
    final unrealisticReason = _checkUnrealisticCombinations(userAnswers);
    if (unrealisticReason != null) {
      throw Exception(unrealisticReason);
    }

    // 2. 사용자 요구사항 엔티티 생성
    final criteria = RecommendationCriteriaEntity.fromUserAnswers(userAnswers);

    // 3. Firestore에서 재고가 있는 부품들 조회
    final availableParts = await _basePartRepository.getAllAvailableParts(
      minListingCount: 1,
    );

    // 4. 재고 체크 (디버깅 정보 포함)
    AppLogger.d('재고 확인: CPU=${availableParts['cpu']?.length ?? 0}, GPU=${availableParts['gpu']?.length ?? 0}, Mainboard=${availableParts['mainboard']?.length ?? 0}, RAM=${availableParts['ram']?.length ?? 0}, SSD=${availableParts['ssd']?.length ?? 0}, PSU=${availableParts['psu']?.length ?? 0}, Cooler=${availableParts['cooler']?.length ?? 0}, Case=${availableParts['case']?.length ?? 0}', tag: 'RecommendationRepository');

    // 필수 부품 재고 확인 (SSD/PSU/쿨러/케이스는 가상 상품이므로 제외)
    final List<String> missingParts = [];

    if (availableParts['cpu']?.isEmpty ?? true) missingParts.add('CPU');
    if (availableParts['gpu']?.isEmpty ?? true) missingParts.add('GPU (그래픽카드)');
    if (availableParts['mainboard']?.isEmpty ?? true) missingParts.add('메인보드');
    if (availableParts['ram']?.isEmpty ?? true) missingParts.add('RAM (메모리)');

    if (missingParts.isNotEmpty) {
      final missingPartsText = missingParts.join(', ');
      throw Exception(
        '죄송합니다. 현재 다음 부품의 재고가 부족합니다:\n\n'
        '📦 $missingPartsText\n\n'
        '재고가 충분한 다른 카테고리의 부품을 먼저 둘러보시거나, '
        '나중에 다시 시도해주세요.'
      );
    }

    // 5. ✅ 추천 엔진으로 PC 구성 추천 (실제 listing 포함!)
    final recommendations = await _recommendationEngine.recommendBuilds(
      criteria: criteria,
      availableParts: availableParts,
      topK: 1,  // 최고 점수 1개만 가져오기
    );

    if (recommendations.isEmpty) {
      // 구체적인 실패 이유 제공
      final budgetText = '${criteria.minBudget / 10000}~${criteria.maxBudget / 10000}만원';

      throw Exception(
        '조건에 맞는 PC 구성을 찾지 못했습니다.\n\n'
        '🎯 입력하신 조건:\n'
        '  • 예산: $budgetText\n'
        '  • 용도: ${_getMainUseText(criteria.usage)}\n\n'
        '💡 해결 방법:\n'
        '  1. 예산 범위를 늘려보세요\n'
        '  2. 나중에 다시 시도해보세요 (재고가 추가될 수 있습니다)'
      );
    }

    // 6. 최고 점수 빌드 선택
    final bestBuild = recommendations.first;

    // 7. SpecProfile 생성 (실제 부품 정보 사용)
    final profile = SpecProfileEntity(
      cpuSocket: bestBuild.cpu?.socket,
      ramType: bestBuild.ram?.memoryType,
      motherboardFormFactor: bestBuild.mainboard?.formFactor,
      recommendedPsuWattage: bestBuild.gpu?.tdp,
      cpuPerformanceTier: null,  // TODO: 필요시 구현
      gpuPerformanceTier: null,  // TODO: 필요시 구현
    );

    // 8. ✅ RecommendationEntity 생성 (listing 정보 포함!)
    final recommendation = RecommendationEntity(
      // 부품명
      cpu: bestBuild.cpu?.modelName,
      mainboard: bestBuild.mainboard?.modelName,
      memory: bestBuild.ram != null
          ? '${bestBuild.ram!.memoryType} ${bestBuild.ram!.capacity}GB'
          : null,
      gpu: bestBuild.gpu?.modelName,
      ssd: bestBuild.ssd != null
          ? '${bestBuild.ssd!.capacity}GB ${bestBuild.ssd!.interface ?? ""}'
          : null,
      psu: bestBuild.psu != null
          ? '${bestBuild.psu!.wattage}W'
          : null,
      cpuCooler: bestBuild.cooler?.modelName,
      pcCase: bestBuild.pcCase?.modelName,

      // ✅ Listing ID (실제 상품 연결)
      cpuListingId: bestBuild.cpuListing?.listingId,
      mainboardListingId: bestBuild.mainboardListing?.listingId,
      memoryListingId: bestBuild.ramListing?.listingId,
      gpuListingId: bestBuild.gpuListing?.listingId,
      ssdListingId: bestBuild.ssdListing?.listingId,
      psuListingId: bestBuild.psuListing?.listingId,
      cpuCoolerListingId: bestBuild.coolerListing?.listingId,
      pcCaseListingId: bestBuild.pcCaseListing?.listingId,

      // ✅ 가격 정보 (실제 listing 가격)
      cpuPrice: bestBuild.cpuListing?.price,
      mainboardPrice: bestBuild.mainboardListing?.price,
      memoryPrice: bestBuild.ramListing?.price,
      gpuPrice: bestBuild.gpuListing?.price,
      ssdPrice: bestBuild.ssdListing?.price,
      psuPrice: bestBuild.psuListing?.price,
      cpuCoolerPrice: bestBuild.coolerListing?.price,
      pcCasePrice: bestBuild.pcCaseListing?.price,
      totalPrice: bestBuild.totalPrice,
    );

    return (profile: profile, recommendation: recommendation);
  }

  /// 비현실적인 조합 체크
  String? _checkUnrealisticCombinations(Map<String, dynamic> answers) {
    final budgetParts = (answers['Q2'] as String? ?? '0 ~ 0').split(' ~ ');
    final maxBudget = int.tryParse(budgetParts[1]) ?? 0;

    if (answers['Q3'] == 500 &&
        (answers['Q5C'] == '4K' ||
            answers['Q5C'] == '8K' ||
            answers['Q6C'] == '대규모' ||
            answers['Q6C'] == '스튜디오급')) {
      return '고해상도 미디어 파일은 용량이 매우 크므로 500GB는 심각하게 부족하며, 최소 1TB 이상(권장 2TB)이 필요합니다.';
    }

    if (answers['Q5C'] == '4K' &&
        (answers['Q3'] == 500 || answers['Q6C'] == '대규모' || answers['Q6C'] == '스튜디오급')) {
      return '4K 작업은 시스템 자원을 많이 소모하며, 특히 SSD 용량과 프로젝트 규모가 클수록 메모리/CPU/GPU 성능이 매우 중요합니다.';
    }

    if (answers['Q5C'] == '8K') {
      return '8K는 현존하는 일반 PC 환경에서 최고 사양을 요구합니다. 제공된 모든 견적으로는 원활한 8K 작업이 사실상 불가능합니다.';
    }

    if (answers['Q6C'] == '대규모' &&
        (answers['Q3'] == 500 ||
            answers['Q3'] == 1000 ||
            answers['Q5C'] == '4K' ||
            answers['Q5C'] == '8K')) {
      return '대규모 프로젝트는 수백 GB의 용량과 엄청난 시스템 자원을 필요로 합니다. 최소 2TB SSD 및 고성능 CPU/GPU/RAM(64GB 이상)이 필수입니다.';
    }

    if (answers['Q6C'] == '스튜디오급') {
      return '\'스튜디오급\' 작업은 전문적인 워크스테이션 수준의 사양(고성능 CPU/GPU, 2TB 이상 SSD, 128GB+ RAM)을 의미하며, 제공된 모든 견적 사양으로는 적합하지 않습니다.';
    }

    if (answers['Q7C'] == '실시간' &&
        (answers['Q5C'] == '4K' ||
            answers['Q5C'] == '8K' ||
            answers['Q6C'] == '대규모' ||
            answers['Q6C'] == '스튜디오급')) {
      return '실시간 렌더링은 GPU의 VRAM과 CUDA/Tensor 코어 성능이 매우 중요하며, 제공된 견적 사양으로는 4K 이상에서 불가능합니다.';
    }

    if (answers['Q5O'] == '10개 이상' &&
        (answers['Q3'] == 500 || answers['Q3'] == 1000 || answers['Q7O'] == '1TB 미만')) {
      return '10개 이상의 고사양 프로그램을 동시에 실행하려면 최소 32GB RAM(권장 64GB)과 2TB 이상의 고속 SSD가 필요합니다.';
    }

    if (answers['Q7O'] == '1TB 이상' && answers['Q3'] == 500) {
      return '저장 공간(Q7O)이 필요한 SSD 용량(Q3)보다 커서, 주 저장 장치로는 부족합니다. 이는 외부 저장소를 필수적으로 가정해야만 가능한 조합입니다.';
    }

    if (maxBudget < 50 &&
        (answers['Q4O'] == '데이터분석' || answers['Q5O'] == '10개 이상' || answers['Q7O'] == '1TB 이상')) {
      return '이 예산은 문서/웹서핑(Q4O: ①, ③)용입니다. 데이터 분석(LLM)은 최소 390만원 견적(64GB RAM, RTX 5080)이 필요하며, 10개 이상 실행에는 고용량 RAM이 필수입니다.';
    }

    if (maxBudget < 100 &&
        (answers['Q4O'] == '데이터분석' || answers['Q5O'] == '10개 이상' || answers['Q7O'] == '1TB 이상')) {
      return '이 예산은 개발/코딩 입문 정도에 적합합니다. 데이터 분석(LLM)은 불가능하며, 10개 이상 프로그램 실행에 필요한 32GB~64GB RAM 구성이 어렵습니다.';
    }

    if (maxBudget < 250 && answers['Q4O'] == '데이터분석') {
      return 'LLM 딥러닝에 필요한 고성능 GPU(RTX 5080/5090)와 64GB 이상의 RAM 구성은 최소 390만원 이상이 필요합니다.';
    }

    if (maxBudget < 400 &&
        answers['Q4O'] == '데이터분석' &&
        answers['Q5O'] == '10개 이상' &&
        answers['Q7O'] == '1TB 이상') {
      return 'LLM개발용(390만원) 견적의 사양입니다. 이 사양은 고성능이지만, 최고 사양 AI 개발(660만원 견적의 RTX 5090 급)까지 커버하기는 어렵습니다.';
    }

    return null;
  }

  /// 최적 매칭 찾기
  // ignore: unused_element
  Sample? _findBestMatch(EstimateSamples samples, Map<String, dynamic> userAnswers) {
    int bestScore = -1;
    Sample? bestMatch;
    double minAbsBudgetDiff = double.infinity;
    Sample? closestBudgetMatch;

    final budgetParts = (userAnswers['Q2'] as String).split(' ~ ');
    final userMinBudget = int.tryParse(budgetParts[0]) ?? 0;
    final userMaxBudget = int.tryParse(budgetParts[1]) ?? 0;
    final userAvgBudget = (userMinBudget + userMaxBudget) / 2.0;

    for (final sample in samples.samples) {
      int currentScore = 0;

      // 예산 매칭
      if (sample.budget != null) {
        final sampleMin = sample.budget!.min;
        final sampleMax = sample.budget!.max;
        final sampleAvg = (sampleMin + sampleMax) / 2.0;

        if (userMinBudget <= sampleMax && userMaxBudget >= sampleMin) {
          currentScore += 20;
          if (userAvgBudget >= sampleMin && userAvgBudget <= sampleMax) {
            currentScore += 15;
          }
        }

        final absDiff = (userAvgBudget - sampleAvg).abs();
        if (absDiff < minAbsBudgetDiff) {
          minAbsBudgetDiff = absDiff;
          closestBudgetMatch = sample;
        }
      }

      // SSD 매칭
      final userSsd = userAnswers['Q3'] as int;
      final sampleSsd = int.tryParse(sample.ssd ?? '0') ?? 0;
      if (sampleSsd >= userSsd) {
        currentScore += 10;
      }

      // 용도 매칭
      final usage = userAnswers['Q1'];
      if (sample.task != null) {
        final task = sample.task!;

        // 주 용도 매칭
        if (task.mainUse != null && task.mainUse!.contains(_getMainUseText(usage))) {
          currentScore += 10;

          // 세부 매칭
          switch (usage) {
            case 'C': // 창작작업
              if (task.software != null &&
                  userAnswers['Q4C'] != null &&
                  task.software!.contains(userAnswers['Q4C'])) {
                currentScore += 20;
              }
              if (task.resolution != null &&
                  userAnswers['Q5C'] != null &&
                  task.resolution!.contains(userAnswers['Q5C'])) {
                currentScore += 15;
              }
              if (task.scale != null &&
                  userAnswers['Q6C'] != null &&
                  task.scale!.contains(userAnswers['Q6C'])) {
                currentScore += 10;
              }
              if (task.frequency != null &&
                  userAnswers['Q7C'] != null &&
                  task.frequency!.contains(userAnswers['Q7C'])) {
                currentScore += 10;
              }
              break;

            case 'O': // 사무·개발
              if (task.work != null &&
                  userAnswers['Q4O'] != null &&
                  task.work!.contains(userAnswers['Q4O'])) {
                currentScore += 20;
              }
              if (task.progs != null &&
                  userAnswers['Q5O'] != null &&
                  task.progs!.contains(userAnswers['Q5O'])) {
                currentScore += 10;
              }
              if (task.monitors != null &&
                  userAnswers['Q6O'] != null &&
                  task.monitors!.contains(userAnswers['Q6O'])) {
                currentScore += 10;
              }
              if (task.dataSize != null &&
                  userAnswers['Q7O'] != null &&
                  task.dataSize!.contains(userAnswers['Q7O'])) {
                currentScore += 10;
              }
              break;

            case 'G': // 게임
              if (userAnswers['Q4G'] != null && task.gameIds != null) {
                final userGames = (userAnswers['Q4G'] as String).split(', ');
                int matchCount = 0;
                for (var game in userGames) {
                  if (task.gameIds!.contains(game)) matchCount++;
                }
                currentScore += matchCount * 10;
              }
              if (task.resolution != null &&
                  userAnswers['Q5G'] != null &&
                  task.resolution!.contains(userAnswers['Q5G'])) {
                currentScore += 15;
              }
              break;
          }
        }
      }

      if (currentScore > bestScore) {
        bestScore = currentScore;
        bestMatch = sample;
      }
    }

    // 매칭 점수가 낮으면 예산이 가장 가까운 것 반환
    if (bestScore < 20 && closestBudgetMatch != null) {
      bestMatch = closestBudgetMatch;
    }
    if (bestMatch == null && closestBudgetMatch != null) {
      bestMatch = closestBudgetMatch;
    }

    return bestMatch;
  }

  /// 용도 코드를 텍스트로 변환
  String _getMainUseText(String? usage) {
    switch (usage) {
      case 'G':
        return '게임';
      case 'C':
        return '창작작업';
      case 'O':
        return '사무';
      default:
        return '';
    }
  }

  /// [Phase 2] 동적 추천 구현
  @override
  Future<List<PcBuildEntity>> getDynamicRecommendations({
    required Map<String, dynamic> userAnswers,
    int topK = 3,
  }) async {
    // 1. 비현실적인 조합 체크
    final unrealisticReason = _checkUnrealisticCombinations(userAnswers);
    if (unrealisticReason != null) {
      throw Exception(unrealisticReason);
    }

    // 2. 사용자 요구사항 엔티티 생성
    final criteria = RecommendationCriteriaEntity.fromUserAnswers(userAnswers);

    // 3. Firestore에서 재고가 있는 부품들 조회
    final availableParts = await _basePartRepository.getAllAvailableParts(
      minListingCount: 1,
    );

    // 4. 재고 체크
    if (availableParts['cpu']?.isEmpty ?? true) {
      throw Exception('현재 CPU 재고가 부족합니다.');
    }
    if (availableParts['gpu']?.isEmpty ?? true) {
      throw Exception('현재 GPU 재고가 부족합니다.');
    }
    if (availableParts['mainboard']?.isEmpty ?? true) {
      throw Exception('현재 메인보드 재고가 부족합니다.');
    }

    // 5. 추천 엔진으로 PC 구성 추천
    final recommendations = await _recommendationEngine.recommendBuilds(
      criteria: criteria,
      availableParts: availableParts,
      topK: topK,
    );

    if (recommendations.isEmpty) {
      throw Exception('조건에 맞는 PC 구성을 찾지 못했습니다. 예산 범위를 조정해보세요.');
    }

    return recommendations;
  }
}
