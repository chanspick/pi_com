// lib/features/listing/data/models/listing_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/listing_entity.dart';

class ListingModel {
  final String listingId;
  final String basePartId;
  final String sellerId;
  final String brand;
  final String modelName;
  final int price;
  final double conditionScore;
  final List<String> imageUrls;
  final String status;
  final Timestamp createdAt;
  final String? category;
  final String? buyerId;  // 추가
  final Timestamp? soldAt;  // 추가
  final bool? markedForSold;  // 판매완료 마킹 (그래프 데이터 유지용)
  final Timestamp? markedAt;  // 마킹 시간

  ListingModel({
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
    this.buyerId,  // 추가
    this.soldAt,  // 추가
    this.markedForSold,  // 추가
    this.markedAt,  // 추가
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    print('🔍 [ListingModel] Creating from Firestore doc ID: ${doc.id}');
    try {
      // 문서 데이터 확인
      if (!doc.exists) {
        throw Exception('Document does not exist: ${doc.id}');
      }

      final data = doc.data() as Map<String, dynamic>?;

      // 데이터가 null인 경우 처리
      if (data == null) {
        throw Exception('Document data is null: ${doc.id}');
      }

      print('🔍 [ListingModel] Parsing document: ${doc.id}');
      print('📋 [ListingModel] Data fields: ${data.keys.toList()}');

      // imageUrls 안전하게 파싱
      final imageUrlsRaw = data['imageUrls'];
      final List<String> imageUrls;
      if (imageUrlsRaw is List) {
        imageUrls = imageUrlsRaw.map((e) => e.toString()).toList();
      } else {
        imageUrls = [];
        print('⚠️ [ListingModel] No imageUrls found, using empty list');
      }

      // 필수 필드 검증
      if (!data.containsKey('listingId') && doc.id.isEmpty) {
        throw Exception('Missing listingId field and doc.id is empty');
      }

      final model = ListingModel(
        listingId: doc.id,  // ✅ 항상 doc.id 사용 (data['listingId']는 outdated될 수 있음)
        basePartId: data['basePartId'] ?? data['partId'] ?? '',  // ✅ basePartId 우선, fallback으로 partId
        sellerId: data['sellerId'] ?? '',
        brand: data['brand'] ?? '',
        modelName: data['modelName'] ?? '',
        price: (data['price'] ?? 0) is int
            ? (data['price'] ?? 0) as int
            : ((data['price'] ?? 0) as num).toInt(),
        conditionScore: ((data['conditionScore'] ?? 0) as num).toDouble(),
        imageUrls: imageUrls,
        status: data['status'] ?? 'pending',
        createdAt: data['createdAt'] ?? Timestamp.now(),
        category: data['category'],
        buyerId: data['buyerId'],  // 추가
        soldAt: data['soldAt'],  // 추가
        markedForSold: data['markedForSold'],  // 추가
        markedAt: data['markedAt'],  // 추가
      );

      print('✅ [ListingModel] Successfully created model for: ${model.listingId}');
      return model;

    } catch (e, stackTrace) {
      print('❌ [ListingModel] Failed to parse document: ${doc.id}');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  ListingEntity toEntity() {
    try {
      final parsedStatus = _parseStatus(status);
      final dateTime = createdAt.toDate();

      return ListingEntity(
        listingId: listingId,
        basePartId: basePartId,
        sellerId: sellerId,
        brand: brand,
        modelName: modelName,
        price: price,
        conditionScore: conditionScore,
        imageUrls: imageUrls,
        status: parsedStatus,
        createdAt: dateTime,
        category: category,
        markedForSold: markedForSold,
      );
    } catch (e) {

      rethrow;
    }
  }

  static ListingStatus _parseStatus(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    switch (normalizedStatus) {
      case 'available':
        return ListingStatus.available;
      case 'sold':
        return ListingStatus.sold;
      case 'cancelled':
        return ListingStatus.cancelled;
      case 'pending':
        return ListingStatus.pending;
      default:
        return ListingStatus.pending; // 기본값
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'basePartId': basePartId,
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
      if (markedForSold != null) 'markedForSold': markedForSold,
      if (markedAt != null) 'markedAt': markedAt,
    };
  }
}
