// lib/features/cart/data/models/cart_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

class CartItemModel {
  final String listingId;
  final String sellerId;
  final String sellerName;
  final String partName;
  final String category;
  final int price;
  final int quantity;
  final String imageUrl;
  final int shippingCostSellerRatio;
  final Timestamp addedAt;

  CartItemModel({
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.partName,
    required this.category,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.shippingCostSellerRatio,
    required this.addedAt,
  });

  factory CartItemModel.fromFirestore(Map<String, dynamic> data) {
    return CartItemModel(
      listingId: data['listingId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      partName: data['partName'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0) as int,
      quantity: data['quantity'] ?? 1,
      imageUrl: data['imageUrl'] ?? '',
      shippingCostSellerRatio: data['shippingCostSellerRatio'] ?? 0,
      addedAt: data['addedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'partName': partName,
      'category': category,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'shippingCostSellerRatio': shippingCostSellerRatio,
      'addedAt': addedAt,
    };
  }

  // Model → Entity 변환
  CartItemEntity toEntity() {
    return CartItemEntity(
      listingId: listingId,
      sellerId: sellerId,
      sellerName: sellerName,
      partName: partName,
      category: category,
      price: price,
      quantity: quantity,
      imageUrl: imageUrl,
      shippingCostSellerRatio: shippingCostSellerRatio,
      addedAt: addedAt.toDate(),
    );
  }

  // Entity → Model 변환
  factory CartItemModel.fromEntity(CartItemEntity entity) {
    return CartItemModel(
      listingId: entity.listingId,
      sellerId: entity.sellerId,
      sellerName: entity.sellerName,
      partName: entity.partName,
      category: entity.category,
      price: entity.price,
      quantity: entity.quantity,
      imageUrl: entity.imageUrl,
      shippingCostSellerRatio: entity.shippingCostSellerRatio,
      addedAt: Timestamp.fromDate(entity.addedAt),
    );
  }
}
