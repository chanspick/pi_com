
// lib/features/order/data/datasources/order_remote_datasource_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/order/data/models/order_model.dart';
import 'order_remote_datasource.dart';

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  OrderRemoteDataSourceImpl({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.orderId).set(order.toFirestore());
    } on FirebaseException catch (e) {
      throw Exception('주문 생성 실패 (Firebase 오류): ${e.message}');
    } catch (e) {
      throw Exception('주문 생성 중 오류 발생: $e');
    }
  }
}
