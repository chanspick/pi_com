// lib/features/dragon_ball/domain/entities/batch_shipment_entity.dart

import 'package:pi_com/core/models/batch_shipment_model.dart';

/// 일괄 배송 엔티티 (Domain Layer)
class BatchShipmentEntity {
  final String batchShipmentId;
  final String userId;
  final List<String> dragonBallIds;
  final String recipientName;
  final String shippingAddress;
  final String phoneNumber;
  final int shippingCost;
  final List<String> additionalServices;
  final int additionalServicesCost;
  final BatchShipmentStatus status;
  final DateTime requestedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? trackingNumber;
  final String? courier;

  BatchShipmentEntity({
    required this.batchShipmentId,
    required this.userId,
    required this.dragonBallIds,
    required this.recipientName,
    required this.shippingAddress,
    required this.phoneNumber,
    required this.shippingCost,
    this.additionalServices = const [],
    this.additionalServicesCost = 0,
    required this.status,
    required this.requestedAt,
    this.shippedAt,
    this.deliveredAt,
    this.trackingNumber,
    this.courier,
  });

  /// 모델에서 엔티티 생성
  factory BatchShipmentEntity.fromModel(BatchShipmentModel model) {
    return BatchShipmentEntity(
      batchShipmentId: model.batchShipmentId,
      userId: model.userId,
      dragonBallIds: model.dragonBallIds,
      recipientName: model.recipientName,
      shippingAddress: model.shippingAddress,
      phoneNumber: model.phoneNumber,
      shippingCost: model.shippingCost,
      additionalServices: model.additionalServices,
      additionalServicesCost: model.additionalServicesCost,
      status: model.status,
      requestedAt: model.requestedAt,
      shippedAt: model.shippedAt,
      deliveredAt: model.deliveredAt,
      trackingNumber: model.trackingNumber,
      courier: model.courier,
    );
  }

  /// 엔티티에서 모델 생성
  BatchShipmentModel toModel() {
    return BatchShipmentModel(
      batchShipmentId: batchShipmentId,
      userId: userId,
      dragonBallIds: dragonBallIds,
      recipientName: recipientName,
      shippingAddress: shippingAddress,
      phoneNumber: phoneNumber,
      shippingCost: shippingCost,
      additionalServices: additionalServices,
      additionalServicesCost: additionalServicesCost,
      status: status,
      requestedAt: requestedAt,
      shippedAt: shippedAt,
      deliveredAt: deliveredAt,
      trackingNumber: trackingNumber,
      courier: courier,
    );
  }

  // 비즈니스 로직 메서드들

  /// 부품 개수
  int get itemCount => dragonBallIds.length;

  /// 배송 대기 중
  bool get isPending => status == BatchShipmentStatus.pending;

  /// 배송 중
  bool get isShipping => status == BatchShipmentStatus.shipped;

  /// 배송 완료
  bool get isDelivered => status == BatchShipmentStatus.delivered;

  /// 운송장 번호 존재 여부
  bool get hasTrackingNumber => trackingNumber != null && trackingNumber!.isNotEmpty;

  /// 배송 취소 가능 여부
  bool canBeCancelled() {
    return status == BatchShipmentStatus.pending || status == BatchShipmentStatus.processing;
  }
}
