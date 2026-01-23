
// lib/features/order/data/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/core/constants/app_constants.dart';
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

  // ✅ 추가: 주문 이력 상세 타임스탬프
  final Timestamp? paidAt;           // 결제 완료 시각
  final Timestamp? shippedAt;        // 배송 시작 시각
  final Timestamp? deliveredAt;      // 배송 완료 시각 (⭐ 환불 기한 계산에 필수)
  final Timestamp? confirmedAt;      // 구매 확정 시각

  // ✅ 추가: 환불 관련 필드
  final Timestamp? refundRequestedAt; // 환불 신청 시각
  final Timestamp? refundCompletedAt; // 환불 완료 시각
  final int? refundAmount;            // 환불 금액

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
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.confirmedAt,
    this.refundRequestedAt,
    this.refundCompletedAt,
    this.refundAmount,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId: doc.id,
      userId: data['userId'],
      sellerId: data['sellerId'],
      sellerName: data['sellerName'],
      items: (data['items'] as List).map((item) => CartItemModel.fromFirestore(item)).toList(),
      totalPrice: (data['totalPrice'] as num).toDouble(),
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? AppConstants.defaultShippingFee.toDouble(),
      status: data['status'],
      createdAt: data['createdAt'],
      shippingAddress: data['shippingAddress'],
      paidAt: data['paidAt'],
      shippedAt: data['shippedAt'],
      deliveredAt: data['deliveredAt'],
      confirmedAt: data['confirmedAt'],
      refundRequestedAt: data['refundRequestedAt'],
      refundCompletedAt: data['refundCompletedAt'],
      refundAmount: data['refundAmount'],
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
      'paidAt': paidAt,
      'shippedAt': shippedAt,
      'deliveredAt': deliveredAt,
      'confirmedAt': confirmedAt,
      'refundRequestedAt': refundRequestedAt,
      'refundCompletedAt': refundCompletedAt,
      'refundAmount': refundAmount,
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
      paidAt: paidAt?.toDate(),
      shippedAt: shippedAt?.toDate(),
      deliveredAt: deliveredAt?.toDate(),
      confirmedAt: confirmedAt?.toDate(),
      refundRequestedAt: refundRequestedAt?.toDate(),
      refundCompletedAt: refundCompletedAt?.toDate(),
      refundAmount: refundAmount,
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
      paidAt: entity.paidAt != null ? Timestamp.fromDate(entity.paidAt!) : null,
      shippedAt: entity.shippedAt != null ? Timestamp.fromDate(entity.shippedAt!) : null,
      deliveredAt: entity.deliveredAt != null ? Timestamp.fromDate(entity.deliveredAt!) : null,
      confirmedAt: entity.confirmedAt != null ? Timestamp.fromDate(entity.confirmedAt!) : null,
      refundRequestedAt: entity.refundRequestedAt != null ? Timestamp.fromDate(entity.refundRequestedAt!) : null,
      refundCompletedAt: entity.refundCompletedAt != null ? Timestamp.fromDate(entity.refundCompletedAt!) : null,
      refundAmount: entity.refundAmount,
    );
  }
}
