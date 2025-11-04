// lib/features/dragon_ball/data/repositories/dragon_ball_repository_impl.dart

import 'package:pi_com/core/models/dragon_ball_model.dart';
import 'package:pi_com/features/dragon_ball/data/datasources/dragon_ball_remote_datasource.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';
import 'package:uuid/uuid.dart';

/// 드래곤볼 Repository 구현체
class DragonBallRepositoryImpl implements DragonBallRepository {
  final DragonBallRemoteDataSource _remoteDataSource;

  DragonBallRepositoryImpl({
    required DragonBallRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<DragonBallEntity>> getUserDragonBalls(String userId) {
    return _remoteDataSource.getUserDragonBalls(userId).map(
          (models) => models.map((model) => DragonBallEntity.fromModel(model)).toList(),
        );
  }

  @override
  Future<DragonBallEntity?> getDragonBall(String userId, String dragonBallId) async {
    final model = await _remoteDataSource.getDragonBall(userId, dragonBallId);
    return model != null ? DragonBallEntity.fromModel(model) : null;
  }

  @override
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
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30));

    final dragonBall = DragonBallModel(
      dragonBallId: const Uuid().v4(),
      userId: userId,
      listingId: listingId,
      orderId: orderId,
      partName: partName,
      imageUrl: imageUrl,
      status: DragonBallStatus.stored,
      storedAt: now,
      expiresAt: expiresAt,
      agreedToTerms: agreedToTerms,
      agreedAt: now,
      purchasePrice: purchasePrice,
      basePartId: basePartId,
      category: category,
    );

    return await _remoteDataSource.createDragonBall(dragonBall);
  }

  @override
  Future<void> updateDragonBallStatus(
    String userId,
    String dragonBallId,
    DragonBallStatus status,
  ) async {
    final dragonBall = await _remoteDataSource.getDragonBall(userId, dragonBallId);
    if (dragonBall == null) {
      throw Exception('DragonBall not found');
    }

    final updatedDragonBall = dragonBall.copyWith(status: status);
    await _remoteDataSource.updateDragonBall(userId, updatedDragonBall);
  }

  @override
  Future<void> linkToBatchShipment(
    String userId,
    String dragonBallId,
    String batchShipmentId,
  ) async {
    final dragonBall = await _remoteDataSource.getDragonBall(userId, dragonBallId);
    if (dragonBall == null) {
      throw Exception('DragonBall not found');
    }

    final updatedDragonBall = dragonBall.copyWith(
      batchShipmentId: batchShipmentId,
      status: DragonBallStatus.packing,
    );
    await _remoteDataSource.updateDragonBall(userId, updatedDragonBall);
  }

  @override
  Future<void> markAsShipped(String userId, String dragonBallId) async {
    final dragonBall = await _remoteDataSource.getDragonBall(userId, dragonBallId);
    if (dragonBall == null) {
      throw Exception('DragonBall not found');
    }

    final updatedDragonBall = dragonBall.copyWith(
      status: DragonBallStatus.shipping,
      shippedAt: DateTime.now(),
    );
    await _remoteDataSource.updateDragonBall(userId, updatedDragonBall);
  }

  @override
  Future<void> markAsDelivered(String userId, String dragonBallId) async {
    final dragonBall = await _remoteDataSource.getDragonBall(userId, dragonBallId);
    if (dragonBall == null) {
      throw Exception('DragonBall not found');
    }

    final updatedDragonBall = dragonBall.copyWith(
      status: DragonBallStatus.delivered,
      deliveredAt: DateTime.now(),
    );
    await _remoteDataSource.updateDragonBall(userId, updatedDragonBall);
  }

  @override
  Future<List<DragonBallEntity>> getExpiringSoonDragonBalls(String userId) async {
    final models = await _remoteDataSource.getExpiringSoonDragonBalls(userId);
    return models.map((model) => DragonBallEntity.fromModel(model)).toList();
  }

  @override
  Future<List<DragonBallEntity>> getStoredDragonBalls(String userId) async {
    final models = await _remoteDataSource.getStoredDragonBalls(userId);
    return models.map((model) => DragonBallEntity.fromModel(model)).toList();
  }

  @override
  Future<void> deleteDragonBall(String userId, String dragonBallId) async {
    await _remoteDataSource.deleteDragonBall(userId, dragonBallId);
  }
}
