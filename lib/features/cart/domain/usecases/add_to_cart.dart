// lib/features/cart/domain/usecases/add_to_cart.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';

class AddToCart {
  final CartRepository repository;

  AddToCart(this.repository);

  Future<void> call(CartItemEntity item) {
    return repository.addToCart(item);
  }
}
