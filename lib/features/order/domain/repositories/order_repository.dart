
// lib/features/order/domain/repositories/order_repository.dart

import 'package:pi_com/features/order/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<void> createOrder(OrderEntity order);

  /// 구매 확정
  Future<void> confirmPurchase(String orderId);
}
