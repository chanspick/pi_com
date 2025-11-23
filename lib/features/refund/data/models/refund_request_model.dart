// lib/features/refund/data/models/refund_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 환불 사유 (약관 제2조 참조)
enum RefundReason {
  simpleChange,      // 단순 변심 (7일 이내)
  malfunction,       // 제품 기능 불량 (30일 이내)
  wrongProduct,      // 오배송 (30일 이내)
  inspectionError,   // 검수 오류 (30일 이내)
  damagedDelivery,   // 배송 중 파손 (30일 이내)
}

/// 환불 진행 상태
enum RefundStatus {
  pending,              // 신청 접수됨
  approved,             // 승인됨 (반품 택배 발송 가능)
  rejected,             // 거부됨
  itemShipped,          // 반품 물품 발송됨
  itemReceived,         // 반품 물품 수령됨 (검수 시작)
  inspectionInProgress, // 검수 진행 중 (3영업일 이내)
  inspectionPass,       // 검수 합격
  inspectionFail,       // 검수 불합격 (재발송)
  refundProcessing,     // 환불 처리 중 (카카오페이 연동)
  refundCompleted,      // 환불 완료
  cancelled,            // 신청 취소됨
}

/// 환불 신청 모델
class RefundRequestModel {
  final String refundId;
  final String orderId;
  final String userId;
  final String sellerId;           // 판매자 ID

  final RefundReason reason;
  final RefundStatus status;
  final String detailReason;       // 상세 사유

  // 증빙 자료 (약관 제3조 - 봉인 씰 확인 필수)
  final List<String> photoUrls;    // 봉인 씰, 외관, 불량 부분 사진
  final bool sealIntact;           // 봉인 씰 온전 여부 (파손 시 환불 불가)

  // 날짜 정보
  final Timestamp requestedAt;     // 환불 신청일
  final Timestamp? approvedAt;     // 승인일
  final Timestamp? itemShippedAt;  // 반품 발송일
  final Timestamp? itemReceivedAt; // 반품 수령일 (검수 시작)
  final Timestamp? inspectionCompletedAt; // 검수 완료일 (3영업일 이내)
  final Timestamp? refundCompletedAt;     // 환불 완료일

  // 배송 정보
  final String? trackingNumber;    // 반품 택배 송장번호
  final String? courierCompany;    // 택배사

  // 환불 금액 정보 (약관 제5조)
  final int originalAmount;        // 원 결제 금액
  final int shippingFee;           // 편도 배송비
  final int refundAmount;          // 실제 환불 금액
  final String? refundCalculationNote; // 환불 금액 계산 설명

  // 검수 정보
  final String? inspectorId;       // 검수자 ID
  final String? inspectionNote;    // 검수 의견
  final List<String>? inspectionPhotoUrls; // 검수 사진

  // 거부/불합격 정보
  final String? rejectReason;      // 신청 거부 사유
  final String? failReason;        // 검수 불합격 사유

  // 반품 배송 정보 (검수 불합격 시 재발송)
  final String? returnTrackingNumber;    // 재발송 송장번호
  final String? returnCourierCompany;    // 재발송 택배사

  RefundRequestModel({
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

  /// Firestore → Model
  factory RefundRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RefundRequestModel(
      refundId: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      reason: RefundReason.values.firstWhere(
        (e) => e.name == data['reason'],
        orElse: () => RefundReason.simpleChange,
      ),
      status: RefundStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RefundStatus.pending,
      ),
      detailReason: data['detailReason'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      sealIntact: data['sealIntact'] ?? false,
      requestedAt: data['requestedAt'] ?? Timestamp.now(),
      approvedAt: data['approvedAt'],
      itemShippedAt: data['itemShippedAt'],
      itemReceivedAt: data['itemReceivedAt'],
      inspectionCompletedAt: data['inspectionCompletedAt'],
      refundCompletedAt: data['refundCompletedAt'],
      trackingNumber: data['trackingNumber'],
      courierCompany: data['courierCompany'],
      originalAmount: data['originalAmount'] ?? 0,
      shippingFee: data['shippingFee'] ?? 0,
      refundAmount: data['refundAmount'] ?? 0,
      refundCalculationNote: data['refundCalculationNote'],
      inspectorId: data['inspectorId'],
      inspectionNote: data['inspectionNote'],
      inspectionPhotoUrls: data['inspectionPhotoUrls'] != null
          ? List<String>.from(data['inspectionPhotoUrls'])
          : null,
      rejectReason: data['rejectReason'],
      failReason: data['failReason'],
      returnTrackingNumber: data['returnTrackingNumber'],
      returnCourierCompany: data['returnCourierCompany'],
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'userId': userId,
      'sellerId': sellerId,
      'reason': reason.name,
      'status': status.name,
      'detailReason': detailReason,
      'photoUrls': photoUrls,
      'sealIntact': sealIntact,
      'requestedAt': requestedAt,
      'approvedAt': approvedAt,
      'itemShippedAt': itemShippedAt,
      'itemReceivedAt': itemReceivedAt,
      'inspectionCompletedAt': inspectionCompletedAt,
      'refundCompletedAt': refundCompletedAt,
      'trackingNumber': trackingNumber,
      'courierCompany': courierCompany,
      'originalAmount': originalAmount,
      'shippingFee': shippingFee,
      'refundAmount': refundAmount,
      'refundCalculationNote': refundCalculationNote,
      'inspectorId': inspectorId,
      'inspectionNote': inspectionNote,
      'inspectionPhotoUrls': inspectionPhotoUrls,
      'rejectReason': rejectReason,
      'failReason': failReason,
      'returnTrackingNumber': returnTrackingNumber,
      'returnCourierCompany': returnCourierCompany,
    };
  }

  /// copyWith 메서드
  RefundRequestModel copyWith({
    String? refundId,
    String? orderId,
    String? userId,
    String? sellerId,
    RefundReason? reason,
    RefundStatus? status,
    String? detailReason,
    List<String>? photoUrls,
    bool? sealIntact,
    Timestamp? requestedAt,
    Timestamp? approvedAt,
    Timestamp? itemShippedAt,
    Timestamp? itemReceivedAt,
    Timestamp? inspectionCompletedAt,
    Timestamp? refundCompletedAt,
    String? trackingNumber,
    String? courierCompany,
    int? originalAmount,
    int? shippingFee,
    int? refundAmount,
    String? refundCalculationNote,
    String? inspectorId,
    String? inspectionNote,
    List<String>? inspectionPhotoUrls,
    String? rejectReason,
    String? failReason,
    String? returnTrackingNumber,
    String? returnCourierCompany,
  }) {
    return RefundRequestModel(
      refundId: refundId ?? this.refundId,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      detailReason: detailReason ?? this.detailReason,
      photoUrls: photoUrls ?? this.photoUrls,
      sealIntact: sealIntact ?? this.sealIntact,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      itemShippedAt: itemShippedAt ?? this.itemShippedAt,
      itemReceivedAt: itemReceivedAt ?? this.itemReceivedAt,
      inspectionCompletedAt: inspectionCompletedAt ?? this.inspectionCompletedAt,
      refundCompletedAt: refundCompletedAt ?? this.refundCompletedAt,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      courierCompany: courierCompany ?? this.courierCompany,
      originalAmount: originalAmount ?? this.originalAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      refundAmount: refundAmount ?? this.refundAmount,
      refundCalculationNote: refundCalculationNote ?? this.refundCalculationNote,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectionNote: inspectionNote ?? this.inspectionNote,
      inspectionPhotoUrls: inspectionPhotoUrls ?? this.inspectionPhotoUrls,
      rejectReason: rejectReason ?? this.rejectReason,
      failReason: failReason ?? this.failReason,
      returnTrackingNumber: returnTrackingNumber ?? this.returnTrackingNumber,
      returnCourierCompany: returnCourierCompany ?? this.returnCourierCompany,
    );
  }
}

/// 환불 사유 한글 변환
extension RefundReasonExtension on RefundReason {
  String get displayName {
    switch (this) {
      case RefundReason.simpleChange:
        return '단순 변심';
      case RefundReason.malfunction:
        return '제품 기능 불량';
      case RefundReason.wrongProduct:
        return '오배송';
      case RefundReason.inspectionError:
        return '검수 오류';
      case RefundReason.damagedDelivery:
        return '배송 중 파손';
    }
  }

  /// 환불 기한 (일)
  int get returnPeriodDays {
    switch (this) {
      case RefundReason.simpleChange:
        return 7;  // 약관 제2조 1항
      default:
        return 30; // 약관 제2조 2항
    }
  }

  /// 구매자 귀책 여부
  bool get isBuyerFault {
    return this == RefundReason.simpleChange;
  }
}

/// 환불 상태 한글 변환
extension RefundStatusExtension on RefundStatus {
  String get displayName {
    switch (this) {
      case RefundStatus.pending:
        return '신청 접수';
      case RefundStatus.approved:
        return '승인됨';
      case RefundStatus.rejected:
        return '거부됨';
      case RefundStatus.itemShipped:
        return '반품 발송됨';
      case RefundStatus.itemReceived:
        return '반품 수령';
      case RefundStatus.inspectionInProgress:
        return '검수 중';
      case RefundStatus.inspectionPass:
        return '검수 합격';
      case RefundStatus.inspectionFail:
        return '검수 불합격';
      case RefundStatus.refundProcessing:
        return '환불 처리 중';
      case RefundStatus.refundCompleted:
        return '환불 완료';
      case RefundStatus.cancelled:
        return '신청 취소';
    }
  }

  /// 완료 상태 여부
  bool get isCompleted {
    return this == RefundStatus.refundCompleted ||
           this == RefundStatus.rejected ||
           this == RefundStatus.cancelled;
  }

  /// 진행 중 상태 여부
  bool get isInProgress {
    return !isCompleted;
  }
}
