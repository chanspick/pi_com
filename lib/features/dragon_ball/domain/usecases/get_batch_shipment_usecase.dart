// lib/features/dragon_ball/domain/usecases/get_batch_shipment_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/entities/batch_shipment_entity.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/batch_shipment_repository.dart';

/// 특정 일괄 배송 조회 UseCase
class GetBatchShipmentUseCase {
  final BatchShipmentRepository _repository;

  GetBatchShipmentUseCase(this._repository);

  Future<BatchShipmentEntity?> call(String batchShipmentId) {
    return _repository.getBatchShipment(batchShipmentId);
  }
}
