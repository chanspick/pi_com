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
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      listingId: doc.id,
      partId: data['partId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      brand: data['brand'] ?? '',
      modelName: data['modelName'] ?? '',
      price: data['price'] ?? 0,
      conditionScore: data['conditionScore'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      category: data['category'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
    };
  }

  // Model → Entity 변환
  ListingEntity toEntity() {
    return ListingEntity(
      listingId: listingId,
      partId: partId,
      sellerId: sellerId,
      brand: brand,
      modelName: modelName,
      price: price,
      conditionScore: conditionScore,
      imageUrls: imageUrls,
      status: _parseStatus(status),
      createdAt: createdAt.toDate(),
      category: category,
    );
  }

  // Entity → Model 변환
  factory ListingModel.fromEntity(ListingEntity entity) {
    return ListingModel(
      listingId: entity.listingId,
      partId: entity.partId,
      sellerId: entity.sellerId,
      brand: entity.brand,
      modelName: entity.modelName,
      price: entity.price,
      conditionScore: entity.conditionScore,
      imageUrls: entity.imageUrls,
      status: entity.status.name,
      createdAt: Timestamp.fromDate(entity.createdAt),
      category: entity.category,
    );
  }

  static ListingStatus _parseStatus(String status) {
    return ListingStatus.values.firstWhere(
          (e) => e.name == status,
      orElse: () => ListingStatus.pending,
    );
  }
}
