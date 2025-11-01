// lib/features/cart/data/datasources/cart_remote_datasource.dart

import 'package:pi_com/features/cart/data/models/cart_item_model.dart';

abstract class CartRemoteDataSource {
  Future<void> addToCart(CartItemModel item);
  Stream<List<CartItemModel>> getCartItems();
  Future<void> removeFromCart(String productId);
  Future<void> updateCartItemQuantity(String productId, int quantity);
}