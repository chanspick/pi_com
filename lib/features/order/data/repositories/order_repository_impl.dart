
// lib/features/order/data/repositories/order_repository_impl.dart

import 'package:pi_com/features/order/data/datasources/order_remote_datasource.dart';
import 'package:pi_com/features/order/data/models/order_model.dart';
import 'package:pi_com/features/order/domain/entities/order_entity.dart';
import 'package:pi_com/features/order/domain/repositories/order_repository.dart';
import '../../../../core/utils/notification_helper.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final NotificationHelper _notificationHelper = NotificationHelper();

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> createOrder(OrderEntity order) {
    final orderModel = OrderModel.fromEntity(order);
    return remoteDataSource.createOrder(orderModel);
  }

  @override
  Future<void> confirmPurchase(String orderId) async {
    // 1. 주문 정보 조회
    final order = await remoteDataSource.getOrder(orderId);
    if (order == null) {
      throw Exception('주문을 찾을 수 없습니다');
    }

    // 2. 상태를 confirmed로 업데이트
    await remoteDataSource.updateOrderStatus(
      orderId,
      OrderStatus.confirmed,
    );

    // 3. 판매자에게 정산 대기 알림 발송
    await _notificationHelper.notifySettlementPending(
      sellerId: order.sellerId,
      orderId: orderId,
      partName: order.items.length == 1
          ? order.items.first.partName
          : '${order.items.first.partName} 외 ${order.items.length - 1}건',
      settlementAmount: (order.totalPrice + order.shippingFee).toInt(),
    );
  }
}
