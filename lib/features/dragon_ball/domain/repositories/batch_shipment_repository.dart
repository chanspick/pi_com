// lib/features/dragon_ball/domain/repositories/batch_shipment_repository.dart

import 'package:pi_com/features/dragon_ball/domain/entities/batch_shipment_entity.dart';
import 'package:pi_com/core/models/batch_shipment_model.dart';

/// 일괄 배송 Repository 인터페이스
abstract class BatchShipmentRepository {
  /// 사용자의 일괄 배송 목록 스트림 (실시간)
  Stream<List<BatchShipmentEntity>> getUserBatchShipments(String userId);

  /// 특정 일괄 배송 조회
  Future<BatchShipmentEntity?> getBatchShipment(String batchShipmentId);

  /// 일괄 배송 요청 생성
  Future<String> createBatchShipment({
    required String userId,
    required List<String> dragonBallIds,
    required String recipientName,
    required String shippingAddress,
    required String phoneNumber,
    required int shippingCost,
    List<String> additionalServices = const [],
    int additionalServicesCost = 0,
  });

  /// 일괄 배송 상태 업데이트
  Future<void> updateBatchShipmentStatus(
    String batchShipmentId,
    BatchShipmentStatus status,
  );

  /// 운송장 번호 등록
  Future<void> updateTrackingInfo({
    required String batchShipmentId,
    required String trackingNumber,
    String? courier,
  });

  /// 배송 시작 처리
  Future<void> markAsShipped(String batchShipmentId);

  /// 배송 완료 처리
  Future<void> markAsDelivered(String batchShipmentId);

  /// 일괄 배송 취소
  Future<void> cancelBatchShipment(String batchShipmentId);

  /// 대기 중인 일괄 배송 목록
  Future<List<BatchShipmentEntity>> getPendingShipments(String userId);
}
