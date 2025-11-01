// lib/features/cart/presentation/providers/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:pi_com/features/cart/data/datasources/cart_remote_datasource_impl.dart';
import 'package:pi_com/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';
import 'package:pi_com/features/cart/domain/usecases/get_cart_items.dart';
import 'package:pi_com/features/cart/domain/usecases/remove_from_cart.dart';
import 'package:pi_com/features/cart/domain/usecases/update_cart_item_quantity.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  return CartRemoteDataSourceImpl();
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final remoteDataSource = ref.watch(cartRemoteDataSourceProvider);
  return CartRepositoryImpl(remoteDataSource: remoteDataSource);
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

final cartItemsStreamProvider = StreamProvider.autoDispose<List<CartItemEntity>>((ref) {
  final getCartItems = ref.watch(getCartItemsProvider);
  return getCartItems();
});