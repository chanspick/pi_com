
// lib/features/order/data/datasources/order_remote_datasource_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/order/data/models/order_model.dart';
import 'order_remote_datasource.dart';

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  OrderRemoteDataSourceImpl({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createOrder(OrderModel order) {
    return _firestore.collection('orders').doc(order.orderId).set(order.toFirestore());
  }
}
