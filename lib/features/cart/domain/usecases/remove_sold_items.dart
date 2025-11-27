// lib/features/cart/domain/usecases/remove_sold_items.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';

class RemoveSoldItems {
  final CartRepository _repository;

  RemoveSoldItems(this._repository);

  /// 장바구니에서 이미 판매된 상품을 제거하고 제거된 상품 목록 반환
  Future<List<CartItemEntity>> call() {
    return _repository.removeSoldItemsFromCart();
  }
}
