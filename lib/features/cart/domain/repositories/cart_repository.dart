
// lib/features/cart/domain/repositories/cart_repository.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

abstract class CartRepository {
  Future<void> addToCart(CartItemEntity item);
  Stream<List<CartItemEntity>> getCartItems();
  Future<void> removeFromCart(String productId);
  Future<void> updateCartItemQuantity(String productId, int quantity);
}
