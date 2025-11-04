// lib/core/models/batch_shipment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 일괄 배송 상태
enum BatchShipmentStatus {
  pending,      // 대기 중
  processing,   // 처리 중
  shipped,      // 배송 중
  delivered,    // 배송 완료
}

/// 일괄 배송 모델
/// 드래곤볼에 보관된 여러 부품을 한 번에 배송하는 요청
/// Firestore: batchShipments/{batchShipmentId}
class BatchShipmentModel {
  final String batchShipmentId;
  final String userId;
  final List<String> dragonBallIds;       // 포함된 드래곤볼 ID 목록
  final String recipientName;             // 수령인
  final String shippingAddress;           // 배송지
  final String phoneNumber;               // 연락처
  final int shippingCost;                 // 배송비
  final BatchShipmentStatus status;       // 배송 상태
  final DateTime requestedAt;             // 요청일
  final DateTime? shippedAt;              // 배송 시작일
  final DateTime? deliveredAt;            // 배송 완료일
  final String? trackingNumber;           // 운송장 번호
  final String? courier;                  // 택배사

  BatchShipmentModel({
    required this.batchShipmentId,
    required this.userId,
    required this.dragonBallIds,
    required this.recipientName,
    required this.shippingAddress,
    required this.phoneNumber,
    required this.shippingCost,
    required this.status,
    required this.requestedAt,
    this.shippedAt,
    this.deliveredAt,
    this.trackingNumber,
    this.courier,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'batchShipmentId': batchShipmentId,
      'userId': userId,
      'dragonBallIds': dragonBallIds,
      'recipientName': recipientName,
      'shippingAddress': shippingAddress,
      'phoneNumber': phoneNumber,
      'shippingCost': shippingCost,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'trackingNumber': trackingNumber,
      'courier': courier,
    };
  }

  /// Firestore 문서에서 생성
  factory BatchShipmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BatchShipmentModel(
      batchShipmentId: doc.id,
      userId: data['userId'] ?? '',
      dragonBallIds: List<String>.from(data['dragonBallIds'] ?? []),
      recipientName: data['recipientName'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      shippingCost: (data['shippingCost'] as num?)?.toInt() ?? 0,
      status: _parseStatus(data['status']),
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shippedAt: (data['shippedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      trackingNumber: data['trackingNumber'],
      courier: data['courier'],
    );
  }

  /// Map에서 생성
  factory BatchShipmentModel.fromMap(Map<String, dynamic> data) {
    return BatchShipmentModel(
      batchShipmentId: data['batchShipmentId'] ?? '',
      userId: data['userId'] ?? '',
      dragonBallIds: List<String>.from(data['dragonBallIds'] ?? []),
      recipientName: data['recipientName'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      shippingCost: (data['shippingCost'] as num?)?.toInt() ?? 0,
      status: _parseStatus(data['status']),
      requestedAt: data['requestedAt'] is Timestamp
          ? (data['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      shippedAt: data['shippedAt'] is Timestamp
          ? (data['shippedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['deliveredAt'] is Timestamp
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      trackingNumber: data['trackingNumber'],
      courier: data['courier'],
    );
  }

  /// 상태 파싱 헬퍼
  static BatchShipmentStatus _parseStatus(dynamic status) {
    if (status == null) return BatchShipmentStatus.pending;

    switch (status.toString()) {
      case 'pending':
        return BatchShipmentStatus.pending;
      case 'processing':
        return BatchShipmentStatus.processing;
      case 'shipped':
        return BatchShipmentStatus.shipped;
      case 'delivered':
        return BatchShipmentStatus.delivered;
      default:
        return BatchShipmentStatus.pending;
    }
  }

  /// copyWith 메서드
  BatchShipmentModel copyWith({
    String? batchShipmentId,
    String? userId,
    List<String>? dragonBallIds,
    String? recipientName,
    String? shippingAddress,
    String? phoneNumber,
    int? shippingCost,
    BatchShipmentStatus? status,
    DateTime? requestedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? trackingNumber,
    String? courier,
  }) {
    return BatchShipmentModel(
      batchShipmentId: batchShipmentId ?? this.batchShipmentId,
      userId: userId ?? this.userId,
      dragonBallIds: dragonBallIds ?? this.dragonBallIds,
      recipientName: recipientName ?? this.recipientName,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shippingCost: shippingCost ?? this.shippingCost,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      courier: courier ?? this.courier,
    );
  }

  /// 상태 배지 텍스트
  String get statusBadgeText {
    switch (status) {
      case BatchShipmentStatus.pending:
        return '대기 중';
      case BatchShipmentStatus.processing:
        return '처리 중';
      case BatchShipmentStatus.shipped:
        return '배송 중';
      case BatchShipmentStatus.delivered:
        return '배송 완료';
    }
  }

  /// 상태 배지 색상 (Material Color name)
  String get statusBadgeColor {
    switch (status) {
      case BatchShipmentStatus.pending:
        return 'orange';
      case BatchShipmentStatus.processing:
        return 'blue';
      case BatchShipmentStatus.shipped:
        return 'purple';
      case BatchShipmentStatus.delivered:
        return 'green';
    }
  }

  /// 부품 개수
  int get itemCount => dragonBallIds.length;
}

/// 배송비 계산 유틸리티
class ShippingCostCalculator {
  /// 일괄 배송 배송비 계산
  /// 기본: 10,000원
  /// 부품 2개 이상: 개당 3,000원 추가
  static int calculateBatchShippingCost(int itemCount) {
    if (itemCount <= 0) return 0;
    if (itemCount == 1) return 10000;

    // 기본 10,000원 + (추가 부품 수 × 3,000원)
    return 10000 + ((itemCount - 1) * 3000);
  }

  /// 개별 배송 총 비용 (비교용)
  /// 각 부품마다 10,000원씩
  static int calculateIndividualShippingCost(int itemCount) {
    return itemCount * 10000;
  }

  /// 절약액 계산
  static int calculateSavings(int itemCount) {
    final individual = calculateIndividualShippingCost(itemCount);
    final batch = calculateBatchShippingCost(itemCount);
    return individual - batch;
  }

  /// 절약 비율 (%)
  static double calculateSavingsPercentage(int itemCount) {
    if (itemCount <= 1) return 0.0;

    final individual = calculateIndividualShippingCost(itemCount);
    final savings = calculateSavings(itemCount);

    return (savings / individual) * 100;
  }
}
