// lib/features/refund/data/datasources/refund_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/refund_request_model.dart';

/// 환불 Remote DataSource
class RefundRemoteDataSource {
  final FirebaseFirestore _firestore;

  RefundRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore 경로: /refund_requests/{refundId}
  CollectionReference get _refundRequestsCollection =>
      _firestore.collection('refund_requests');

  // ===== CREATE =====

  /// 환불 신청 생성
  Future<String> createRefundRequest(RefundRequestModel refundRequest) async {
    final docRef = await _refundRequestsCollection.add(refundRequest.toFirestore());
    return docRef.id;
  }

  // ===== READ =====

  /// 환불 신청 조회 (단건)
  Future<RefundRequestModel?> getRefundRequest(String refundId) async {
    final doc = await _refundRequestsCollection.doc(refundId).get();
    if (!doc.exists) return null;
    return RefundRequestModel.fromFirestore(doc);
  }

  /// 특정 주문의 환불 신청 조회
  Future<RefundRequestModel?> getRefundRequestByOrderId(String orderId) async {
    final querySnapshot = await _refundRequestsCollection
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return RefundRequestModel.fromFirestore(querySnapshot.docs.first);
  }

  /// 사용자의 모든 환불 신청 목록 조회 (Stream)
  Stream<List<RefundRequestModel>> watchUserRefundRequests(String userId) {
    return _refundRequestsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RefundRequestModel.fromFirestore(doc))
            .toList());
  }

  /// 판매자의 모든 환불 신청 목록 조회 (Stream)
  Stream<List<RefundRequestModel>> watchSellerRefundRequests(String sellerId) {
    return _refundRequestsCollection
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RefundRequestModel.fromFirestore(doc))
            .toList());
  }

  /// 검수 대기 중인 환불 목록 (관리자용)
  Stream<List<RefundRequestModel>> watchPendingInspections() {
    return _refundRequestsCollection
        .where('status', whereIn: [
          RefundStatus.itemReceived.name,
          RefundStatus.inspectionInProgress.name,
        ])
        .orderBy('itemReceivedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RefundRequestModel.fromFirestore(doc))
            .toList());
  }

  /// 환불 처리 대기 중인 목록 (관리자용)
  Stream<List<RefundRequestModel>> watchPendingRefunds() {
    return _refundRequestsCollection
        .where('status', whereIn: [
          RefundStatus.inspectionPass.name,
          RefundStatus.refundProcessing.name,
        ])
        .orderBy('inspectionCompletedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RefundRequestModel.fromFirestore(doc))
            .toList());
  }

  // ===== UPDATE =====

  /// 환불 신청 업데이트
  Future<void> updateRefundRequest(String refundId, Map<String, dynamic> updates) async {
    await _refundRequestsCollection.doc(refundId).update(updates);
  }

  // ===== DELETE =====

  /// 환불 신청 삭제 (사용 주의)
  Future<void> deleteRefundRequest(String refundId) async {
    await _refundRequestsCollection.doc(refundId).delete();
  }

  // ===== 통계 =====

  /// 특정 기간의 환불 통계
  Future<Map<String, dynamic>> getRefundStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final querySnapshot = await _refundRequestsCollection
        .where('requestedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('requestedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final refunds = querySnapshot.docs
        .map((doc) => RefundRequestModel.fromFirestore(doc))
        .toList();

    // 통계 계산
    final totalRequests = refunds.length;
    final approvedCount = refunds.where((r) => r.status == RefundStatus.approved ||
                                                r.status == RefundStatus.refundCompleted).length;
    final rejectedCount = refunds.where((r) => r.status == RefundStatus.rejected).length;
    final completedCount = refunds.where((r) => r.status == RefundStatus.refundCompleted).length;
    final inspectionPassCount = refunds.where((r) => r.status == RefundStatus.inspectionPass).length;
    final inspectionFailCount = refunds.where((r) => r.status == RefundStatus.inspectionFail).length;

    final totalRefundAmount = refunds
        .where((r) => r.status == RefundStatus.refundCompleted)
        .fold(0, (sum, r) => sum + r.refundAmount);

    // 사유별 통계
    final reasonCounts = <RefundReason, int>{};
    for (final reason in RefundReason.values) {
      reasonCounts[reason] = refunds.where((r) => r.reason == reason).length;
    }

    return {
      'totalRequests': totalRequests,
      'approvedCount': approvedCount,
      'rejectedCount': rejectedCount,
      'completedCount': completedCount,
      'inspectionPassCount': inspectionPassCount,
      'inspectionFailCount': inspectionFailCount,
      'totalRefundAmount': totalRefundAmount,
      'reasonCounts': reasonCounts.map((k, v) => MapEntry(k.name, v)),
      'averageRefundAmount': completedCount > 0 ? totalRefundAmount / completedCount : 0,
    };
  }
}
