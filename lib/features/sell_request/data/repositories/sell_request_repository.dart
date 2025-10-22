// lib/features/sell_request/domain/repositories/sell_request_repository.dart

import '../../../../core/models/sell_request_model.dart'; // ✅ 파일명은 맞음

abstract class SellRequestRepository {
  // 사용자용
  Future<void> createSellRequest(SellRequest sellRequest); // ✅ 수정
  Future<SellRequest?> getSellRequest(String requestId); // ✅ 수정
  Stream<List<SellRequest>> getUserSellRequestsStream(String userId); // ✅ 수정
  Future<void> deleteSellRequest(String requestId);

  // Admin용
  Stream<List<SellRequest>> getAllSellRequestsStream(); // ✅ 수정
  Stream<List<SellRequest>> getSellRequestsByStatusStream( // ✅ 수정
      SellRequestStatus status,
      );
  Future<void> updateSellRequestStatus({
    required String requestId,
    required SellRequestStatus status,
    String? listingId,
    String? adminNotes, // ✅ adminMemo → adminNotes (모델에 맞춤)
  });
}
