
// lib/features/cart/domain/usecases/validate_purchase.dart

import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';

class ValidatePurchase {
  void call(ListingEntity listing, String userId) {
    if (listing.isSold) {
      throw Exception('이미 판매된 상품입니다.');
    }
    if (listing.sellerId == userId) {
      throw Exception('자신이 판매하는 상품은 구매할 수 없습니다.');
    }
  }
}
