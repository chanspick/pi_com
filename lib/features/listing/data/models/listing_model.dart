// lib/features/listing/data/models/listing_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/listing_entity.dart';

class ListingModel {
  final String listingId;
  final String partId;
  final String sellerId;
  final String brand;
  final String modelName;
  final int price;
  final int conditionScore;
  final List<String> imageUrls;
  final String status;
  final Timestamp createdAt;
  final String? category;
  final String? buyerId;  // 추가
  final Timestamp? soldAt;  // 추가

  ListingModel({
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
    this.buyerId,  // 추가
    this.soldAt,  // 추가
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;


      // imageUrls 안전하게 파싱
      final imageUrlsRaw = data['imageUrls'];
      final List<String> imageUrls;
      if (imageUrlsRaw is List) {
        imageUrls = imageUrlsRaw.map((e) => e.toString()).toList();
      } else {
        imageUrls = [];
      }

      return ListingModel(
        listingId: data['listingId'] ?? doc.id,  // Firestore 필드 우선, 없으면 doc.id
        partId: data['partId'] ?? '',
        sellerId: data['sellerId'] ?? '',
        brand: data['brand'] ?? '',
        modelName: data['modelName'] ?? '',
        price: (data['price'] ?? 0) as int,
        conditionScore: (data['conditionScore'] ?? 0) as int,
        imageUrls: imageUrls,
        status: data['status'] ?? 'pending',
        createdAt: data['createdAt'] ?? Timestamp.now(),
        category: data['category'],
        buyerId: data['buyerId'],  // 추가
        soldAt: data['soldAt'],  // 추가
      );
    } catch (e, stackTrace) {

      rethrow;
    }
  }

  ListingEntity toEntity() {
    try {
      final parsedStatus = _parseStatus(status);
      final dateTime = createdAt.toDate();

      return ListingEntity(
        listingId: listingId,
        partId: partId,
        sellerId: sellerId,
        brand: brand,
        modelName: modelName,
        price: price,
        conditionScore: conditionScore,
        imageUrls: imageUrls,
        status: parsedStatus,
        createdAt: dateTime,
        category: category,
      );
    } catch (e, stackTrace) {

      rethrow;
    }
  }

  static ListingStatus _parseStatus(String status) {
    if (status.toLowerCase().trim() == 'active') {
      return ListingStatus.active;
    }
    return ListingStatus.pending; // 기본값
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'partId': partId,
      'sellerId': sellerId,
      'brand': brand,
      'modelName': modelName,
      'price': price,
      'conditionScore': conditionScore,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': createdAt,
      if (category != null) 'category': category,
      if (buyerId != null) 'buyerId': buyerId,
      if (soldAt != null) 'soldAt': soldAt,
    };
  }
}
