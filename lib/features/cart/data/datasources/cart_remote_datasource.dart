// lib/features/cart/data/datasources/cart_remote_datasource.dart

import 'package:pi_com/features/cart/data/models/cart_item_model.dart';

abstract class CartRemoteDataSource {
  Future<void> addToCart(CartItemModel item);
  Stream<List<CartItemModel>> getCartItems();
  Future<void> removeFromCart(String listingId);
  Future<void> updateCartItemQuantity(String listingId, int quantity);
  Future<void> clearCart();

  /// 장바구니에서 이미 판매된 상품을 제거하고 제거된 상품 목록 반환
  Future<List<CartItemModel>> removeSoldItemsFromCart();
}