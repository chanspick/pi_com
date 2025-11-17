import 'package:pi_com/core/models/sell_request_model.dart';

/// 컨디션 스코어 자동 계산 서비스
///
/// SellRequest의 정보를 기반으로 제품 상태 점수(1-100)를 자동 계산합니다.
class ConditionScoreCalculator {
  /// 추천 컨디션 스코어 계산
  ///
  /// Returns: (score, explanation) 튜플
  static ({double score, String explanation}) calculateScore(
    SellRequest sellRequest,
  ) {
    double baseScore = 100.0;
    List<String> reasons = [];

    // 1. 신제품/중고 여부 (기본 점수)
    if (!sellRequest.isSecondHand) {
      baseScore = 95.0;
      reasons.add('✅ 새 제품 (미개봉/미사용)');
    } else {
      baseScore = 85.0;
      reasons.add('📦 중고 제품');
    }

    // 2. 보증서 여부 (+5점)
    if (sellRequest.hasWarranty) {
      baseScore += 5.0;
      reasons.add('✅ 보증서 있음 (+5점)');
    } else {
      baseScore -= 5.0;
      reasons.add('⚠️ 보증서 없음 (-5점)');
    }

    // 3. 사용 빈도에 따른 감점
    final usageScore = _calculateUsageScore(sellRequest.usageFrequency);
    baseScore += usageScore;
    if (usageScore < 0) {
      reasons.add('📉 사용 빈도: ${sellRequest.usageFrequency} (${usageScore.toStringAsFixed(1)}점)');
    } else {
      reasons.add('📈 사용 빈도: ${sellRequest.usageFrequency} (양호)');
    }

    // 4. 사용 기간에 따른 감점
    final ageInMonths = _calculateAgeInMonths(sellRequest);
    if (ageInMonths != null) {
      final ageScore = _calculateAgeScore(ageInMonths);
      baseScore += ageScore;
      final ageText = _getAgeText(ageInMonths);
      if (ageScore < 0) {
        reasons.add('📅 사용 기간: $ageText (${ageScore.toStringAsFixed(1)}점)');
      } else {
        reasons.add('📅 사용 기간: $ageText (최신)');
      }
    }

    // 5. 사용 목적에 따른 가중치 (마이닝, 오버클럭 등은 감점)
    final purposeScore = _calculatePurposeScore(sellRequest.purpose);
    baseScore += purposeScore;
    if (purposeScore < 0) {
      reasons.add('⚠️ 사용 목적: ${sellRequest.purpose} (${purposeScore.toStringAsFixed(1)}점)');
    }

    // 6. 최종 점수 범위 제한 (1-100)
    final finalScore = baseScore.clamp(1.0, 100.0);

    // 설명 텍스트 생성
    final explanation = reasons.join('\n');

    return (score: finalScore, explanation: explanation);
  }

  /// SellRequest로부터 제품 나이를 개월 수로 계산
  static int? _calculateAgeInMonths(SellRequest sellRequest) {
    if (sellRequest.ageInfoYear == null) return null;

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 구매 연도와 월 계산
    final purchaseYear = sellRequest.ageInfoYear!;
    final purchaseMonth = sellRequest.ageInfoMonth ?? 1;

    // 개월 수 계산
    final monthsDiff = (currentYear - purchaseYear) * 12 + (currentMonth - purchaseMonth);

    return monthsDiff > 0 ? monthsDiff : 0;
  }

  /// 사용 빈도에 따른 점수 계산
  static double _calculateUsageScore(String? frequency) {
    if (frequency == null || frequency.isEmpty) return 0.0;

    final lowerFreq = frequency.toLowerCase();

    // 거의 사용 안 함
    if (lowerFreq.contains('거의') || lowerFreq.contains('없') || lowerFreq.contains('미사용')) {
      return 5.0;
    }
    // 가끔
    if (lowerFreq.contains('가끔') || lowerFreq.contains('주 1') || lowerFreq.contains('월')) {
      return 0.0;
    }
    // 자주 (주 3-5회)
    if (lowerFreq.contains('자주') || lowerFreq.contains('주 3') || lowerFreq.contains('주 5')) {
      return -5.0;
    }
    // 매일
    if (lowerFreq.contains('매일') || lowerFreq.contains('daily') || lowerFreq.contains('항상')) {
      return -10.0;
    }
    // 하루종일
    if (lowerFreq.contains('하루종일') || lowerFreq.contains('24시간') || lowerFreq.contains('계속')) {
      return -15.0;
    }

    return 0.0;
  }

  /// 사용 기간에 따른 점수 계산
  static double _calculateAgeScore(int months) {
    if (months <= 3) {
      return 5.0; // 3개월 이하: 거의 새것
    } else if (months <= 6) {
      return 0.0; // 6개월 이하: 양호
    } else if (months <= 12) {
      return -5.0; // 1년 이하: 약간 감점
    } else if (months <= 24) {
      return -10.0; // 2년 이하: 중간 감점
    } else if (months <= 36) {
      return -15.0; // 3년 이하: 높은 감점
    } else if (months <= 48) {
      return -20.0; // 4년 이하: 매우 높은 감점
    } else {
      return -25.0; // 4년 초과: 최대 감점
    }
  }

  /// 사용 목적에 따른 점수 계산
  static double _calculatePurposeScore(String? purpose) {
    if (purpose == null || purpose.isEmpty) return 0.0;

    final lowerPurpose = purpose.toLowerCase();

    // 마이닝, 서버 등 고부하 작업 (큰 감점)
    if (lowerPurpose.contains('마이닝') ||
        lowerPurpose.contains('mining') ||
        lowerPurpose.contains('렌더팜') ||
        lowerPurpose.contains('서버')) {
      return -20.0;
    }
    // 오버클럭, 게임 (중간 감점)
    if (lowerPurpose.contains('오버') ||
        lowerPurpose.contains('overclock') ||
        lowerPurpose.contains('게임')) {
      return -10.0;
    }
    // 업무용, 문서 작업 (감점 없음)
    if (lowerPurpose.contains('업무') ||
        lowerPurpose.contains('사무') ||
        lowerPurpose.contains('문서') ||
        lowerPurpose.contains('학습')) {
      return 5.0;
    }

    return 0.0;
  }

  /// 사용 기간 텍스트 변환
  static String _getAgeText(int months) {
    if (months < 1) {
      return '1개월 미만';
    } else if (months < 12) {
      return '$months개월';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years년';
      } else {
        return '$years년 $remainingMonths개월';
      }
    }
  }

  /// 점수에 따른 등급 텍스트
  static String getGradeText(double score) {
    if (score >= 95) {
      return 'S등급 (최상)';
    } else if (score >= 90) {
      return 'A+등급 (우수)';
    } else if (score >= 85) {
      return 'A등급 (양호)';
    } else if (score >= 80) {
      return 'B+등급 (보통 상)';
    } else if (score >= 75) {
      return 'B등급 (보통)';
    } else if (score >= 70) {
      return 'C+등급 (보통 하)';
    } else if (score >= 65) {
      return 'C등급 (다소 불량)';
    } else {
      return 'D등급 (불량)';
    }
  }

  /// 점수에 따른 색상 (UI용)
  static String getGradeColor(double score) {
    if (score >= 90) {
      return '#4CAF50'; // Green
    } else if (score >= 80) {
      return '#8BC34A'; // Light Green
    } else if (score >= 70) {
      return '#FFC107'; // Amber
    } else if (score >= 60) {
      return '#FF9800'; // Orange
    } else {
      return '#F44336'; // Red
    }
  }
}
