
// lib/features/cart/domain/repositories/cart_repository.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

abstract class CartRepository {
  Future<void> addToCart(CartItemEntity item);
  Stream<List<CartItemEntity>> getCartItems();
  Future<void> removeFromCart(String listingId);
  Future<void> updateCartItemQuantity(String listingId, int quantity);
  Future<void> clearCart();

  /// 장바구니에서 이미 판매된 상품을 제거하고 제거된 상품 목록 반환
  Future<List<CartItemEntity>> removeSoldItemsFromCart();
}
