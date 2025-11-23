// lib/features/refund/domain/entities/refund_request_entity.dart

import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import '../../data/models/refund_request_model.dart';

/// 환불 신청 엔티티 (Domain Layer)
class RefundRequestEntity {
  final String refundId;
  final String orderId;
  final String userId;
  final String sellerId;

  final RefundReason reason;
  final RefundStatus status;
  final String detailReason;

  // 증빙 자료
  final List<String> photoUrls;
  final bool sealIntact;

  // 날짜 정보
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? itemShippedAt;
  final DateTime? itemReceivedAt;
  final DateTime? inspectionCompletedAt;
  final DateTime? refundCompletedAt;

  // 배송 정보
  final String? trackingNumber;
  final String? courierCompany;

  // 환불 금액 정보
  final int originalAmount;
  final int shippingFee;
  final int refundAmount;
  final String? refundCalculationNote;

  // 검수 정보
  final String? inspectorId;
  final String? inspectionNote;
  final List<String>? inspectionPhotoUrls;

  // 거부/불합격 정보
  final String? rejectReason;
  final String? failReason;

  // 반품 배송 정보
  final String? returnTrackingNumber;
  final String? returnCourierCompany;

  RefundRequestEntity({
    required this.refundId,
    required this.orderId,
    required this.userId,
    required this.sellerId,
    required this.reason,
    required this.status,
    required this.detailReason,
    required this.photoUrls,
    required this.sealIntact,
    required this.requestedAt,
    required this.originalAmount,
    required this.shippingFee,
    required this.refundAmount,
    this.approvedAt,
    this.itemShippedAt,
    this.itemReceivedAt,
    this.inspectionCompletedAt,
    this.refundCompletedAt,
    this.trackingNumber,
    this.courierCompany,
    this.refundCalculationNote,
    this.inspectorId,
    this.inspectionNote,
    this.inspectionPhotoUrls,
    this.rejectReason,
    this.failReason,
    this.returnTrackingNumber,
    this.returnCourierCompany,
  });

  /// Model → Entity
  factory RefundRequestEntity.fromModel(RefundRequestModel model) {
    return RefundRequestEntity(
      refundId: model.refundId,
      orderId: model.orderId,
      userId: model.userId,
      sellerId: model.sellerId,
      reason: model.reason,
      status: model.status,
      detailReason: model.detailReason,
      photoUrls: model.photoUrls,
      sealIntact: model.sealIntact,
      requestedAt: model.requestedAt.toDate(),
      approvedAt: model.approvedAt?.toDate(),
      itemShippedAt: model.itemShippedAt?.toDate(),
      itemReceivedAt: model.itemReceivedAt?.toDate(),
      inspectionCompletedAt: model.inspectionCompletedAt?.toDate(),
      refundCompletedAt: model.refundCompletedAt?.toDate(),
      trackingNumber: model.trackingNumber,
      courierCompany: model.courierCompany,
      originalAmount: model.originalAmount,
      shippingFee: model.shippingFee,
      refundAmount: model.refundAmount,
      refundCalculationNote: model.refundCalculationNote,
      inspectorId: model.inspectorId,
      inspectionNote: model.inspectionNote,
      inspectionPhotoUrls: model.inspectionPhotoUrls,
      rejectReason: model.rejectReason,
      failReason: model.failReason,
      returnTrackingNumber: model.returnTrackingNumber,
      returnCourierCompany: model.returnCourierCompany,
    );
  }

  /// Entity → Model
  RefundRequestModel toModel() {
    return RefundRequestModel(
      refundId: refundId,
      orderId: orderId,
      userId: userId,
      sellerId: sellerId,
      reason: reason,
      status: status,
      detailReason: detailReason,
      photoUrls: photoUrls,
      sealIntact: sealIntact,
      requestedAt: cloud_firestore.Timestamp.fromDate(requestedAt),
      approvedAt: approvedAt != null ? cloud_firestore.Timestamp.fromDate(approvedAt!) : null,
      itemShippedAt: itemShippedAt != null ? cloud_firestore.Timestamp.fromDate(itemShippedAt!) : null,
      itemReceivedAt: itemReceivedAt != null ? cloud_firestore.Timestamp.fromDate(itemReceivedAt!) : null,
      inspectionCompletedAt: inspectionCompletedAt != null ? cloud_firestore.Timestamp.fromDate(inspectionCompletedAt!) : null,
      refundCompletedAt: refundCompletedAt != null ? cloud_firestore.Timestamp.fromDate(refundCompletedAt!) : null,
      trackingNumber: trackingNumber,
      courierCompany: courierCompany,
      originalAmount: originalAmount,
      shippingFee: shippingFee,
      refundAmount: refundAmount,
      refundCalculationNote: refundCalculationNote,
      inspectorId: inspectorId,
      inspectionNote: inspectionNote,
      inspectionPhotoUrls: inspectionPhotoUrls,
      rejectReason: rejectReason,
      failReason: failReason,
      returnTrackingNumber: returnTrackingNumber,
      returnCourierCompany: returnCourierCompany,
    );
  }

  /// 검수 대기 중 여부
  bool get isPendingInspection {
    return status == RefundStatus.itemReceived ||
           status == RefundStatus.inspectionInProgress;
  }

  /// 환불 처리 중 여부
  bool get isRefundProcessing {
    return status == RefundStatus.inspectionPass ||
           status == RefundStatus.refundProcessing;
  }

  /// 검수 소요 시간 (영업일 기준 3일 이내 완료 필요)
  int? get inspectionDaysRemaining {
    if (itemReceivedAt == null) return null;
    if (inspectionCompletedAt != null) return null;

    final daysSinceReceived = DateTime.now().difference(itemReceivedAt!).inDays;
    return 3 - daysSinceReceived;
  }

  /// 검수 기한 초과 여부
  bool get isInspectionOverdue {
    final daysRemaining = inspectionDaysRemaining;
    if (daysRemaining == null) return false;
    return daysRemaining < 0;
  }
}
