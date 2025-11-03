
// lib/features/cart/domain/usecases/update_cart_item_quantity.dart

import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';

class UpdateCartItemQuantity {
  final CartRepository repository;

  UpdateCartItemQuantity(this.repository);

  Future<void> call(String listingId, int quantity) {
    return repository.updateCartItemQuantity(listingId, quantity);
  }
}
