// lib/core/models/base_part_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BasePart {
  final String basePartId;
  final String modelName;
  final String category;
  final String brand;  // 제조사 (예: Intel, AMD, Samsung)
  // Cloud Function이 업데이트해 줄 가격 통계 필드
  final int lowestPrice;
  final double averagePrice;
  final int listingCount;

  BasePart({
    required this.basePartId,
    required this.modelName,
    required this.category,
    this.brand = '',  // 기본값: 빈 문자열
    required this.lowestPrice,
    required this.averagePrice,
    required this.listingCount,
  });

  factory BasePart.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BasePart(
      basePartId: doc.id,
      modelName: data['modelName'] ?? '이름 없음',
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      lowestPrice: (data['lowestPrice'] as num?)?.toInt() ?? 0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      listingCount: (data['listingCount'] as num?)?.toInt() ?? 0,
    );
  }

  // === 추가: fromMap 팩토리 생성자 ===
  factory BasePart.fromMap(Map<String, dynamic> data) {
    return BasePart(
      basePartId: data['basePartId'] ?? data['objectID'] ?? '',
      modelName: data['modelName'] ?? '이름 없음',
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      lowestPrice: (data['lowestPrice'] as num?)?.toInt() ?? 0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      listingCount: (data['listingCount'] as num?)?.toInt() ?? 0,
    );
  }

  // === 추가: toMap 메서드 (필요시 사용) ===
  Map<String, dynamic> toMap() {
    return {
      'basePartId': basePartId,
      'modelName': modelName,
      'category': category,
      'brand': brand,
      'lowestPrice': lowestPrice,
      'averagePrice': averagePrice,
      'listingCount': listingCount,
    };
  }
}
