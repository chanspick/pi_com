// lib/core/utils/refund_calculator.dart

import 'package:pi_com/features/refund/data/models/refund_request_model.dart';

/// 환불 금액 계산 유틸리티 (약관 제5조 기반)
class RefundCalculator {
  /// 환불 금액 계산
  ///
  /// [reason]: 환불 사유
  /// [originalAmount]: 원 결제 금액
  /// [shippingFee]: 편도 배송비
  ///
  /// Returns: { 'refundAmount': int, 'note': String }
  static Map<String, dynamic> calculateRefund({
    required RefundReason reason,
    required int originalAmount,
    required int shippingFee,
  }) {
    int refundAmount;
    String note;

    if (reason.isBuyerFault) {
      // 구매자 귀책 (단순 변심) - 약관 제5조 1항
      // 환불액 = 원 결제 금액 - 왕복 배송비
      refundAmount = originalAmount - (shippingFee * 2);
      note = '단순 변심으로 인한 환불\n'
          '원 결제 금액: ${_formatCurrency(originalAmount)}원\n'
          '차감: 왕복 배송비 ${_formatCurrency(shippingFee * 2)}원\n'
          '환불액: ${_formatCurrency(refundAmount)}원';
    } else {
      // 판매자/제품 귀책 (불량, 오배송, 검수 오류, 배송 파손) - 약관 제5조 2항
      // 환불액 = 원 결제 금액 + 왕복 배송비
      refundAmount = originalAmount + (shippingFee * 2);
      note = '판매자/제품 귀책으로 인한 환불\n'
          '원 결제 금액: ${_formatCurrency(originalAmount)}원\n'
          '추가: 왕복 배송비 ${_formatCurrency(shippingFee * 2)}원\n'
          '환불액: ${_formatCurrency(refundAmount)}원';
    }

    return {
      'refundAmount': refundAmount,
      'note': note,
    };
  }

  /// 환불 가능 여부 및 남은 기한 확인
  ///
  /// [deliveredAt]: 배송 완료 시각
  /// [reason]: 환불 사유
  ///
  /// Returns: {
  ///   'canRefund': bool,
  ///   'daysRemaining': int?,
  ///   'deadline': DateTime?,
  ///   'message': String
  /// }
  static Map<String, dynamic> checkRefundEligibility({
    required DateTime deliveredAt,
    required RefundReason reason,
  }) {
    final now = DateTime.now();
    final daysSinceDelivery = now.difference(deliveredAt).inDays;
    final returnPeriodDays = reason.returnPeriodDays;
    final daysRemaining = returnPeriodDays - daysSinceDelivery;
    final deadline = deliveredAt.add(Duration(days: returnPeriodDays));

    final canRefund = daysRemaining >= 0;

    String message;
    if (canRefund) {
      if (reason.isBuyerFault) {
        message = '단순 변심 환불 가능 기간: ${daysRemaining}일 남음 (7일 이내)';
      } else {
        message = '제품 불량/오배송 환불 가능 기간: ${daysRemaining}일 남음 (30일 이내)';
      }
    } else {
      message = '환불 가능 기간이 지났습니다. (배송 완료 후 ${returnPeriodDays}일 이내)';
    }

    return {
      'canRefund': canRefund,
      'daysRemaining': daysRemaining,
      'deadline': deadline,
      'message': message,
    };
  }

  /// 봉인 씰 확인 (약관 제3조)
  ///
  /// [sealIntact]: 봉인 씰 온전 여부
  ///
  /// Returns: { 'canRefund': bool, 'message': String }
  static Map<String, dynamic> checkSealRequirement({
    required bool sealIntact,
  }) {
    if (!sealIntact) {
      return {
        'canRefund': false,
        'message': '봉인 씰이 파손되어 환불이 불가능합니다. (약관 제3조)\n'
            '홀로그램 봉인 씰이 온전한 상태여야 반품 가능합니다.',
      };
    }

    return {
      'canRefund': true,
      'message': '봉인 씰이 온전하여 환불 가능합니다.',
    };
  }

  /// 검수 기한 확인 (약관 제4조 - 3영업일 이내)
  ///
  /// [itemReceivedAt]: 반품 물품 수령 시각
  ///
  /// Returns: {
  ///   'daysRemaining': int,
  ///   'isOverdue': bool,
  ///   'deadline': DateTime,
  ///   'message': String
  /// }
  static Map<String, dynamic> checkInspectionDeadline({
    required DateTime itemReceivedAt,
  }) {
    final now = DateTime.now();
    final daysSinceReceived = now.difference(itemReceivedAt).inDays;
    final daysRemaining = 3 - daysSinceReceived;
    final deadline = itemReceivedAt.add(const Duration(days: 3));
    final isOverdue = daysRemaining < 0;

    String message;
    if (isOverdue) {
      message = '검수 기한이 ${-daysRemaining}일 초과되었습니다. (3영업일 이내 완료 필요)';
    } else {
      message = '검수 완료 기한: ${daysRemaining}일 남음 (3영업일 이내)';
    }

    return {
      'daysRemaining': daysRemaining,
      'isOverdue': isOverdue,
      'deadline': deadline,
      'message': message,
    };
  }

  /// 환불 완료 예상 일자 계산
  ///
  /// [status]: 현재 환불 상태
  /// [currentDate]: 기준 날짜 (현재 상태의 완료 시각)
  ///
  /// Returns: { 'estimatedDate': DateTime, 'message': String }
  static Map<String, dynamic> estimateRefundCompletion({
    required RefundStatus status,
    DateTime? currentDate,
  }) {
    final baseDate = currentDate ?? DateTime.now();
    DateTime estimatedDate;
    String message;

    switch (status) {
      case RefundStatus.pending:
        estimatedDate = baseDate.add(const Duration(days: 1)); // 승인 1일
        message = '환불 승인까지 약 1영업일 소요';
        break;

      case RefundStatus.approved:
        estimatedDate = baseDate.add(const Duration(days: 3)); // 반품 발송 2일 + 수령 1일
        message = '반품 택배 배송 및 수령까지 약 3일 소요';
        break;

      case RefundStatus.itemShipped:
        estimatedDate = baseDate.add(const Duration(days: 2)); // 배송 1일 + 수령 1일
        message = '반품 수령까지 약 2일 소요';
        break;

      case RefundStatus.itemReceived:
      case RefundStatus.inspectionInProgress:
        estimatedDate = baseDate.add(const Duration(days: 3)); // 검수 3영업일
        message = '검수 완료까지 약 3영업일 소요';
        break;

      case RefundStatus.inspectionPass:
      case RefundStatus.refundProcessing:
        estimatedDate = baseDate.add(const Duration(days: 2)); // 환불 처리 2일
        message = '환불 처리 완료까지 약 2영업일 소요';
        break;

      case RefundStatus.refundCompleted:
        estimatedDate = baseDate;
        message = '환불이 완료되었습니다.';
        break;

      case RefundStatus.rejected:
      case RefundStatus.cancelled:
        estimatedDate = baseDate;
        message = '환불이 거부/취소되었습니다.';
        break;

      case RefundStatus.inspectionFail:
        estimatedDate = baseDate.add(const Duration(days: 3)); // 재발송 3일
        message = '검수 불합격으로 반송 예정 (약 3일 소요)';
        break;
    }

    return {
      'estimatedDate': estimatedDate,
      'message': message,
    };
  }

  /// 금액 포맷팅 (3자리마다 콤마)
  static String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// 환불 가능 여부 종합 검사
  ///
  /// Returns: { 'canRefund': bool, 'issues': List<String> }
  static Map<String, dynamic> validateRefundRequest({
    required DateTime deliveredAt,
    required RefundReason reason,
    required bool sealIntact,
  }) {
    final issues = <String>[];

    // 1. 환불 기한 확인
    final eligibility = checkRefundEligibility(
      deliveredAt: deliveredAt,
      reason: reason,
    );
    if (!eligibility['canRefund']) {
      issues.add(eligibility['message']);
    }

    // 2. 봉인 씰 확인
    final sealCheck = checkSealRequirement(sealIntact: sealIntact);
    if (!sealCheck['canRefund']) {
      issues.add(sealCheck['message']);
    }

    return {
      'canRefund': issues.isEmpty,
      'issues': issues,
    };
  }
}
