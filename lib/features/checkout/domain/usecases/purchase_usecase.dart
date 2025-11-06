
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
    // 판매자별로 아이템 그룹화
    final Map<String, List<CartItemEntity>> itemsBySeller = {};
    for (final item in items) {
      if (!itemsBySeller.containsKey(item.sellerId)) {
        itemsBySeller[item.sellerId] = [];
      }
      itemsBySeller[item.sellerId]!.add(item);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 판매자별로 주문 생성
    int orderIndex = 0;
    for (final entry in itemsBySeller.entries) {
      final sellerId = entry.key;
      final sellerItems = entry.value;
      final sellerName = sellerItems.first.sellerName;

      final totalPrice = sellerItems.fold(0.0, (sum, item) => sum + item.price * item.quantity);
      final shippingFee = 3000.0; // 판매자당 3000원

      final order = OrderEntity(
        orderId: '${timestamp}_$orderIndex', // 판매자별로 고유한 주문 ID
        userId: userId,
        sellerId: sellerId,
        sellerName: sellerName,
        items: sellerItems,
        totalPrice: totalPrice,
        shippingFee: shippingFee,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        shippingAddress: shippingAddress,
      );

      // 1. 판매자별 주문 생성
      await _orderRepository.createOrder(order);

      // 2. 해당 판매자의 listing 상태 업데이트
      for (final item in sellerItems) {
        await _listingRepository.updateListingStatus(item.listingId, ListingStatus.sold);
      }

      orderIndex++;
    }

    // 3. 장바구니 비우기 (모든 아이템)
    for (final item in items) {
      await _cartRepository.removeFromCart(item.listingId);
    }
  }
}
