
// lib/features/order/data/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/cart/data/models/cart_item_model.dart';
import 'package:pi_com/features/order/domain/entities/order_entity.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final List<CartItemModel> items;
  final double totalPrice;
  final String status;
  final Timestamp createdAt;
  final String shippingAddress;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.shippingAddress,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId: doc.id,
      userId: data['userId'],
      items: (data['items'] as List).map((item) => CartItemModel.fromFirestore(item)).toList(),
      totalPrice: data['totalPrice'],
      status: data['status'],
      createdAt: data['createdAt'],
      shippingAddress: data['shippingAddress'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toFirestore()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt,
      'shippingAddress': shippingAddress,
    };
  }

  OrderEntity toEntity() {
    return OrderEntity(
      orderId: orderId,
      userId: userId,
      items: items.map((item) => item.toEntity()).toList(),
      totalPrice: totalPrice,
      status: OrderStatus.values.firstWhere((e) => e.toString() == 'OrderStatus.$status', orElse: () => OrderStatus.pending),
      createdAt: createdAt.toDate(),
      shippingAddress: shippingAddress,
    );
  }

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      orderId: entity.orderId,
      userId: entity.userId,
      items: entity.items.map((item) => CartItemModel.fromEntity(item)).toList(),
      totalPrice: entity.totalPrice,
      status: entity.status.toString().split('.').last,
      createdAt: Timestamp.fromDate(entity.createdAt),
      shippingAddress: entity.shippingAddress,
    );
  }
}
