// lib/features/refund/data/repositories/refund_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/refund_request_entity.dart';
import '../../domain/repositories/refund_repository.dart';
import '../datasources/refund_remote_datasource.dart';
import '../models/refund_request_model.dart';
import '../../../../core/utils/notification_helper.dart';

/// 환불 Repository 구현체
class RefundRepositoryImpl implements RefundRepository {
  final RefundRemoteDataSource _remoteDataSource;
  final NotificationHelper _notificationHelper;

  RefundRepositoryImpl({
    RefundRemoteDataSource? remoteDataSource,
    NotificationHelper? notificationHelper,
  })  : _remoteDataSource = remoteDataSource ?? RefundRemoteDataSource(),
        _notificationHelper = notificationHelper ?? NotificationHelper();

  // ===== 환불 신청 관련 =====

  @override
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
  }) async {
    final refundRequest = RefundRequestModel(
      refundId: '', // Firestore will generate
      orderId: orderId,
      userId: userId,
      sellerId: sellerId,
      reason: reason,
      status: RefundStatus.pending,
      detailReason: detailReason,
      photoUrls: photoUrls,
      sealIntact: sealIntact,
      requestedAt: Timestamp.now(),
      originalAmount: originalAmount,
      shippingFee: shippingFee,
      refundAmount: refundAmount,
      refundCalculationNote: refundCalculationNote,
    );

    final refundId = await _remoteDataSource.createRefundRequest(refundRequest);

    // ✅ 판매자에게 환불 신청 접수 알림 발송
    await _notificationHelper.notifyRefundRequested(
      sellerId: sellerId,
      refundId: refundId,
      orderId: orderId,
      partName: '주문 상품', // TODO: Order에서 실제 상품명 가져오기
      reason: reason.displayName,
    );

    return refundId;
  }

  @override
  Future<RefundRequestEntity?> getRefundRequest(String refundId) async {
    final model = await _remoteDataSource.getRefundRequest(refundId);
    return model != null ? RefundRequestEntity.fromModel(model) : null;
  }

  @override
  Future<RefundRequestEntity?> getRefundRequestByOrderId(String orderId) async {
    final model = await _remoteDataSource.getRefundRequestByOrderId(orderId);
    return model != null ? RefundRequestEntity.fromModel(model) : null;
  }

  @override
  Stream<List<RefundRequestEntity>> watchUserRefundRequests(String userId) {
    return _remoteDataSource
        .watchUserRefundRequests(userId)
        .map((models) => models.map((m) => RefundRequestEntity.fromModel(m)).toList());
  }

  @override
  Stream<List<RefundRequestEntity>> watchSellerRefundRequests(String sellerId) {
    return _remoteDataSource
        .watchSellerRefundRequests(sellerId)
        .map((models) => models.map((m) => RefundRequestEntity.fromModel(m)).toList());
  }

  // ===== 환불 상태 변경 =====

  @override
  Future<void> approveRefund(String refundId) async {
    // 환불 정보 조회
    final refund = await _remoteDataSource.getRefundRequest(refundId);
    if (refund == null) return;

    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.approved.name,
      'approvedAt': Timestamp.now(),
    });

    // ✅ 구매자에게 환불 승인 알림 발송
    await _notificationHelper.notifyRefundApproved(
      buyerId: refund.userId,
      refundId: refundId,
      orderId: refund.orderId,
      partName: '주문 상품', // TODO: Order에서 실제 상품명 가져오기
    );
  }

  @override
  Future<void> rejectRefund(String refundId, String rejectReason) async {
    // 환불 정보 조회
    final refund = await _remoteDataSource.getRefundRequest(refundId);
    if (refund == null) return;

    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.rejected.name,
      'rejectReason': rejectReason,
    });

    // ✅ 구매자에게 환불 거부 알림 발송
    await _notificationHelper.notifyRefundRejected(
      buyerId: refund.userId,
      refundId: refundId,
      orderId: refund.orderId,
      partName: '주문 상품', // TODO: Order에서 실제 상품명 가져오기
      rejectReason: rejectReason,
    );
  }

  @override
  Future<void> markItemShipped(String refundId, String trackingNumber, String courierCompany) async {
    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.itemShipped.name,
      'trackingNumber': trackingNumber,
      'courierCompany': courierCompany,
      'itemShippedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> markItemReceived(String refundId) async {
    // 환불 정보 조회
    final refund = await _remoteDataSource.getRefundRequest(refundId);
    if (refund == null) return;

    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.itemReceived.name,
      'itemReceivedAt': Timestamp.now(),
    });

    // ✅ 구매자에게 반품 물품 수령 알림 발송
    await _notificationHelper.notifyReturnItemReceived(
      buyerId: refund.userId,
      refundId: refundId,
      orderId: refund.orderId,
      partName: '주문 상품', // TODO: Order에서 실제 상품명 가져오기
    );
  }

  // ===== 검수 관련 =====

  @override
  Future<void> startInspection(String refundId, String inspectorId) async {
    // 환불 정보 조회
    final refund = await _remoteDataSource.getRefundRequest(refundId);
    if (refund == null) return;

    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.inspectionInProgress.name,
      'inspectorId': inspectorId,
    });

    // ✅ 구매자에게 환불 검수 중 알림 발송
    await _notificationHelper.notifyRefundInspecting(
      buyerId: refund.userId,
      refundId: refundId,
      orderId: refund.orderId,
      partName: '주문 상품', // TODO: Order에서 실제 상품명 가져오기
    );
  }

  @override
  Future<void> markInspectionPass(
    String refundId,
    String inspectorId,
    String inspectionNote,
    List<String> inspectionPhotoUrls,
  ) async {
    // 환불 정보 조회
    final refund = await _remoteDataSource.getRefundRequest(refundId);
    if (refund == null) return;

    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.inspectionPass.name,
      'inspectorId': inspectorId,
      'inspectionNote': inspectionNote,
      'inspectionPhotoUrls': inspectionPhotoUrls,
      'inspectionCompletedAt': Timestamp.now(),
    });

    // ✅ 구매자에게 환불 검수 합격 알림 발송
    await _notificationHelper.notifyRefundInspectionPass(
      buyerId: refund.userId,
      refundId: refundId,
      orderId: refund.orderId,
      partName: '주문 상품', // TODO: Order에서 실제 상품명 가져오기
      refundAmount: refund.refundAmount,
    );
  }

  @override
  Future<void> markInspectionFail(
    String refundId,
    String inspectorId,
    String failReason,
    List<String> inspectionPhotoUrls,
    String returnTrackingNumber,
    String returnCourierCompany,
  ) async {
    // 환불 정보 조회
    final refund = await _remoteDataSource.getRefundRequest(refundId);
    if (refund == null) return;

    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.inspectionFail.name,
      'inspectorId': inspectorId,
      'failReason': failReason,
      'inspectionPhotoUrls': inspectionPhotoUrls,
      'inspectionCompletedAt': Timestamp.now(),
      'returnTrackingNumber': returnTrackingNumber,
      'returnCourierCompany': returnCourierCompany,
    });

    // ✅ 구매자에게 환불 검수 불합격 알림 발송
    await _notificationHelper.notifyRefundInspectionFail(
      buyerId: refund.userId,
      refundId: refundId,
      orderId: refund.orderId,
      partName: '주문 상품', // TODO: Order에서 실제 상품명 가져오기
      failReason: failReason,
      trackingNumber: returnTrackingNumber,
    );
  }

  // ===== 환불 처리 =====

  @override
  Future<void> startRefundProcessing(String refundId) async {
    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.refundProcessing.name,
    });
  }

  @override
  Future<void> completeRefund(String refundId) async {
    // 환불 정보 조회
    final refund = await _remoteDataSource.getRefundRequest(refundId);
    if (refund == null) return;

    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.refundCompleted.name,
      'refundCompletedAt': Timestamp.now(),
    });

    // ✅ 구매자에게 환불 완료 알림 발송
    await _notificationHelper.notifyRefundCompleted(
      buyerId: refund.userId,
      refundId: refundId,
      orderId: refund.orderId,
      partName: '주문 상품', // TODO: Order에서 실제 상품명 가져오기
      refundAmount: refund.refundAmount,
    );
  }

  @override
  Future<void> cancelRefund(String refundId) async {
    await _remoteDataSource.updateRefundRequest(refundId, {
      'status': RefundStatus.cancelled.name,
    });
  }

  @override
  Future<void> updateReturnAddress(
    String refundId, {
    required String name,
    required String phone,
    required String address,
  }) async {
    final refund = await _remoteDataSource.getRefundRequest(refundId);
    if (refund == null) {
      throw Exception('환불 요청을 찾을 수 없습니다');
    }

    // 검수 불합격 상태인지 확인
    if (refund.status != RefundStatus.inspectionFail) {
      throw Exception('검수 불합격 상태만 재발송 주소를 입력할 수 있습니다');
    }

    await _remoteDataSource.updateRefundRequest(refundId, {
      'returnAddress': {
        'name': name,
        'phone': phone,
        'address': address,
        'updatedAt': Timestamp.now(),
      },
    });
  }

  // ===== 통계 및 관리 =====

  @override
  Stream<List<RefundRequestEntity>> watchPendingInspections() {
    return _remoteDataSource
        .watchPendingInspections()
        .map((models) => models.map((m) => RefundRequestEntity.fromModel(m)).toList());
  }

  @override
  Stream<List<RefundRequestEntity>> watchPendingRefunds() {
    return _remoteDataSource
        .watchPendingRefunds()
        .map((models) => models.map((m) => RefundRequestEntity.fromModel(m)).toList());
  }

  @override
  Future<Map<String, dynamic>> getRefundStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _remoteDataSource.getRefundStatistics(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
