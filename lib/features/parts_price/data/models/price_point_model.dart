// lib/features/parts_price/data/models/price_point_model.dart
import '../../domain/entities/price_point_entity.dart';

class PricePointModel {
  final DateTime date;
  final double lowestPrice;
  final double averagePrice;
  final int count;

  PricePointModel({
    required this.date,
    required this.lowestPrice,
    required this.averagePrice,
    required this.count,
  });

  factory PricePointModel.fromMap(Map<String, dynamic> data) {
    return PricePointModel(
      date: DateTime.parse(data['date']),
      lowestPrice: (data['lowestPrice'] ?? 0).toDouble(),
      averagePrice: (data['averagePrice'] ?? 0).toDouble(),
      count: data['count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'lowestPrice': lowestPrice,
      'averagePrice': averagePrice,
      'count': count,
    };
  }

  PricePointEntity toEntity() {
    return PricePointEntity(
      date: date,
      lowestPrice: lowestPrice,
      averagePrice: averagePrice,
      count: count,
    );
  }

  factory PricePointModel.fromEntity(PricePointEntity entity) {
    return PricePointModel(
      date: entity.date,
      lowestPrice: entity.lowestPrice,
      averagePrice: entity.averagePrice,
      count: entity.count,
    );
  }
}
