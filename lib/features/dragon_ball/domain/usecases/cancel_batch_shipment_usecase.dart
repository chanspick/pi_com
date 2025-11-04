// lib/features/dragon_ball/domain/usecases/cancel_batch_shipment_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/repositories/batch_shipment_repository.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';
import 'package:pi_com/core/models/dragon_ball_model.dart';

/// 일괄 배송 취소 UseCase
class CancelBatchShipmentUseCase {
  final BatchShipmentRepository _batchShipmentRepository;
  final DragonBallRepository _dragonBallRepository;

  CancelBatchShipmentUseCase(
    this._batchShipmentRepository,
    this._dragonBallRepository,
  );

  /// 일괄 배송 취소 및 연결된 드래곤볼들을 보관 중 상태로 복구
  Future<void> call(String userId, String batchShipmentId) async {
    // 1. 일괄 배송 정보 조회
    final batchShipment = await _batchShipmentRepository.getBatchShipment(batchShipmentId);
    if (batchShipment == null) {
      throw Exception('BatchShipment not found');
    }

    // 2. 연결된 드래곤볼들을 보관 중 상태로 복구
    for (final dragonBallId in batchShipment.dragonBallIds) {
      await _dragonBallRepository.updateDragonBallStatus(
        userId,
        dragonBallId,
        DragonBallStatus.stored,
      );
    }

    // 3. 일괄 배송 취소
    await _batchShipmentRepository.cancelBatchShipment(batchShipmentId);
  }
}
