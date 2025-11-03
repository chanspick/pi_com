// lib/features/cart/domain/entities/cart_item_entity.dart

class CartItemEntity {
  final String listingId;
  final String sellerId;
  final String sellerName;
  final String partName;
  final String category;
  final int price;
  final int quantity;
  final String imageUrl;
  final int shippingCostSellerRatio; // 0-100 (0=구매자 전액, 100=판매자 전액)
  final DateTime addedAt;

  CartItemEntity({
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

  int get totalPrice => price * quantity;

  /// 배송비 계산 (구매자 부담분)
  int calculateBuyerShippingCost(int totalShippingCost) {
    return (totalShippingCost * (100 - shippingCostSellerRatio) / 100).round();
  }

  /// 배송비 계산 (판매자 부담분)
  int calculateSellerShippingCost(int totalShippingCost) {
    return (totalShippingCost * shippingCostSellerRatio / 100).round();
  }
}