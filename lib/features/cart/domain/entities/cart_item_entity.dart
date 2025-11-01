// lib/features/cart/domain/entities/cart_item_entity.dart

class CartItemEntity {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;
  final DateTime addedAt;

  CartItemEntity({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.addedAt,
  });

  double get totalPrice => price * quantity;
}