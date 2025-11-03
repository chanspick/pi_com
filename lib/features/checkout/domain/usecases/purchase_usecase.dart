
// lib/features/checkout/domain/usecases/purchase_usecase.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';
import 'package:pi_com/features/listing/domain/repositories/listing_repository.dart';
import 'package:pi_com/features/order/domain/entities/order_entity.dart';
import 'package:pi_com/features/order/domain/repositories/order_repository.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';

class PurchaseUseCase {
  final OrderRepository _orderRepository;
  final ListingRepository _listingRepository;
  final CartRepository _cartRepository;

  PurchaseUseCase(this._orderRepository, this._listingRepository, this._cartRepository);

  Future<void> call({
    required String userId,
    required List<CartItemEntity> items,
    required String shippingAddress,
  }) async {
    final totalPrice = items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

    final order = OrderEntity(
      orderId: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID generation
      userId: userId,
      items: items,
      totalPrice: totalPrice,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      shippingAddress: shippingAddress,
    );

    // 1. Create order
    await _orderRepository.createOrder(order);

    // 2. Update listing statuses
    for (final item in items) {
      await _listingRepository.updateListingStatus(item.listingId, ListingStatus.sold);
    }

    // 3. Clear cart
    for (final item in items) {
      await _cartRepository.removeFromCart(item.listingId);
    }
  }
}
