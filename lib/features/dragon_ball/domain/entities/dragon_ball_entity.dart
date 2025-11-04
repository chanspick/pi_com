// lib/features/dragon_ball/domain/entities/dragon_ball_entity.dart

import 'package:pi_com/core/models/dragon_ball_model.dart';

/// 드래곤볼 엔티티 (Domain Layer)
class DragonBallEntity {
  final String dragonBallId;
  final String userId;
  final String listingId;
  final String orderId;
  final String partName;
  final String? imageUrl;
  final DragonBallStatus status;
  final DateTime storedAt;
  final DateTime expiresAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? batchShipmentId;
  final bool agreedToTerms;
  final DateTime agreedAt;
  final int purchasePrice;
  final String? basePartId;
  final String? category;

  DragonBallEntity({
    required this.dragonBallId,
    required this.userId,
    required this.listingId,
    required this.orderId,
    required this.partName,
    this.imageUrl,
    required this.status,
    required this.storedAt,
    required this.expiresAt,
    this.shippedAt,
    this.deliveredAt,
    this.batchShipmentId,
    required this.agreedToTerms,
    required this.agreedAt,
    required this.purchasePrice,
    this.basePartId,
    this.category,
  });

  /// 모델에서 엔티티 생성
  factory DragonBallEntity.fromModel(DragonBallModel model) {
    return DragonBallEntity(
      dragonBallId: model.dragonBallId,
      userId: model.userId,
      listingId: model.listingId,
      orderId: model.orderId,
      partName: model.partName,
      imageUrl: model.imageUrl,
      status: model.status,
      storedAt: model.storedAt,
      expiresAt: model.expiresAt,
      shippedAt: model.shippedAt,
      deliveredAt: model.deliveredAt,
      batchShipmentId: model.batchShipmentId,
      agreedToTerms: model.agreedToTerms,
      agreedAt: model.agreedAt,
      purchasePrice: model.purchasePrice,
      basePartId: model.basePartId,
      category: model.category,
    );
  }

  /// 엔티티에서 모델 생성
  DragonBallModel toModel() {
    return DragonBallModel(
      dragonBallId: dragonBallId,
      userId: userId,
      listingId: listingId,
      orderId: orderId,
      partName: partName,
      imageUrl: imageUrl,
      status: status,
      storedAt: storedAt,
      expiresAt: expiresAt,
      shippedAt: shippedAt,
      deliveredAt: deliveredAt,
      batchShipmentId: batchShipmentId,
      agreedToTerms: agreedToTerms,
      agreedAt: agreedAt,
      purchasePrice: purchasePrice,
      basePartId: basePartId,
      category: category,
    );
  }

  // 비즈니스 로직 메서드들

  /// 보관 중 상태인지
  bool get isStored => status == DragonBallStatus.stored;

  /// 배송 가능 상태인지
  bool get isShippable => status == DragonBallStatus.stored;

  /// 배송 완료 여부
  bool get isDelivered => status == DragonBallStatus.delivered;

  /// 만료까지 남은 일수
  int get daysUntilExpiration {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 0;
    return expiresAt.difference(now).inDays;
  }

  /// 만료 임박 여부 (3일 이하)
  bool get isExpiringSoon {
    return daysUntilExpiration <= 3 && daysUntilExpiration > 0;
  }

  /// 만료됨 여부
  bool get isExpired {
    return daysUntilExpiration <= 0 && status == DragonBallStatus.stored;
  }

  /// 배송 요청 가능 여부 확인
  bool canRequestShipment() {
    return isStored && !isExpired;
  }

  /// 일괄 배송에 포함될 수 있는지
  bool canBeAddedToBatch() {
    return isStored && batchShipmentId == null;
  }
}
