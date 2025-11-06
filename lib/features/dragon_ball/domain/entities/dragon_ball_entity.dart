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
  final int accumulatedFee; // 누적 보관료

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
    this.accumulatedFee = 0,
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
      accumulatedFee: model.accumulatedFee,
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
      accumulatedFee: accumulatedFee,
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

  /// 보관료 계산
  /// 60일 이후 하루 1% 보관료 (구매가 기준)
  int calculateStorageFee() {
    final now = DateTime.now();
    final daysSinceStored = now.difference(storedAt).inDays;

    // 60일 이내는 무료
    if (daysSinceStored <= 60) {
      return 0;
    }

    // 60일 이후 하루 1%
    final overdueDays = daysSinceStored - 60;
    final dailyFee = (purchasePrice * 0.01).round(); // 1%
    return dailyFee * overdueDays;
  }

  /// 보관료율 계산 (구매가 대비 %)
  double calculateStorageFeePercentage() {
    if (purchasePrice == 0) return 0;
    final totalFee = calculateStorageFee() + accumulatedFee;
    return (totalFee / purchasePrice) * 100;
  }

  /// 소유권 이전 대상인지 (보관료 100% 초과)
  bool shouldTransferOwnership() {
    return calculateStorageFeePercentage() >= 100;
  }

  /// 60일 무료 기간 남은 일수
  int get freeDaysRemaining {
    final daysSinceStored = DateTime.now().difference(storedAt).inDays;
    final remaining = 60 - daysSinceStored;
    return remaining > 0 ? remaining : 0;
  }

  /// 60일 무료 기간 종료일
  DateTime get freeStorageEndsAt {
    return storedAt.add(const Duration(days: 60));
  }
}
