// lib/features/parts_price/data/models/base_part_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/base_part_entity.dart';

class BasePartModel {
  final String basePartId;
  final String modelName;
  final String category;
  final int lowestPrice;
  final double averagePrice;
  final int listingCount;

  BasePartModel({
    required this.basePartId,
    required this.modelName,
    required this.category,
    required this.lowestPrice,
    required this.averagePrice,
    required this.listingCount,
  });

  factory BasePartModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BasePartModel(
      basePartId: doc.id,
      modelName: data['modelName'] ?? '이름 없음',
      category: data['category'] ?? '',
      lowestPrice: (data['lowestPrice'] as num?)?.toInt() ?? 0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      listingCount: (data['listingCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory BasePartModel.fromMap(Map<String, dynamic> data) {
    return BasePartModel(
      basePartId: data['basePartId'] ?? '',
      modelName: data['modelName'] ?? '이름 없음',
      category: data['category'] ?? '',
      lowestPrice: (data['lowestPrice'] as num?)?.toInt() ?? 0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      listingCount: (data['listingCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'basePartId': basePartId,
      'modelName': modelName,
      'category': category,
      'lowestPrice': lowestPrice,
      'averagePrice': averagePrice,
      'listingCount': listingCount,
    };
  }

  // Model → Entity 변환
  BasePartEntity toEntity() {
    return BasePartEntity(
      basePartId: basePartId,
      modelName: modelName,
      category: category,
      lowestPrice: lowestPrice,
      averagePrice: averagePrice,
      listingCount: listingCount,
    );
  }

  // Entity → Model 변환
  factory BasePartModel.fromEntity(BasePartEntity entity) {
    return BasePartModel(
      basePartId: entity.basePartId,
      modelName: entity.modelName,
      category: entity.category,
      lowestPrice: entity.lowestPrice,
      averagePrice: entity.averagePrice,
      listingCount: entity.listingCount,
    );
  }
}
