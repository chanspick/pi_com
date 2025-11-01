
// lib/features/order/data/datasources/order_remote_datasource.dart

import 'package:pi_com/features/order/data/models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<void> createOrder(OrderModel order);
}
