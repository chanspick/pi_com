// lib/features/dragon_ball/domain/usecases/get_user_batch_shipments_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/entities/batch_shipment_entity.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/batch_shipment_repository.dart';

/// 사용자의 일괄 배송 목록 조회 UseCase
class GetUserBatchShipmentsUseCase {
  final BatchShipmentRepository _repository;

  GetUserBatchShipmentsUseCase(this._repository);

  Stream<List<BatchShipmentEntity>> call(String userId) {
    return _repository.getUserBatchShipments(userId);
  }
}
