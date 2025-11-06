// lib/features/dragon_ball/domain/usecases/create_batch_shipment_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/repositories/batch_shipment_repository.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';

/// 일괄 배송 요청 생성 UseCase
class CreateBatchShipmentUseCase {
  final BatchShipmentRepository _batchShipmentRepository;
  final DragonBallRepository _dragonBallRepository;

  CreateBatchShipmentUseCase(
    this._batchShipmentRepository,
    this._dragonBallRepository,
  );

  /// 일괄 배송 요청 생성
  /// dragonBallIds에 있는 각 드래곤볼을 batchShipmentId와 연결
  Future<String> call({
    required String userId,
    required List<String> dragonBallIds,
    required String recipientName,
    required String shippingAddress,
    required String phoneNumber,
    required int shippingCost,
    List<String> additionalServices = const [],
    int additionalServicesCost = 0,
  }) async {
    // 1. 일괄 배송 생성
    final batchShipmentId = await _batchShipmentRepository.createBatchShipment(
      userId: userId,
      dragonBallIds: dragonBallIds,
      recipientName: recipientName,
      shippingAddress: shippingAddress,
      phoneNumber: phoneNumber,
      shippingCost: shippingCost,
      additionalServices: additionalServices,
      additionalServicesCost: additionalServicesCost,
    );

    // 2. 각 드래곤볼에 batchShipmentId 연결
    for (final dragonBallId in dragonBallIds) {
      await _dragonBallRepository.linkToBatchShipment(
        userId,
        dragonBallId,
        batchShipmentId,
      );
    }

    return batchShipmentId;
  }
}
