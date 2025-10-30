// lib/features/listing/domain/entities/listing_entity.dart
enum ListingStatus {
  active,
  sold,
  pending,
  cancelled;
}

class ListingEntity {
  final String listingId;
  final String partId;
  final String sellerId;
  final String brand;
  final String modelName;
  final int price;
  final int conditionScore;
  final List<String> imageUrls;
  final ListingStatus status;
  final DateTime createdAt;
  final String? category;

  ListingEntity({
    required this.listingId,
    required this.partId,
    required this.sellerId,
    required this.brand,
    required this.modelName,
    required this.price,
    required this.conditionScore,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    this.category,
  });

  bool get isSold => status == ListingStatus.sold;
  bool get isActive => status == ListingStatus.active;

  bool canBePurchasedBy(String userId) {
    return isActive && sellerId != userId;
  }
}
