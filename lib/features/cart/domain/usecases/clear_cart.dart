// lib/features/cart/domain/usecases/clear_cart.dart

import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';

class ClearCart {
  final CartRepository repository;

  ClearCart(this.repository);

  Future<void> call() {
    return repository.clearCart();
  }
}
