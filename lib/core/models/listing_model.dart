// lib/core/models/listing_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart' as entity;

enum ListingStatus { available, sold }

class Listing {
  final String listingId;
  final String basePartId;      // BasePart 참조
  final double conditionScore;   // 1~100 컨디션 점수 (실수, ML label용)
  final int price;
  final ListingStatus status;
  final String sellerId;
  final String? buyerId;
  final String brand;            // 비정규화: 브랜드명
  final String modelName;        // 비정규화: 모델명
  final DateTime createdAt;
  final DateTime? soldAt;
  final List<String> imageUrls;
  final String? category;

  Listing({
    required this.listingId,
    required this.basePartId,
    required this.conditionScore,
    required this.price,
    required this.status,
    required this.sellerId,
    this.buyerId,
    required this.brand,
    required this.modelName,
    required this.createdAt,
    this.soldAt,
    required this.imageUrls,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'basePartId': basePartId,
      'conditionScore': conditionScore,
      'price': price,
      'status': status.name,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'brand': brand,
      'modelName': modelName,
      'createdAt': Timestamp.fromDate(createdAt),
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
      'imageUrls': imageUrls,
      'category': category,
    };
  }

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Listing(
      listingId: doc.id,
      basePartId: data['basePartId'] ?? data['partId'] ?? '',  // basePartId 우선, fallback으로 partId
      conditionScore: (data['conditionScore'] as num?)?.toDouble() ?? 100.0,
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status'] == 'sold'
          ? ListingStatus.sold
          : ListingStatus.available,
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'],
      brand: data['brand'] ?? '',
      modelName: data['modelName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      soldAt: (data['soldAt'] as Timestamp?)?.toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'],
    );
  }

  factory Listing.fromMap(Map<String, dynamic> data) {
    return Listing(
      listingId: data['listingId'] ?? '',
      basePartId: data['basePartId'] ?? data['partId'] ?? '',  // basePartId 우선, fallback으로 partId
      conditionScore: (data['conditionScore'] as num?)?.toDouble() ?? 100.0,
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status'] == 'sold'
          ? ListingStatus.sold
          : ListingStatus.available,
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'],
      brand: data['brand'] ?? '',
      modelName: data['modelName'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      soldAt: data['soldAt'] is Timestamp
          ? (data['soldAt'] as Timestamp).toDate()
          : null,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'],
    );
  }

  // copyWith 메서드 (상태 업데이트 시 유용)
  Listing copyWith({
    String? listingId,
    String? basePartId,
    double? conditionScore,
    int? price,
    ListingStatus? status,
    String? sellerId,
    String? buyerId,
    String? brand,
    String? modelName,
    DateTime? createdAt,
    DateTime? soldAt,
    List<String>? imageUrls,
    String? category,
  }) {
    return Listing(
      listingId: listingId ?? this.listingId,
      basePartId: basePartId ?? this.basePartId,
      conditionScore: conditionScore ?? this.conditionScore,
      price: price ?? this.price,
      status: status ?? this.status,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
    );
  }

  entity.ListingEntity toEntity() {
    return entity.ListingEntity(
      listingId: listingId,
      basePartId: basePartId,
      sellerId: sellerId,
      brand: brand,
      modelName: modelName,
      price: price,
      conditionScore: conditionScore,
      imageUrls: imageUrls,
      status: status == ListingStatus.sold ? entity.ListingStatus.sold : entity.ListingStatus.available,
      createdAt: createdAt,
      category: category,
    );
  }
}
