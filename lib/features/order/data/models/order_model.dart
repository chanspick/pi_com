
// lib/features/order/data/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/cart/data/models/cart_item_model.dart';
import 'package:pi_com/features/order/domain/entities/order_entity.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final String sellerId;
  final String sellerName;
  final List<CartItemModel> items;
  final double totalPrice;
  final double shippingFee;
  final String status;
  final Timestamp createdAt;
  final String shippingAddress;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.totalPrice,
    required this.shippingFee,
    required this.status,
    required this.createdAt,
    required this.shippingAddress,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId: doc.id,
      userId: data['userId'],
      sellerId: data['sellerId'],
      sellerName: data['sellerName'],
      items: (data['items'] as List).map((item) => CartItemModel.fromFirestore(item)).toList(),
      totalPrice: data['totalPrice'],
      shippingFee: data['shippingFee'] ?? 3000.0,
      status: data['status'],
      createdAt: data['createdAt'],
      shippingAddress: data['shippingAddress'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'items': items.map((item) => item.toFirestore()).toList(),
      'totalPrice': totalPrice,
      'shippingFee': shippingFee,
      'status': status,
      'createdAt': createdAt,
      'shippingAddress': shippingAddress,
    };
  }

  OrderEntity toEntity() {
    return OrderEntity(
      orderId: orderId,
      userId: userId,
      sellerId: sellerId,
      sellerName: sellerName,
      items: items.map((item) => item.toEntity()).toList(),
      totalPrice: totalPrice,
      shippingFee: shippingFee,
      status: OrderStatus.values.firstWhere((e) => e.toString() == 'OrderStatus.$status', orElse: () => OrderStatus.pending),
      createdAt: createdAt.toDate(),
      shippingAddress: shippingAddress,
    );
  }

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      orderId: entity.orderId,
      userId: entity.userId,
      sellerId: entity.sellerId,
      sellerName: entity.sellerName,
      items: entity.items.map((item) => CartItemModel.fromEntity(item)).toList(),
      totalPrice: entity.totalPrice,
      shippingFee: entity.shippingFee,
      status: entity.status.toString().split('.').last,
      createdAt: Timestamp.fromDate(entity.createdAt),
      shippingAddress: entity.shippingAddress,
    );
  }
}
