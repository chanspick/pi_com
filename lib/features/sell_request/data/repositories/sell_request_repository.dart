// lib/features/sell_request/domain/repositories/sell_request_repository.dart

import '../../../../core/models/sell_request_model.dart';

abstract class SellRequestRepository {
  // 사용자용
  Future<void> createSellRequest(SellRequest sellRequest);
  Future<SellRequest?> getSellRequest(String requestId);
  Stream<List<SellRequest>> getUserSellRequestsStream(String userId);
  Future<void> deleteSellRequest(String requestId);

  // Admin용
  Stream<List<SellRequest>> getAllSellRequestsStream();
  Stream<List<SellRequest>> getSellRequestsByStatusStream(
      SellRequestStatus status,
      );
  Future<void> updateSellRequestStatus({
    required String requestId,
    required SellRequestStatus status,
    String? listingId,
    String? adminNotes,
  });

  // Batch 작업
  Future<void> createMultipleSellRequests(List<SellRequest> sellRequests);
}
