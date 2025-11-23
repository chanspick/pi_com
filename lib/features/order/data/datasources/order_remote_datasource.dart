
// lib/features/order/data/datasources/order_remote_datasource.dart

import 'package:pi_com/features/order/data/models/order_model.dart';
import '../../domain/entities/order_entity.dart';

abstract class OrderRemoteDataSource {
  Future<void> createOrder(OrderModel order);

  /// 주문 조회
  Future<OrderModel?> getOrder(String orderId);

  /// 주문 상태 업데이트
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}
