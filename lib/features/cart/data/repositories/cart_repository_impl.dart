// lib/features/cart/data/repositories/cart_repository_impl.dart

import 'package:pi_com/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';
import 'package:pi_com/features/cart/data/models/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;

  CartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addToCart(CartItemEntity item) {
    final model = CartItemModel.fromEntity(item);
    return remoteDataSource.addToCart(model);
  }

  @override
  Stream<List<CartItemEntity>> getCartItems() {
    return remoteDataSource.getCartItems().map((models) {
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<void> removeFromCart(String listingId) {
    return remoteDataSource.removeFromCart(listingId);
  }

  @override
  Future<void> updateCartItemQuantity(String listingId, int quantity) {
    return remoteDataSource.updateCartItemQuantity(listingId, quantity);
  }

  @override
  Future<void> clearCart() {
    return remoteDataSource.clearCart();
  }
}