// lib/features/cart/data/datasources/cart_remote_datasource.dart

import 'package:pi_com/features/cart/data/models/cart_item_model.dart';

abstract class CartRemoteDataSource {
  Future<void> addToCart(CartItemModel item);
  Stream<List<CartItemModel>> getCartItems();
  Future<void> removeFromCart(String listingId);
  Future<void> updateCartItemQuantity(String listingId, int quantity);
  Future<void> clearCart();
}