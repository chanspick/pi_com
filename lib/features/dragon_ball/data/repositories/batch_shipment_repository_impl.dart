// lib/features/dragon_ball/data/repositories/batch_shipment_repository_impl.dart

import 'package:pi_com/core/models/batch_shipment_model.dart';
import 'package:pi_com/features/dragon_ball/data/datasources/batch_shipment_remote_datasource.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/batch_shipment_entity.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/batch_shipment_repository.dart';
import 'package:uuid/uuid.dart';

/// 일괄 배송 Repository 구현체
class BatchShipmentRepositoryImpl implements BatchShipmentRepository {
  final BatchShipmentRemoteDataSource _remoteDataSource;

  BatchShipmentRepositoryImpl({
    required BatchShipmentRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<BatchShipmentEntity>> getUserBatchShipments(String userId) {
    return _remoteDataSource.getUserBatchShipments(userId).map(
          (models) => models.map((model) => BatchShipmentEntity.fromModel(model)).toList(),
        );
  }

  @override
  Future<BatchShipmentEntity?> getBatchShipment(String batchShipmentId) async {
    final model = await _remoteDataSource.getBatchShipment(batchShipmentId);
    return model != null ? BatchShipmentEntity.fromModel(model) : null;
  }

  @override
  Future<String> createBatchShipment({
    required String userId,
    required List<String> dragonBallIds,
    required String recipientName,
    required String shippingAddress,
    required String phoneNumber,
    required int shippingCost,
  }) async {
    final batchShipment = BatchShipmentModel(
      batchShipmentId: const Uuid().v4(),
      userId: userId,
      dragonBallIds: dragonBallIds,
      recipientName: recipientName,
      shippingAddress: shippingAddress,
      phoneNumber: phoneNumber,
      shippingCost: shippingCost,
      status: BatchShipmentStatus.pending,
      requestedAt: DateTime.now(),
    );

    return await _remoteDataSource.createBatchShipment(batchShipment);
  }

  @override
  Future<void> updateBatchShipmentStatus(
    String batchShipmentId,
    BatchShipmentStatus status,
  ) async {
    final batchShipment = await _remoteDataSource.getBatchShipment(batchShipmentId);
    if (batchShipment == null) {
      throw Exception('BatchShipment not found');
    }

    final updatedBatchShipment = batchShipment.copyWith(status: status);
    await _remoteDataSource.updateBatchShipment(updatedBatchShipment);
  }

  @override
  Future<void> updateTrackingInfo({
    required String batchShipmentId,
    required String trackingNumber,
    String? courier,
  }) async {
    final batchShipment = await _remoteDataSource.getBatchShipment(batchShipmentId);
    if (batchShipment == null) {
      throw Exception('BatchShipment not found');
    }

    final updatedBatchShipment = batchShipment.copyWith(
      trackingNumber: trackingNumber,
      courier: courier,
    );
    await _remoteDataSource.updateBatchShipment(updatedBatchShipment);
  }

  @override
  Future<void> markAsShipped(String batchShipmentId) async {
    final batchShipment = await _remoteDataSource.getBatchShipment(batchShipmentId);
    if (batchShipment == null) {
      throw Exception('BatchShipment not found');
    }

    final updatedBatchShipment = batchShipment.copyWith(
      status: BatchShipmentStatus.shipped,
      shippedAt: DateTime.now(),
    );
    await _remoteDataSource.updateBatchShipment(updatedBatchShipment);
  }

  @override
  Future<void> markAsDelivered(String batchShipmentId) async {
    final batchShipment = await _remoteDataSource.getBatchShipment(batchShipmentId);
    if (batchShipment == null) {
      throw Exception('BatchShipment not found');
    }

    final updatedBatchShipment = batchShipment.copyWith(
      status: BatchShipmentStatus.delivered,
      deliveredAt: DateTime.now(),
    );
    await _remoteDataSource.updateBatchShipment(updatedBatchShipment);
  }

  @override
  Future<void> cancelBatchShipment(String batchShipmentId) async {
    final batchShipment = await _remoteDataSource.getBatchShipment(batchShipmentId);
    if (batchShipment == null) {
      throw Exception('BatchShipment not found');
    }

    // 대기 중이거나 처리 중인 경우에만 취소 가능
    if (batchShipment.status != BatchShipmentStatus.pending &&
        batchShipment.status != BatchShipmentStatus.processing) {
      throw Exception('Cannot cancel shipment in current status');
    }

    await _remoteDataSource.deleteBatchShipment(batchShipmentId);
  }

  @override
  Future<List<BatchShipmentEntity>> getPendingShipments(String userId) async {
    final models = await _remoteDataSource.getPendingBatchShipments(userId);
    return models.map((model) => BatchShipmentEntity.fromModel(model)).toList();
  }
}
