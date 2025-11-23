
// lib/features/order/data/datasources/order_remote_datasource_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/order/data/models/order_model.dart';
import '../../domain/entities/order_entity.dart';
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

  @override
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) {
        return null;
      }
      return OrderModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception('주문 조회 실패 (Firebase 오류): ${e.message}');
    } catch (e) {
      throw Exception('주문 조회 중 오류 발생: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 구매 확정 시 confirmedAt 추가
      if (status == OrderStatus.confirmed) {
        updateData['confirmedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
    } on FirebaseException catch (e) {
      throw Exception('주문 상태 업데이트 실패 (Firebase 오류): ${e.message}');
    } catch (e) {
      throw Exception('주문 상태 업데이트 중 오류 발생: $e');
    }
  }
}
