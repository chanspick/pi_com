
// lib/features/order/domain/entities/order_entity.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderEntity {
  final String orderId;
  final String userId;
  final List<CartItemEntity> items;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final String shippingAddress;

  OrderEntity({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.shippingAddress,
  });
}
