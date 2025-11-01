
// lib/features/cart/domain/usecases/remove_from_cart.dart

import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';

class RemoveFromCart {
  final CartRepository repository;

  RemoveFromCart(this.repository);

  Future<void> call(String productId) {
    return repository.removeFromCart(productId);
  }
}
