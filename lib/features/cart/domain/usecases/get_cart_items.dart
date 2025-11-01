
// lib/features/cart/domain/usecases/get_cart_items.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';

class GetCartItems {
  final CartRepository repository;

  GetCartItems(this.repository);

  Stream<List<CartItemEntity>> call() {
    return repository.getCartItems();
  }
}
