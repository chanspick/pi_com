// lib/features/listing/domain/entities/listing_entity.dart
enum ListingStatus {
  available,
  sold,
  pending,
  cancelled,
  reserved,
  sold_external;
}

class ListingEntity {
  final String listingId;
  final String basePartId;
  final String sellerId;
  final String brand;
  final String modelName;
  final int price;
  final double conditionScore;
  final List<String> imageUrls;
  final ListingStatus status;
  final DateTime createdAt;
  final String? category;
  final bool? markedForSold;  // 판매완료 마킹 (그래프 데이터 유지용)
  final String? sourceUrl;    // 원본 링크 (당근마켓 등)

  ListingEntity({
    required this.listingId,
    required this.basePartId,
    required this.sellerId,
    required this.brand,
    required this.modelName,
    required this.price,
    required this.conditionScore,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    this.category,
    this.markedForSold,
    this.sourceUrl,
  });

  bool get isSold => status == ListingStatus.sold;
  bool get isAvailable => status == ListingStatus.available;

  bool canBePurchasedBy(String userId) {
    return isAvailable && sellerId != userId;
  }
}

// 🆕 페이지네이션 결과 Entity
class ListingPaginationEntity {
  final List<ListingEntity> listings;
  final dynamic lastDocument; // Firestore DocumentSnapshot (도메인 레이어에서는 opaque)
  final bool hasMore;

  ListingPaginationEntity({
    required this.listings,
    this.lastDocument,
    required this.hasMore,
  });
}
