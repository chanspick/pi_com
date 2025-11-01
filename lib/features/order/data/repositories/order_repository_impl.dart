
// lib/features/order/data/repositories/order_repository_impl.dart

import 'package:pi_com/features/order/data/datasources/order_remote_datasource.dart';
import 'package:pi_com/features/order/data/models/order_model.dart';
import 'package:pi_com/features/order/domain/entities/order_entity.dart';
import 'package:pi_com/features/order/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> createOrder(OrderEntity order) {
    final orderModel = OrderModel.fromEntity(order);
    return remoteDataSource.createOrder(orderModel);
  }
}
