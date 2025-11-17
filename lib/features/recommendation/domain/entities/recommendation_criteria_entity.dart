/// 추천 기준 엔티티 (사용자 요구사항)
class RecommendationCriteriaEntity {
  final String usage;            // 용도: G(게임), C(창작), O(사무/개발)
  final int minBudget;           // 최소 예산 (만원)
  final int maxBudget;           // 최대 예산 (만원)
  final int ssdCapacity;         // SSD 용량 (GB)

  // 게임용
  final List<String>? gameIds;   // 게임 번호 목록
  final String? resolution;      // 해상도
  final int? targetFps;          // 목표 FPS
  final String? graphicsQuality; // 그래픽 품질

  // 창작용
  final String? software;        // 주 사용 소프트웨어
  final String? projectScale;    // 프로젝트 규모
  final String? renderFrequency; // 렌더링 빈도

  // 사무/개발용
  final String? workType;        // 주요 업무
  final String? programCount;    // 동시 실행 프로그램 수
  final String? monitorCount;    // 모니터 개수
  final String? dataSize;        // 데이터 규모

  const RecommendationCriteriaEntity({
    required this.usage,
    required this.minBudget,
    required this.maxBudget,
    required this.ssdCapacity,
    this.gameIds,
    this.resolution,
    this.targetFps,
    this.graphicsQuality,
    this.software,
    this.projectScale,
    this.renderFrequency,
    this.workType,
    this.programCount,
    this.monitorCount,
    this.dataSize,
  });

  factory RecommendationCriteriaEntity.fromUserAnswers(Map<String, dynamic> answers) {
    final budgetParts = (answers['Q2'] as String).split(' ~ ');
    final minBudget = int.tryParse(budgetParts[0]) ?? 0;
    final maxBudget = int.tryParse(budgetParts[1]) ?? 0;

    // Q4G: 게임 카테고리를 그래픽 품질로 변환 (간소화된 설문지)
    // 'light', 'medium', 'heavy', 'ultra' -> 실제 요구사항으로 변환
    String? gameCategory = answers['Q4G'] as String?;
    String? derivedGraphicsQuality;
    if (gameCategory != null) {
      switch (gameCategory) {
        case 'light':
          derivedGraphicsQuality = '보통';  // 가벼운 게임 → 보통 품질
          break;
        case 'medium':
          derivedGraphicsQuality = '높음';  // 중간 게임 → 높은 품질
          break;
        case 'heavy':
          derivedGraphicsQuality = '최고';  // 무거운 게임 → 최고 품질
          break;
        case 'ultra':
          derivedGraphicsQuality = '레이트레이싱';  // 최신 AAA급 → 레이트레이싱
          break;
      }
    }

    return RecommendationCriteriaEntity(
      usage: answers['Q1'] as String,
      minBudget: minBudget,
      maxBudget: maxBudget,
      ssdCapacity: 500, // 고정 500GB
      // 게임용
      gameIds: null,  // 더 이상 게임 번호를 직접 입력받지 않음
      resolution: answers['Q5G'] as String?,
      targetFps: answers['Q6G'] as int?,
      graphicsQuality: answers['Q7G'] as String? ?? derivedGraphicsQuality,
      // 창작용
      software: answers['Q4C'] as String?,
      projectScale: answers['Q6C'] as String?,
      renderFrequency: answers['Q7C'] as String?,
      // 사무/개발용
      workType: answers['Q4O'] as String?,
      programCount: answers['Q5O'] as String?,
      monitorCount: answers['Q6O'] as String?,
      dataSize: answers['Q7O'] as String?,
    );
  }

  int get avgBudget => ((minBudget + maxBudget) / 2).toInt();
}
