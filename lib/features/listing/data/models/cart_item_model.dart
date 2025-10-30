// lib/features/listing/data/models/cart_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cart_item_entity.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;
  final Timestamp addedAt;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.addedAt,
  });

  factory CartItemModel.fromFirestore(Map<String, dynamic> data) {
    return CartItemModel(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      imageUrl: data['imageUrl'] ?? '',
      addedAt: data['addedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'addedAt': addedAt,
    };
  }

  // Model → Entity 변환
  CartItemEntity toEntity() {
    return CartItemEntity(
      productId: productId,
      productName: productName,
      price: price,
      quantity: quantity,
      imageUrl: imageUrl,
      addedAt: addedAt.toDate(),
    );
  }

  // Entity → Model 변환
  factory CartItemModel.fromEntity(CartItemEntity entity) {
    return CartItemModel(
      productId: entity.productId,
      productName: entity.productName,
      price: entity.price,
      quantity: entity.quantity,
      imageUrl: entity.imageUrl,
      addedAt: Timestamp.fromDate(entity.addedAt),
    );
  }
}
