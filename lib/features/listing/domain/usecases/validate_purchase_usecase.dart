// lib/features/listing/domain/usecases/validate_purchase_usecase.dart
import '../entities/listing_entity.dart';

class ValidatePurchaseUseCase {
  bool call(ListingEntity listing, String currentUserId) {
    if (listing.isSold) {
      throw Exception('이미 판매된 상품입니다.');
    }

    if (listing.sellerId == currentUserId) {
      throw Exception('자신의 판매 상품은 구매할 수 없습니다.');
    }

    return true;
  }
}
