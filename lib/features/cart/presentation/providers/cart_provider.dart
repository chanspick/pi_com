// lib/features/cart/presentation/providers/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:pi_com/features/cart/data/datasources/cart_remote_datasource_impl.dart';
import 'package:pi_com/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';
import 'package:pi_com/features/cart/domain/usecases/add_to_cart.dart';
import 'package:pi_com/features/cart/domain/usecases/get_cart_items.dart';
import 'package:pi_com/features/cart/domain/usecases/remove_from_cart.dart';
import 'package:pi_com/features/cart/domain/usecases/update_cart_item_quantity.dart';
import 'package:pi_com/features/cart/domain/usecases/clear_cart.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

// ===========================
// Data Layer Providers
// ===========================

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  return CartRemoteDataSourceImpl();
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final remoteDataSource = ref.watch(cartRemoteDataSourceProvider);
  return CartRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ===========================
// Use Case Providers
// ===========================

final addToCartProvider = Provider<AddToCart>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return AddToCart(repository);
});

final getCartItemsProvider = Provider<GetCartItems>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return GetCartItems(repository);
});

final removeFromCartProvider = Provider<RemoveFromCart>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return RemoveFromCart(repository);
});

final updateCartItemQuantityProvider = Provider<UpdateCartItemQuantity>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return UpdateCartItemQuantity(repository);
});

final clearCartProvider = Provider<ClearCart>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return ClearCart(repository);
});

// ===========================
// Stream Providers
// ===========================

final cartItemsStreamProvider = StreamProvider.autoDispose<List<CartItemEntity>>((ref) {
  final getCartItems = ref.watch(getCartItemsProvider);
  return getCartItems();
});

// ===========================
// Computed Providers
// ===========================

/// 장바구니 총 상품 개수
final cartTotalItemsProvider = Provider<int>((ref) {
  final cartItemsAsync = ref.watch(cartItemsStreamProvider);
  return cartItemsAsync.maybeWhen(
    data: (items) => items.fold(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

/// 장바구니 총 금액 (배송비 제외)
final cartTotalPriceProvider = Provider<int>((ref) {
  final cartItemsAsync = ref.watch(cartItemsStreamProvider);
  return cartItemsAsync.maybeWhen(
    data: (items) => items.fold(0, (sum, item) => sum + item.totalPrice),
    orElse: () => 0,
  );
});

/// 장바구니 비어있는지 확인
final cartIsEmptyProvider = Provider<bool>((ref) {
  final cartItemsAsync = ref.watch(cartItemsStreamProvider);
  return cartItemsAsync.maybeWhen(
    data: (items) => items.isEmpty,
    orElse: () => true,
  );
});