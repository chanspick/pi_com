// lib/features/dragon_ball/domain/repositories/dragon_ball_repository.dart

import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/core/models/dragon_ball_model.dart';

/// 드래곤볼 Repository 인터페이스
abstract class DragonBallRepository {
  /// 사용자의 드래곤볼 목록 스트림 (실시간)
  Stream<List<DragonBallEntity>> getUserDragonBalls(String userId);

  /// 특정 드래곤볼 조회
  Future<DragonBallEntity?> getDragonBall(String userId, String dragonBallId);

  /// 드래곤볼 생성 (구매 완료 시)
  Future<String> createDragonBall({
    required String userId,
    required String listingId,
    required String orderId,
    required String partName,
    String? imageUrl,
    required int purchasePrice,
    String? basePartId,
    String? category,
    required bool agreedToTerms,
  });

  /// 드래곤볼 상태 업데이트
  Future<void> updateDragonBallStatus(
    String userId,
    String dragonBallId,
    DragonBallStatus status,
  );

  /// 일괄 배송 ID 연결
  Future<void> linkToBatchShipment(
    String userId,
    String dragonBallId,
    String batchShipmentId,
  );

  /// 배송 시작 (shippedAt 기록)
  Future<void> markAsShipped(String userId, String dragonBallId);

  /// 배송 완료 (deliveredAt 기록)
  Future<void> markAsDelivered(String userId, String dragonBallId);

  /// 만료 임박 드래곤볼 조회 (3일 이하)
  Future<List<DragonBallEntity>> getExpiringSoonDragonBalls(String userId);

  /// 보관 중인 드래곤볼만 조회
  Future<List<DragonBallEntity>> getStoredDragonBalls(String userId);

  /// 드래곤볼 삭제
  Future<void> deleteDragonBall(String userId, String dragonBallId);
}
