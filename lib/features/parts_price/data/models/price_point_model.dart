// lib/features/parts_price/data/models/price_point_model.dart
import '../../domain/entities/price_point_entity.dart';

class PricePointModel {
  final DateTime date;
  final double price;
  final int count;

  PricePointModel({
    required this.date,
    required this.price,
    required this.count,
  });

  factory PricePointModel.fromMap(Map<String, dynamic> data) {
    return PricePointModel(
      date: DateTime.parse(data['date']),
      price: (data['price'] ?? 0).toDouble(),
      count: data['count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'price': price,
      'count': count,
    };
  }

  PricePointEntity toEntity() {
    return PricePointEntity(
      date: date,
      price: price,
      count: count,
    );
  }

  factory PricePointModel.fromEntity(PricePointEntity entity) {
    return PricePointModel(
      date: entity.date,
      price: entity.price,
      count: entity.count,
    );
  }
}
