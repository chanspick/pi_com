// lib/features/refund/domain/repositories/refund_repository.dart

import '../entities/refund_request_entity.dart';
import '../../data/models/refund_request_model.dart';

/// 환불 Repository Interface (Domain Layer)
abstract class RefundRepository {
  // ===== 환불 신청 관련 =====

  /// 환불 신청 생성
  Future<String> createRefundRequest({
    required String orderId,
    required String userId,
    required String sellerId,
    required RefundReason reason,
    required String detailReason,
    required List<String> photoUrls,
    required bool sealIntact,
    required int originalAmount,
    required int shippingFee,
    required int refundAmount,
    String? refundCalculationNote,
  });

  /// 환불 신청 조회 (단건)
  Future<RefundRequestEntity?> getRefundRequest(String refundId);

  /// 특정 주문의 환불 신청 조회
  Future<RefundRequestEntity?> getRefundRequestByOrderId(String orderId);

  /// 사용자의 모든 환불 신청 목록 조회 (Stream)
  Stream<List<RefundRequestEntity>> watchUserRefundRequests(String userId);

  /// 판매자의 모든 환불 신청 목록 조회 (Stream)
  Stream<List<RefundRequestEntity>> watchSellerRefundRequests(String sellerId);

  // ===== 환불 상태 변경 =====

  /// 환불 승인 (관리자/판매자)
  Future<void> approveRefund(String refundId);

  /// 환불 거부 (관리자/판매자)
  Future<void> rejectRefund(String refundId, String rejectReason);

  /// 반품 물품 발송 완료 (구매자)
  Future<void> markItemShipped(String refundId, String trackingNumber, String courierCompany);

  /// 반품 물품 수령 완료 (판매자/관리자)
  Future<void> markItemReceived(String refundId);

  // ===== 검수 관련 =====

  /// 검수 시작
  Future<void> startInspection(String refundId, String inspectorId);

  /// 검수 합격 처리
  Future<void> markInspectionPass(
    String refundId,
    String inspectorId,
    String inspectionNote,
    List<String> inspectionPhotoUrls,
  );

  /// 검수 불합격 처리 (재발송)
  Future<void> markInspectionFail(
    String refundId,
    String inspectorId,
    String failReason,
    List<String> inspectionPhotoUrls,
    String returnTrackingNumber,
    String returnCourierCompany,
  );

  // ===== 환불 처리 =====

  /// 환불 처리 시작 (카카오페이 연동)
  Future<void> startRefundProcessing(String refundId);

  /// 환불 완료 처리
  Future<void> completeRefund(String refundId);

  /// 환불 신청 취소 (구매자)
  Future<void> cancelRefund(String refundId);

  /// 검수 불합격 후 재발송 주소 업데이트
  Future<void> updateReturnAddress(
    String refundId, {
    required String name,
    required String phone,
    required String address,
  });

  // ===== 통계 및 관리 =====

  /// 검수 대기 중인 환불 목록 (관리자용)
  Stream<List<RefundRequestEntity>> watchPendingInspections();

  /// 환불 처리 대기 중인 목록 (관리자용)
  Stream<List<RefundRequestEntity>> watchPendingRefunds();

  /// 특정 기간의 환불 통계
  Future<Map<String, dynamic>> getRefundStatistics({
    required DateTime startDate,
    required DateTime endDate,
  });
}
